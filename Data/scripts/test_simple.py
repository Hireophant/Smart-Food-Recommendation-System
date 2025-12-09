"""Simple test for MongoDB handler - Search 'bún bò'"""

import asyncio
import sys
from pathlib import Path

backend_path = Path(__file__).parent.parent.parent / "Backend"
sys.path.insert(0, str(backend_path))

from core.database.mongodb import MongoDB, MongoConfig
from core.mongodb.handlers import MongoDBHandlers, MongoDBSearchInputSchema


async def main():
    # Connect
    connection_string = "mongodb+srv://ndhung2431_db_user:dfyyXhRZ30obpdX2@foodrestaurant.hbwst3c.mongodb.net/smart_food_db?retryWrites=true&w=majority&appName=FoodRestaurant&tlsAllowInvalidCertificates=true"
    config = MongoConfig(connection_string=connection_string)
    await MongoDB.initialize(config)
    
    db = MongoDB.get_database()
    handler = MongoDBHandlers(db)
    
    print("="*60)
    print("TEST: Search 'bún bò' near HCM")
    print("="*60)
    
    # Test with large radius and no rating filter
    result = await handler.Search(MongoDBSearchInputSchema(
        Text="bún bò",
        Latitude=10.762622,
        Longitude=106.660172,
        Radius=50000,  # 50km - very large
        MinRating=None,  # No rating filter
        Limit=10
    ))
    
    print(f"\nSuccess: {result.success}")
    print(f"Count: {result.count}")
    
    if not result.success:
        print(f"Error: {result.error}")
    else:
        print(f"\nQuery Info: {result.query_info}")
        
        for i, r in enumerate(result.restaurants, 1):
            print(f"\n{i}. {r.name}")
            print(f"   Rating: {r.rating}⭐")
            print(f"   Distance: {r.distance_km:.2f}km")
            print(f"   Address: {r.address}")
            if r.score:
                print(f"   Text Score: {r.score:.2f}")
    
    await MongoDB.close()


if __name__ == "__main__":
    asyncio.run(main())
