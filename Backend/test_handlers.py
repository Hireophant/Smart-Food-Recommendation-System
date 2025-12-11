"""
Quick Test Script for Vietmap and Query System Handlers

This script demonstrates how to use both handlers in your application.
Run this after starting the FastAPI server to test the endpoints.
"""

import asyncio
from core.vietmap.handlers import VietmapHandlers, VietmapSearchInputSchema
from core.query_handler import QuerySystemHandler, QueryFilter
from core import MapCoordinate


async def test_vietmap_handler():
    """Test the Vietmap handler directly (without API)."""
    print("\n" + "="*60)
    print("TESTING VIETMAP HANDLER")
    print("="*60)
    
    handler = VietmapHandlers()
    
    try:
        # Test 1: Search for a location
        print("\n1. Searching for 'Cafe Hanoi'...")
        search_input = VietmapSearchInputSchema(
            Text="Cafe Hanoi",
            Focus=MapCoordinate(Latitude=21.0285, Longitude=105.8542)
        )
        results = await handler.Search(search_input)
        
        if results:
            print(f"   ✓ Found {len(results)} results")
            print(f"   First result: {results[0].Name}")
            print(f"   Address: {results[0].Address}")
            print(f"   Distance: {results[0].Distance} km")
        else:
            print("   ✗ No results found")
        
        # Test 2: Autocomplete
        print("\n2. Testing autocomplete for 'Cafe Ha'...")
        autocomplete_input = VietmapSearchInputSchema(
            Text="Cafe Ha"
        )
        suggestions = await handler.Autocomplete(autocomplete_input)
        
        if suggestions:
            print(f"   ✓ Got {len(suggestions)} suggestions")
            for i, suggestion in enumerate(suggestions[:3], 1):
                print(f"   {i}. {suggestion.Name} - {suggestion.Address}")
        else:
            print("   ✗ No suggestions")
        
        # Test 3: Reverse geocoding
        print("\n3. Testing reverse geocoding...")
        coords = MapCoordinate(Latitude=21.0285, Longitude=105.8542)
        addresses = await handler.Reverse(coords)
        
        if addresses:
            print(f"   ✓ Found address: {addresses[0].Display}")
        else:
            print("   ✗ No address found")
        
        # Test 4: Place details
        if results and len(results) > 0:
            print("\n4. Getting place details...")
            ref_id = results[0].ReferenceId
            place = await handler.Place(ref_id)
            
            if place:
                print(f"   ✓ Place: {place.Name}")
                print(f"   Full address: {place.Address}")
                print(f"   City: {place.CityName}")
                print(f"   District: {place.DistrictName}")
                print(f"   Coordinates: ({place.Latitude}, {place.Longitude})")
            else:
                print("   ✗ No place details")
        
    except Exception as e:
        print(f"\n✗ Error: {e}")
    finally:
        await handler.Close()
        print("\n✓ Vietmap handler closed")


async def test_query_handler():
    """Test the Query System handler."""
    print("\n" + "="*60)
    print("TESTING QUERY SYSTEM HANDLER")
    print("="*60)
    
    handler = QuerySystemHandler()
    
    try:
        # Test 1: Search by name
        print("\n1. Searching for restaurants with 'Cafe' in name...")
        result = await handler.search_by_name(
            "Cafe",
            filters=QueryFilter(limit=5)
        )
        
        if result.success:
            print(f"   ✓ Found {result.total_count} total, showing {result.returned_count}")
            if result.data:
                for i, restaurant in enumerate(result.data[:3], 1):
                    print(f"   {i}. {restaurant['name']} - {restaurant.get('rating', 'N/A')} ⭐")
        else:
            print(f"   ✗ Error: {result.error}")
        
        # Test 2: Search by category
        print("\n2. Searching restaurants by category 'Cafe'...")
        result = await handler.search_by_category(
            "Cafe",
            filters=QueryFilter(min_rating=4.0, limit=3)
        )
        
        if result.success:
            print(f"   ✓ Found {result.returned_count} cafes with rating >= 4.0")
            if result.data:
                for restaurant in result.data:
                    print(f"   - {restaurant['name']}: {restaurant.get('rating', 'N/A')} ⭐")
        else:
            print(f"   ✗ Error: {result.error}")
        
        # Test 3: Search by location (Hanoi center)
        print("\n3. Searching restaurants near Hanoi center...")
        result = await handler.search_by_location(
            latitude=21.0285,
            longitude=105.8542,
            max_distance=3000,  # 3km
            filters=QueryFilter(limit=5)
        )
        
        if result.success:
            print(f"   ✓ Found {result.returned_count} restaurants within 3km")
            if result.data:
                for restaurant in result.data[:3]:
                    print(f"   - {restaurant['name']}")
                    print(f"     Location: {restaurant.get('district', 'N/A')}")
        else:
            print(f"   ✗ Error: {result.error}")
        
        # Test 4: Get all categories
        print("\n4. Getting all categories...")
        result = await handler.get_all_categories()
        
        if result.success and result.data:
            categories = result.data[0].get('categories', [])
            print(f"   ✓ Found {len(categories)} categories:")
            print(f"   {', '.join(categories[:5])}")
        else:
            print(f"   ✗ Error: {result.error if not result.success else 'No data'}")
        
        # Test 5: Get statistics
        print("\n5. Getting database statistics...")
        result = await handler.get_statistics()
        
        if result.success and result.data:
            stats = result.data[0]
            print(f"   ✓ Total restaurants: {stats.get('total_restaurants', 0)}")
            print(f"   Average rating: {stats.get('avg_rating', 0):.2f}")
            print(f"   Unique categories: {stats.get('unique_categories', 0)}")
        else:
            print(f"   ✗ Error: {result.error if not result.success else 'No data'}")
        
    except Exception as e:
        print(f"\n✗ Error: {e}")


async def test_combined_workflow():
    """Test a real-world workflow combining both handlers."""
    print("\n" + "="*60)
    print("TESTING COMBINED WORKFLOW")
    print("="*60)
    print("\nScenario: User searches for 'Ba Dinh district' and wants")
    print("to find restaurants near that location.\n")
    
    vietmap = VietmapHandlers()
    query_handler = QuerySystemHandler()
    
    try:
        # Step 1: User searches for a place
        print("1. Searching for 'Ba Dinh Hanoi' using Vietmap...")
        search_input = VietmapSearchInputSchema(Text="Ba Dinh Hanoi")
        places = await vietmap.Search(search_input)
        
        if not places or len(places) == 0:
            print("   ✗ No places found")
            return
        
        print(f"   ✓ Found: {places[0].Display}")
        
        # Step 2: Get exact coordinates
        print("\n2. Getting place details...")
        place = await vietmap.Place(places[0].ReferenceId)
        
        if not place:
            print("   ✗ Could not get place details")
            return
        
        print(f"   ✓ Coordinates: ({place.Latitude}, {place.Longitude})")
        
        # Step 3: Find restaurants near those coordinates
        print("\n3. Finding restaurants within 2km...")
        result = await query_handler.search_by_location(
            latitude=place.Latitude,
            longitude=place.Longitude,
            max_distance=2000,
            filters=QueryFilter(min_rating=4.0, limit=5)
        )
        
        if result.success and result.data:
            print(f"   ✓ Found {result.returned_count} restaurants:")
            for i, restaurant in enumerate(result.data, 1):
                print(f"\n   {i}. {restaurant['name']}")
                print(f"      Category: {restaurant.get('category', 'N/A')}")
                print(f"      Rating: {restaurant.get('rating', 'N/A')} ⭐")
                print(f"      Address: {restaurant.get('address', 'N/A')}")
        else:
            print(f"   ✗ No restaurants found")
        
    except Exception as e:
        print(f"\n✗ Error: {e}")
    finally:
        await vietmap.Close()


async def main():
    """Run all tests."""
    print("\n" + "="*60)
    print("VIETMAP & QUERY SYSTEM - INTEGRATION TEST")
    print("="*60)
    
    # Test Vietmap
    await test_vietmap_handler()
    
    # Test Query System
    await test_query_handler()
    
    # Test combined workflow
    await test_combined_workflow()
    
    print("\n" + "="*60)
    print("ALL TESTS COMPLETED")
    print("="*60 + "\n")


if __name__ == "__main__":
    print("\n⚠️  Note: Make sure you have:")
    print("   1. MongoDB running with restaurant data")
    print("   2. VIETMAP_API_KEY set in .env file")
    print("   3. All dependencies installed\n")
    
    asyncio.run(main())
