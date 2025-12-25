import 'backend_api.dart';
import 'maps_models.dart';

class MapsClient {
  const MapsClient(this._api);

  final BackendAPI _api;

  /// GET /maps/autocomplete
  Future<List<MapGeocoding>> autocomplete(MapsAutocompleteParams params) async {
    params.validate();
    return _api.getCollections(
      '/maps/autocomplete',
      query: params.toQuery(),
      fromJson: MapGeocoding.fromJson,
    );
  }

  /// GET /maps/place
  Future<MapPlace> place(MapsPlaceParams params) async {
    params.validate();
    return _api.getObject(
      '/maps/place',
      query: params.toQuery(),
      fromJson: MapPlace.fromJson,
    );
  }

  /// GET /maps/reverse
  Future<List<MapGeocoding>> reverseGeocoding(MapsReverseParams params) async {
    params.validate();
    return _api.getCollections(
      '/maps/reverse',
      query: params.toQuery(),
      fromJson: MapGeocoding.fromJson,
    );
  }

  /// GET /maps/route
  Future<MapRoute> route(MapsRouteParams params) async {
    params.validate();
    return _api.getObject(
      '/maps/route',
      query: params.toQuery(),
      fromJson: MapRoute.fromJson,
    );
  }
}
