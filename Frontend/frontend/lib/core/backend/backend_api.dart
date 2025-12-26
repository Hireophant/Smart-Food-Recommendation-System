import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

enum BackendApiErrorKind {
  notLoggedIn,
  unauthorized,
  notFound,
  rateLimited,
  validation,
  server,
  network,
  invalidResponse,
  unknown,
}

class BackendApiException implements Exception {
  const BackendApiException(
    this.kind, {
    this.message,
    this.statusCode,
    this.cause,
    this.stackTrace,
    this.details,
  });

  final BackendApiErrorKind kind;
  final String? message;
  final int? statusCode;
  final Object? cause;
  final StackTrace? stackTrace;

  /// Optional structured error details returned by the backend.
  ///
  /// The backend uses `{status: 'error', result: 'error', data: [{code, detail}]}`.
  final List<BackendApiErrorDetail>? details;

  @override
  String toString() {
    final msg = message == null ? '' : ': $message';
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return 'BackendApiException($kind$code$msg)';
  }
}

class BackendApiErrorDetail {
  const BackendApiErrorDetail({required this.code, required this.detail});

  final int code;
  final String detail;

  factory BackendApiErrorDetail.fromJson(Map<String, dynamic> json) {
    return BackendApiErrorDetail(
      code: (json['code'] as num?)?.toInt() ?? 0,
      detail: json['detail']?.toString() ?? '',
    );
  }
}

/// A small transport client for the FastAPI backend.
///
/// - Base URL is provided by the app at construction time.
/// - Authentication uses Supabase session JWT (no manual JWT parsing/expiry).
/// - Throws [BackendApiException] for errors.
///
/// Endpoint clients built on top of this transport:
/// - Maps: `/maps/*`
/// - Restaurants: `/data/*`
/// - Search: `/search`, `/search/formatted`
class BackendAPI {
  BackendAPI({
    String baseUrl = 'http://localhost:8000',
    SupabaseClient? supabase,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
  }) : _baseUri = Uri.parse(baseUrl.replaceAll(RegExp(r'/$'), '')),
       _supabase = supabase ?? Supabase.instance.client,
       _http = httpClient ?? http.Client(),
       _timeout = timeout;

  final Uri _baseUri;
  final SupabaseClient _supabase;
  final http.Client _http;
  final Duration _timeout;
  bool _disposed = false;

  bool get isLoggedIn =>
      _supabase.auth.currentUser != null && accessToken != null;

  String? get accessToken => _supabase.auth.currentSession?.accessToken;

  void dispose() {
    if (_disposed) return;
    _http.close();
    _disposed = true;
  }

  Future<T> getObject<T>(
    String path, {
    Map<String, Object?> query = const {},
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final jsonBody = await _getJson(_buildUri(path, query: query));

    final data = jsonBody['data'];
    if (data is Map) {
      return fromJson(data.cast<String, dynamic>());
    }

    throw BackendApiException(
      BackendApiErrorKind.invalidResponse,
      message: 'Unexpected response shape: missing data object.',
      statusCode: 200,
    );
  }

  Future<List<T>> getCollections<T>(
    String path, {
    Map<String, Object?> query = const {},
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final jsonBody = await _getJson(_buildUri(path, query: query));

    final data = jsonBody['data'];
    if (data is List) {
      return data
          .whereType<Object>()
          .map((e) => (e as Map).cast<String, dynamic>())
          .map(fromJson)
          .toList();
    }

    throw BackendApiException(
      BackendApiErrorKind.invalidResponse,
      message: 'Unexpected response shape: missing data list.',
      statusCode: 200,
    );
  }

  String _requireAccessToken() {
    final token = accessToken;
    if (_supabase.auth.currentUser == null || token == null || token.isEmpty) {
      throw const BackendApiException(
        BackendApiErrorKind.notLoggedIn,
        message: 'No authenticated Supabase session.',
        statusCode: 401,
      );
    }
    return token;
  }

  Map<String, String> _headers() {
    final token = _requireAccessToken();
    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Uri _buildUri(String path, {required Map<String, Object?> query}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final queryString = _encodeQuery(query);
    return _baseUri.replace(
      path: '${_baseUri.path}$normalizedPath',
      query: queryString.isEmpty ? null : queryString,
    );
  }

  String _encodeQuery(Map<String, Object?> query) {
    final parts = <String>[];
    for (final entry in query.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;

      void addOne(String v) {
        final trimmed = v.trim();
        if (trimmed.isEmpty) return;
        parts.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(trimmed)}',
        );
      }

      if (value is String) {
        addOne(value);
        continue;
      }

      if (value is Iterable) {
        for (final item in value) {
          if (item == null) continue;
          addOne(item.toString());
        }
        continue;
      }

      addOne(value.toString());
    }

    return parts.join('&');
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final res = await _http
          .get(uri, headers: _headers())
          .timeout(
            _timeout,
            onTimeout: () {
              throw BackendApiException(
                BackendApiErrorKind.network,
                message: 'Request timed out after ${_timeout.inSeconds}s.',
                statusCode: 408,
              );
            },
          );

      if (res.statusCode == 200) {
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map) {
            return decoded.cast<String, dynamic>();
          }
          throw BackendApiException(
            BackendApiErrorKind.invalidResponse,
            message: 'Expected JSON object response.',
            statusCode: 200,
          );
        } catch (e, st) {
          throw BackendApiException(
            BackendApiErrorKind.invalidResponse,
            message: 'Failed to decode JSON response.',
            statusCode: 200,
            cause: e,
            stackTrace: st,
          );
        }
      }

      throw _mapHttpError(res.statusCode, res.body);
    } on BackendApiException {
      rethrow;
    } on AuthException catch (e, st) {
      throw BackendApiException(
        BackendApiErrorKind.notLoggedIn,
        message: e.message,
        cause: e,
        stackTrace: st,
        statusCode: 401,
      );
    } on SocketException catch (e, st) {
      throw BackendApiException(
        BackendApiErrorKind.network,
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      throw BackendApiException(
        BackendApiErrorKind.unknown,
        message: 'Unexpected error while calling backend.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  BackendApiException _mapHttpError(int statusCode, String body) {
    final details = _tryParseErrorDetails(body);
    final message = _tryParseErrorMessage(body);

    if (statusCode == 401) {
      return BackendApiException(
        BackendApiErrorKind.unauthorized,
        statusCode: 401,
        message: message,
        details: details,
      );
    }

    if (statusCode == 404) {
      return BackendApiException(
        BackendApiErrorKind.notFound,
        statusCode: 404,
        message: message,
        details: details,
      );
    }

    if (statusCode == 422) {
      return BackendApiException(
        BackendApiErrorKind.validation,
        statusCode: 422,
        message: message,
        details: details,
      );
    }

    if (statusCode == 429) {
      return BackendApiException(
        BackendApiErrorKind.rateLimited,
        statusCode: 429,
        message: message.isEmpty
            ? 'Rate limited by backend (too many requests).'
            : message,
        details: details,
      );
    }

    if (statusCode >= 500) {
      return BackendApiException(
        BackendApiErrorKind.server,
        statusCode: statusCode,
        message: message.isEmpty ? 'Backend server error.' : message,
        details: details,
      );
    }

    return BackendApiException(
      BackendApiErrorKind.unknown,
      statusCode: statusCode,
      message: message.isEmpty ? 'HTTP $statusCode error.' : message,
      details: details,
    );
  }

  String _tryParseErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final map = decoded.cast<String, dynamic>();
        final data = map['data'];
        if (data is List && data.isNotEmpty) {
          final first = data.first;
          if (first is Map) {
            final detail = first['detail']?.toString();
            if (detail != null && detail.trim().isNotEmpty) {
              return detail.trim();
            }
          }
        }

        final detail = map['detail']?.toString();
        if (detail != null && detail.trim().isNotEmpty) return detail.trim();

        final message = map['message']?.toString();
        if (message != null && message.trim().isNotEmpty) return message.trim();
      }

      return body;
    } catch (_) {
      return body;
    }
  }

  List<BackendApiErrorDetail>? _tryParseErrorDetails(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final data = decoded['data'];
      if (data is! List) return null;

      final parsed = data
          .whereType<Object>()
          .whereType<Map>()
          .map((e) => BackendApiErrorDetail.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);

      return parsed.isEmpty ? null : parsed;
    } catch (_) {
      return null;
    }
  }
}
