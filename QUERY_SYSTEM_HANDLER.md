# Query System Handler Documentation

## Overview

The Query System Handler provides a comprehensive set of tools for searching and filtering restaurants in the Smart Food Recommendation System. It supports multiple search methods including name-based search, category filtering, geospatial queries, and combined searches.

## Architecture

### Components

1. **QuerySystemHandler** (`core/query_handler.py`)
   - Core handler for all restaurant queries
   - Integrates with MongoDB for data retrieval
   - Provides filtering and pagination support

2. **QueryRouter** (`routers/query_router.py`)
   - FastAPI router exposing query endpoints
   - Request validation and response formatting
   - Error handling and HTTP status codes

3. **Models**
   - `QueryFilter`: Search filter criteria
   - `QueryResult`: Standardized response format

## Search Methods

### 1. Search by Name
Search for restaurants by name with optional filters.

**Endpoint:** `GET /api/query/search/name`

**Parameters:**
```
q (string, required): Search term (min length: 1)
category (string, optional): Filter by category
min_rating (float, optional): Minimum rating (0-5)
max_rating (float, optional): Maximum rating (0-5)
district (string, optional): Filter by district
province (string, optional): Filter by province
limit (int, optional): Results per page (default: 10, max: 100)
skip (int, optional): Number of results to skip (default: 0)
```

**Example Request:**
```bash
curl "http://localhost:8000/api/query/search/name?q=Cafe&category=Cafe&limit=10"
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "507f1f77bcf86cd799439011",
      "name": "THAIYEN CAFE Quán Thánh",
      "category": "Cafe",
      "address": "Quận Ba Đình, Thành phố Hà Nội",
      "latitude": 21.042939,
      "longitude": 105.8391546,
      "rating": 4.7,
      "district": "Quận Ba Đình",
      "province": "Thành phố Hà Nội"
    }
  ],
  "total_count": 25,
  "returned_count": 10,
  "timestamp": "2025-12-10T10:30:00"
}
```

### 2. Search by Category
Find restaurants by category type.

**Endpoint:** `GET /api/query/search/category`

**Parameters:**
```
category (string, required): Category to search
min_rating (float, optional): Minimum rating (0-5)
max_rating (float, optional): Maximum rating (0-5)
limit (int, optional): Results per page (default: 10, max: 100)
skip (int, optional): Number of results to skip (default: 0)
```

**Example Request:**
```bash
curl "http://localhost:8000/api/query/search/category?category=Restaurant&min_rating=4.0"
```

### 3. Search by Location (Geospatial)
Find restaurants near a geographic coordinate with optional radius.

**Endpoint:** `GET /api/query/search/location`

**Parameters:**
```
latitude (float, required): Center latitude (-90 to 90)
longitude (float, required): Center longitude (-180 to 180)
max_distance (float, optional): Maximum distance in meters (default: 5000)
category (string, optional): Filter by category
min_rating (float, optional): Minimum rating (0-5)
max_rating (float, optional): Maximum rating (0-5)
limit (int, optional): Results per page (default: 10, max: 100)
skip (int, optional): Number of results to skip (default: 0)
```

**Example Request:**
```bash
curl "http://localhost:8000/api/query/search/location?latitude=21.0285&longitude=105.8542&max_distance=3000"
```

**Note:** Requires a geospatial index on the "location" field in MongoDB.

### 4. Search by Rating
Find restaurants within a rating range.

**Endpoint:** `GET /api/query/search/rating`

**Parameters:**
```
min_rating (float, required): Minimum rating (0-5, default: 0)
max_rating (float, required): Maximum rating (0-5, default: 5)
category (string, optional): Filter by category
district (string, optional): Filter by district
province (string, optional): Filter by province
limit (int, optional): Results per page (default: 10, max: 100)
skip (int, optional): Number of results to skip (default: 0)
```

**Example Request:**
```bash
curl "http://localhost:8000/api/query/search/rating?min_rating=4.0&max_rating=5.0&limit=15"
```

### 5. Combined Search
Search with name, location, and multiple filters at once.

**Endpoint:** `GET /api/query/search/combined`

**Parameters:**
```
q (string, optional): Search term for name/category
latitude (float, optional): Center latitude
longitude (float, optional): Center longitude
max_distance (float, optional): Maximum distance in meters
category (string, optional): Filter by category
min_rating (float, optional): Minimum rating (0-5)
max_rating (float, optional): Maximum rating (0-5)
district (string, optional): Filter by district
province (string, optional): Filter by province
limit (int, optional): Results per page (default: 10, max: 100)
skip (int, optional): Number of results to skip (default: 0)
```

**Example Request:**
```bash
curl "http://localhost:8000/api/query/search/combined?q=Cafe&latitude=21.0285&longitude=105.8542&max_distance=5000&category=Cafe&min_rating=4.0"
```

## Utility Endpoints

### Get Restaurant by ID
Retrieve detailed information about a specific restaurant.

**Endpoint:** `GET /api/query/restaurant/{restaurant_id}`

**Parameters:**
```
restaurant_id (string, required): MongoDB ObjectId as string
```

**Example Request:**
```bash
curl "http://localhost:8000/api/query/restaurant/507f1f77bcf86cd799439011"
```

### Get All Categories
Get a list of all available restaurant categories in the database.

**Endpoint:** `GET /api/query/categories`

**Example Request:**
```bash
curl "http://localhost:8000/api/query/categories"
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "categories": ["Cafe", "Restaurant", "Bar", "Bakery", "Dessert"]
    }
  ],
  "returned_count": 5
}
```

### Get Statistics
Retrieve overall statistics about restaurants in the database.

**Endpoint:** `GET /api/query/statistics`

**Example Request:**
```bash
curl "http://localhost:8000/api/query/statistics"
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": null,
      "total_restaurants": 1250,
      "avg_rating": 4.23,
      "max_rating": 5.0,
      "min_rating": 2.5,
      "unique_categories": 12
    }
  ],
  "returned_count": 1
}
```

## Filter Capabilities

The QueryFilter model provides the following filtering options:

```python
class QueryFilter(BaseModel):
    category: Optional[str]              # Filter by restaurant category
    min_rating: Optional[float]          # Minimum rating (0-5)
    max_rating: Optional[float]          # Maximum rating (0-5)
    district: Optional[str]              # Filter by district
    province: Optional[str]              # Filter by province/city
    max_distance: Optional[float]        # Maximum distance in meters
    limit: int = 10                      # Number of results (1-100)
    skip: int = 0                        # Pagination offset
```

### Combining Filters

Filters are applied using MongoDB AND logic (all conditions must be met):

```bash
# Find highly-rated cafes in Hoan Kiem district
curl "http://localhost:8000/api/query/search/name?q=Cafe&min_rating=4.5&district=Hoan%20Kiem"
```

## Response Format

All endpoints return a standardized `QueryResult` response:

```python
class QueryResult(BaseModel):
    success: bool                        # Operation status
    data: Optional[List[Dict]]          # Search results
    total_count: int                    # Total matching records
    returned_count: int                 # Records in this response
    error: Optional[str]                # Error message if failed
    timestamp: datetime                 # Response timestamp
```

## Error Handling

The handler returns appropriate HTTP status codes:

- **400 Bad Request**: Invalid parameters or filter criteria
- **404 Not Found**: Restaurant ID not found
- **500 Internal Server Error**: Database or server errors

Example error response:
```json
{
  "detail": "Invalid latitude value"
}
```

## Database Requirements

The handler expects the following MongoDB collection structure:

```javascript
// Collection: restaurants
{
  "_id": ObjectId,
  "name": String,
  "category": String,
  "address": String,
  "latitude": Number,
  "longitude": Number,
  "rating": Number,
  "district": String,
  "province": String,
  "full_location": String,
  "google_maps_link": String,
  "location": {              // For geospatial queries
    "type": "Point",
    "coordinates": [lng, lat]
  }
}
```

### Required Indexes

For optimal performance, create these MongoDB indexes:

```javascript
// Text search index for name and category
db.restaurants.createIndex({ name: "text", category: "text" })

// Geospatial index for location queries
db.restaurants.createIndex({ location: "2dsphere" })

// Single field indexes for filtering
db.restaurants.createIndex({ category: 1 })
db.restaurants.createIndex({ rating: 1 })
db.restaurants.createIndex({ district: 1 })
db.restaurants.createIndex({ province: 1 })
```

## Integration with App

### 1. Register Router in FastAPI App

In `Backend/app.py`, add:

```python
from routers.query_router import router as query_router

app.include_router(query_router)
```

### 2. Basic Usage Example

```python
from core.query_handler import QuerySystemHandler, QueryFilter

# Create handler instance
query_handler = QuerySystemHandler()

# Search by name
result = await query_handler.search_by_name(
    "Cafe",
    filters=QueryFilter(category="Cafe", min_rating=4.0, limit=10)
)

if result.success:
    for restaurant in result.data:
        print(f"{restaurant['name']}: {restaurant['rating']} stars")
else:
    print(f"Error: {result.error}")
```

### 3. Frontend Integration (Flutter)

The frontend can call the APIs like:

```dart
Future<List<Restaurant>> searchRestaurants(String query) async {
  final response = await http.get(
    Uri.parse(
      'http://localhost:8000/api/query/search/combined?q=$query&limit=20'
    ),
  );
  
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return List<Restaurant>.from(
      json['data'].map((r) => Restaurant.fromJson(r))
    );
  }
  throw Exception('Failed to load restaurants');
}
```

## Performance Tips

1. **Use Combined Search**: Instead of making multiple requests, use the combined search endpoint
2. **Set Appropriate Limits**: Use pagination (limit and skip) for large result sets
3. **Filter Early**: Provide specific filters to reduce database query size
4. **Geospatial Queries**: Ensure geospatial index is created for location searches
5. **Rating Filters**: Pre-filter by rating before displaying results to users

## Future Enhancements

- [ ] Advanced text search with relevance scoring
- [ ] Saved searches and user preferences
- [ ] Trending restaurants and popular times
- [ ] Similar restaurant recommendations
- [ ] Review and comment integration
- [ ] Favorites and bookmarking system
