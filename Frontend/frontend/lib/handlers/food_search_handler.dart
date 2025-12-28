import 'package:geolocator/geolocator.dart';
import '../models/food_model.dart';
import '../models/dish_model.dart';
import 'dish_handler.dart';
import 'restaurant_handler.dart';

/// Handler Interface (Core/Backend Contract)
///
/// Định nghĩa các "Hành động" mà Frontend cần.
/// Core/Backend sẽ implement interface này.
/// Xem thêm: Guideline.md -> Mục 3.2 "Fake it until you make it"
abstract class FoodSearchHandler {
  // --- Discovery Flow ---
  Future<List<DishItem>> getAllDishes(); //lay all cac mon an ra
  Future<List<DishItem>> searchDishes(String query); //tim mon an theo query
  Future<SearchResult> searchFoods({
    String? query,
    String? tag,
    double? lat,
    double? lon,
    double? radius,
    int? limit,
  }); //tim restaurant (o day goi la Food) theo query

  // --- Restaurant Flow ---
  Future<SearchResult> getAllFoods(); //lay all nha hang ra (Food = nha hang)
  Future<SearchResult> getRestaurantsByDish(
    String dishId,
  ); //tim nha hang theo mon an (dish)
  
  // --- Client-side Filtering ---
  Future<SearchResult> searchFoodsWithClientFiltering({
    String? query,
    String? tag,
    double? userLat,
    double? userLon,
    double? maxDistanceKm, // Client-side distance filter
    List<String>? tastes, // Client-side taste filter
    int? limit,
  });
}

/// Implementation hiện tại - Mock Data kết hợp OSM Search
///
/// Class này giả lập việc gọi API từ Backend.
/// - Dữ liệu cứng (Hardcoded) được dùng để hiển thị các quán mẫu đẹp mắt.
/// - T tích hợp gọi API OpenStreetMap (Nominatim) để tìm kiếm địa điểm thực tế.
// class MockFoodSearchHandler implements FoodSearchHandler {
//   // Use data from RestaurantHandler to ensure consistency
//   List<RestaurantItem> get _mockFoods => MockRestaurantHandler.mockRestaurants;

//   @override
//   Future<SearchResult> searchFoods(String query) async {
//     // 1. Search in local mock data
//     final lowerQuery = query.toLowerCase();

//     // If query is "all", return all restaurants
//     if (lowerQuery == 'all') {
//       return SearchResult(items: _mockFoods);
//     }

//     final localResults = _mockFoods
//         .where(
//           (restaurant) =>
//               restaurant.name.toLowerCase().contains(lowerQuery) ||
//               restaurant.category.toLowerCase().contains(lowerQuery) ||
//               (restaurant.description?.toLowerCase().contains(lowerQuery) ??
//                   false) ||
//               restaurant.tags.any(
//                 (tag) => tag.toLowerCase().contains(lowerQuery),
//               ),
//         )
//         .toList();

//     // 2. Search in OSM (if query is long enough)
//     if (query.length > 2) {
//       try {
//         final url = Uri.parse(
//           'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=vn',
//         );

//         // Add User-Agent as required by Nominatim
//         final response = await http.get(
//           url,
//           headers: {'User-Agent': 'SmartFoodApp/1.0'},
//         );

//         if (response.statusCode == 200) {
//           final List<dynamic> data = json.decode(response.body);
//           final osmResults = data.map((item) {
//             return RestaurantItem(
//               id: 'osm_${item['place_id']}',
//               name:
//                   item['display_name']?.split(',').first ?? 'Unknown Location',
//               category: item['type'] ?? 'Place',
//               rating: 4.0, // Default rating for OSM
//               ratingCount: 10,
//               imageUrl: 'assets/images/com_tam.png', // Fallback image
//               address: item['display_name'] ?? 'Địa chỉ đang cập nhật',
//               description: item['display_name'],
//               priceLevel: '\$\$',
//               isOpen: true,
//               distance: 'Unknown',
//               tags: ['OSM Result'],
//               latitude: double.parse(item['lat']),
//               longitude: double.parse(item['lon']),
//             );
//           }).toList();

//           localResults.addAll(osmResults);
//         }
//       } catch (e) {
//         // print('OSM Search Error: $e');
//         // Ignore error and return local results
//       }
//     }

//     return SearchResult(items: localResults);
//   }

//   @override
//   Future<SearchResult> getAllFoods() async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     return SearchResult(items: _mockFoods);
//   }

//   @override
//   Future<RestaurantItem?> getFoodDetails(String id) async {
//     await Future.delayed(const Duration(milliseconds: 100));
//     try {
//       return _mockFoods.firstWhere((restaurant) => restaurant.id == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   @override
//   Future<List<MenuItem>> getMenu(String restaurantId) async {
//     await Future.delayed(const Duration(milliseconds: 500));
//     // Mock menu - Generic items for now
//     return [
//       MenuItem(
//         id: '1',
//         name: 'Signature Dish',
//         description: 'Best in town',
//         price: 50000,
//         imageUrl: 'assets/images/com_tam.png',
//       ),
//       MenuItem(
//         id: '2',
//         name: 'Special Drink',
//         description: 'Refeshing',
//         price: 25000,
//         imageUrl: 'assets/images/che.png',
//       ),
//     ];
//   }

//   @override
//   Future<List<DishItem>> getAllDishes() async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     // Retrieve from DishHandler to ensure consistency
//     return DishHandler.allDishes;
//   }

//   @override
//   Future<List<DishItem>> searchDishes(String query) async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     final lowerQuery = query.toLowerCase();
//     return DishHandler.allDishes.where((dish) {
//       return dish.name.toLowerCase().contains(lowerQuery) ||
//           dish.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
//     }).toList();
//   }

//   @override
//   Future<SearchResult> getRestaurantsByDish(String dishId) async {
//     await Future.delayed(const Duration(milliseconds: 500));

//     // Use the logic from RestaurantHandler to map dishId to Name
//     // For simplicity, we can instantiate MockRestaurantHandler or just use similar logic
//     // Since FoodSearchHandler is somewhat redundant with RestaurantHandler, ideally they merge.
//     // But for now, let's delegate.

//     return MockRestaurantHandler().getRestaurantsByDish(dishId);
//   }
// }

class FoodSearchHandlerImpl implements FoodSearchHandler {
  final DishHandler dishHandler;
  final RestaurantHandler restaurantHandler;

  FoodSearchHandlerImpl({
    required this.dishHandler,
    required this.restaurantHandler,
  });

  // -------------------------
  // Discovery Flow
  // -------------------------

  @override
  Future<List<DishItem>> getAllDishes() {
    return dishHandler.searchDishes(query: '');
  }

  @override
  Future<List<DishItem>> searchDishes(String query) {
    return dishHandler.searchDishes(query: query);
  }

  /// Wrapper: search ăn uống (dish + restaurant)
  @override
  Future<SearchResult> searchFoods({
    String? query,
    String? tag,
    double? lat,
    double? lon,
    double? radius,
    int? limit,
  }) async {
    try {
      final results = await restaurantHandler.searchRestaurants(
        query: query,
        tag: tag,
        lat: lat,
        lon: lon,
        radius: radius,
        limit: limit ?? 20,
      );

      return SearchResult(items: results);
    } catch (e) {
      return SearchResult.error("Lỗi: ${e.toString()}");
    }
  }

  // -------------------------
  // Restaurant Flow
  // -------------------------

  @override
  Future<SearchResult> getAllFoods() async {
    try {
      final restaurants = await restaurantHandler.searchRestaurants(query: '');
      return SearchResult(items: restaurants);
    } catch (e) {
      return SearchResult.error("Lỗi: ${e.toString()}");
    }
  }

  @override
  Future<SearchResult> getRestaurantsByDish(String dishName) async {
    try {
      final restaurants = await restaurantHandler.searchRestaurants(
        query: dishName,
      );
      return SearchResult(items: restaurants);
    } catch (e) {
      return SearchResult.error("Lỗi: ${e.toString()}");
    }
  }

  // -------------------------
  // Client-side Filtering
  // -------------------------

  /// Client-side filtering for distance and taste
  /// 
  /// Since Backend API doesn't support radius and taste parameters yet,
  /// we implement filtering on the client side.
  /// 
  /// Logic:
  /// 1. Fetch raw list from Backend API
  /// 2. Filter by distance (using geolocator to calculate)
  /// 3. Filter by taste (matching tags/description)
  /// 4. Return filtered list
  @override
  Future<SearchResult> searchFoodsWithClientFiltering({
    String? query,
    String? tag,
    double? userLat,
    double? userLon,
    double? maxDistanceKm,
    List<String>? tastes,
    int? limit,
  }) async {
    try {
      // 1. Fetch raw data from Backend (without radius/taste params)
      final rawResults = await restaurantHandler.searchRestaurants(
        query: query,
        tag: tag,
        lat: userLat,
        lon: userLon,
        // Don't pass radius to Backend - we'll filter client-side
        limit: 100, // Get more results to filter from
      );

      List<RestaurantItem> filteredResults = rawResults;

      // 2. Apply Distance Filter (Client-side)
      if (maxDistanceKm != null &&
          userLat != null &&
          userLon != null &&
          maxDistanceKm < 100) {
        // Only filter if distance < 100km (< 100 means user wants filtering)
        filteredResults = filteredResults.where((restaurant) {
          final distanceInMeters = Geolocator.distanceBetween(
            userLat,
            userLon,
            restaurant.latitude,
            restaurant.longitude,
          );
          final distanceInKm = distanceInMeters / 1000;
          return distanceInKm <= maxDistanceKm;
        }).toList();
      }

      // 3. Apply Taste Filter (Client-side)
      if (tastes != null && tastes.isNotEmpty) {
        filteredResults = filteredResults.where((restaurant) {
          // Check if any taste matches in tags or description
          final tagsLower = restaurant.tags.map((t) => t.toLowerCase()).toList();
          final descLower = restaurant.description?.toLowerCase() ?? '';
          final nameLower = restaurant.name.toLowerCase();
          final categoryLower = restaurant.category.toLowerCase();

          return tastes.any((taste) {
            final tasteLower = taste.toLowerCase();
            return tagsLower.contains(tasteLower) ||
                descLower.contains(tasteLower) ||
                nameLower.contains(tasteLower) ||
                categoryLower.contains(tasteLower);
          });
        }).toList();
      }

      // 4. Apply limit
      if (limit != null && filteredResults.length > limit) {
        filteredResults = filteredResults.sublist(0, limit);
      }

      return SearchResult(items: filteredResults);
    } catch (e) {
      return SearchResult.error("Lỗi: ${e.toString()}");
    }
  }
}
