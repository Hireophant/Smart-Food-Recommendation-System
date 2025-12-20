# Frontend Usage: DataAPIWrapper (`apply.dart`)

## Quick Setup
- Add dependency in `pubspec.yaml`:
  ```yaml
  dependencies:
    http: ^1.1.0
  ```
- Import where you call the API:
  ```dart
  import 'package:your_app/core/backend/apply.dart';
  ```

## Init Once (e.g., in a provider/service)
```dart
final api = DataAPIWrapper(
  baseUrl: 'https://your-backend-api.com',
  accessToken: 'token_if_needed',
);
```

## Simple Call From UI Logic
```dart
Future<List<Restaurant>> loadRestaurants() async {
  return api.searchRestaurantsSimple(
    focusLat: 10.8231,
    focusLon: 106.6297,
    query: 'pho',
    radius: 4000,
    minRating: 3.5,
    limit: 15,
  );
}
```

## With Params Object (when building dynamic filters)
```dart
final params = RestaurantSearchParams(
  focusLat: 10.7626,
  focusLon: 106.6823,
  query: searchText,
  radius: selectedRadius,
  minRating: sliderValue,
  category: selectedCategory,
  province: selectedProvince,
  district: selectedDistrict,
  limit: 20,
);

final results = await api.restaurantSearch(params);
```

## UI Integration Pattern
- Trigger calls inside view models/providers, not directly in widgets.
- Debounce search input before calling to respect backend rate limits (20/min).
- Show loading + error states; catch `ArgumentError` for bad params and generic exceptions for network/auth issues.

## Token Updates
```dart
api.setAccessToken(newToken);
```

## Cleanup (e.g., in provider dispose)
```dart
api.dispose();
```

## Maps API (map.dart)
- Import: `import 'package:your_app/core/backend/map.dart';`
- Init: `final maps = MapApiWrapper(baseUrl: 'https://your-backend-api.com', accessToken: 'token');`
- Search:
  ```dart
  final results = await maps.search(query: 'Ben Thanh', focusLat: 10.772, focusLon: 106.698);
  ```
- Autocomplete (same params as search):
  ```dart
  final hints = await maps.autocomplete(query: searchText, searchCenterLat: 10.77, searchCenterLon: 106.69, searchRadius: 3000);
  ```
- Place detail:
  ```dart
  final place = await maps.place('some_place_id');
  ```
- Reverse geocoding:
  ```dart
  final addresses = await maps.reverse(lat: 10.77, lon: 106.69);
  ```
- Route (2–15 points):
  ```dart
  final route = await maps.route(
    points: ['10.77,106.69', '10.78,106.70'],
    vehicle: 'car',
    avoid: ['toll'],
  );
  ```
- Remember to `maps.dispose()` when done.
