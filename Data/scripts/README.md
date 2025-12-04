# MongoDB Setup Guide

## Prerequisites

1. **Install MongoDB** (choose one):
   
   **Option A - Local MongoDB (macOS):**
   ```bash
   brew tap mongodb/brew
   brew install mongodb-community
   brew services start mongodb-community
   ```
   
   **Option B - Docker:**
   ```bash
   docker run -d -p 27017:27017 --name mongodb mongo:latest
   ```
   
   **Option C - MongoDB Atlas (Cloud - Free):**
   - Sign up at https://www.mongodb.com/cloud/atlas
   - Create a free cluster
   - Get connection string

2. **Install Python dependencies:**
   ```bash
   cd Backend/
   pip install -r requirements.txt
   ```

## Configuration

1. **Create `.env` file:**
   ```bash
   cd Backend/
   cp .env.example .env
   ```

2. **Edit `.env` with your MongoDB connection:**
   ```env
   # For local MongoDB:
   MONGODB_CONNECTION_STRING=mongodb://localhost:27017/smart_food_db
   
   # For MongoDB Atlas:
   MONGODB_CONNECTION_STRING=mongodb+srv://username:password@cluster.mongodb.net/smart_food_db
   ```

3. **Config file** is already created at `Backend/data/configs/general.json`

## Import Data

Run the import script to load the CSV data into MongoDB:

```bash
cd Data/scripts/
python import_to_mongodb.py
```

This will:
- ✅ Connect to MongoDB
- ✅ Import all 36,175+ restaurants from CSV
- ✅ Create GeoJSON format for location queries
- ✅ Create all necessary indexes

**Expected output:**
```
🚀 Starting CSV import to MongoDB...
📁 CSV file: VietnamRestaurants.csv
🔌 Connecting to MongoDB: localhost:27017
✅ Connected to MongoDB successfully
📖 Reading CSV file...
📊 Found 36,175 records in CSV
🔄 Transforming and inserting data...
  ✓ Inserted 36,175 / 36,175 documents (100.0%)
✅ Import completed successfully!
```

## Verify Installation

**Method 1 - Using mongosh:**
```bash
mongosh
use smart_food_db
db.restaurants.countDocuments()  # Should return 36175
db.restaurants.findOne()         # Show sample document
```

**Method 2 - Run Backend:**
```bash
cd Backend/
uvicorn app:app --reload
```

Check logs for:
```
[DATE TIME] SmartFoodBackend - INFO: MongoDB connected successfully to database: smart_food_db
[DATE TIME] SmartFoodBackend - INFO: All MongoDB indexes created successfully
```

## Database Schema

**Collection: `restaurants`**
```json
{
  "_id": ObjectId,
  "name": "Restaurant Name",
  "category": "Cafe",
  "address": "District, City",
  "latitude": 21.042939,
  "longitude": 105.8391546,
  "location": {
    "type": "Point",
    "coordinates": [105.8391546, 21.042939]
  },
  "rating": 4.7,
  "google_maps_link": "https://...",
  "district": "Quận Ba Đình",
  "province": "Thành phố Hà Nội",
  "full_location": "Quận Ba Đình, Thành phố Hà Nội",
  "created_at": ISODate,
  "updated_at": ISODate
}
```

## Indexes Created

1. **Geospatial Index** - For nearby search
   ```javascript
   { "location": "2dsphere" }
   ```

2. **Text Search Index** - For name/category/address search
   ```javascript
   { "name": "text", "category": "text", "address": "text" }
   ```

3. **Compound Indexes** - For efficient filtering
   ```javascript
   { "category": 1, "rating": -1 }
   { "province": 1, "district": 1, "rating": -1 }
   { "rating": -1 }
   ```

## Troubleshooting

**Connection refused:**
- Make sure MongoDB is running: `brew services list` or `docker ps`
- Check connection string in `.env`

**Import fails:**
- Check CSV file path: `Data/VietnamRestaurants.csv`
- Verify pandas is installed: `pip install pandas`

**Permission denied:**
- If using MongoDB Atlas, check IP whitelist
- Verify username/password in connection string

## Next Steps

After successful setup:
1. ✅ MongoDB is running
2. ✅ Data is imported (36,175 restaurants)
3. ✅ Indexes are created
4. ✅ Backend can connect to MongoDB

Now you can:
- Build recommendation algorithms
- Create API endpoints
- Implement location-based search
- Add user preferences filtering
