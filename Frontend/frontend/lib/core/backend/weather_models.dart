class WeatherCoord {
  const WeatherCoord({required this.lat, required this.lon});

  final double lat;
  final double lon;

  factory WeatherCoord.fromJson(Map<String, dynamic> json) {
    return WeatherCoord(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WeatherTemperature {
  const WeatherTemperature({
    required this.currentC,
    required this.feelsLikeC,
    required this.minC,
    required this.maxC,
  });

  final double currentC;
  final double feelsLikeC;
  final double minC;
  final double maxC;

  factory WeatherTemperature.fromJson(Map<String, dynamic> json) {
    return WeatherTemperature(
      currentC: (json['current_c'] as num?)?.toDouble() ?? 0.0,
      feelsLikeC: (json['feels_like_c'] as num?)?.toDouble() ?? 0.0,
      minC: (json['min_c'] as num?)?.toDouble() ?? 0.0,
      maxC: (json['max_c'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WeatherWind {
  const WeatherWind({
    required this.speedMs,
    required this.directionDeg,
    required this.gustMs,
  });

  final double speedMs;
  final int? directionDeg;
  final double? gustMs;

  factory WeatherWind.fromJson(Map<String, dynamic> json) {
    return WeatherWind(
      speedMs: (json['speed_ms'] as num?)?.toDouble() ?? 0.0,
      directionDeg: (json['direction_deg'] as num?)?.toInt(),
      gustMs: (json['gust_ms'] as num?)?.toDouble(),
    );
  }
}

class WeatherResponse {
  const WeatherResponse({
    required this.coord,
    required this.temperature,
    required this.wind,
    required this.weatherCondition,
    required this.name,
  });

  final WeatherCoord coord;
  final WeatherTemperature temperature;
  final WeatherWind wind;
  final String weatherCondition;
  final String name;

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    return WeatherResponse(
      coord: WeatherCoord.fromJson(
        (json['coord'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      temperature: WeatherTemperature.fromJson(
        (json['temperature'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      wind: WeatherWind.fromJson(
        (json['wind'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      weatherCondition: json['weather_condition']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class WeatherResultFormatted {
  const WeatherResultFormatted({required this.result});

  final String result;

  factory WeatherResultFormatted.fromJson(Map<String, dynamic> json) {
    return WeatherResultFormatted(result: json['result']?.toString() ?? '');
  }
}

class WeatherParams {
  WeatherParams({required this.lat, required this.lon});

  final double lat;
  final double lon;

  void validate() {
    if (lat < -90 || lat > 90) {
      throw ArgumentError('lat must be between -90 and 90.');
    }
    if (lon < -180 || lon > 180) {
      throw ArgumentError('lon must be between -180 and 180.');
    }
  }

  Map<String, Object?> toQuery() {
    return {
      'lat': lat,
      'lon': lon,
    };
  }
}
