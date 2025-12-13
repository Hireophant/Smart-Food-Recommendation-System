# MongoDB Module Documentation

## Overview
The MongoDB module provides an async connection manager and an async handler layer for searching restaurants using **geospatial** and optional **text search**.

**Import:** `from core.mongodb import *`

**Requirements:** Set `MONGODB_CONNECTION_STRING` environment variable before use.

---

## Quick Start

```python
from core.mongodb import MongoDB, MongoDBHandlers, MongoDBSearchInputSchema

# App startup
await MongoDB.initialize()       # reads MONGODB_CONNECTION_STRING from environment
await MongoDB.create_indexes()   # optional but recommended

# Runtime usage
db = MongoDB.get_database()
handler = MongoDBHandlers(db)

results = await handler.Search(MongoDBSearchInputSchema(
    Text="phở",
    Latitude=10.762622,
    Longitude=106.660172,
    Radius=5000,
    MinRating=4.0,
    Limit=10
))

print(results.count)
for r in results.restaurants:
    print(r.name, r.distance_km)
```

---

## Main Components

### MongoDB
Singleton connection manager (async Motor client + optional sync PyMongo client).

### MongoDBHandlers
Handler class for searching restaurants.

### Key Schemas

- **MongoDBSearchInputSchema**: Input for `Search(...)`
- **MongoDBSearchResponse**: Wrapper response (`success`, `count`, `restaurants`, `query_info`)
- **MongoDBRestaurantResponse**: A single restaurant record

---

## What It Can Do

### 1. Initialize MongoDB Connection

**Input:** optional `MongoConfig` (usually you don’t need it)

**Output:** `bool` (success/failure) from `MongoDB.initialize(...)`

**Example:**
```python
from core.mongodb import MongoDB

ok = await MongoDB.initialize()  # reads MONGODB_CONNECTION_STRING
if not ok:
    raise RuntimeError("MongoDB init failed")
```

---

### 2. Create Indexes (Recommended)
Creates indexes for performance:
- `location` **2dsphere** index (required for `$geoNear`)
- text index (name/category/address)
- rating/category/province/district compound indexes

**Example:**
```python
from core.mongodb import MongoDB

await MongoDB.initialize()
await MongoDB.create_indexes()
```

---

### 3. Search Restaurants (Main API)
Search near a user location, optionally using text search.

**Input:** `MongoDBSearchInputSchema`
- `Text` (optional): text query (name/category/address/tags)
- `Latitude`, `Longitude` (required)
- `Radius` (meters, default 5000)
- `MinRating` (optional, 0..5)
- `Category` (optional)
- `Province`, `District` (optional)
- `Limit` (default 20)

**Output:** `MongoDBSearchResponse`
- `success: bool`
- `count: int`
- `query_info: dict`
- `restaurants: list[MongoDBRestaurantResponse]`
- `error: Optional[str]`

**Example (text + geo):**
```python
from core.mongodb import MongoDB, MongoDBHandlers, MongoDBSearchInputSchema

db = MongoDB.get_database()
handler = MongoDBHandlers(db)

resp = await handler.Search(MongoDBSearchInputSchema(
    Text="bún bò",
    Latitude=10.762622,
    Longitude=106.660172,
    Radius=5000,
    MinRating=4.0,
    Limit=10
))

for r in resp.restaurants:
    print(f"{r.name} - {r.rating} - {r.distance_km:.2f}km")
```

**Example (geo only):**
```python
resp = await handler.Search(MongoDBSearchInputSchema(
    Latitude=10.762622,
    Longitude=106.660172,
    Radius=3000,
    Limit=10
))
```

---

### 4. Convenience APIs

#### SearchNearby
Geo-only search, thin wrapper around `Search(...)`.

```python
from core.mongodb import MongoDBHandlers

resp = await handler.SearchNearby(
    latitude=10.762622,
    longitude=106.660172,
    radius=3000,
    min_rating=4.5,
    category="Quán ăn",
    limit=10
)
```

#### SearchByText
Text + geo convenience wrapper.

```python
resp = await handler.SearchByText(
    text="phở",
    latitude=10.762622,
    longitude=106.660172,
    radius=10000,
    min_rating=4.0,
    limit=20
)
```

#### GetTopRated
Returns top-rated restaurants near location (currently defaults to `MinRating=4.0`).

```python
resp = await handler.GetTopRated(
    latitude=10.762622,
    longitude=106.660172,
    radius=10000,
    category="Quán ăn",
    limit=10
)
```

---

## Response Data Structure

### MongoDBRestaurantResponse
A single restaurant record.

**Key fields:**
- `id`, `name`, `category`, `rating`, `address`
- `province`, `district`, `ward`
- `tags: list[str]`
- `location` (GeoJSON)
- `distance` (meters), `distance_km` (kilometers)
- `link` (optional)
- `score` (optional, if text search used)

### MongoDBSearchResponse
Wrapper returned by handler methods.

**Key fields:**
- `success`: whether query succeeded
- `count`: number of results
- `restaurants`: list of results
- `query_info`: echo of query parameters
- `error`: error message (if `success=False`)

---

## Error Handling

- `MongoDB.initialize()` returns `False` on failure and logs via `Logger`.
- Handler methods return `MongoDBSearchResponse(success=False, error=str(e))` if a query fails.

**Example:**
```python
resp = await handler.Search(...)
if not resp.success:
    print("Mongo error:", resp.error)
```

---

## Notes

- This module is **backend-only**. Do not expose `MONGODB_CONNECTION_STRING` to clients.
- `Radius` is in **meters**. Returned `distance_km` is in **kilometers**.
- For best performance, run `MongoDB.create_indexes()` once after initialization (or ensure indexes exist in Atlas).
- Current handler supports both:
  - `$geoNear` (fast path, when `Text` is empty)
  - `$text` + computed distance (when `Text` is provided)
