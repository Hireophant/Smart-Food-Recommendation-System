import 'package:frontend/core/backend/foods_client.dart';
import 'package:frontend/core/backend/foods_models.dart';
import '../models/dish_item.dart';

class DishHandler {
  final FoodsClient _foodsClient;

  DishHandler(this._foodsClient);

  /// Search dishes (food)
  Future<List<DishItem>> searchDishes({
    required String query,
    int limit = 20,
  }) async {
    final foods = await _foodsClient.search(
      FoodSearchParams(
        query: query,
        limit: limit,
      ),
    );

    return foods.map(_mapFoodToDish).toList();
  }

  /// Get all dishes (no query)
  Future<List<DishItem>> getAllDishes({int limit = 20}) async {
    final foods = await _foodsClient.search(
      FoodSearchParams(
        query: '',
        limit: limit,
      ),
    );

    return foods.map(_mapFoodToDish).toList();
  }

  /// Get dish detail by id
  Future<DishItem?> getDishById(String id) async {
    final foods = await _foodsClient.byIds(
      FoodsByIdsParams(ids: [id]),
    );

    if (foods.isEmpty) return null;
    return _mapFoodToDish(foods.first);
  }

  // ----------------------------
  // Mapping
  // ----------------------------
  DishItem _mapFoodToDish(FoodModel food) {
    return DishItem(
      id: food.id,
      name: food.dishName,
      category: food.category,
      tags: food.tags ?? [],
    );
  }
}
