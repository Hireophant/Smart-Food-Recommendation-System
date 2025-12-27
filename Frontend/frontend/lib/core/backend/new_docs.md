# New Backend API (Dart)

This folder keeps the *new* backend API layer.

- Old files `apply.dart` / `map.dart` are intentionally left as-is.
- The backend requires `Authorization: Bearer <jwt>` for most routes.
- JWT is taken directly from the current Supabase session.

## Files

- `backend_api.dart`: shared HTTP transport + error mapping + Supabase session check.
- `maps_models.dart`, `maps_client.dart`: Maps models + client.
- `restaurants_models.dart`, `restaurants_client.dart`: Restaurant models + client.
- `foods_models.dart`, `foods_client.dart`: Foods models + client.
- `search_models.dart`, `search_client.dart`: Search models + client.
- `weather_models.dart`, `weather_client.dart`: Weather models + client.

## Quick usage

```dart
import 'package:frontend/core/backend/backend_api.dart';
import 'package:frontend/core/backend/maps_client.dart';
import 'package:frontend/core/backend/maps_models.dart';
import 'package:frontend/core/backend/foods_client.dart';
import 'package:frontend/core/backend/foods_models.dart';
import 'package:frontend/core/backend/restaurants_client.dart';
import 'package:frontend/core/backend/restaurants_models.dart';
import 'package:frontend/core/backend/search_client.dart';
import 'package:frontend/core/backend/search_models.dart';
import 'package:frontend/core/backend/weather_client.dart';
import 'package:frontend/core/backend/weather_models.dart';

final api = BackendAPI(); // defaults to http://localhost:8000
final maps = MapsClient(api);
final foods = FoodsClient(api);
final restaurants = RestaurantsClient(api);
final search = SearchClient(api);
final weather = WeatherClient(api);

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

// Restaurants: Search (Formatted)
final restaurantsFormatted = await restaurants.searchFormatted(
  RestaurantSearchParams(
    focusLat: 10.8231,
    focusLon: 106.6297,
    query: 'phở',
    radius: 5000,
    minRating: 3.5,
    limit: 20,
  ),
);
print(restaurantsFormatted.result);

// Restaurants: By IDs
final byIds = await restaurants.byIds(
  RestaurantsByIdsParams(ids: results.take(3).map((e) => e.id).toList()),
);

// Restaurants: By IDs (Formatted)
final byIdsFormatted = await restaurants.byIdsFormatted(
  RestaurantsByIdsParams(ids: results.take(3).map((e) => e.id).toList()),
);
print(byIdsFormatted.result);

// Foods: Search
final foodsResult = await foods.search(
  FoodSearchParams(
    query: 'bún',
    // Optional filters
    // category: 'Phở & Bún',
    // loai: 'món nước',
    // kieuTenMon: '...',
    // tags: 'cay',
    limit: 20,
  ),
);

// Each Food now includes a `description` field (defaults to "No description" when missing).

// Foods: Search (Formatted)
final foodsFormatted = await foods.searchFormatted(
  FoodSearchParams(
    query: 'bún',
    limit: 20,
  ),
);
print(foodsFormatted.result);

// Foods: By IDs
final foodsByIds = await foods.byIds(
  FoodsByIdsParams(ids: foodsResult.take(3).map((e) => e.id).toList()),
);

// Foods: By IDs (Formatted)
final foodsByIdsFormatted = await foods.byIdsFormatted(
  FoodsByIdsParams(ids: foodsResult.take(3).map((e) => e.id).toList()),
);
print(foodsByIdsFormatted.result);

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

// Weather: Structured object
final w = await weather.weather(WeatherParams(lat: 10.8231, lon: 106.6297));

// Weather: Formatted string
final wText = await weather.formatted(WeatherParams(lat: 10.8231, lon: 106.6297));
print(wText.result);

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
