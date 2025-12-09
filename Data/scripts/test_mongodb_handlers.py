"""
Test script for MongoDB handlers.
Demonstrates how to use the handlers similar to VietMap handlers.
"""

import asyncio
import sys
from pathlib import Path

# Add Backend to path
backend_path = Path(__file__).parent.parent.parent / "Backend"
sys.path.insert(0, str(backend_path))

from core.database.mongodb import MongoDB, MongoConfig
from core.mongodb.handlers import MongoDBHandlers, MongoDBSearchInputSchema


async def test_search_with_text():
    """Test 1: Search 'bún bò' near a location with rating filter."""
    print("=" * 60)
    print("TEST 1: Search 'bún bò' near Quận 1, HCM")
    print("=" * 60)
    
    # Initialize MongoDB connection
    connection_string = "mongodb+srv://ndhung2431_db_user:dfyyXhRZ30obpdX2@foodrestaurant.hbwst3c.mongodb.net/smart_food_db?retryWrites=true&w=majority&appName=FoodRestaurant&tlsAllowInvalidCertificates=true"
    config = MongoConfig(connection_string=connection_string)
    await MongoDB.initialize(config)
    
    # Get database and create handler
    db = MongoDB.get_database()
    handler = MongoDBHandlers(db)
    
    # Search with text filter
    result = await handler.Search(MongoDBSearchInputSchema(
        Text="bún bò",
        Latitude=10.762622,  # Quận 1, HCM
        Longitude=106.660172,
        Radius=5000,  # 5km radius
        MinRating=4.0,  # Rating >= 4.0
        Limit=10
    ))
    
    # Display results
    print(f"\n✅ Success: {result.success}")
    print(f"📊 Found: {result.count} restaurants")
    print(f"🔍 Query: {result.query_info}\n")
    
    for i, restaurant in enumerate(result.restaurants, 1):
        print(f"{i}. {restaurant.name}")
        print(f"   Category: {restaurant.category}")
        print(f"   Rating: {restaurant.rating}⭐")
        print(f"   Distance: {restaurant.distance_km:.2f}km")
        if restaurant.score:
            print(f"   Relevance Score: {restaurant.score:.2f}")
        print(f"   Address: {restaurant.address}")
        print(f"   Tags: {', '.join(restaurant.tags[:3])}")
        print()
    
    await MongoDB.close()


async def test_search_nearby_no_text():
    """Test 2: Search nearby restaurants without text filter."""
    print("=" * 60)
    print("TEST 2: Find nearby restaurants (no text filter)")
    print("=" * 60)
    
    # Initialize MongoDB
    connection_string = "mongodb+srv://ndhung2431_db_user:dfyyXhRZ30obpdX2@foodrestaurant.hbwst3c.mongodb.net/smart_food_db?retryWrites=true&w=majority&appName=FoodRestaurant&tlsAllowInvalidCertificates=true"
    config = MongoConfig(connection_string=connection_string)
    await MongoDB.initialize(config)
    
    # Create handler
    db = MongoDB.get_database()
    handler = MongoDBHandlers(db)
    
    # Search nearby (simplified method)
    result = await handler.SearchNearby(
        latitude=10.762622,
        longitude=106.660172,
        radius=3000,  # 3km
        min_rating=4.5,  # High-rated only
        limit=5
    )
    
    # Display results
    print(f"\n✅ Found: {result.count} restaurants")
    print(f"📍 Location: {result.query_info['location']}")
    print(f"📏 Radius: {result.query_info['radius_km']}km\n")
    
    for i, restaurant in enumerate(result.restaurants, 1):
        print(f"{i}. {restaurant.name} - {restaurant.rating}⭐")
        print(f"   📍 {restaurant.distance_km:.2f}km away")
        print(f"   📮 {restaurant.district}, {restaurant.province}")
        print()
    
    await MongoDB.close()


async def test_search_with_category():
    """Test 3: Search by text with category filter."""
    print("=" * 60)
    print("TEST 3: Search 'phở' in 'Nhà hàng' category")
    print("=" * 60)
    
    # Initialize MongoDB
    connection_string = "mongodb+srv://ndhung2431_db_user:dfyyXhRZ30obpdX2@foodrestaurant.hbwst3c.mongodb.net/smart_food_db?retryWrites=true&w=majority&appName=FoodRestaurant&tlsAllowInvalidCertificates=true"
    config = MongoConfig(connection_string=connection_string)
    await MongoDB.initialize(config)
    
    # Create handler
    db = MongoDB.get_database()
    handler = MongoDBHandlers(db)
    
    # Search with text and category
    result = await handler.Search(MongoDBSearchInputSchema(
        Text="phở",
        Latitude=21.028511,  # Hà Nội
        Longitude=105.804817,
        Radius=10000,  # 10km
        Category="Nhà hàng",
        MinRating=4.0,
        Limit=10
    ))
    
    # Display results
    print(f"\n✅ Found: {result.count} restaurants")
    print(f"🏷️  Category: {result.query_info['category']}\n")
    
    for i, restaurant in enumerate(result.restaurants, 1):
        print(f"{i}. {restaurant.name}")
        print(f"   {restaurant.category} | {restaurant.rating}⭐ | {restaurant.distance_km:.2f}km")
        print(f"   {restaurant.address}")
        print()
    
    await MongoDB.close()


async def test_top_rated():
    """Test 4: Get top-rated restaurants."""
    print("=" * 60)
    print("TEST 4: Get top-rated restaurants")
    print("=" * 60)
    
    # Initialize MongoDB
    connection_string = "mongodb+srv://ndhung2431_db_user:dfyyXhRZ30obpdX2@foodrestaurant.hbwst3c.mongodb.net/smart_food_db?retryWrites=true&w=majority&appName=FoodRestaurant&tlsAllowInvalidCertificates=true"
    config = MongoConfig(connection_string=connection_string)
    await MongoDB.initialize(config)
    
    # Create handler
    db = MongoDB.get_database()
    handler = MongoDBHandlers(db)
    
    # Get top rated (simplified method)
    result = await handler.GetTopRated(
        latitude=10.762622,
        longitude=106.660172,
        radius=10000,
        limit=10
    )
    
    # Display results
    print(f"\n✅ Found: {result.count} top-rated restaurants")
    print(f"⭐ Min Rating: {result.query_info['min_rating']}\n")
    
    for i, restaurant in enumerate(result.restaurants, 1):
        print(f"{i}. {restaurant.name} - {restaurant.rating}⭐")
        print(f"   📍 {restaurant.distance_km:.2f}km | {restaurant.district}")
        print(f"   🏷️  {', '.join(restaurant.tags[:3])}")
        print()
    
    await MongoDB.close()


async def main():
    """Run all tests."""
    print("\n🚀 Starting MongoDB Handlers Test\n")
    
    # Test 1: Search with text filter
    await test_search_with_text()
    print("\n" + "="*60 + "\n")
    
    # Test 2: Search nearby without text
    await test_search_nearby_no_text()
    print("\n" + "="*60 + "\n")
    
    # Test 3: Search with category filter
    await test_search_with_category()
    print("\n" + "="*60 + "\n")
    
    # Test 4: Get top rated
    await test_top_rated()
    
    print("\n✅ All tests completed!\n")


if __name__ == "__main__":
    asyncio.run(main())
