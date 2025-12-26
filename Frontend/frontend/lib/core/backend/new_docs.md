# New Backend API (Dart)

This folder keeps the *new* backend API layer.

- Old files `apply.dart` / `map.dart` are intentionally left as-is.
- The backend requires `Authorization: Bearer <jwt>` for most routes.
- JWT is taken directly from the current Supabase session.

## Files

- `backend_api.dart`: shared HTTP transport + error mapping + Supabase session check.
- `maps_models.dart`, `maps_client.dart`: Maps models + client.
- `restaurants_models.dart`, `restaurants_client.dart`: Restaurant models + client.
- `search_models.dart`, `search_client.dart`: Search models + client.

## Quick usage

```dart
import 'package:frontend/core/backend/backend_api.dart';
import 'package:frontend/core/backend/maps_client.dart';
import 'package:frontend/core/backend/maps_models.dart';
import 'package:frontend/core/backend/restaurants_client.dart';
import 'package:frontend/core/backend/restaurants_models.dart';
import 'package:frontend/core/backend/search_client.dart';
import 'package:frontend/core/backend/search_models.dart';

final api = BackendAPI(); // defaults to http://localhost:8000
final maps = MapsClient(api);
final restaurants = RestaurantsClient(api);
final search = SearchClient(api);

// Maps: Autocomplete
final suggestions = await maps.autocomplete(
  MapsAutocompleteParams(
    query: 'Bến Thành',
    focusLat: 10.8231,
    focusLon: 106.6297,
  ),
);

// Maps: Place details
final place = await maps.place(MapsPlaceParams(id: suggestions.first.id));

// Maps: Reverse geocoding
final reverse = await maps.reverseGeocoding(
  MapsReverseParams(lat: 10.8231, lon: 106.6297),
);

// Maps: Route
final route = await maps.route(
  MapsRouteParams(
    points: ['10.8231,106.6297', '10.7769,106.7009'],
    vehicle: VietmapRouteVehicleType.motorcycle,
    avoid: [VietmapRouteAvoidType.toll],
  ),
);

// Restaurants: Search
final results = await restaurants.search(
  RestaurantSearchParams(
    focusLat: 10.8231,
    focusLon: 106.6297,
    query: 'phở',
    // Optional: filter by tags (dish types, vibes, etc.)
    // tags: 'bún',
    radius: 5000,
    minRating: 3.5,
    limit: 20,
  ),
);

// Restaurants: By IDs
final byIds = await restaurants.byIds(
  RestaurantsByIdsParams(ids: results.take(3).map((e) => e.id).toList()),
);

// Search: Structured result (locations + organic results)
final searchResult = await search.search(
  SearchParams(
    query: 'Bánh mì',
    location: 'Vietnam',
    maxLocations: 5,
    maxResults: 5,
  ),
);

// Search: Formatted Vietnamese text
final formatted = await search.formatted(
  SearchParams(query: 'Bánh mì', maxLocations: 5, maxResults: 5),
);
print(formatted.result);

api.dispose();
```

## Error handling

All calls throw `BackendApiException` on failure.

```dart
try {
  final results = await restaurants.search(RestaurantSearchParams(query: 'bún'));
} on BackendApiException catch (e) {
  // e.kind is a small enum: notLoggedIn / unauthorized / validation / etc.
  // e.statusCode is the HTTP code when known
  // e.details holds backend `{code, detail}` list when present
}
```
