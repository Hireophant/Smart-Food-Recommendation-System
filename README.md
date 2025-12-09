# Smart Food Recommendation System

AI-powered restaurant recommendation system using geospatial queries and intelligent scoring algorithms.

## 🚀 Quick Start

### Prerequisites

- Python 3.10+
- Database credentials (provided by project lead)

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Hireophant/Smart-Food-Recommendation-System.git
   cd Smart-Food-Recommendation-System
   ```

2. **Install Python dependencies:**

   ```bash
   cd Backend/
   pip install -r requirements.txt
   ```

3. **Get Database Access:**

   **Contact the project lead to get:**

   - MongoDB Atlas connection string
   - VietMap API key (if needed)

   **We use a shared team database** - no setup needed!

   - Database already has 36,173 restaurants
   - All indexes created
   - Ready to use immediately

4. **Configure environment variables:**

   ```bash
   cd Backend/
   cp .env.example .env
   # Edit .env with credentials provided by project lead
   ```

   **⚠️ Never commit `.env` to git!**

5. **Verify connection:**

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
       print(f'✅ Connected! Total: {count:,} restaurants')
       client.close()

   asyncio.run(test())
   "
   ```

6. **Run the backend:**

   ```bash
   uvicorn app:app --reload
   ```

   Visit http://127.0.0.1:8000/docs for API documentation.

**📖 Detailed Setup Guide:** [Data/scripts/README.md](Data/scripts/README.md)

## 📊 Dataset

- **36,173 restaurants** across Vietnam
- **3 categories:** Nhà hàng, Cafe, Quán ăn
- **63 provinces, 675 districts**
- **Geospatial data** with lat/lng coordinates
- **Rating information** for quality scoring

## 🏗️ Architecture

```
Smart-Food-Recommendation-System/
├── Backend/
│   ├── app.py                    # FastAPI application entry point
│   ├── query.py                  # Query system (core recommendation logic)
│   ├── utils.py                  # Configuration and logging utilities
│   ├── requirements.txt          # Python dependencies
│   ├── .env.example              # Environment variables template
│   ├── core/
│   │   ├── database/
│   │   │   └── mongodb.py        # MongoDB connection manager
│   │   ├── models/
│   │   │   └── restaurant.py    # Restaurant data models
│   │   └── vietmap/
│   │       ├── handlers.py       # VietMap API integration
│   │       └── schemas.py        # VietMap response models
│   ├── middleware/
│   │   ├── auth.py               # JWT authentication
│   │   └── rate_limit.py         # API rate limiting
│   ├── routers/                  # API endpoints (coming soon)
│   └── schemas/
│       └── errors.py             # Error response schemas
├── Data/
│   ├── VietnamRestaurants.csv    # Restaurant dataset
│   └── scripts/
│       ├── import_to_mongodb.py  # CSV to MongoDB import script
│       └── README.md             # Detailed setup guide
└── Frontend/
    └── index.html                # Web interface (coming soon)
```

## 🔧 Technology Stack

- **Backend:** FastAPI, Uvicorn
- **Database:** MongoDB Atlas (Cloud)
- **Data Processing:** Pandas, Motor (async MongoDB driver)
- **Authentication:** JWT (Supabase)
- **Rate Limiting:** SlowAPI
- **External APIs:** VietMap API (Vietnamese geocoding)

## 📚 Documentation

- **MongoDB Setup:** [Data/scripts/README.md](Data/scripts/README.md)
- **API Documentation:** `/docs` endpoint when running locally
- **Project Proposal:** [Proposal_TDTT/readme.md](<Proposal_TDTT%20(1)/readme.md>)

## 🤝 Team Collaboration

**Shared Database Setup:**

- ✅ Everyone works on the **same MongoDB Atlas database**
- ✅ No local installation or data import needed
- ✅ **36,173 restaurants** already loaded and indexed
- ✅ Real-time data access for all team members

**Getting Started:**

1. Contact project lead for database credentials
2. Add credentials to `.env` file
3. Start coding immediately!

**Benefits:**

- 🌐 Consistent data across all team members
- 💻 Works from anywhere with internet
- 🚀 Faster onboarding - no setup overhead
- 📊 Shared Atlas dashboard for monitoring
- 🔄 Changes visible to everyone instantly

## 📝 Development Status

- ✅ Backend architecture setup
- ✅ MongoDB Atlas integration
- ✅ Restaurant data imported (36,173 records)
- ✅ Geospatial and text search indexes
- ✅ VietMap API integration
- 🚧 Core recommendation algorithms (in progress)
- 🚧 API endpoints (planned)
- 🚧 Frontend interface (planned)

## 🔐 Security

- Environment variables stored in `.env` (not committed to git)
- JWT authentication for protected routes
- API rate limiting to prevent abuse
- IP whitelisting for MongoDB Atlas

## 📄 License

[Add license information]

## 👥 Contributors

[Add team members]

---

**Need help?** Check the [setup guide](Data/scripts/README.md) or contact the team!
