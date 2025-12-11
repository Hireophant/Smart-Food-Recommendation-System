# Vietmap API Integration Guide

## Overview

The Vietmap integration provides geocoding, place search, autocomplete, and reverse geocoding services for Vietnamese locations. It's built on top of the Vietmap API v4 and provides clean FastAPI endpoints.

## Architecture

### Components Structure

```
Backend/
├── core/
│   ├── __init__.py                    # MapCoordinate class
│   └── vietmap/
│       ├── handlers.py                # VietmapHandlers - API client
│       └── schemas.py                 # Response models
└── routers/
    └── vietmap.py                     # API endpoints
```

### Flow Diagram

```
Frontend Request
      ↓
FastAPI Router (routers/vietmap.py)
      ↓
VietmapHandlers (core/vietmap/handlers.py)
      ↓
Vietmap API (maps.vietmap.vn)
      ↓
Response Models (core/vietmap/schemas.py)
      ↓
JSON Response to Frontend
```

## Setup

### 1. Environment Configuration

Add your Vietmap API key to `.env`:

```env
VIETMAP_API_KEY=your_api_key_here
```

### 2. Register Router in FastAPI App

In `Backend/app.py`, add:

```python
from routers.vietmap import router as vietmap_router

# After creating the FastAPI app
app.include_router(vietmap_router)
```

### 3. Verify Configuration

Check if the API is properly configured:

```bash
curl http://localhost:8000/api/vietmap/health
```

Expected response:
```json
{
  "status": "ok",
  "message": "Vietmap API is properly configured",
  "configured": true,
  "api_key_length": 32
}
```

## API Endpoints

### 1. Search Locations

Search for places, addresses, or POIs.

**POST** `/api/vietmap/search`

**Request Body:**
```json
{
  "text": "Cafe Hanoi",
  "focus_lat": 21.0285,
  "focus_lng": 105.8542,
  "categories": "cafe",
  "city_id": 1
}
```

**GET** `/api/vietmap/search?text=Cafe%20Hanoi&focus_lat=21.0285&focus_lng=105.8542`

**Parameters:**
- `text` (required): Search query
- `focus_lat`, `focus_lng` (optional): Point to prioritize results around
- `circle_center_lat`, `circle_center_lng`, `circle_radius` (optional): Geographic boundary
- `layers` (optional): Filter by layers (e.g., 'venue,address')
- `categories` (optional): Filter by categories
- `city_id`, `dist_id`, `ward_id` (optional): Administrative boundaries

**Response:**
```json
[
  {
    "ref_id": "abc123",
    "name": "THAIYEN CAFE",
    "address": "Quận Ba Đình, Hà Nội",
    "display": "THAIYEN CAFE, Quận Ba Đình",
    "distance": 1.2,
    "categories": ["cafe", "food"],
    "boundaries": [
      {
        "type": 0,
        "id": 1,
        "full_name": "Hà Nội"
      }
    ],
    "entry_points": [
      {
        "ref_id": "entry123",
        "name": "Main entrance"
      }
    ]
  }
]
```

**Use Cases:**
- Find restaurants near user location
- Search for specific addresses
- Filter places by category (cafe, restaurant, etc.)

---

### 2. Autocomplete Suggestions

Get real-time suggestions as the user types.

**POST** `/api/vietmap/autocomplete`

**Request Body:**
```json
{
  "text": "Cafe Ha",
  "focus_lat": 21.0285,
  "focus_lng": 105.8542,
  "categories": "cafe"
}
```

**GET** `/api/vietmap/autocomplete?text=Cafe%20Ha&focus_lat=21.0285&focus_lng=105.8542`

**Parameters:**
- `text` (required): Partial text to autocomplete
- `focus_lat`, `focus_lng` (optional): Point to prioritize results
- `categories` (optional): Filter by categories

**Response:**
```json
[
  {
    "ref_id": "abc123",
    "name": "Cafe Hanoi",
    "address": "Ba Đình",
    "display": "Cafe Hanoi - Ba Đình",
    "distance": 0.5,
    "categories": ["cafe"]
  }
]
```

**Use Cases:**
- Search box autocomplete
- Quick place name suggestions
- Type-ahead functionality

---

### 3. Place Details

Get detailed information about a specific place.

**GET** `/api/vietmap/place/{ref_id}`

**Parameters:**
- `ref_id` (path parameter): Reference ID from search/autocomplete results

**Example:**
```bash
curl http://localhost:8000/api/vietmap/place/abc123def456
```

**Response:**
```json
{
  "display": "THAIYEN CAFE - Quán Thánh, Quận Ba Đình, Hà Nội",
  "name": "THAIYEN CAFE",
  "hs_num": "123",
  "street": "Quán Thánh",
  "address": "123 Quán Thánh",
  "city_id": 1,
  "city": "Hà Nội",
  "district_id": 5,
  "district": "Quận Ba Đình",
  "ward_id": 50,
  "ward": "Phường Quán Thánh",
  "lat": 21.042939,
  "lng": 105.8391546
}
```

**Use Cases:**
- Get full address details
- Retrieve exact coordinates
- Show place information on detail page

---

### 4. Reverse Geocoding

Convert coordinates to address information.

**POST** `/api/vietmap/reverse`

**Request Body:**
```json
{
  "latitude": 21.0285,
  "longitude": 105.8542
}
```

**GET** `/api/vietmap/reverse?latitude=21.0285&longitude=105.8542`

**Parameters:**
- `latitude` (required): Latitude (-90 to 90)
- `longitude` (required): Longitude (-180 to 180)

**Response:**
```json
[
  {
    "ref_id": "xyz789",
    "name": "Hồ Hoàn Kiếm",
    "address": "Hoàn Kiếm, Hà Nội",
    "display": "Hồ Hoàn Kiếm, Hoàn Kiếm, Hà Nội",
    "distance": 0.1,
    "categories": ["landmark"],
    "boundaries": [
      {
        "type": 0,
        "id": 1,
        "full_name": "Hà Nội"
      }
    ]
  }
]
```

**Use Cases:**
- Get address from map click
- Convert GPS coordinates to readable address
- Show "You are here" information

---

### 5. Health Check

Check API configuration status.

**GET** `/api/vietmap/health`

**Response:**
```json
{
  "status": "ok",
  "message": "Vietmap API is properly configured",
  "configured": true,
  "api_key_length": 32
}
```

## Code Examples

### Backend Usage (Python)

```python
from core.vietmap.handlers import VietmapHandlers, VietmapSearchInputSchema
from core import MapCoordinate

# Create handler
handler = VietmapHandlers()

try:
    # Search for a location
    search_input = VietmapSearchInputSchema(
        Text="Cafe Hanoi",
        Focus=MapCoordinate(Latitude=21.0285, Longitude=105.8542)
    )
    results = await handler.Search(search_input)
    
    # Get place details
    if results and len(results) > 0:
        ref_id = results[0].ReferenceId
        place_details = await handler.Place(ref_id)
        print(f"Place: {place_details.Name}")
        print(f"Address: {place_details.Address}")
        print(f"Coordinates: {place_details.Latitude}, {place_details.Longitude}")
    
    # Reverse geocoding
    coords = MapCoordinate(Latitude=21.0285, Longitude=105.8542)
    address = await handler.Reverse(coords)
    print(f"Address at coordinates: {address[0].Display}")
    
finally:
    await handler.Close()
```

### Frontend Integration (Flutter)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class VietmapService {
  static const String baseUrl = 'http://localhost:8000/api/vietmap';

  // Search for locations
  Future<List<dynamic>> searchLocations(String query, 
      {double? lat, double? lng}) async {
    final params = {
      'text': query,
      if (lat != null) 'focus_lat': lat.toString(),
      if (lng != null) 'focus_lng': lng.toString(),
    };
    
    final uri = Uri.parse('$baseUrl/search')
        .replace(queryParameters: params);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to search locations');
  }

  // Autocomplete
  Future<List<dynamic>> autocomplete(String text) async {
    final uri = Uri.parse('$baseUrl/autocomplete')
        .replace(queryParameters: {'text': text});
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get autocomplete');
  }

  // Get place details
  Future<Map<String, dynamic>> getPlaceDetails(String refId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/place/$refId'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get place details');
  }

  // Reverse geocode
  Future<List<dynamic>> reverseGeocode(double lat, double lng) async {
    final uri = Uri.parse('$baseUrl/reverse').replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
      },
    );
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to reverse geocode');
  }
}
```

### Frontend Usage Example

```dart
// In your Flutter widget
final vietmapService = VietmapService();

// Search for cafes
void searchCafes() async {
  try {
    final results = await vietmapService.searchLocations(
      'Cafe',
      lat: 21.0285,
      lng: 105.8542,
    );
    
    setState(() {
      searchResults = results;
    });
  } catch (e) {
    print('Search error: $e');
  }
}

// Get address from map tap
void onMapTap(double lat, double lng) async {
  try {
    final addresses = await vietmapService.reverseGeocode(lat, lng);
    if (addresses.isNotEmpty) {
      final address = addresses[0]['display'];
      showSnackBar('Location: $address');
    }
  } catch (e) {
    print('Reverse geocode error: $e');
  }
}
```

## Integration with Restaurant Search

Combine Vietmap with your restaurant query system:

```python
from core.query_handler import QuerySystemHandler
from core.vietmap.handlers import VietmapHandlers

async def search_restaurants_by_place_name(place_name: str):
    """Search restaurants near a place by name."""
    
    vietmap = VietmapHandlers()
    restaurant_handler = QuerySystemHandler()
    
    try:
        # 1. Search for the place
        search_input = VietmapSearchInputSchema(Text=place_name)
        places = await vietmap.Search(search_input)
        
        if not places or len(places) == 0:
            return {"error": "Place not found"}
        
        # 2. Get place details to get exact coordinates
        place_details = await vietmap.Place(places[0].ReferenceId)
        
        # 3. Search restaurants near those coordinates
        restaurants = await restaurant_handler.search_by_location(
            latitude=place_details.Latitude,
            longitude=place_details.Longitude,
            max_distance=5000  # 5km radius
        )
        
        return {
            "place": place_details,
            "restaurants": restaurants
        }
        
    finally:
        await vietmap.Close()
```

## Error Handling

All endpoints return standard HTTP error codes:

- **400 Bad Request**: Invalid parameters
- **404 Not Found**: No results found
- **500 Internal Server Error**: API errors or configuration issues

Example error response:
```json
{
  "detail": "Search failed: Connection timeout"
}
```

## Best Practices

1. **Always close the handler**: Use `try/finally` to ensure `handler.Close()` is called
2. **Use focus points**: Provide user's location for better relevance
3. **Cache results**: Consider caching autocomplete results to reduce API calls
4. **Handle errors gracefully**: Show user-friendly messages for API failures
5. **Validate coordinates**: Ensure lat/lng are within valid ranges before calling
6. **Use appropriate endpoints**: Use autocomplete for type-ahead, search for full queries

## Testing

### Test with cURL

```bash
# Health check
curl http://localhost:8000/api/vietmap/health

# Search
curl "http://localhost:8000/api/vietmap/search?text=Cafe%20Hanoi"

# Autocomplete
curl "http://localhost:8000/api/vietmap/autocomplete?text=Cafe%20Ha"

# Reverse geocode
curl "http://localhost:8000/api/vietmap/reverse?latitude=21.0285&longitude=105.8542"
```

### Test with Python

```python
import requests

BASE_URL = "http://localhost:8000/api/vietmap"

# Search
response = requests.get(f"{BASE_URL}/search", params={"text": "Cafe Hanoi"})
print(response.json())

# Autocomplete
response = requests.get(f"{BASE_URL}/autocomplete", params={"text": "Cafe Ha"})
print(response.json())

# Reverse geocode
response = requests.get(
    f"{BASE_URL}/reverse",
    params={"latitude": 21.0285, "longitude": 105.8542}
)
print(response.json())
```

## Troubleshooting

### "VIETMAP_API_KEY not configured"

**Solution**: Add the API key to your `.env` file:
```env
VIETMAP_API_KEY=your_actual_api_key
```

### "No results found"

**Possible causes**:
- Search query too specific
- Location outside Vietnam
- API rate limit reached

**Solution**: Try broader search terms or check API quota.

### Connection errors

**Solution**: Check internet connection and Vietmap API status.

## Additional Resources

- [Vietmap API Documentation](https://maps.vietmap.vn/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic Models](https://docs.pydantic.dev/)
