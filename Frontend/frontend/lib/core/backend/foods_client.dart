import 'backend_api.dart';
import 'foods_models.dart';

class FoodsClient {
  const FoodsClient(this._api);

  final BackendAPI _api;

  /// GET /data/food/search
  Future<List<Food>> search(FoodSearchParams params) async {
    params.validate();
    return _api.getCollections(
      '/data/food/search',
      query: params.toQuery(),
      fromJson: Food.fromJson,
    );
  }

  /// GET /data/food/byids
  Future<List<Food>> byIds(FoodsByIdsParams params) async {
    params.validate();
    return _api.getCollections(
      '/data/food/byids',
      query: params.toQuery(),
      fromJson: Food.fromJson,
    );
  }
}
