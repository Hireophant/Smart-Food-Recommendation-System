"""
Reimport refined restaurant data to MongoDB Atlas.
1. Drop old restaurants collection
2. Import Data_100k_AI_Refined.csv with GeoJSON format
3. Create indexes for optimal performance
"""

import os
import sys
import pandas as pd
from pymongo import MongoClient, GEOSPHERE, TEXT, ASCENDING, DESCENDING
from dotenv import load_dotenv
from pathlib import Path

# Add Backend to path to use utils
backend_path = Path(__file__).parent.parent.parent / "Backend"
sys.path.insert(0, str(backend_path))

from utils import Logger

# Load environment variables
env_path = backend_path / ".env"
load_dotenv(env_path)

def connect_to_mongodb():
    """Connect to MongoDB Atlas."""
    try:
        connection_string = os.getenv("MONGODB_CONNECTION_STRING")
        if not connection_string:
            raise ValueError("MONGODB_CONNECTION_STRING not found in .env file")
        
        client = MongoClient(connection_string)
        
        # Test connection
        client.admin.command('ping')
        Logger.LogInfo("✅ Connected to MongoDB Atlas successfully")
        
        return client
    except Exception as e:
        Logger.LogException(e, "Failed to connect to MongoDB")
        raise

def drop_old_collection(db):
    """Drop old restaurants collection."""
    try:
        collection_name = "restaurants"
        
        # Check if collection exists
        if collection_name in db.list_collection_names():
            db[collection_name].drop()
            Logger.LogInfo(f"🗑️  Dropped old collection: {collection_name}")
        else:
            Logger.LogInfo(f"ℹ️  Collection '{collection_name}' does not exist, skipping drop")
            
    except Exception as e:
        Logger.LogException(e, "Failed to drop collection")
        raise

def load_and_transform_data(csv_path):
    """Load CSV and transform to MongoDB-ready format."""
    try:
        Logger.LogInfo(f"📖 Loading data from: {csv_path}")
        
        # Read CSV
        df = pd.read_csv(csv_path)
        Logger.LogInfo(f"📊 Loaded {len(df)} records from CSV")
        
        # Drop rows with missing critical fields
        original_count = len(df)
        df = df.dropna(subset=['Name', 'Latitude', 'Longitude'])
        dropped_count = original_count - len(df)
        
        if dropped_count > 0:
            Logger.LogInfo(f"⚠️  Dropped {dropped_count} records with missing Name/Latitude/Longitude")
        
        # Transform to MongoDB documents with GeoJSON
        documents = []
        for idx, row in df.iterrows():
            try:
                # Create GeoJSON location
                longitude = float(row['Longitude'])
                latitude = float(row['Latitude'])
                
                # Parse tags if available
                tags = []
                if pd.notna(row.get('Full_Tags')) and row['Full_Tags'].strip():
                    tags = [tag.strip() for tag in str(row['Full_Tags']).split(',')]
                
                doc = {
                    'name': str(row['Name']),
                    'category': str(row['Category']) if pd.notna(row['Category']) else 'Unknown',
                    'address': str(row['Address']) if pd.notna(row['Address']) else '',
                    'rating': float(row['Rating']) if pd.notna(row['Rating']) else 0.0,
                    'link': str(row['Link']) if pd.notna(row['Link']) else '',
                    'district': str(row['District']) if pd.notna(row['District']) else '',
                    'province': str(row['Province']) if pd.notna(row['Province']) else '',
                    'ward': str(row['Ward']) if pd.notna(row['Ward']) else '',
                    'full_location': str(row['Full_Location']) if pd.notna(row['Full_Location']) else '',
                    'tags': tags,  # NEW: Tags for recommendation
                    'location': {
                        'type': 'Point',
                        'coordinates': [longitude, latitude]  # GeoJSON format: [lng, lat]
                    }
                }
                
                documents.append(doc)
                
            except (ValueError, TypeError) as e:
                Logger.LogInfo(f"⚠️  Skipping row {idx} due to invalid data: {e}")
                continue
        
        Logger.LogInfo(f"✅ Transformed {len(documents)} documents successfully")
        return documents
        
    except Exception as e:
        Logger.LogException(e, "Failed to load and transform data")
        raise

def import_data_to_mongodb(db, documents):
    """Import documents to MongoDB in batches."""
    try:
        collection = db.restaurants
        batch_size = 1000
        total = len(documents)
        
        Logger.LogInfo(f"📤 Importing {total} documents in batches of {batch_size}...")
        
        for i in range(0, total, batch_size):
            batch = documents[i:i + batch_size]
            collection.insert_many(batch, ordered=False)
            
            progress = min(i + batch_size, total)
            Logger.LogInfo(f"   Progress: {progress}/{total} ({progress*100//total}%)")
        
        Logger.LogInfo(f"✅ Successfully imported {total} documents")
        
        # Verify count
        count = collection.count_documents({})
        Logger.LogInfo(f"📊 Total documents in collection: {count}")
        
    except Exception as e:
        Logger.LogException(e, "Failed to import data")
        raise

def create_indexes(db):
    """Create indexes for optimal query performance."""
    try:
        collection = db.restaurants
        
        Logger.LogInfo("🔧 Creating indexes...")
        
        # 1. Geospatial index (CRITICAL for nearby search)
        collection.create_index([("location", GEOSPHERE)], name="location_2dsphere")
        Logger.LogInfo("   ✅ Created geospatial index on 'location'")
        
        # 2. Text search index (name, category, address, tags)
        collection.create_index([
            ("name", TEXT),
            ("category", TEXT),
            ("address", TEXT),
            ("tags", TEXT)  # NEW: Include tags in text search
        ], name="text_search_index")
        Logger.LogInfo("   ✅ Created text search index")
        
        # 3. Compound index: category + rating
        collection.create_index([
            ("category", ASCENDING),
            ("rating", DESCENDING)
        ], name="category_rating_idx")
        Logger.LogInfo("   ✅ Created index on 'category' + 'rating'")
        
        # 4. Compound index: province + district + rating
        collection.create_index([
            ("province", ASCENDING),
            ("district", ASCENDING),
            ("rating", DESCENDING)
        ], name="location_rating_idx")
        Logger.LogInfo("   ✅ Created index on 'province' + 'district' + 'rating'")
        
        # 5. Rating index for sorting
        collection.create_index([("rating", DESCENDING)], name="rating_idx")
        Logger.LogInfo("   ✅ Created index on 'rating'")
        
        # 6. Tags index for tag-based filtering (NEW)
        collection.create_index([("tags", ASCENDING)], name="tags_idx")
        Logger.LogInfo("   ✅ Created index on 'tags'")
        
        Logger.LogInfo("✅ All indexes created successfully")
        
        # Show all indexes
        indexes = list(collection.list_indexes())
        Logger.LogInfo(f"📋 Total indexes: {len(indexes)}")
        for idx in indexes:
            Logger.LogInfo(f"   - {idx['name']}")
        
    except Exception as e:
        Logger.LogException(e, "Failed to create indexes")
        raise

def main():
    """Main execution flow."""
    try:
        Logger.LogInfo("=" * 60)
        Logger.LogInfo("🚀 Starting MongoDB Atlas Reimport Process")
        Logger.LogInfo("=" * 60)
        
        # 1. Connect to MongoDB
        client = connect_to_mongodb()
        db = client.smart_food_db
        
        # 2. Drop old collection
        Logger.LogInfo("\n" + "=" * 60)
        Logger.LogInfo("STEP 1: Drop old collection")
        Logger.LogInfo("=" * 60)
        drop_old_collection(db)
        
        # 3. Load and transform data
        Logger.LogInfo("\n" + "=" * 60)
        Logger.LogInfo("STEP 2: Load and transform data")
        Logger.LogInfo("=" * 60)
        csv_path = Path(__file__).parent.parent / "Data_100k_AI_Refined.csv"
        documents = load_and_transform_data(csv_path)
        
        # 4. Import to MongoDB
        Logger.LogInfo("\n" + "=" * 60)
        Logger.LogInfo("STEP 3: Import to MongoDB")
        Logger.LogInfo("=" * 60)
        import_data_to_mongodb(db, documents)
        
        # 5. Create indexes
        Logger.LogInfo("\n" + "=" * 60)
        Logger.LogInfo("STEP 4: Create indexes")
        Logger.LogInfo("=" * 60)
        create_indexes(db)
        
        # 6. Summary
        Logger.LogInfo("\n" + "=" * 60)
        Logger.LogInfo("✅ IMPORT COMPLETED SUCCESSFULLY")
        Logger.LogInfo("=" * 60)
        
        # Show sample document
        sample = db.restaurants.find_one()
        Logger.LogInfo("\n📄 Sample document:")
        Logger.LogInfo(f"   Name: {sample.get('name')}")
        Logger.LogInfo(f"   Category: {sample.get('category')}")
        Logger.LogInfo(f"   Rating: {sample.get('rating')}")
        Logger.LogInfo(f"   Location: {sample.get('location')}")
        Logger.LogInfo(f"   Tags: {sample.get('tags')}")
        
        # Close connection
        client.close()
        Logger.LogInfo("\n🔒 MongoDB connection closed")
        
    except Exception as e:
        Logger.LogException(e, "Main process failed")
        sys.exit(1)

if __name__ == "__main__":
    main()
