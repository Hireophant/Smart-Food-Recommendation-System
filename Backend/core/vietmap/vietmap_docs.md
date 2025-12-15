# Vietmap Module Documentation

## Overview
The Vietmap module provides an async client for interacting with Vietmap API services. It handles geocoding, reverse geocoding, place search, and autocomplete functionality for Vietnam locations.

**Import:** `from core.vietmap import *`

**Requirements:** Set `VIETMAP_API_KEY` environment variable before use.

---

## Quick Start

```python
from core.vietmap import VietmapClient, VietmapSearchInputSchema, MapCoordinate

async with VietmapClient() as client:
    # Search for a place
    results = await client.Search(VietmapSearchInputSchema(Text="coffee shop"))
```

---

## Main Components

### VietmapClient
The main client for all Vietmap operations. Always use as async context manager.

### Key Schemas

- **MapCoordinate**: Geographic coordinates (Latitude, Longitude)
- **VietmapSearchInputSchema**: Input for Search/Autocomplete operations
- **VietmapGeocodingResponseModel**: Result from Search/Autocomplete/Reverse
- **VietmapPlaceResponseModel**: Detailed place information

---

## What It Can Do

### 1. Search for Places
Find places by text query with optional filters.

**Input:** `VietmapSearchInputSchema`
- `Text` (required): Search query
- `Focus`: Prioritize results near coordinates
- `CircleCenter` + `CircleRadius`: Search within radius (km)
- `CityId`, `DistId`, `WardId`: Filter by administrative boundaries
- `Categories`: Filter by place categories

**Output:** List of `VietmapGeocodingResponseModel` or None

**Example:**
```python
# Basic search
search_input = VietmapSearchInputSchema(Text="restaurant")
results = await client.Search(search_input)

# Search near location with radius
search_input = VietmapSearchInputSchema(
    Text="hotel",
    CircleCenter=MapCoordinate(Latitude=21.0285, Longitude=105.8542),
    CircleRadius=2500  # 2.5 km radius
)
results = await client.Search(search_input)

# Access results
for place in results:
    print(f"{place.Name} - {place.Address}")
    print(f"Distance: {place.Distance} km")
    print(f"Ref ID: {place.ReferenceId}")
```

---

### 2. Autocomplete Suggestions
Get autocomplete suggestions for partial text input.

**Input:** `VietmapAutocompleteInputSchema` (same as Search)
- `Text` (required): Partial search query
- Same optional filters as Search

**Output:** List of `VietmapGeocodingResponseModel` or None

**Example:**
```python
autocomplete_input = VietmapAutocompleteInputSchema(
    Text="Ha No",
    CityId=1  # Limit to specific city
)
suggestions = await client.Autocomplete(autocomplete_input)

for suggestion in suggestions:
    print(f"{suggestion.Display}")
```

---

### 3. Get Place Details
Retrieve detailed information about a specific place using its reference ID.

**Input:** Reference ID string (from Search/Autocomplete results)

**Output:** `VietmapPlaceResponseModel` or None

**Example:**
```python
# Get ref_id from search results
search_results = await client.Search(VietmapSearchInputSchema(Text="Hanoi Opera House"))
ref_id = search_results[0].ReferenceId

# Get detailed place info
place_details = await client.Place(ref_id)

print(f"Name: {place_details.Name}")
print(f"Address: {place_details.Address}")
print(f"City: {place_details.CityName}")
print(f"District: {place_details.DistrictName}")
print(f"Coordinates: {place_details.Latitude}, {place_details.Longitude}")
```

---

### 4. Reverse Geocoding
Convert coordinates to place information.

**Input:** `MapCoordinate` (Latitude, Longitude)

**Output:** List of `VietmapGeocodingResponseModel` or None

**Example:**
```python
coords = MapCoordinate(Latitude=21.0285, Longitude=105.8542)
places = await client.Reverse(coords)

for place in places:
    print(f"{place.Name} - {place.Address}")
```

---

## Common Usage Patterns

### Finding Nearby Restaurants
```python
async with VietmapClient() as client:
    user_location = MapCoordinate(Latitude=21.0285, Longitude=105.8542)
    
    results = await client.Search(VietmapSearchInputSchema(
        Text="restaurant",
        CircleCenter=user_location,
        CircleRadius=1000.0  # 1 km radius
    ))
    
    # Sort by distance
    sorted_results = sorted(results, key=lambda x: x.Distance)
```

### Search + Get Details Workflow
```python
async with VietmapClient() as client:
    # Step 1: Search
    search_results = await client.Search(
        VietmapSearchInputSchema(Text="coffee shop hanoi")
    )
    
    # Step 2: Get details for first result
    if search_results:
        details = await client.Place(search_results[0].ReferenceId)
        print(f"Full info: {details.Address}")
```

### Location-Based Autocomplete
```python
async with VietmapClient() as client:
    user_coords = MapCoordinate(Latitude=21.0285, Longitude=105.8542)
    
    suggestions = await client.Autocomplete(VietmapAutocompleteInputSchema(
        Text="caf",
        Focus=user_coords  # Prioritize nearby results
    ))
```

---

## Response Data Structure

### VietmapGeocodingResponseModel
Returned by Search, Autocomplete, and Reverse operations.

**Key Fields:**
- `ReferenceId`: Use with Place() to get details
- `Name`: Place name
- `Address`: Full address
- `Display`: Display-friendly name
- `Distance`: Distance from query point (km)
- `Boundaries`: Administrative info (city, district, ward)
- `Categories`: Place categories

### VietmapPlaceResponseModel
Returned by Place operation with detailed info.

**Key Fields:**
- `Name`, `Display`: Place name
- `Address`: Full address
- `Street`, `HouseNumber`: Address components
- `CityName`, `DistrictName`, `WardName`: Administrative names
- `CityId`, `DistrictId`, `WardId`: Administrative IDs
- `Latitude`, `Longitude`: Coordinates

---

## Error Handling

The client raises `HTTPException` on errors:
- `404`: Place not found
- `500`: API key issues or server errors

```python
from fastapi import HTTPException

try:
    async with VietmapClient() as client:
        results = await client.Search(VietmapSearchInputSchema(Text="xyz"))
except HTTPException as e:
    print(f"Error: {e.status_code} - {e.detail}")
```

---

## Notes

- You should use `VietmapClient` as async context manager (`async with`), if not you'll need to manually close it using `Close()`.
- Results are `None` if failed to query.
- Coordinates use format: `MapCoordinate(Latitude=..., Longitude=...)`
- `CircleRadius` provided are in meters, and result `Distance` are in kilometers
- Set `VIETMAP_API_KEY` environment variable before initializing client (otherwise `EnvironmentError` will be throw).
