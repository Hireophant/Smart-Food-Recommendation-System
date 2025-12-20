// Maps API wrapper for backend maps endpoints.
// Supports Supabase JWT authentication.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Custom exception for Maps API errors
class MapAPIException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;
  final dynamic originalError;

  MapAPIException({
    required this.message,
    this.statusCode,
    this.body,
    this.originalError,
  });

  @override
  String toString() => 'MapAPIException(statusCode: $statusCode, message: $message)';
}

class MapGeocodingResult {
	final String? id;
	final String? name;
	final String? address;
	final double? latitude;
	final double? longitude;
	final Map<String, dynamic> raw;

	MapGeocodingResult({
		this.id,
		this.name,
		this.address,
		this.latitude,
		this.longitude,
		required this.raw,
	});

	factory MapGeocodingResult.fromJson(Map<String, dynamic> json) {
		return MapGeocodingResult(
			id: json['id']?.toString() ?? json['_id']?.toString(),
			name: json['name']?.toString() ?? json['display_name']?.toString(),
			address: json['address']?.toString() ?? json['formatted_address']?.toString(),
			latitude: _toDouble(json['latitude'] ?? json['lat']),
			longitude: _toDouble(json['longitude'] ?? json['lon']),
			raw: json,
		);
	}
}

class MapPlaceResult {
	final String? id;
	final String? name;
	final String? address;
	final double? latitude;
	final double? longitude;
	final Map<String, dynamic> raw;

	MapPlaceResult({
		this.id,
		this.name,
		this.address,
		this.latitude,
		this.longitude,
		required this.raw,
	});

	factory MapPlaceResult.fromJson(Map<String, dynamic> json) {
		return MapPlaceResult(
			id: json['id']?.toString() ?? json['_id']?.toString(),
			name: json['name']?.toString(),
			address: json['address']?.toString(),
			latitude: _toDouble(json['latitude'] ?? json['lat']),
			longitude: _toDouble(json['longitude'] ?? json['lon']),
			raw: json,
		);
	}
}

class MapRouteResult {
	final double? distance; // meters
	final double? duration; // seconds
	final Map<String, dynamic> raw;

	MapRouteResult({
		this.distance,
		this.duration,
		required this.raw,
	});

	factory MapRouteResult.fromJson(Map<String, dynamic> json) {
		return MapRouteResult(
			distance: _toDouble(json['distance']),
			duration: _toDouble(json['duration']),
			raw: json,
		);
	}
}

class MapApiWrapper {
  final String baseUrl;
  String? _accessToken;
  final http.Client _client;
  final Function()? onTokenExpired;

  MapApiWrapper({
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

	Map<String, String> _headers() {
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

	void _validateLatLon(double lat, double lon) {
		if (lat < -90 || lat > 90) {
			throw ArgumentError('Latitude must be between -90 and 90.');
		}
		if (lon < -180 || lon > 180) {
			throw ArgumentError('Longitude must be between -180 and 180.');
		}
	}

	void _validatePair(double? lat, double? lon, String label) {
		final hasLat = lat != null;
		final hasLon = lon != null;
		if (hasLat != hasLon) {
			throw ArgumentError('$label requires both latitude and longitude.');
		}
		if (hasLat && hasLon) {
			_validateLatLon(lat!, lon!);
		}
	}

	Uri _buildUri(String path, Map<String, dynamic?> params) {
		final clean = params
				.map((k, v) => MapEntry(k, v == null ? null : v.toString()))
				.map((k, v) => v == null ? null : MapEntry(k, v))
				.cast<String, String?>()
			..removeWhere((key, value) => value == null || value.isEmpty);
		return Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path')
				.replace(queryParameters: clean);
	}

	Future<List<MapGeocodingResult>> search({
		required String query,
		double? focusLat,
		double? focusLon,
		double? searchCenterLat,
		double? searchCenterLon,
		double? searchRadius,
		int? cityId,
		int? districtId,
		int? wardId,
	}) async {
		if (query.trim().isEmpty) {
			throw ArgumentError('query cannot be empty');
		}

		// Check if token is expired
		if (isTokenExpired()) {
			onTokenExpired?.call();
			throw MapAPIException(
				message: 'Access token expired. Please refresh.',
				statusCode: 401,
			);
		}

		_validatePair(focusLat, focusLon, 'focusLat/focusLon');
		_validatePair(searchCenterLat, searchCenterLon, 'searchCenterLat/searchCenterLon');

		final uri = _buildUri('/maps/search', {
			'query': query.trim(),
			'focus_lat': focusLat,
			'focus_lon': focusLon,
			'search_center_lat': searchCenterLat,
			'search_center_lon': searchCenterLon,
			'search_radius': searchRadius,
			'city_id': cityId,
			'district_id': districtId,
			'ward_id': wardId,
		});

		try {
			final res = await _client.get(uri, headers: _headers()).timeout(
				const Duration(seconds: 30),
				onTimeout: () => throw MapAPIException(
					message: 'Request timeout after 30 seconds',
					statusCode: 408,
				),
			);
			return _parseCollection(res, MapGeocodingResult.fromJson);
		} on MapAPIException {
			rethrow;
		} catch (e) {
			throw MapAPIException(
				message: 'Network error: ${e.runtimeType}',
				originalError: e,
			);
		}
	}

	Future<List<MapGeocodingResult>> autocomplete({
		required String query,
		double? focusLat,
		double? focusLon,
		double? searchCenterLat,
		double? searchCenterLon,
		double? searchRadius,
		int? cityId,
		int? districtId,
		int? wardId,
	}) async {
		if (query.trim().isEmpty) {
			throw ArgumentError('query cannot be empty');
		}

		// Check if token is expired
		if (isTokenExpired()) {
			onTokenExpired?.call();
			throw MapAPIException(
				message: 'Access token expired. Please refresh.',
				statusCode: 401,
			);
		}

		_validatePair(focusLat, focusLon, 'focusLat/focusLon');
		_validatePair(searchCenterLat, searchCenterLon, 'searchCenterLat/searchCenterLon');

		final uri = _buildUri('/maps/autocomplete', {
			'query': query.trim(),
			'focus_lat': focusLat,
			'focus_lon': focusLon,
			'search_center_lat': searchCenterLat,
			'search_center_lon': searchCenterLon,
			'search_radius': searchRadius,
			'city_id': cityId,
			'district_id': districtId,
			'ward_id': wardId,
		});

		try {
			final res = await _client.get(uri, headers: _headers()).timeout(
				const Duration(seconds: 30),
				onTimeout: () => throw MapAPIException(
					message: 'Request timeout after 30 seconds',
					statusCode: 408,
				),
			);
			return _parseCollection(res, MapGeocodingResult.fromJson);
		} on MapAPIException {
			rethrow;
		} catch (e) {
			throw MapAPIException(
				message: 'Network error: ${e.runtimeType}',
				originalError: e,
			);
		}
	}

	Future<MapPlaceResult> place(String id) async {
		if (id.trim().isEmpty) {
			throw ArgumentError('id cannot be empty');
		}

		// Check if token is expired
		if (isTokenExpired()) {
			onTokenExpired?.call();
			throw MapAPIException(
				message: 'Access token expired. Please refresh.',
				statusCode: 401,
			);
		}

		final uri = _buildUri('/maps/place', {
			'ids': id.trim(),
		});

		try {
			final res = await _client.get(uri, headers: _headers()).timeout(
				const Duration(seconds: 30),
				onTimeout: () => throw MapAPIException(
					message: 'Request timeout after 30 seconds',
					statusCode: 408,
				),
			);
			return _parseObject(res, MapPlaceResult.fromJson);
		} on MapAPIException {
			rethrow;
		} catch (e) {
			throw MapAPIException(
				message: 'Network error: ${e.runtimeType}',
				originalError: e,
			);
		}
	}

	Future<List<MapGeocodingResult>> reverse({
		required double lat,
		required double lon,
	}) async {
		_validateLatLon(lat, lon);

		// Check if token is expired
		if (isTokenExpired()) {
			onTokenExpired?.call();
			throw MapAPIException(
				message: 'Access token expired. Please refresh.',
				statusCode: 401,
			);
		}

		final uri = _buildUri('/maps/reverse', {
			'lat': lat,
			'lon': lon,
		});

		try {
			final res = await _client.get(uri, headers: _headers()).timeout(
				const Duration(seconds: 30),
				onTimeout: () => throw MapAPIException(
					message: 'Request timeout after 30 seconds',
					statusCode: 408,
				),
			);
			return _parseCollection(res, MapGeocodingResult.fromJson);
		} on MapAPIException {
			rethrow;
		} catch (e) {
			throw MapAPIException(
				message: 'Network error: ${e.runtimeType}',
				originalError: e,
			);
		}
	}

	Future<MapRouteResult> route({
		required List<String> points,
		String? vehicle,
		List<String>? avoid,
	}) async {
		if (points.length < 2 || points.length > 15) {
			throw ArgumentError('points must contain between 2 and 15 items.');
		}

		// Check if token is expired
		if (isTokenExpired()) {
			onTokenExpired?.call();
			throw MapAPIException(
				message: 'Access token expired. Please refresh.',
				statusCode: 401,
			);
		}

		final uri = _buildUri('/maps/route', {
			'vehicle': vehicle,
		});

		final queryParams = uri.queryParametersAll;
		queryParams['point'] = points;
		if (avoid != null && avoid.isNotEmpty) {
			queryParams['avoid'] = avoid;
		}

		final finalUri = uri.replace(queryParameters: queryParams);

		try {
			final res = await _client.get(finalUri, headers: _headers()).timeout(
				const Duration(seconds: 30),
				onTimeout: () => throw MapAPIException(
					message: 'Request timeout after 30 seconds',
					statusCode: 408,
				),
			);
			return _parseObject(res, MapRouteResult.fromJson);
		} on MapAPIException {
			rethrow;
		} catch (e) {
			throw MapAPIException(
				message: 'Network error: ${e.runtimeType}',
				originalError: e,
			);
		}
	}

	List<T> _parseCollection<T>(http.Response res, T Function(Map<String, dynamic>) fromJson) {
		_throwIfError(res);
		try {
			final jsonBody = json.decode(res.body) as Map<String, dynamic>;
			final data = jsonBody['data'];
			if (data is List) {
				return data.map((e) => fromJson((e as Map).cast<String, dynamic>())).toList();
			}
			throw MapAPIException(
				message: 'Unexpected response shape: missing data list',
				statusCode: 200,
				body: res.body,
			);
		} catch (e) {
			throw MapAPIException(
				message: 'Failed to parse response: $e',
				statusCode: 200,
				body: res.body,
				originalError: e,
			);
		}
	}

	T _parseObject<T>(http.Response res, T Function(Map<String, dynamic>) fromJson) {
		_throwIfError(res);
		try {
			final jsonBody = json.decode(res.body) as Map<String, dynamic>;
			final data = jsonBody['data'];
			if (data is Map) {
				return fromJson(data.cast<String, dynamic>());
			}
			throw MapAPIException(
				message: 'Unexpected response shape: missing data object',
				statusCode: 200,
				body: res.body,
			);
		} catch (e) {
			throw MapAPIException(
				message: 'Failed to parse response: $e',
				statusCode: 200,
				body: res.body,
				originalError: e,
			);
		}
	}

	void _throwIfError(http.Response res) {
		if (res.statusCode == 200) return;
		if (res.statusCode == 401) {
			onTokenExpired?.call();
			throw MapAPIException(
				message: _parseErrorMessage(res.body),
				statusCode: 401,
				body: res.body,
			);
		}
		if (res.statusCode == 422) {
			throw MapAPIException(
				message: _parseErrorMessage(res.body),
				statusCode: 422,
				body: res.body,
			);
		}
		if (res.statusCode == 429) {
			throw MapAPIException(
				message: 'Rate limit exceeded: Too many requests (20/minute)',
				statusCode: 429,
				body: res.body,
			);
		}
		if (res.statusCode == 500) {
			throw MapAPIException(
				message: 'Internal server error',
				statusCode: 500,
				body: res.body,
			);
		}
		throw MapAPIException(
			message: _parseErrorMessage(res.body),
			statusCode: res.statusCode,
			body: res.body,
		);
	}

	void dispose() {
		_client.close();
	}
}

double? _toDouble(dynamic value) {
	if (value == null) return null;
	if (value is num) return value.toDouble();
	return double.tryParse(value.toString());
}
