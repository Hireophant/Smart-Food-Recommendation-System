import 'backend_api.dart';
import 'search_models.dart';

class SearchClient {
  const SearchClient(this._api);

  final BackendAPI _api;

  /// GET /search
  Future<SearchResponse> search(SearchParams params) async {
    params.validate();
    return _api.getObject(
      '/search',
      query: params.toQuery(),
      fromJson: SearchResponse.fromJson,
    );
  }

  /// GET /search/formatted
  Future<SearchResultFormatted> formatted(SearchParams params) async {
    params.validate();
    return _api.getObject(
      '/search/formatted',
      query: params.toQuery(),
      fromJson: SearchResultFormatted.fromJson,
    );
  }
}
