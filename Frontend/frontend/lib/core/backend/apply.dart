/// API Wrapper for Backend Data Router
/// This module provides a Dart wrapper for interacting with the Backend data endpoints.
/// Supports Supabase JWT authentication.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Parameters for restaurant search endpoint
class RestaurantSearchParams {
  final double focusLat; // -90 to 90
  final double focusLon; // -180 to 180
  final String? query;
  final double radius; // meters
  final double minRating; // 0 to 5
  final String? category;
  final String? province;
  final String? district;
  final int limit; // 1 to 100

  RestaurantSearchParams({
    required this.focusLat,
    required this.focusLon,
    this.query,
    this.radius = 5000,
    this.minRating = 0,
    this.category,
    this.province,
    this.district,
    this.limit = 10,
  });

  /// Validate parameters
  void validate() {
    if (focusLat < -90 || focusLat > 90) {
      throw ArgumentError('focus_lat must be between -90 and 90, got $focusLat');
    }
    if (focusLon < -180 || focusLon > 180) {
      throw ArgumentError('focus_lon must be between -180 and 180, got $focusLon');
    }
    if (minRating < 0 || minRating > 5) {
      throw ArgumentError('min_rating must be between 0 and 5, got $minRating');
    }
    if (limit < 1 || limit > 100) {
      throw ArgumentError('limit must be between 1 and 100, got $limit');
    }
    if (radius <= 0) {
      throw ArgumentError('radius must be positive, got $radius');
    }
  }

  /// Convert to query parameters map
  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'focus_lat': focusLat.toString(),
      'focus_lon': focusLon.toString(),
      'radius': radius.toString(),
      'min_rating': minRating.toString(),
      'limit': limit.toString(),
    };

    if (query != null && query!.trim().isNotEmpty) {
      params['query'] = query!.trim();
    }
    if (category != null && category!.trim().isNotEmpty) {
      params['category'] = category!.trim();
    }
    if (province != null && province!.trim().isNotEmpty) {
      params['province'] = province!.trim();
    }
    if (district != null && district!.trim().isNotEmpty) {
      params['district'] = district!.trim();
    }

    return params;
  }
}

/// Response model for collections
class CollectionsResponse<T> {
  final List<T> data;

  CollectionsResponse({required this.data});

  factory CollectionsResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return CollectionsResponse(
      data: (json['data'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Restaurant data model
class Restaurant {
  final String? id;
  final String? name;
  final double? rating;
  final String? address;
  final String? category;
  final String? province;
  final String? district;
  final double? latitude;
  final double? longitude;
  final double? distance;

  Restaurant({
    this.id,
    this.name,
    this.rating,
    this.address,
    this.category,
    this.province,
    this.district,
    this.latitude,
    this.longitude,
    this.distance,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      rating: json['rating']?.toDouble(),
      address: json['address'],
      category: json['category'],
      province: json['province'],
      district: json['district'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      distance: json['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'address': address,
      'category': category,
      'province': province,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
    };
  }

  @override
  String toString() {
    return 'Restaurant(name: $name, rating: $rating, distance: ${distance?.toStringAsFixed(0)}m)';
  }
}

/// Custom exception for API errors
class DataAPIException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;
  final dynamic originalError;

  DataAPIException({
    required this.message,
    this.statusCode,
    this.body,
    this.originalError,
  });

  @override
  String toString() => 'DataAPIException(statusCode: $statusCode, message: $message)';
}

/// Wrapper class for Backend Data API endpoints
/// Supports Supabase JWT authentication
class DataAPIWrapper {
  final String baseUrl;
  String? _accessToken;
  final http.Client _client;
  final Function()? onTokenExpired;

  DataAPIWrapper({
    required this.baseUrl,
    String? accessToken,
    http.Client? client,
    this.onTokenExpired,
  })
      : _accessToken = accessToken,
        _client = client ?? http.Client();

  /// Set access token (e.g., from Supabase)
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Get current access token
  String? getAccessToken() => _accessToken;

  /// Check if token is expired (basic JWT check)
  bool isTokenExpired() {
    if (_accessToken == null) return true;
    try {
      final parts = _accessToken!.split('.');
      if (parts.length != 3) return true;
      final decoded = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = decoded['exp'] as int?;
      if (exp == null) return false;
      return DateTime.now().millisecondsSinceEpoch > (exp * 1000);
    } catch (e) {
      return false;
    }
  }

  /// Get headers with authentication
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Parse error response
  String _parseErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail'] ?? json['message'] ?? body;
    } catch (e) {
      return body;
    }
  }

  /// Search for restaurants with the given filters
  ///
  /// Returns a list of restaurants matching the search criteria
  ///
  /// Throws [DataAPIException] on API errors
  /// Throws [ArgumentError] if parameters are invalid
  Future<List<Restaurant>> restaurantSearch(
    RestaurantSearchParams params,
  ) async {
    // Validate parameters
    params.validate();

    // Check if token is expired
    if (isTokenExpired()) {
      onTokenExpired?.call();
      throw DataAPIException(
        message: 'Access token expired. Please refresh.',
        statusCode: 401,
      );
    }

    // Build URL with query parameters
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/data/restaurant/search')
        .replace(queryParameters: params.toQueryParams());

    try {
      // Make the request
      final response = await _client.get(uri, headers: _getHeaders()).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw DataAPIException(
          message: 'Request timeout after 30 seconds',
          statusCode: 408,
        ),
      );

      // Check status code
      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
          final collectionResponse = CollectionsResponse.fromJson(
            jsonResponse,
            (json) => Restaurant.fromJson(json),
          );
          return collectionResponse.data;
        } catch (e) {
          throw DataAPIException(
            message: 'Failed to parse response: $e',
            statusCode: 200,
            body: response.body,
            originalError: e,
          );
        }
      } else if (response.statusCode == 401) {
        onTokenExpired?.call();
        throw DataAPIException(
          message: _parseErrorMessage(response.body),
          statusCode: 401,
          body: response.body,
        );
      } else if (response.statusCode == 422) {
        throw DataAPIException(
          message: _parseErrorMessage(response.body),
          statusCode: 422,
          body: response.body,
        );
      } else if (response.statusCode == 429) {
        throw DataAPIException(
          message: 'Rate limit exceeded: Too many requests (20/minute)',
          statusCode: 429,
          body: response.body,
        );
      } else if (response.statusCode == 500) {
        throw DataAPIException(
          message: 'Internal server error',
          statusCode: 500,
          body: response.body,
        );
      } else {
        throw DataAPIException(
          message: _parseErrorMessage(response.body),
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on DataAPIException {
      rethrow;
    } catch (e) {
      throw DataAPIException(
        message: 'Network error: ${e.runtimeType}',
        originalError: e,
      );
    }
  }

  /// Simplified method to search restaurants with direct parameters
  ///
  /// Returns a list of restaurant objects
  Future<List<Restaurant>> searchRestaurantsSimple({
    required double focusLat,
    required double focusLon,
    String? query,
    double radius = 5000,
    double minRating = 0,
    String? category,
    String? province,
    String? district,
    int limit = 10,
  }) async {
    final params = RestaurantSearchParams(
      focusLat: focusLat,
      focusLon: focusLon,
      query: query,
      radius: radius,
      minRating: minRating,
      category: category,
      province: province,
      district: district,
      limit: limit,
    );

    return restaurantSearch(params);
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Example usage
void main() async {
  // Initialize the API wrapper with Supabase token
  final api = DataAPIWrapper(
    baseUrl: 'http://localhost:8000',
    accessToken: 'your_supabase_jwt_token_here',
    onTokenExpired: () {
      print('Token expired - refresh needed');
      // Handle token refresh from Supabase
    },
  );

  try {
    // Check token status
    if (api.isTokenExpired()) {
      print('Token already expired');
      return;
    }

    // Example 1: Using RestaurantSearchParams
    final searchParams = RestaurantSearchParams(
      focusLat: 10.8231, // Ho Chi Minh City
      focusLon: 106.6297,
      query: 'phở',
      radius: 3000,
      minRating: 4.0,
      limit: 20,
    );

    final results = await api.restaurantSearch(searchParams);
    print('Found ${results.length} restaurants');
    for (var restaurant in results) {
      print('- ${restaurant.name} (${restaurant.rating}⭐)');
    }

    // Example 2: Using simplified method
    final restaurants = await api.searchRestaurantsSimple(
      focusLat: 10.8231,
      focusLon: 106.6297,
      query: 'bún',
      radius: 5000,
      minRating: 3.5,
    );
    print('\nFound ${restaurants.length} restaurants with simplified method');
    for (var restaurant in restaurants) {
      print(restaurant);
    }
  } on DataAPIException catch (e) {
    print('API Error [${e.statusCode}]: ${e.message}');
    if (e.statusCode == 401) {
      print('Authentication failed - refresh token or login again');
    } else if (e.statusCode == 429) {
      print('Rate limited - please wait before retrying');
    }
  } catch (e) {
    print('Unexpected error: $e');
  } finally {
    api.dispose();
  }
}
