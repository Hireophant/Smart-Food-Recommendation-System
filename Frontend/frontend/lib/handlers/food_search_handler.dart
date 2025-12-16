import 'dart:convert';
import 'package:http/http.dart' as http;
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
  Future<List<DishItem>> getAllDishes();
  Future<SearchResult> searchFoods(String query);

  // --- Restaurant Flow ---
  Future<SearchResult> getAllFoods();
  Future<SearchResult> getRestaurantsByDish(String dishId);
  Future<RestaurantItem?> getFoodDetails(String id);
  Future<List<MenuItem>> getMenu(String id);
}

/// Implementation hiện tại - Mock Data kết hợp OSM Search
///
/// Class này giả lập việc gọi API từ Backend.
/// - Dữ liệu cứng (Hardcoded) được dùng để hiển thị các quán mẫu đẹp mắt.
/// - T tích hợp gọi API OpenStreetMap (Nominatim) để tìm kiếm địa điểm thực tế.
class MockFoodSearchHandler implements FoodSearchHandler {
  // Use data from RestaurantHandler to ensure consistency
  List<RestaurantItem> get _mockFoods => MockRestaurantHandler.mockRestaurants;

  @override
  Future<SearchResult> searchFoods(String query) async {
    // 1. Search in local mock data
    final lowerQuery = query.toLowerCase();
    final localResults = _mockFoods
        .where(
          (restaurant) =>
              restaurant.name.toLowerCase().contains(lowerQuery) ||
              restaurant.category.toLowerCase().contains(lowerQuery) ||
              (restaurant.description?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              restaurant.tags.any(
                (tag) => tag.toLowerCase().contains(lowerQuery),
              ),
        )
        .toList();

    // 2. Search in OSM (if query is long enough)
    if (query.length > 2) {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=vn',
        );

        // Add User-Agent as required by Nominatim
        final response = await http.get(
          url,
          headers: {'User-Agent': 'SmartFoodApp/1.0'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final osmResults = data.map((item) {
            return RestaurantItem(
              id: 'osm_${item['place_id']}',
              name:
                  item['display_name']?.split(',').first ?? 'Unknown Location',
              category: item['type'] ?? 'Place',
              rating: 4.0, // Default rating for OSM
              ratingCount: 10,
              imageUrl: 'assets/images/com_tam.png', // Fallback image
              address: item['display_name'] ?? 'Địa chỉ đang cập nhật',
              description: item['display_name'],
              priceLevel: '\$\$',
              isOpen: true,
              distance: 'Unknown',
              tags: ['OSM Result'],
              latitude: double.parse(item['lat']),
              longitude: double.parse(item['lon']),
            );
          }).toList();

          localResults.addAll(osmResults);
        }
      } catch (e) {
        // print('OSM Search Error: $e');
        // Ignore error and return local results
      }
    }

    return SearchResult(items: localResults);
  }

  @override
  Future<SearchResult> getAllFoods() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SearchResult(items: _mockFoods);
  }

  @override
  Future<RestaurantItem?> getFoodDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockFoods.firstWhere((restaurant) => restaurant.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<MenuItem>> getMenu(String restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock menu - Generic items for now
    return [
      MenuItem(
        id: '1',
        name: 'Signature Dish',
        description: 'Best in town',
        price: 50000,
        imageUrl: 'assets/images/com_tam.png',
      ),
      MenuItem(
        id: '2',
        name: 'Special Drink',
        description: 'Refeshing',
        price: 25000,
        imageUrl: 'assets/images/che.png',
      ),
    ];
  }

  @override
  Future<List<DishItem>> getAllDishes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Retrieve from DishHandler to ensure consistency
    return DishHandler.allDishes;
  }

  @override
  Future<SearchResult> getRestaurantsByDish(String dishId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Use the logic from RestaurantHandler to map dishId to Name
    // For simplicity, we can instantiate MockRestaurantHandler or just use similar logic
    // Since FoodSearchHandler is somewhat redundant with RestaurantHandler, ideally they merge.
    // But for now, let's delegate.

    return MockRestaurantHandler().getRestaurantsByDish(dishId);
  }
}
