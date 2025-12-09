"""Script to import VietnamRestaurants.csv into MongoDB."""

import sys
import os
from pathlib import Path

# Add Backend directory to path so we can import modules
backend_path = Path(__file__).parent.parent.parent / "Backend"
sys.path.insert(0, str(backend_path))

import pandas as pd
import asyncio
from datetime import datetime
from pymongo import MongoClient
from typing import List, Dict
import dotenv

# Load environment variables
dotenv.load_dotenv(backend_path / ".env")


def transform_csv_row(row: pd.Series) -> Dict:
    """
    Transform a CSV row into MongoDB document format.
    
    Args:
        row: Pandas Series representing a CSV row
        
    Returns:
        Dict: MongoDB document with GeoJSON location format
    """
    # Create GeoJSON Point for geospatial queries
    # MongoDB expects [longitude, latitude] order
    doc = {
        "name": str(row['Name']).strip(),
        "category": str(row['Category']).strip(),
        "address": str(row['Address']).strip(),
        "latitude": float(row['Latitude']),
        "longitude": float(row['Longitude']),
        "location": {
            "type": "Point",
            "coordinates": [float(row['Longitude']), float(row['Latitude'])]  # [lng, lat]
        },
        "rating": float(row['Rating']) if pd.notna(row['Rating']) else None,
        "google_maps_link": str(row['Link']).strip() if pd.notna(row['Link']) else None,
        "district": str(row['District']).strip() if pd.notna(row['District']) else None,
        "province": str(row['Province']).strip() if pd.notna(row['Province']) else None,
        "full_location": str(row['Full_Location']).strip() if pd.notna(row['Full_Location']) else None,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    return doc


def load_csv_to_mongodb(
    csv_path: str,
    connection_string: str = None,
    database_name: str = "smart_food_db",
    collection_name: str = "restaurants",
    batch_size: int = 1000,
    drop_existing: bool = False
):
    """
    Load CSV data into MongoDB collection.
    
    Args:
        csv_path: Path to the CSV file
        connection_string: MongoDB connection string (default from env)
        database_name: Name of the database
        collection_name: Name of the collection
        batch_size: Number of documents to insert at once
        drop_existing: If True, drop existing collection before import
    """
    print(f"🚀 Starting CSV import to MongoDB...")
    print(f"📁 CSV file: {csv_path}")
    
    # Get connection string from environment if not provided
    if connection_string is None:
        connection_string = os.getenv("MONGODB_CONNECTION_STRING", "mongodb://localhost:27017")
    
    print(f"🔌 Connecting to MongoDB: {connection_string.split('@')[-1] if '@' in connection_string else connection_string}")
    
    try:
        # Connect to MongoDB
        client = MongoClient(connection_string)
        db = client[database_name]
        collection = db[collection_name]
        
        # Test connection
        client.admin.command('ping')
        print(f"✅ Connected to MongoDB successfully")
        
        # Drop existing collection if requested
        if drop_existing:
            print(f"⚠️  Dropping existing collection: {collection_name}")
            collection.drop()
            print(f"✅ Collection dropped")
        
        # Read CSV file
        print(f"📖 Reading CSV file...")
        df = pd.read_csv(csv_path)
        total_rows = len(df)
        print(f"📊 Found {total_rows:,} records in CSV")
        
        # Transform and insert data in batches
        print(f"🔄 Transforming and inserting data (batch size: {batch_size})...")
        
        documents = []
        inserted_count = 0
        
        for idx, row in df.iterrows():
            try:
                doc = transform_csv_row(row)
                documents.append(doc)
                
                # Insert batch when batch_size is reached
                if len(documents) >= batch_size:
                    collection.insert_many(documents)
                    inserted_count += len(documents)
                    print(f"  ✓ Inserted {inserted_count:,} / {total_rows:,} documents ({inserted_count/total_rows*100:.1f}%)")
                    documents = []
                    
            except Exception as e:
                print(f"  ⚠️  Error processing row {idx}: {e}")
                continue
        
        # Insert remaining documents
        if documents:
            collection.insert_many(documents)
            inserted_count += len(documents)
            print(f"  ✓ Inserted {inserted_count:,} / {total_rows:,} documents ({inserted_count/total_rows*100:.1f}%)")
        
        print(f"\n✅ Import completed successfully!")
        print(f"📊 Total documents inserted: {inserted_count:,}")
        
        # Create indexes
        print(f"\n🔧 Creating indexes...")
        
        # Geospatial index
        collection.create_index([("location", "2dsphere")])
        print(f"  ✓ Created geospatial index on 'location'")
        
        # Text search index
        collection.create_index([
            ("name", "text"),
            ("category", "text"),
            ("address", "text")
        ], name="text_search_index")
        print(f"  ✓ Created text search index")
        
        # Compound indexes
        collection.create_index([("category", 1), ("rating", -1)], name="category_rating_index")
        print(f"  ✓ Created compound index on 'category' and 'rating'")
        
        collection.create_index([("province", 1), ("district", 1), ("rating", -1)], name="location_rating_index")
        print(f"  ✓ Created compound index on 'province', 'district', and 'rating'")
        
        collection.create_index([("rating", -1)], name="rating_index")
        print(f"  ✓ Created index on 'rating'")
        
        print(f"\n✅ All indexes created successfully!")
        
        # Show some statistics
        print(f"\n📈 Collection Statistics:")
        print(f"  Total documents: {collection.count_documents({}):,}")
        print(f"  Categories: {len(collection.distinct('category'))}")
        print(f"  Provinces: {len(collection.distinct('province'))}")
        print(f"  Districts: {len(collection.distinct('district'))}")
        
        # Show sample categories
        categories = collection.distinct('category')
        print(f"\n📋 Categories found: {', '.join(categories[:10])}" + (" ..." if len(categories) > 10 else ""))
        
        # Close connection
        client.close()
        print(f"\n🎉 Import process completed successfully!")
        
    except Exception as e:
        print(f"\n❌ Error during import: {e}")
        raise


if __name__ == "__main__":
    # Path to CSV file
    csv_file = Path(__file__).parent.parent / "VietnamRestaurants.csv"
    
    if not csv_file.exists():
        print(f"❌ CSV file not found: {csv_file}")
        sys.exit(1)
    
    print("=" * 80)
    print("CSV to MongoDB Import Tool")
    print("=" * 80)
    print()
    
    # Ask user if they want to drop existing collection
    drop = input("⚠️  Drop existing 'restaurants' collection? (yes/no) [no]: ").strip().lower()
    drop_existing = drop in ['yes', 'y']
    
    if drop_existing:
        confirm = input("⚠️  Are you sure? This will delete all existing data! (yes/no) [no]: ").strip().lower()
        drop_existing = confirm in ['yes', 'y']
    
    print()
    
    # Run import
    load_csv_to_mongodb(
        csv_path=str(csv_file),
        drop_existing=drop_existing
    )
