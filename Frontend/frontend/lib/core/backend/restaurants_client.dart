import 'backend_api.dart';
import 'restaurants_models.dart';

class RestaurantsClient {
  const RestaurantsClient(this._api);

  final BackendAPI _api;

  /// GET /data/restaurant/search
  Future<List<Restaurant>> search(RestaurantSearchParams params) async {
    params.validate();
    return _api.getCollections(
      '/data/restaurant/search',
      query: params.toQuery(),
      fromJson: Restaurant.fromJson,
    );
  }

  /// GET /data/restaurant/byids
  Future<List<Restaurant>> byIds(RestaurantsByIdsParams params) async {
    params.validate();
    return _api.getCollections(
      '/data/restaurant/byids',
      query: params.toQuery(),
      fromJson: Restaurant.fromJson,
    );
  }
}
