import 'backend_api.dart';
import 'weather_models.dart';

class WeatherClient {
  const WeatherClient(this._api);

  final BackendAPI _api;

  /// GET /weather
  Future<WeatherResponse> weather(WeatherParams params) async {
    params.validate();
    return _api.getObject(
      '/weather',
      query: params.toQuery(),
      fromJson: WeatherResponse.fromJson,
    );
  }

  /// GET /weather/formatted
  Future<WeatherResultFormatted> formatted(WeatherParams params) async {
    params.validate();
    return _api.getObject(
      '/weather/formatted',
      query: params.toQuery(),
      fromJson: WeatherResultFormatted.fromJson,
    );
  }
}
