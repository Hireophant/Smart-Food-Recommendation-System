import 'package:frontend/core/backend/restaurants_client.dart';
import 'package:frontend/core/backend/restaurants_models.dart';

import '../models/food_model.dart';

class RestaurantHandler {
  final RestaurantsClient _restaurantsClient;

  RestaurantHandler(this._restaurantsClient);

  /// Search restaurants
  Future<List<RestaurantItem>> searchRestaurants({
    required String query,
    int limit = 10,
  }) async {
    final restaurants = await _restaurantsClient.search(
      RestaurantSearchParams(query: query, limit: limit),
    );

    return restaurants.map(_mapRestaurantToItem).toList();
  }

  /// Get restaurant detail by id
  Future<RestaurantItem?> getRestaurantById(String id) async {
    final restaurants = await _restaurantsClient.byIds(
      RestaurantsByIdsParams(ids: [id]),
    );

    if (restaurants.isEmpty) return null;
    return _mapRestaurantToItem(restaurants.first);
  }

  // ============================
  // Mapping
  // ============================
  RestaurantItem _mapRestaurantToItem(Restaurant restaurant) {
    final location = restaurant.location;

    return RestaurantItem(
      id: restaurant.id,
      name: restaurant.name,
      category: restaurant.category,
      rating: restaurant.rating,
      address: location.address,
      //province: location.province,
      //district: location.district,
      //distanceKm: location.distanceKm,
      tags: restaurant.tags,
      imageUrl: 'assets/images/com_tam.png',
      //link: restaurant.link,
    );
  }
}
