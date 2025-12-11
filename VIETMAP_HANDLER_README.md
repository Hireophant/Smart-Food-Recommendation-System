# Vietmap Handler - Quick Start

## What I Created For You

I've built a complete Vietmap integration system with the following components:

### 1. **Core Components**

#### `Backend/core/__init__.py`
- Added `MapCoordinate` class to represent lat/lng coordinates
- Used throughout the system for type safety

#### `Backend/core/vietmap/handlers.py` (Already existed)
- `VietmapHandlers` class - Your base API client
- Handles all communication with Vietmap API
- Methods: Search, Autocomplete, Place, Reverse

#### `Backend/core/vietmap/schemas.py` (Already existed)
- Pydantic models for Vietmap responses
- Type-safe data structures

### 2. **API Router** - `Backend/routers/vietmap.py` ✨ NEW

This is the **main file you'll use**. It exposes REST endpoints:

```
POST/GET /api/vietmap/search          - Search locations
POST/GET /api/vietmap/autocomplete    - Autocomplete suggestions  
GET      /api/vietmap/place/{ref_id}  - Get place details
POST/GET /api/vietmap/reverse         - Reverse geocoding
GET      /api/vietmap/health           - Check configuration
```

### 3. **Documentation** ✨ NEW

#### `VIETMAP_INTEGRATION_GUIDE.md`
Complete guide with:
- API endpoint documentation
- Request/response examples
- Code examples (Python & Flutter)
- Integration patterns
- Best practices

### 4. **Test File** - `Backend/test_handlers.py` ✨ NEW

Run this to test everything:
```bash
python Backend/test_handlers.py
```

## How to Use

### Step 1: Setup Environment

Add to your `.env` file:
```env
VIETMAP_API_KEY=your_api_key_here
```

### Step 2: Router is Already Registered!

I already added this to your `app.py`:
```python
from routers.vietmap import router as vietmap_router
app.include_router(vietmap_router)
```

### Step 3: Start Your Server

```bash
cd Backend
uvicorn app:app --reload
```

### Step 4: Test the API

Visit: http://localhost:8000/docs

You'll see all the Vietmap endpoints in Swagger UI!

## Quick Examples

### From Frontend (Flutter)

```dart
// Search for a place
final response = await http.get(
  Uri.parse('http://localhost:8000/api/vietmap/search?text=Cafe%20Hanoi'),
);
final results = jsonDecode(response.body);
```

### From Backend (Python)

```python
from core.vietmap.handlers import VietmapHandlers

handler = VietmapHandlers()
try:
    results = await handler.Search(VietmapSearchInputSchema(Text="Cafe"))
    for place in results:
        print(f"{place.Name}: {place.Address}")
finally:
    await handler.Close()
```

## Architecture

```
User Request (Flutter)
      ↓
FastAPI Router (/api/vietmap/search)
      ↓
VietmapHandlers (core/vietmap/handlers.py)
      ↓
Vietmap API (maps.vietmap.vn)
      ↓
Response (JSON)
```

## Key Features

✅ **Both POST and GET methods** - Flexible API usage
✅ **Complete type safety** - Pydantic models everywhere
✅ **Error handling** - Proper HTTP status codes
✅ **Context manager support** - Auto-closes connections
✅ **Well documented** - Every endpoint has examples
✅ **Ready for Flutter** - Simple HTTP calls

## Common Use Cases

### 1. Search Box Autocomplete
```python
GET /api/vietmap/autocomplete?text=Cafe%20Ha
```

### 2. Find Restaurants Near Location
```python
# First, get location coordinates
GET /api/vietmap/search?text=Hoan%20Kiem

# Then search restaurants
GET /api/query/search/location?latitude=21.0285&longitude=105.8542
```

### 3. Get Address from Map Click
```python
GET /api/vietmap/reverse?latitude=21.0285&longitude=105.8542
```

### 4. Get Full Place Details
```python
GET /api/vietmap/place/{ref_id}
```

## Files Created/Modified

✨ **NEW FILES:**
- `Backend/routers/vietmap.py` - Main router with all endpoints
- `Backend/test_handlers.py` - Test script
- `VIETMAP_INTEGRATION_GUIDE.md` - Complete documentation
- `VIETMAP_HANDLER_README.md` - This file

✏️ **MODIFIED FILES:**
- `Backend/core/__init__.py` - Added MapCoordinate class
- `Backend/app.py` - Registered the router

## What Makes This Handler Good?

1. **Based on your existing code** - Uses your `VietmapHandlers` class
2. **RESTful API design** - Standard HTTP methods
3. **Flexible endpoints** - Both POST (JSON) and GET (query params)
4. **Type-safe** - Pydantic validation everywhere
5. **Error handling** - Proper status codes and messages
6. **Documentation** - Swagger UI auto-generated
7. **Easy to test** - Test file included
8. **Production-ready** - Proper resource cleanup

## Next Steps

1. **Test it**: Run `python Backend/test_handlers.py`
2. **Try the API**: Visit http://localhost:8000/docs
3. **Integrate**: Use the Flutter examples from the guide
4. **Customize**: Add more endpoints as needed

## Need Help?

Check these files:
- `VIETMAP_INTEGRATION_GUIDE.md` - Complete API documentation
- `Backend/routers/vietmap.py` - See the implementation
- `Backend/test_handlers.py` - Example usage

## Where to Start Coding?

**For API endpoints**: Modify `Backend/routers/vietmap.py`
**For API logic**: The handler is already in `Backend/core/vietmap/handlers.py`
**For data models**: Check `Backend/core/vietmap/schemas.py`

That's it! Your Vietmap handler is ready to use! 🚀
