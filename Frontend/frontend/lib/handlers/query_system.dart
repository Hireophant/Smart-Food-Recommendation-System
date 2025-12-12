// ignore_for_file: non_constant_identifier_names
import '../handlers/dish_handler.dart';
import '../handlers/restaurant_handler.dart';
import '../models/food_model.dart';
import '../models/dish_model.dart'; // Will create next

/// Query System - Trung tâm điều phối
/// Facade pattern to decouple UI from Handlers
class QuerySystem {
  // Singleton pattern
  static final QuerySystem _instance = QuerySystem._internal();
  factory QuerySystem() => _instance;
  QuerySystem._internal();

  // Registered Handlers
  final DishHandler _dishHandler = MockDishHandler();
  final RestaurantHandler _restaurantHandler = MockRestaurantHandler();

  /// Task: Query Dishes (Lấy danh sách món ăn đề xuất)
  Future<List<DishItem>> QueryDishes({List<String> filters = const []}) {
    return _dishHandler.getAllDishes(filters: filters);
  }

  /// Task: Query Search (Tìm kiếm món ăn hoặc nhà hàng)
  Future<SearchResult> QuerySearch(String query) {
    return _restaurantHandler.searchRestaurants(query);
  }

  /// Task: Query Restaurants By Dish (Tìm nhà hàng bán món cụ thể)
  Future<SearchResult> QueryRestaurantsByDish(String dishId) {
    return _restaurantHandler.getRestaurantsByDish(dishId);
  }

  /// Task: Query Menu (Lấy menu của nhà hàng)
  Future<List<MenuItem>> QueryMenu(String restaurantId) {
    return _restaurantHandler.getMenu(restaurantId);
  }
}
