# MongoDB Atlas Setup Guide

## Prerequisites

1. **Python dependencies:**
   ```bash
   cd Backend/
   pip install -r requirements.txt
   ```

2. **Team Database Access:**
   - We're using a **shared MongoDB Atlas database** for the whole team
   - No need to create your own database!
   - Connection credentials will be provided by the project lead

## Step 1: Get Database Credentials

**Contact the project lead to get:**
- MongoDB Atlas connection string
- Database username and password
- VietMap API key (if needed)

**Database Information:**
- **Cluster:** FoodRestaurant (Singapore region)
- **Database:** smart_food_db
- **Collection:** restaurants
- **Total Records:** 36,173 restaurants

⚠️ **IMPORTANT:** Keep credentials confidential and never commit them to git!

## Step 2: Configure Your Local Environment

1. **Create `.env` file:**
   ```bash
   cd Backend/
   cp .env.example .env
   ```

2. **Edit `.env` with the credentials provided by project lead:**
   ```env
   # MongoDB Atlas Configuration (Team Shared Database)
   MONGODB_CONNECTION_STRING=mongodb+srv://username:password@foodrestaurant.hbwst3c.mongodb.net/smart_food_db?retryWrites=true&w=majority&tlsAllowInvalidCertificates=true
   
   # Replace username and password with the credentials provided
   
   # Supabase Configuration
   SUPABASE_JWT_SECRET=your_jwt_secret_here
   
   # VietMap API Configuration
   VIETMAP_API_KEY=your_vietmap_key_here
   
   # Application Configuration
   DEBUG=True
   ```
   
   ⚠️ **Important:**
   - Use the exact connection string provided by the team lead
   - Keep `tlsAllowInvalidCertificates=true` for macOS SSL compatibility
   - **Never commit `.env` file to git!** (already in `.gitignore`)

3. **Verify your IP is whitelisted:**
   - If you get connection errors, share your IP address with the project lead
   - They will add it to the MongoDB Atlas whitelist

## Step 3: Verify Database Connection

**The database already has 36,173 restaurants imported!**

You just need to verify your connection works:

```bash
cd Backend/
python3 -c "
from motor.motor_asyncio import AsyncIOMotorClient
import asyncio, os
from dotenv import load_dotenv

async def test():
    load_dotenv()
    client = AsyncIOMotorClient(os.getenv('MONGODB_CONNECTION_STRING'))
    db = client['smart_food_db']
    count = await db.restaurants.count_documents({})
    print(f'✅ Connected successfully!')
    print(f'📊 Total restaurants in database: {count:,}')
    sample = await db.restaurants.find_one()
    print(f'📍 Sample: {sample[\"name\"]} - {sample[\"province\"]}')
    client.close()

asyncio.run(test())
"
```

**Expected output:**
```
✅ Connected successfully!
� Total restaurants in database: 36,173
📍 Sample: [Restaurant Name] - [Province]
```

**If connection fails, see [Troubleshooting](#troubleshooting) section below.**

## Step 4: Run the Backend

Start the FastAPI backend server:

```bash
cd Backend/
uvicorn app:app --reload
```

**Expected output:**
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

Check the logs for successful MongoDB connection:
```
[DATE TIME] Backend - INFO: MongoDB connected successfully to database: smart_food_db
```

Visit http://127.0.0.1:8000/docs for API documentation.

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

**❌ "No connection string provided" or "Cannot connect":**
```
ConnectionFailure: No connection string provided
```
**Solutions:**
- Make sure `.env` file exists in `Backend/` directory
- Verify `MONGODB_CONNECTION_STRING` is set correctly in `.env`
- Check that you copied the exact connection string from project lead

**❌ SSL Certificate Error (macOS):**
```
[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed
```
**Solution:** Make sure your connection string has `tlsAllowInvalidCertificates=true`:
```
MONGODB_CONNECTION_STRING=mongodb+srv://...?...&tlsAllowInvalidCertificates=true
```

**❌ Connection Timeout or IP Not Whitelisted:**
```
ServerSelectionTimeoutError: connection refused
```
**Solutions:**
- Check your internet connection
- **Contact project lead to whitelist your IP address**
- Get your IP: Visit https://whatismyipaddress.com/
- Share it with the team lead to add to MongoDB Atlas whitelist

**❌ Authentication Failed:**
```
MongoServerError: Authentication failed
```
**Solutions:**
- Verify username and password in connection string
- Contact project lead to confirm credentials
- Make sure there are no extra spaces in `.env` file

**❌ Wrong Database:**
```
Database smart_food_db not found
```
**Solution:** 
- Verify connection string includes `/smart_food_db?` in the URL
- Example: `...mongodb.net/smart_food_db?retryWrites=true...`

**❌ ".env file not loaded":**
```
Environment variable not found
```
**Solutions:**
- Make sure you're running commands from `Backend/` directory
- Verify `.env` file exists: `ls -la .env`
- Check python-dotenv is installed: `pip install python-dotenv`

## Team Shared Database Information

**Current Setup:**
- **Cluster:** FoodRestaurant (AWS Singapore)
- **Database:** smart_food_db
- **Collection:** restaurants
- **Total Records:** 36,173 restaurants
- **Storage Used:** ~40-50 MB
- **Free Tier Limit:** 512 MB (plenty of room!)

**Existing Indexes:**
1. **Geospatial Index** - For nearby restaurant search
2. **Text Search Index** - For name/category/address search
3. **Category + Rating Index** - For filtering by category
4. **Province + District + Rating Index** - For location-based filtering
5. **Rating Index** - For sorting by rating

**Data Structure:**
- 3 categories: Nhà hàng, Cafe, Quán ăn
- 63 provinces across Vietnam
- 675 districts
- GeoJSON format for all locations
- Rating data included

## For Project Lead: Adding New Team Members

When a new member joins:

1. **Whitelist their IP:**
   - Ask them to visit https://whatismyipaddress.com/
   - Go to Atlas → Network Access → Add IP Address
   - Enter their IP or use `0.0.0.0/0` for dev (less secure)

2. **Share credentials securely:**
   - Send connection string via secure channel (not public chat)
   - Share VietMap API key if needed
   - Remind them to never commit `.env` to git

3. **Optional: Create individual users:**
   - Go to Atlas → Database Access → Add New Database User
   - Create user with "Read and write to any database" role
   - Share individual credentials for better tracking

## Next Steps

After successful connection:
1. ✅ You're connected to the team's shared database
2. ✅ Data is already there (36,173 restaurants)
3. ✅ All indexes are set up
4. ✅ Ready to develop!

Now you can:
- **Build recommendation algorithms** in `Backend/core/`
- **Create API endpoints** in `Backend/routers/`
- **Test geospatial queries** (find restaurants near coordinates)
- **Implement filtering** by category, rating, province
- **Work with real data** immediately - no setup needed!

## Team Collaboration Benefits

Using a shared MongoDB Atlas database:
- 🌐 **Everyone sees the same data** - no sync issues
- 💻 **No local MongoDB needed** - works anywhere
- � **Fast development** - data ready immediately
- 📊 **Real-time changes** - updates visible to all
- 🔧 **Easy debugging** - check Atlas dashboard together

## Important Reminders

⚠️ **DO:**
- Keep connection credentials secure
- Use `.env` for configuration (never commit it!)
- Test your changes before pushing code
- Communicate with team about database changes

⚠️ **DON'T:**
- Share connection string publicly
- Commit `.env` file to git
- Drop/modify collections without team approval
- Add/delete large amounts of data without notice

## Security Best Practices

⚠️ **Keep credentials safe:**
- Never commit `.env` to git (already in `.gitignore`)
- Don't share connection string in public channels
- Use secure messaging for credential sharing
- Rotate passwords if compromised

**For Production Deployment:**
- Remove `tlsAllowInvalidCertificates=true`
- Use specific IP whitelisting
- Create separate production database
- Enable encryption at rest (paid feature)
- Set up monitoring and alerts

## Viewing Data in MongoDB Atlas

Team members can browse data directly:

1. Go to https://cloud.mongodb.com/
2. Login with team account (ask project lead)
3. Select **FoodRestaurant** cluster
4. Click **Browse Collections**
5. Navigate to `smart_food_db` → `restaurants`
6. View, search, and analyze data

**Useful Atlas Features:**
- **Metrics:** Monitor database performance
- **Query Profiler:** Optimize slow queries  
- **Charts:** Create data visualizations
- **Search:** Test text search queries

---

**Need help?** Contact the project lead or check MongoDB Atlas docs!
