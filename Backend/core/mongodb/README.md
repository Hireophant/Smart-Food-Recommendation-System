# MongoDB Handlers Documentation

## ⚠️ **IMPORTANT: Access Requirements**

**Để sử dụng database và handler này, bạn cần:**

1. **MongoDB Atlas Connection String**
   - Credentials được cung cấp bởi project lead
   - Thêm vào file `Backend/.env`:
     ```bash
     MONGODB_CONNECTION_STRING="mongodb+srv://username:password@cluster.mongodb.net/..."
     ```

2. **IP Address Whitelist**
   - IP address của bạn phải được thêm vào Atlas Network Access
   - Contact project lead để whitelist IP
   - Hoặc config "Allow access from anywhere" (0.0.0.0/0) cho development

3. **Network Access**
   - Cần kết nối internet để truy cập MongoDB Atlas (cloud database)
   - Không thể dùng offline

**⚠️ Security Note:**
- Handler này chạy trên **backend server only**
- **KHÔNG** expose MongoDB credentials ra frontend/client
- User bên ngoài phải call qua REST API, không dùng handler trực tiếp

---

## 📅 Development Log

### **8 Tháng 12, 2025: Data Import & MongoDB Handler Development**

#### **Task 1: Import refined dataset lên MongoDB Atlas**

**Vấn đề:** Cần thay thế dataset cũ (36,173 records) bằng dataset mới đã được AI refine (48,757 records) với tags cho recommendation.

**Cách làm:**
1. **Drop collection cũ trên Atlas** (đã drop thủ công trên MongoDB Atlas dashboard)
2. **Tạo import script đơn giản:** `Data/scripts/simple_import.py`
   - Đọc CSV: `Data_100k_AI_Refined.csv` (48,757 records)
   - Clean data: Remove rows thiếu Name/Latitude/Longitude
   - Transform data:
     - Parse `Full_Tags` column → array of tags
     - Convert Latitude/Longitude → GeoJSON format: `{type: "Point", coordinates: [lng, lat]}`
     - Preserve all fields: name, category, address, rating, province, district, ward, link, tags
   - Import batch: 1000 documents/batch để tránh timeout
   - Tạo 6 indexes cho performance:
     - `location_2dsphere`: Geospatial queries (nearby search)
     - `text_search_index`: Full-text search (name, category, address, tags)
     - `category_rating_idx`: Filter by category + sort by rating
     - `location_rating_idx`: Filter by province/district + sort by rating
     - `rating_idx`: Sort by rating only
     - `tags_idx`: Filter by tags (NEW - từ refined data)

3. **Xử lý SSL certificate issue trên macOS:**
   ```python
   client = MongoClient(
       CONNECTION_STRING,
       tlsAllowInvalidCertificates=True  # Fix macOS SSL
   )
   ```

**Kết quả:**
- ✅ Import thành công **48,757 restaurants** (tăng từ 36,173)
- ✅ 7 indexes created (bao gồm _id_ default)
- ✅ Có thêm field `tags` để improve recommendation accuracy
- ✅ Sample document: "Bánh Hỏi Út Dzách" với tags ["địa điểm ăn uống"]

**Script:** `Data/scripts/simple_import.py`

---

#### **Task 2: Tạo MongoDB Search Handler (theo format VietMap handler)**

**Vấn đề:** Cần API để search restaurants theo text (tên món ăn) + location (lat/lng) + rating filter, giống format VietMap handler để frontend dễ integrate.

**Cách làm:**

1. **Thiết kế Input Schema** (`MongoDBSearchInputSchema`):
   ```python
   - Text: Optional[str]           # Search query (món ăn, tên quán)
   - Latitude: float               # Required - User location
   - Longitude: float              # Required
   - Radius: float = 5000          # Search radius (meters)
   - MinRating: Optional[float]    # Rating filter (0-5)
   - Category: Optional[str]       # Filter by category
   - Province: Optional[str]       # Filter by province
   - District: Optional[str]       # Filter by district
   - Limit: int = 20               # Max results
   ```

2. **Thiết kế Response Schema** (giống VietMap):
   ```python
   MongoDBSearchResponse:
     - success: bool
     - count: int
     - query_info: dict            # Query details for debugging
     - restaurants: List[MongoDBRestaurantResponse]
     - error: Optional[str]
   
   MongoDBRestaurantResponse:
     - id, name, category, rating
     - address, province, district, ward
     - tags: List[str]
     - location: GeoJSON Point
     - distance: float (meters)
     - distance_km: float
     - score: Optional[float]      # Text relevance score
   ```

3. **Implement Aggregation Pipeline Strategy:**

   **Problem:** MongoDB không cho phép `$text` search sau `$geoNear` trong pipeline (error: "$match with $text is only allowed as the first pipeline stage").

   **Solution:** Implement 2 strategies:

   **Strategy A - Có Text Search:**
   ```
   1. $match với $text (MUST be first stage)
   2. $addFields: textScore = $meta("textScore")
   3. $addFields: distance = Haversine formula calculation
      - Công thức: d = 2R × arcsin(sqrt(sin²(Δlat/2) + cos(lat1)×cos(lat2)×sin²(Δlon/2)))
      - R = 6371000 meters (Earth radius)
   4. $match: distance <= Radius
   5. $match: Apply other filters (rating, category, province, district)
   6. $addFields: distance_km = distance / 1000
   7. $sort: textScore DESC, distance ASC
   8. $limit: Limit
   ```

   **Strategy B - Không có Text Search:**
   ```
   1. $geoNear (fast geospatial query)
      - near: {type: "Point", coordinates: [lng, lat]}
      - distanceField: "distance"
      - maxDistance: Radius
      - query: {rating: {$gte: MinRating}, category, province, district}
   2. $addFields: distance_km = distance / 1000
   3. $sort: distance ASC, rating DESC
   4. $limit: Limit
   ```

4. **Implement Helper Methods:**
   ```python
   - Search(inputs)              # Main method - full control
   - SearchNearby(...)           # Simplified - no text
   - SearchByText(...)           # Simplified - with text
   - GetTopRated(...)            # Get high-rated restaurants
   ```

**Giải thích kỹ thuật:**

- **Tại sao dùng 2 strategies?**
  - MongoDB $text search phải là first stage
  - $geoNear cũng phải là first stage
  - → Không thể combine cả 2
  - → Strategy A: $text first, calculate distance manually
  - → Strategy B: $geoNear first (faster khi không có text)

- **Haversine Formula:**
  - Tính khoảng cách giữa 2 điểm trên mặt cầu (Earth)
  - Accurate cho distances < 1000km
  - Implement bằng MongoDB aggregation expressions

- **Text Search:**
  - Search trong 4 fields: name, category, address, tags
  - MongoDB automatically tokenize và match
  - Return relevance score để sort

**Kết quả:**
- ✅ Handler hoạt động perfect
- ✅ Test "bún bò" → Found 10 restaurants trong 50km radius
  - Top result: "Bún Bò Huế Đồng Gia" - 4.9⭐ - 14.36km - Score: 5.93
- ✅ Test nearby (no text) → Found 5 restaurants rating 4.5+ trong 3km
  - "Phở La Quận 10" - 4.5⭐ - 0.15km away
- ✅ Response format giống VietMap handler
- ✅ Performance: Strategy A ~100-200ms, Strategy B ~20-50ms

**Files created:**
- `Backend/core/mongodb/handlers.py` - Main handler (350+ lines)
- `Backend/core/mongodb/__init__.py` - Exports
- `Backend/core/mongodb/README.md` - Full documentation
- `Data/scripts/test_mongodb_handlers.py` - Test suite
- `Data/scripts/test_simple.py` - Simple test

---

### **Hướng dẫn sử dụng MongoDB Handler**

#### **1. Setup & Initialize**

```python
from core.database.mongodb import MongoDB, MongoConfig
from core.mongodb.handlers import MongoDBHandlers, MongoDBSearchInputSchema

# Initialize connection
config = MongoConfig(connection_string=YOUR_MONGODB_URI)
await MongoDB.initialize(config)

# Create handler
db = MongoDB.get_database()
handler = MongoDBHandlers(db)
```

#### **2. Search với Text (Tìm món ăn)**

```python
# Tìm "bún bò" gần vị trí, rating >= 4.0
result = await handler.Search(MongoDBSearchInputSchema(
    Text="bún bò",
    Latitude=10.762622,      # User location
    Longitude=106.660172,
    Radius=5000,             # 5km
    MinRating=4.0,           # Optional
    Limit=20
))

# Check results
if result.success:
    print(f"Found: {result.count} restaurants")
    for r in result.restaurants:
        print(f"{r.name} - {r.rating}⭐ - {r.distance_km:.2f}km")
        if r.score:
            print(f"  Relevance: {r.score:.2f}")
else:
    print(f"Error: {result.error}")
```

#### **3. Search Nearby (Không có text)**

```python
# Tìm quán gần nhất, rating cao
result = await handler.SearchNearby(
    latitude=10.762622,
    longitude=106.660172,
    radius=3000,        # 3km
    min_rating=4.5,     # Optional
    limit=10
)

# Results sorted by distance → rating
for r in result.restaurants:
    print(f"{r.name} - {r.distance_km:.2f}km")
```

#### **4. Search với Filters**

```python
# Tìm "phở" ở Hà Nội, category "Nhà hàng", rating >= 4.5
result = await handler.Search(MongoDBSearchInputSchema(
    Text="phở",
    Latitude=21.028511,
    Longitude=105.804817,
    Radius=10000,           # 10km
    Category="Nhà hàng",    # Filter by category
    Province="Hà Nội",      # Filter by province
    MinRating=4.5,
    Limit=20
))
```

#### **5. Get Top Rated**

```python
# Lấy top 10 quán rating cao gần user
result = await handler.GetTopRated(
    latitude=10.762622,
    longitude=106.660172,
    radius=10000,           # 10km
    category="Quán ăn",     # Optional
    limit=10
)

# Kết quả: rating >= 4.0, sorted by distance
```

#### **6. Response Structure**

```python
result = MongoDBSearchResponse(
    success=True,
    count=10,
    query_info={
        "text": "bún bò",
        "location": {"latitude": 10.762622, "longitude": 106.660172},
        "radius_meters": 5000,
        "radius_km": 5.0,
        "min_rating": 4.0
    },
    restaurants=[
        MongoDBRestaurantResponse(
            id="675580...",
            name="Bún Bò Huế Ngon",
            category="Quán ăn",
            rating=4.9,
            address="Phường Thạnh Xuân, Quận 12, TP HCM",
            province="Thành phố Hồ Chí Minh",
            district="Quận 12",
            ward="Phường Thạnh Xuân",
            tags=["bún", "huế", "cay", "sả"],
            location={"type": "Point", "coordinates": [106.7, 10.8]},
            distance=14360.5,      # meters
            distance_km=14.36,     # kilometers
            link="https://google.com/maps/...",
            score=5.93             # Text relevance (if text search)
        ),
        # ... more restaurants
    ]
)
```

#### **7. Frontend Integration Example**

```javascript
// React/Next.js
const searchRestaurants = async (query, userLat, userLng) => {
  const response = await fetch('/api/restaurants/search', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      Text: query,
      Latitude: userLat,
      Longitude: userLng,
      Radius: 5000,
      MinRating: 4.0,
      Limit: 20
    })
  });
  
  const data = await response.json();
  
  // Display results
  data.restaurants.forEach(r => {
    console.log(`${r.name} - ${r.distance_km}km - ${r.rating}⭐`);
  });
};

// Usage
searchRestaurants("bún bò", 10.762622, 106.660172);
```

#### **8. Performance Tips**

- ✅ **MinRating = None:** Faster nếu không cần filter rating
- ✅ **Radius nhỏ:** < 10km sẽ nhanh hơn
- ✅ **Limit thấp:** 10-20 results optimal
- ✅ **Không có Text:** Strategy B nhanh hơn 3-5x
- ✅ **Text Search:** Dùng keywords ngắn gọn ("bún bò" thay vì "bún bò huế ngon")

#### **9. Common Use Cases**

```python
# Use Case 1: User search món ăn
await handler.SearchByText("phở", user_lat, user_lng, radius=5000)

# Use Case 2: Explore quán gần đây
await handler.SearchNearby(user_lat, user_lng, radius=3000, min_rating=4.5)

# Use Case 3: Top quán trong khu vực
await handler.GetTopRated(user_lat, user_lng, radius=10000)

# Use Case 4: Search trong province cụ thể
await handler.Search(MongoDBSearchInputSchema(
    Text="lẩu",
    Latitude=user_lat,
    Longitude=user_lng,
    Province="Thành phố Hồ Chí Minh",
    MinRating=4.0
))
```

**📖 Chi tiết:** Xem `Backend/core/mongodb/README.md`

---

**Need help?** Check the [setup guide](Data/scripts/README.md) or contact the team!

## 📋 Overview

MongoDB handlers cung cấp API tương tự như VietMap handlers để frontend dễ dàng integrate. Handler này tối ưu cho việc tìm kiếm nhà hàng theo text và location.

## 🚀 Quick Start

### 1. Import và Initialize

```python
from core.database.mongodb import MongoDB, MongoConfig
from core.mongodb.handlers import MongoDBHandlers, MongoDBSearchInputSchema

# Initialize MongoDB connection
config = MongoConfig(connection_string=YOUR_MONGODB_URI)
await MongoDB.initialize(config)

# Create handler
db = MongoDB.get_database()
handler = MongoDBHandlers(db)
```

### 2. Search với Text Filter

Tìm nhà hàng "bún bò" gần vị trí, có rating >= 4.0:

```python
result = await handler.Search(MongoDBSearchInputSchema(
    Text="bún bò",
    Latitude=10.762622,
    Longitude=106.660172,
    Radius=5000,  # 5km
    MinRating=4.0,
    Limit=20
))

print(f"Found: {result.count} restaurants")
for restaurant in result.restaurants:
    print(f"{restaurant.name} - {restaurant.rating}⭐ - {restaurant.distance_km:.2f}km")
```

### 3. Search Nearby (Không có text)

Tìm nhà hàng gần vị trí (không filter text):

```python
result = await handler.SearchNearby(
    latitude=10.762622,
    longitude=106.660172,
    radius=3000,  # 3km
    min_rating=4.5,
    limit=10
)
```

### 4. Search by Text + Location

Simplified method cho text search:

```python
result = await handler.SearchByText(
    text="phở",
    latitude=21.028511,
    longitude=105.804817,
    radius=10000,  # 10km
    min_rating=4.0,
    limit=20
)
```

### 5. Get Top Rated

Lấy nhà hàng rating cao:

```python
result = await handler.GetTopRated(
    latitude=10.762622,
    longitude=106.660172,
    radius=10000,
    category="Nhà hàng",  # Optional
    limit=10
)
```

## 📊 Input Schema

### MongoDBSearchInputSchema

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `Text` | `str` | No | `None` | Text để search (tên món, tên quán, địa chỉ, tags) |
| `Latitude` | `float` | **Yes** | - | Vĩ độ của user |
| `Longitude` | `float` | **Yes** | - | Kinh độ của user |
| `Radius` | `float` | No | `5000.0` | Bán kính tìm kiếm (meters) |
| `MinRating` | `float` | No | `None` | Rating tối thiểu (0.0-5.0) |
| `Category` | `str` | No | `None` | Filter theo category ("Quán ăn", "Nhà hàng", etc.) |
| `Province` | `str` | No | `None` | Filter theo tỉnh/thành phố |
| `District` | `str` | No | `None` | Filter theo quận/huyện |
| `Limit` | `int` | No | `20` | Số lượng kết quả tối đa (1-100) |

**Example:**
```python
MongoDBSearchInputSchema(
    Text="bún bò",                           # Search "bún bò"
    Latitude=10.762622,                       # User location
    Longitude=106.660172,
    Radius=5000,                              # 5km radius
    MinRating=4.0,                            # Rating >= 4.0
    Category="Quán ăn",                       # Only "Quán ăn"
    Limit=20                                  # Max 20 results
)
```

## 📤 Response Schema

### MongoDBSearchResponse

```python
{
    "success": bool,                  # True if successful
    "count": int,                     # Number of results
    "query_info": {                   # Query information
        "text": str,
        "location": {
            "latitude": float,
            "longitude": float
        },
        "radius_meters": float,
        "radius_km": float,
        "min_rating": float,
        "category": str,
        "province": str,
        "district": str,
        "limit": int
    },
    "restaurants": [...],             # List of restaurants
    "error": str                      # Error message (if failed)
}
```

### MongoDBRestaurantResponse

```python
{
    "id": str,                        # Restaurant ID
    "name": str,                      # Restaurant name
    "category": str,                  # Category
    "rating": float,                  # Rating (0.0-5.0)
    "address": str,                   # Full address
    "province": str,                  # Province
    "district": str,                  # District
    "ward": str,                      # Ward
    "tags": [str],                    # Tags for recommendation
    "location": {                     # GeoJSON location
        "type": "Point",
        "coordinates": [lng, lat]
    },
    "distance": float,                # Distance in meters
    "distance_km": float,             # Distance in kilometers
    "link": str,                      # Google Maps link
    "score": float                    # Relevance score (if text search)
}
```

## 🎯 Use Cases

### Use Case 1: Tìm món ăn gần vị trí

```python
# User nhập "bún bò", app lấy GPS coordinates
result = await handler.SearchByText(
    text="bún bò",
    latitude=user_lat,
    longitude=user_lng,
    radius=5000,
    min_rating=4.0
)
```

### Use Case 2: Explore quán gần đây

```python
# Không nhập text, chỉ lấy quán gần
result = await handler.SearchNearby(
    latitude=user_lat,
    longitude=user_lng,
    radius=3000,
    min_rating=4.5
)
```

### Use Case 3: Tìm món ăn ở khu vực cụ thể

```python
# Tìm phở ở Hà Nội, rating cao
result = await handler.Search(MongoDBSearchInputSchema(
    Text="phở",
    Latitude=21.028511,
    Longitude=105.804817,
    Radius=20000,
    Province="Hà Nội",
    MinRating=4.5
))
```

### Use Case 4: Top restaurants gần user

```python
# Lấy top 10 quán rating cao nhất
result = await handler.GetTopRated(
    latitude=user_lat,
    longitude=user_lng,
    radius=10000,
    limit=10
)
```

## ⚡ Performance Notes

### Strategy A: Text Search (when `Text` provided)

```
1. $match with $text (MUST be first stage)
2. Calculate text score
3. Calculate distance using Haversine formula
4. Filter by radius
5. Apply other filters (rating, category, etc.)
6. Sort by text score + distance
```

**Pros:**
- ✅ Full text search với relevance scoring
- ✅ Search trong name, category, address, tags

**Cons:**
- ⚠️ Chậm hơn Strategy B (phải calculate distance manually)
- ⚠️ MongoDB $text MUST be first stage

### Strategy B: No Text Search (when `Text` is None)

```
1. $geoNear (geospatial search - very fast)
2. Filter by other criteria
3. Sort by distance + rating
```

**Pros:**
- ✅ Cực nhanh (dùng geospatial index trực tiếp)
- ✅ Tối ưu cho "nearby search"

**Cons:**
- ⚠️ Không có text search

## 🔍 Text Search Examples

MongoDB text search hỗ trợ:

```python
# Single word
Text="bún"         # Matches "Bún Bò Huế", "Bún Chả", etc.

# Multiple words (OR logic)
Text="bún bò"      # Matches documents containing "bún" OR "bò"

# Exact phrase (use quotes)
Text='"bún bò"'    # Matches exact phrase "bún bò"

# Exclude words (use minus)
Text="bún -chả"    # Matches "bún" but NOT "chả"
```

## 🎨 Frontend Integration

### React/Next.js Example

```typescript
// API call
const searchRestaurants = async (
  text: string,
  lat: number,
  lng: number,
  radius: number = 5000,
  minRating?: number
) => {
  const response = await fetch('/api/restaurants/search', {
    method: 'POST',
    body: JSON.stringify({
      Text: text,
      Latitude: lat,
      Longitude: lng,
      Radius: radius,
      MinRating: minRating,
      Limit: 20
    })
  });
  
  return await response.json();
};

// Usage
const results = await searchRestaurants(
  "bún bò",
  10.762622,
  106.660172,
  5000,
  4.0
);

console.log(`Found ${results.count} restaurants`);
results.restaurants.forEach(r => {
  console.log(`${r.name} - ${r.distance_km}km - ${r.rating}⭐`);
});
```

## 🔥 Advanced Usage

### Combine with VietMap Handlers

```python
from core.vietmap.handlers import VietmapHandlers, VietmapSearchInputSchema
from core.mongodb.handlers import MongoDBHandlers, MongoDBSearchInputSchema

# Step 1: User nhập địa chỉ text
user_address = "Bến Thành, Quận 1"

# Step 2: Geocode với VietMap
vietmap = VietmapHandlers()
geocode_result = await vietmap.Search(
    VietmapSearchInputSchema(Text=user_address)
)

coords = geocode_result[0]["geometry"]["coordinates"]
lat, lng = coords[1], coords[0]

# Step 3: Search restaurants gần địa chỉ đó
mongo_handler = MongoDBHandlers(db)
restaurants = await mongo_handler.SearchByText(
    text="bún bò",
    latitude=lat,
    longitude=lng,
    radius=5000
)
```

## ✅ Testing

Run test script:

```bash
python Data/scripts/test_mongodb_handlers.py
```

Or simple test:

```bash
python Data/scripts/test_simple.py
```

## 📝 Notes

1. **MinRating = None**: Nếu không truyền `MinRating`, sẽ lấy tất cả ratings
2. **Radius**: Đơn vị là **meters** (5000 = 5km)
3. **Text Search**: Tự động search trong `name`, `category`, `address`, `tags`
4. **Distance Calculation**: Dùng Haversine formula (chính xác cho Earth sphere)
5. **Sorting**: 
   - Có text: Sort by **text score** → distance
   - Không có text: Sort by **distance** → rating

## 🚨 Error Handling

```python
result = await handler.Search(inputs)

if not result.success:
    print(f"Error: {result.error}")
else:
    print(f"Found {result.count} restaurants")
```

## 📚 References

- MongoDB Geospatial Queries: https://docs.mongodb.com/manual/geospatial-queries/
- MongoDB Text Search: https://docs.mongodb.com/manual/text-search/
- Haversine Formula: https://en.wikipedia.org/wiki/Haversine_formula
