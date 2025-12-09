"""
Simple script to import Data_100k_AI_Refined.csv to MongoDB Atlas
"""

import pandas as pd
from pymongo import MongoClient, GEOSPHERE, TEXT, ASCENDING, DESCENDING

# MongoDB Atlas connection string
CONNECTION_STRING = "mongodb+srv://ndhung2431_db_user:dfyyXhRZ30obpdX2@foodrestaurant.hbwst3c.mongodb.net/smart_food_db?retryWrites=true&w=majority&appName=FoodRestaurant&tlsAllowInvalidCertificates=true"

def main():
    print("=" * 60)
    print("🚀 Starting Import Process")
    print("=" * 60)
    
    # 1. Connect to MongoDB
    print("\n1️⃣ Connecting to MongoDB Atlas...")
    client = MongoClient(
        CONNECTION_STRING,
        tlsAllowInvalidCertificates=True  # For macOS SSL issues
    )
    db = client.smart_food_db
    collection = db.restaurants
    
    # Test connection
    client.admin.command('ping')
    print("✅ Connected successfully!")
    
    # 2. Load CSV
    print("\n2️⃣ Loading CSV file...")
    csv_path = "/Users/nguyenduchung/Smart-Food-Recommendation-System/Data/Data_100k_AI_Refined.csv"
    df = pd.read_csv(csv_path)
    print(f"✅ Loaded {len(df)} records from CSV")
    
    # 3. Clean data
    print("\n3️⃣ Cleaning data...")
    original_count = len(df)
    df = df.dropna(subset=['Name', 'Latitude', 'Longitude'])
    dropped_count = original_count - len(df)
    if dropped_count > 0:
        print(f"⚠️  Dropped {dropped_count} records with missing Name/Latitude/Longitude")
    print(f"✅ {len(df)} valid records ready to import")
    
    # 4. Transform to MongoDB documents
    print("\n4️⃣ Transforming data...")
    documents = []
    
    for idx, row in df.iterrows():
        try:
            # Parse tags
            tags = []
            if pd.notna(row.get('Full_Tags')) and str(row['Full_Tags']).strip():
                tags = [tag.strip() for tag in str(row['Full_Tags']).split(',')]
            
            doc = {
                'name': str(row['Name']),
                'category': str(row['Category']) if pd.notna(row.get('Category')) else 'Unknown',
                'address': str(row['Address']) if pd.notna(row.get('Address')) else '',
                'rating': float(row['Rating']) if pd.notna(row.get('Rating')) else 0.0,
                'link': str(row['Link']) if pd.notna(row.get('Link')) else '',
                'district': str(row['District']) if pd.notna(row.get('District')) else '',
                'province': str(row['Province']) if pd.notna(row.get('Province')) else '',
                'ward': str(row['Ward']) if pd.notna(row.get('Ward')) else '',
                'full_location': str(row['Full_Location']) if pd.notna(row.get('Full_Location')) else '',
                'tags': tags,
                'location': {
                    'type': 'Point',
                    'coordinates': [float(row['Longitude']), float(row['Latitude'])]
                }
            }
            
            documents.append(doc)
            
            # Progress indicator
            if (idx + 1) % 5000 == 0:
                print(f"   Processed {idx + 1}/{len(df)} records...")
                
        except Exception as e:
            print(f"⚠️  Error at row {idx}: {e}")
            continue
    
    print(f"✅ Transformed {len(documents)} documents")
    
    # 5. Import to MongoDB
    print("\n5️⃣ Importing to MongoDB Atlas...")
    batch_size = 1000
    total = len(documents)
    
    for i in range(0, total, batch_size):
        batch = documents[i:i + batch_size]
        collection.insert_many(batch, ordered=False)
        progress = min(i + batch_size, total)
        print(f"   Imported {progress}/{total} ({progress*100//total}%)")
    
    print(f"✅ Successfully imported {total} documents!")
    
    # 6. Create indexes
    print("\n6️⃣ Creating indexes...")
    
    # Geospatial index
    collection.create_index([("location", GEOSPHERE)], name="location_2dsphere")
    print("   ✅ Geospatial index")
    
    # Text search index
    collection.create_index([
        ("name", TEXT),
        ("category", TEXT),
        ("address", TEXT),
        ("tags", TEXT)
    ], name="text_search_index")
    print("   ✅ Text search index")
    
    # Compound indexes
    collection.create_index([("category", ASCENDING), ("rating", DESCENDING)], name="category_rating_idx")
    print("   ✅ Category + Rating index")
    
    collection.create_index([("province", ASCENDING), ("district", ASCENDING), ("rating", DESCENDING)], name="location_rating_idx")
    print("   ✅ Province + District + Rating index")
    
    collection.create_index([("rating", DESCENDING)], name="rating_idx")
    print("   ✅ Rating index")
    
    collection.create_index([("tags", ASCENDING)], name="tags_idx")
    print("   ✅ Tags index")
    
    # 7. Verify
    print("\n7️⃣ Verification...")
    count = collection.count_documents({})
    print(f"📊 Total documents in collection: {count:,}")
    
    # Show sample
    sample = collection.find_one()
    print(f"\n📄 Sample document:")
    print(f"   Name: {sample['name']}")
    print(f"   Category: {sample['category']}")
    print(f"   Rating: {sample['rating']}")
    print(f"   Tags: {sample.get('tags', [])[:3]}..." if sample.get('tags') else "   Tags: []")
    print(f"   Location: {sample['location']}")
    
    # List all indexes
    indexes = list(collection.list_indexes())
    print(f"\n📋 Indexes created ({len(indexes)} total):")
    for idx in indexes:
        print(f"   - {idx['name']}")
    
    # Close connection
    client.close()
    
    print("\n" + "=" * 60)
    print("✅ IMPORT COMPLETED SUCCESSFULLY!")
    print("=" * 60)

if __name__ == "__main__":
    main()
