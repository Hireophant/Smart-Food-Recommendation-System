class SearchLocation {
  const SearchLocation({
    required this.name,
    required this.address,
    required this.type,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.lat,
    required this.lon,
    required this.placeId,
    required this.placeIdSearch,
    required this.url,
  });

  final String name;
  final String? address;
  final String? type;
  final String? description;
  final double? rating;
  final int? reviews;
  final String? price;
  final double? lat;
  final double? lon;
  final String? placeId;
  final String? placeIdSearch;
  final String? url;

  factory SearchLocation.fromJson(Map<String, dynamic> json) {
    return SearchLocation(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      type: json['type']?.toString(),
      description: json['description']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviews: (json['reviews'] as num?)?.toInt(),
      price: json['price']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      placeId: json['place_id']?.toString(),
      placeIdSearch: json['place_id_search']?.toString(),
      url: json['url']?.toString(),
    );
  }
}

class SearchOrganicResult {
  const SearchOrganicResult({
    required this.title,
    required this.snippet,
    required this.link,
    required this.source,
  });

  final String title;
  final String? snippet;
  final String? link;
  final String? source;

  factory SearchOrganicResult.fromJson(Map<String, dynamic> json) {
    return SearchOrganicResult(
      title: json['title']?.toString() ?? '',
      snippet: json['snippet']?.toString(),
      link: json['link']?.toString(),
      source: json['source']?.toString(),
    );
  }
}

class SearchResponse {
  const SearchResponse({
    required this.query,
    required this.location,
    required this.locations,
    required this.organicResults,
  });

  final String query;
  final String location;
  final List<SearchLocation> locations;
  final List<SearchOrganicResult> organicResults;

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query']?.toString() ?? '',
      location: json['location']?.toString() ?? 'Vietnam',
      locations:
          (json['locations'] as List?)
              ?.whereType<Object>()
              .whereType<Map>()
              .map((e) => SearchLocation.fromJson(e.cast<String, dynamic>()))
              .toList(growable: false) ??
          const [],
      organicResults:
          (json['organic_results'] as List?)
              ?.whereType<Object>()
              .whereType<Map>()
              .map(
                (e) => SearchOrganicResult.fromJson(e.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const [],
    );
  }
}

class SearchResultFormatted {
  const SearchResultFormatted({required this.result});

  final String result;

  factory SearchResultFormatted.fromJson(Map<String, dynamic> json) {
    return SearchResultFormatted(result: json['result']?.toString() ?? '');
  }
}

class SearchParams {
  SearchParams({
    required this.query,
    this.location,
    this.maxLocations,
    this.maxResults,
  });

  final String query;
  final String? location;

  /// Backend caps these to 5, but we validate non-negative.
  final int? maxLocations;
  final int? maxResults;

  void validate() {
    if (query.trim().isEmpty) {
      throw ArgumentError('query cannot be empty');
    }
    if (maxLocations != null && maxLocations! < 0) {
      throw ArgumentError('maxLocations must be >= 0');
    }
    if (maxResults != null && maxResults! < 0) {
      throw ArgumentError('maxResults must be >= 0');
    }
  }

  Map<String, Object?> toQuery() {
    return {
      'query': query.trim(),
      'location': (location ?? 'Vietnam').trim(),
      'max_locations': maxLocations,
      'max_results': maxResults,
    };
  }
}
