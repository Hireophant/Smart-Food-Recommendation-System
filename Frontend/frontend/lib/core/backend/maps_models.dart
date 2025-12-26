enum MapBoundariesType { unknown, city, district, ward }

MapBoundariesType _mapBoundariesTypeFromJson(dynamic value) {
  final s = value?.toString();
  switch (s) {
    case 'city':
      return MapBoundariesType.city;
    case 'district':
      return MapBoundariesType.district;
    case 'ward':
      return MapBoundariesType.ward;
    default:
      return MapBoundariesType.unknown;
  }
}

class MapBoundaries {
  const MapBoundaries({
    required this.type,
    required this.boundariesId,
    required this.fullName,
  });

  final MapBoundariesType type;
  final int boundariesId;
  final String fullName;

  factory MapBoundaries.fromJson(Map<String, dynamic> json) {
    return MapBoundaries(
      type: _mapBoundariesTypeFromJson(json['type']),
      boundariesId: (json['boundaries_id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name']?.toString() ?? '',
    );
  }
}

class MapEntryPoint {
  const MapEntryPoint({required this.id, required this.name});

  final String id;
  final String name;

  factory MapEntryPoint.fromJson(Map<String, dynamic> json) {
    return MapEntryPoint(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class MapGeocoding {
  const MapGeocoding({
    required this.id,
    required this.distanceKm,
    required this.name,
    required this.address,
    required this.display,
    required this.boundaries,
    required this.entryPoints,
  });

  final String id;
  final double distanceKm;
  final String name;
  final String address;
  final String display;
  final List<MapBoundaries> boundaries;
  final List<MapEntryPoint> entryPoints;

  factory MapGeocoding.fromJson(Map<String, dynamic> json) {
    return MapGeocoding(
      id: json['id']?.toString() ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      display: json['display']?.toString() ?? '',
      boundaries:
          (json['boundaries'] as List?)
              ?.whereType<Object>()
              .whereType<Map>()
              .map((e) => MapBoundaries.fromJson((e).cast<String, dynamic>()))
              .toList(growable: false) ??
          const [],
      entryPoints:
          (json['entry_points'] as List?)
              ?.whereType<Object>()
              .whereType<Map>()
              .map((e) => MapEntryPoint.fromJson((e).cast<String, dynamic>()))
              .toList(growable: false) ??
          const [],
    );
  }
}

class MapPlaceDetails {
  const MapPlaceDetails({
    required this.houseNumber,
    required this.street,
    required this.address,
    required this.city,
    required this.district,
    required this.ward,
  });

  final String houseNumber;
  final String street;
  final String address;
  final MapBoundaries city;
  final MapBoundaries district;
  final MapBoundaries ward;

  factory MapPlaceDetails.fromJson(Map<String, dynamic> json) {
    return MapPlaceDetails(
      houseNumber: json['house_number']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: MapBoundaries.fromJson(
        (json['city'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      district: MapBoundaries.fromJson(
        (json['district'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      ward: MapBoundaries.fromJson(
        (json['ward'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
    );
  }
}

class MapPlace {
  const MapPlace({
    required this.address,
    required this.name,
    required this.lat,
    required this.lon,
    required this.details,
  });

  final String address;
  final String name;
  final double lat;
  final double lon;
  final MapPlaceDetails details;

  factory MapPlace.fromJson(Map<String, dynamic> json) {
    return MapPlace(
      address: json['address']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      details: MapPlaceDetails.fromJson(
        (json['details'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
    );
  }
}

enum VietmapRouteVehicleType { car, motorcycle, truck }

String? _vehicleToQuery(VietmapRouteVehicleType? vehicle) {
  if (vehicle == null) return null;
  switch (vehicle) {
    case VietmapRouteVehicleType.car:
      return 'car';
    case VietmapRouteVehicleType.motorcycle:
      return 'motorcycle';
    case VietmapRouteVehicleType.truck:
      return 'truck';
  }
}

enum VietmapRouteAvoidType { toll, ferry }

String _avoidToQuery(VietmapRouteAvoidType avoid) {
  switch (avoid) {
    case VietmapRouteAvoidType.toll:
      return 'toll';
    case VietmapRouteAvoidType.ferry:
      return 'ferry';
  }
}

enum VietmapRouteStatusCode {
  ok,
  invalidRequest,
  overDailyLimit,
  maxPointsExceed,
  errorUnknown,
  zeroResults,
  unknown,
}

VietmapRouteStatusCode _statusFromJson(dynamic value) {
  final s = value?.toString() ?? '';
  switch (s) {
    case 'OK':
      return VietmapRouteStatusCode.ok;
    case 'INVALID_REQUEST':
      return VietmapRouteStatusCode.invalidRequest;
    case 'OVER_DAILY_LIMIT':
      return VietmapRouteStatusCode.overDailyLimit;
    case 'MAX_POINTS_EXCEED':
      return VietmapRouteStatusCode.maxPointsExceed;
    case 'ERROR_UNKNOWN':
      return VietmapRouteStatusCode.errorUnknown;
    case 'ZERO_RESULTS':
      return VietmapRouteStatusCode.zeroResults;
    default:
      return VietmapRouteStatusCode.unknown;
  }
}

class MapRouteInstruction {
  const MapRouteInstruction({
    required this.distance,
    required this.heading,
    required this.sign,
    required this.interval,
    required this.text,
    required this.time,
    required this.streetName,
  });

  final double distance;
  final int heading;
  final int sign;
  final List<int> interval;
  final String text;
  final int time;
  final String streetName;

  factory MapRouteInstruction.fromJson(Map<String, dynamic> json) {
    return MapRouteInstruction(
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toInt() ?? 0,
      sign: (json['sign'] as num?)?.toInt() ?? 0,
      interval:
          (json['interval'] as List?)
              ?.whereType<num>()
              .map((e) => e.toInt())
              .toList(growable: false) ??
          const [0, 0],
      text: json['text']?.toString() ?? '',
      time: (json['time'] as num?)?.toInt() ?? 0,
      streetName: json['street_name']?.toString() ?? '',
    );
  }
}

class MapRoutePath {
  const MapRoutePath({
    required this.distance,
    required this.weight,
    required this.time,
    required this.transfers,
    required this.bbox,
    required this.points,
    required this.instructions,
  });

  final double distance;
  final double weight;
  final int time;
  final int transfers;
  final List<double> bbox;

  /// Route geometry points (as returned by Vietmap), each point is `[lat, lon]`.
  final List<List<double>> points;

  final List<MapRouteInstruction> instructions;

  factory MapRoutePath.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    final points = <List<double>>[];
    if (rawPoints is List) {
      for (final p in rawPoints) {
        if (p is List && p.length == 2) {
          final a = p[0];
          final b = p[1];
          if (a is num && b is num) {
            points.add([a.toDouble(), b.toDouble()]);
          }
        }
      }
    }

    return MapRoutePath(
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      time: (json['time'] as num?)?.toInt() ?? 0,
      transfers: (json['transfers'] as num?)?.toInt() ?? 0,
      bbox:
          (json['bbox'] as List?)
              ?.whereType<num>()
              .map((e) => e.toDouble())
              .toList(growable: false) ??
          const [],
      points: points,
      instructions:
          (json['instructions'] as List?)
              ?.whereType<Object>()
              .whereType<Map>()
              .map(
                (e) =>
                    MapRouteInstruction.fromJson((e).cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const [],
    );
  }
}

class MapRoute {
  const MapRoute({
    required this.license,
    required this.code,
    required this.messages,
    required this.paths,
  });

  final String license;
  final VietmapRouteStatusCode code;
  final String? messages;
  final List<MapRoutePath> paths;

  factory MapRoute.fromJson(Map<String, dynamic> json) {
    return MapRoute(
      license: json['license']?.toString() ?? '',
      code: _statusFromJson(json['code']),
      messages: json['messages']?.toString(),
      paths:
          (json['paths'] as List?)
              ?.whereType<Object>()
              .whereType<Map>()
              .map((e) => MapRoutePath.fromJson((e).cast<String, dynamic>()))
              .toList(growable: false) ??
          const [],
    );
  }
}

class MapsAutocompleteParams {
  MapsAutocompleteParams({
    required this.query,
    this.focusLat,
    this.focusLon,
    this.searchCenterLat,
    this.searchCenterLon,
    this.searchRadius,
    this.cityId,
    this.districtId,
    this.wardId,
  });

  final String query;

  final double? focusLat;
  final double? focusLon;

  final double? searchCenterLat;
  final double? searchCenterLon;

  final double? searchRadius;

  final int? cityId;
  final int? districtId;
  final int? wardId;

  void validate() {
    if (query.trim().isEmpty) {
      throw ArgumentError('query cannot be empty');
    }

    void validateLatLon(double lat, double lon) {
      if (lat < -90 || lat > 90) {
        throw ArgumentError('Latitude must be between -90 and 90.');
      }
      if (lon < -180 || lon > 180) {
        throw ArgumentError('Longitude must be between -180 and 180.');
      }
    }

    void validatePair(double? lat, double? lon, String label) {
      final hasLat = lat != null;
      final hasLon = lon != null;
      if (hasLat != hasLon) {
        throw ArgumentError('$label requires both latitude and longitude.');
      }
      if (hasLat && hasLon) {
        validateLatLon(lat, lon);
      }
    }

    validatePair(focusLat, focusLon, 'focusLat/focusLon');
    validatePair(
      searchCenterLat,
      searchCenterLon,
      'searchCenterLat/searchCenterLon',
    );

    if (searchRadius != null && searchRadius! <= 0) {
      throw ArgumentError('searchRadius must be > 0.');
    }
  }

  Map<String, Object?> toQuery() {
    return {
      'query': query.trim(),
      'focus_lat': focusLat,
      'focus_lon': focusLon,
      'search_center_lat': searchCenterLat,
      'search_center_lon': searchCenterLon,
      'search_radius': searchRadius,
      'city_id': cityId,
      'district_id': districtId,
      'ward_id': wardId,
    };
  }
}

class MapsReverseParams {
  MapsReverseParams({required this.lat, required this.lon});

  final double lat;
  final double lon;

  void validate() {
    if (lat < -90 || lat > 90) {
      throw ArgumentError('Latitude must be between -90 and 90.');
    }
    if (lon < -180 || lon > 180) {
      throw ArgumentError('Longitude must be between -180 and 180.');
    }
  }

  Map<String, Object?> toQuery() => {'lat': lat, 'lon': lon};
}

class MapsRouteParams {
  MapsRouteParams({required this.points, this.vehicle, this.avoid});

  /// Points in format "lat,lon".
  final List<String> points;

  final VietmapRouteVehicleType? vehicle;
  final List<VietmapRouteAvoidType>? avoid;

  void validate() {
    if (points.length < 2 || points.length > 15) {
      throw ArgumentError('points must contain between 2 and 15 items.');
    }

    for (final p in points) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) {
        throw ArgumentError('points cannot contain empty items.');
      }
      final parts = trimmed.split(',');
      if (parts.length != 2) {
        throw ArgumentError("point must be in format 'lat,lon'.");
      }
      final lat = double.tryParse(parts[0].trim());
      final lon = double.tryParse(parts[1].trim());
      if (lat == null || lon == null) {
        throw ArgumentError("point must be numeric 'lat,lon'.");
      }
      if (lat < -90 || lat > 90) {
        throw ArgumentError('Latitude must be between -90 and 90.');
      }
      if (lon < -180 || lon > 180) {
        throw ArgumentError('Longitude must be between -180 and 180.');
      }
    }
  }

  Map<String, Object?> toQuery() {
    return {
      'point': points,
      'vehicle': _vehicleToQuery(vehicle),
      'avoid': avoid?.map(_avoidToQuery).toList(growable: false),
    };
  }
}

class MapsPlaceParams {
  MapsPlaceParams({required this.id});

  final String id;

  void validate() {
    if (id.trim().isEmpty) {
      throw ArgumentError('id cannot be empty');
    }
  }

  Map<String, Object?> toQuery() => {'ids': id.trim()};
}
