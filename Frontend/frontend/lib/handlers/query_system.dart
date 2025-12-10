import '../handlers/food_search_handler.dart';
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
  final FoodSearchHandler _foodHandler = MockFoodSearchHandler();

  /// Lấy danh sách món ăn đề xuất (Cho màn hình Home)
  Future<List<DishItem>> getAllDishes() {
    return _foodHandler.getAllDishes();
  }

  /// Tìm kiếm món ăn hoặc nhà hàng
  Future<SearchResult> search(String query) {
    return _foodHandler.searchFoods(query);
  }

  /// Tìm nhà hàng bán món cụ thể (Khi user chọn 1 món từ Home)
  Future<SearchResult> findRestaurantsByDish(String dishId) {
    return _foodHandler.getRestaurantsByDish(dishId);
  }

  /// Lấy menu của nhà hàng
  Future<List<MenuItem>> getMenu(String restaurantId) {
    return _foodHandler.getMenu(restaurantId);
  }
}
