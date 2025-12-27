class RestaurantLocation {
  const RestaurantLocation({
    required this.address,
    required this.province,
    required this.district,
    required this.ward,
    required this.lat,
    required this.lon,
    required this.distance,
    required this.distanceKm,
  });

  final String address;
  final String province;
  final String district;
  final String? ward;
  final double lat;
  final double lon;
  final double? distance;
  final double? distanceKm;

  factory RestaurantLocation.fromJson(Map<String, dynamic> json) {
    return RestaurantLocation(
      address: json['address']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      ward: json['ward']?.toString(),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}

class Restaurant {
  const Restaurant({
    required this.id,
    required this.score,
    required this.name,
    required this.category,
    required this.rating,
    required this.location,
    required this.tags,
    required this.link,
  });

  final String id;
  final double? score;
  final String name;
  final String category;
  final double rating;
  final RestaurantLocation location;
  final List<String> tags;
  final String? link;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble(),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      location: RestaurantLocation.fromJson(
        (json['location'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      tags:
          (json['tags'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      link: json['link']?.toString(),
    );
  }
}

class RestaurantSearchParams {
  RestaurantSearchParams({
    this.focusLat,
    this.focusLon,
    this.query,
    this.radius = 5000,
    this.minRating = 0,
    this.category,
    this.tags,
    this.province,
    this.district,
    this.limit = 10,
  });

  final double? focusLat;
  final double? focusLon;
  final String? query;
  final double? radius;
  final double? minRating;
  final String? category;
  final String? tags;
  final String? province;
  final String? district;
  final int limit;

  void validate() {
    final hasLat = focusLat != null;
    final hasLon = focusLon != null;
    if (hasLat != hasLon) {
      throw ArgumentError(
        'focusLat/focusLon requires both latitude and longitude.',
      );
    }
    if (hasLat && (focusLat! < -90 || focusLat! > 90)) {
      throw ArgumentError('focusLat must be between -90 and 90.');
    }
    if (hasLon && (focusLon! < -180 || focusLon! > 180)) {
      throw ArgumentError('focusLon must be between -180 and 180.');
    }

    if (radius != null && radius! <= 0) {
      throw ArgumentError('radius must be > 0.');
    }
    if (minRating != null && (minRating! < 0 || minRating! > 5)) {
      throw ArgumentError('minRating must be between 0 and 5.');
    }
    if (limit < 1 || limit > 100) {
      throw ArgumentError('limit must be between 1 and 100.');
    }
  }

  Map<String, Object?> toQuery() {
    return {
      'focus_lat': focusLat,
      'focus_lon': focusLon,
      'query': query,
      'radius': radius,
      'min_rating': minRating,
      'category': category,
      'tags': tags,
      'province': province,
      'district': district,
      'limit': limit,
    };
  }
}

class RestaurantsByIdsParams {
  RestaurantsByIdsParams({required this.ids, this.limit = 100});

  final List<String> ids;
  final int limit;

  void validate() {
    if (ids.isEmpty) {
      throw ArgumentError('ids must contain at least 1 item.');
    }
    if (ids.length > 200) {
      throw ArgumentError('ids must contain at most 200 items.');
    }
    if (limit < 1 || limit > 200) {
      throw ArgumentError('limit must be between 1 and 200.');
    }
    final cleaned = ids
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.length != ids.length) {
      throw ArgumentError('ids cannot contain empty items.');
    }
  }

  Map<String, Object?> toQuery() {
    return {
      'ids': ids.map((e) => e.trim()).toList(growable: false),
      'limit': limit,
    };
  }
}

class RestaurantsResultFormatted {
  const RestaurantsResultFormatted({required this.result});

  final String result;

  factory RestaurantsResultFormatted.fromJson(Map<String, dynamic> json) {
    return RestaurantsResultFormatted(result: json['result']?.toString() ?? '');
  }
}
