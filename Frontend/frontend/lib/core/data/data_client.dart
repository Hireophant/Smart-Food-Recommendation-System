import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_profile.dart';
import 'user_taste_profile.dart';

enum DataClientErrorKind {
  notLoggedIn,
  notFound,
  permissionDenied,
  network,
  invalidResponse,
  unknown,
}

class DataClientException implements Exception {
  const DataClientException(
    this.kind, {
    this.message,
    this.cause,
    this.stackTrace,
  });

  final DataClientErrorKind kind;
  final String? message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final msg = message == null ? '' : ': $message';
    return 'DataClientException($kind$msg)';
  }
}

class DataClient {
  DataClient._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<UserTasteProfile> getTasteProfile(String userId) async {
    try {
      final sessionUserId = _client.auth.currentUser?.id;
      if (sessionUserId == null) {
        throw const DataClientException(
          DataClientErrorKind.notLoggedIn,
          message: 'No authenticated user in current session.',
        );
      }

      final Map<String, dynamic>? row = await _client
          .from('user_taste_profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        // With RLS, querying someone else's user_id typically returns empty.
        // Only auto-create when requesting the current user's profile.
        if (userId != sessionUserId) {
          throw const DataClientException(
            DataClientErrorKind.notFound,
            message: 'Taste profile not found (or not accessible).',
          );
        }

        final createdRow = await _createDefaultTasteProfile(sessionUserId);
        return _mapTasteProfile(createdRow);
      }

      return _mapTasteProfile(row);
    } on PostgrestException catch (e, st) {
      throw DataClientException(
        _mapPostgrestExceptionKind(e),
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } on AuthException catch (e, st) {
      throw DataClientException(
        DataClientErrorKind.notLoggedIn,
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      throw DataClientException(
        DataClientErrorKind.network,
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is DataClientException) rethrow;
      throw DataClientException(
        DataClientErrorKind.unknown,
        message: 'Unexpected error while fetching taste profile.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  static Future<UserProfile> getUserProfile(String userId) async {
    try {
      final sessionUserId = _client.auth.currentUser?.id;
      if (sessionUserId == null) {
        throw const DataClientException(
          DataClientErrorKind.notLoggedIn,
          message: 'No authenticated user in current session.',
        );
      }

      final Map<String, dynamic>? row = await _client
          .from('user_profile')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        // Only auto-create when requesting the current user's profile.
        if (userId != sessionUserId) {
          throw const DataClientException(
            DataClientErrorKind.notFound,
            message: 'User profile not found (or not accessible).',
          );
        }

        final createdRow = await _createDefaultUserProfile(sessionUserId);
        return _mapUserProfile(createdRow);
      }

      return _mapUserProfile(row);
    } on PostgrestException catch (e, st) {
      throw DataClientException(
        _mapPostgrestExceptionKind(e),
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } on AuthException catch (e, st) {
      throw DataClientException(
        DataClientErrorKind.notLoggedIn,
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      throw DataClientException(
        DataClientErrorKind.network,
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is DataClientException) rethrow;
      throw DataClientException(
        DataClientErrorKind.unknown,
        message: 'Unexpected error while fetching user profile.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  static Future<UserProfile> getCurrentUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const DataClientException(
        DataClientErrorKind.notLoggedIn,
        message: 'No authenticated user in current session.',
      );
    }
    return getUserProfile(userId);
  }

  /// Convenience wrapper for [setUserProfile] using the current session user.
  static Future<UserProfile> setCurrentUserProfile({
    List<String>? favoritesFoodIds,
    List<String>? favoritesRestaurantsIds,
    int? level,
    int? dishEaten,
    int? restaurantVisited,
    String? phoneNumber,
    String? occupations,
    String? address,
    String? nickname,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const DataClientException(
        DataClientErrorKind.notLoggedIn,
        message: 'No authenticated user in current session.',
      );
    }
    return setUserProfile(
      userId,
      favoritesFoodIds: favoritesFoodIds,
      favoritesRestaurantsIds: favoritesRestaurantsIds,
      level: level,
      dishEaten: dishEaten,
      restaurantVisited: restaurantVisited,
      phoneNumber: phoneNumber,
      occupations: occupations,
      address: address,
      nickname: nickname,
    );
  }

  /// Partially updates a user's `user_profile` row.
  ///
  /// - Only allows updating the current authenticated user's row.
  /// - Does not send null fields (so it won't overwrite existing values with NULL).
  /// - If the row doesn't exist yet, it will be created with defaults, then updated.
  static Future<UserProfile> setUserProfile(
    String userId, {
    List<String>? favoritesFoodIds,
    List<String>? favoritesRestaurantsIds,
    int? level,
    int? dishEaten,
    int? restaurantVisited,
    String? phoneNumber,
    String? occupations,
    String? address,
    String? nickname,
  }) async {
    try {
      final sessionUserId = _client.auth.currentUser?.id;
      if (sessionUserId == null) {
        throw const DataClientException(
          DataClientErrorKind.notLoggedIn,
          message: 'No authenticated user in current session.',
        );
      }

      if (userId != sessionUserId) {
        throw const DataClientException(
          DataClientErrorKind.permissionDenied,
          message: 'Cannot update another user\'s profile.',
        );
      }

      final patch = _withoutNulls({
        'favorites_food_ids': favoritesFoodIds,
        'favorites_restaurants_ids': favoritesRestaurantsIds,
        'level': level,
        'dish_eaten': dishEaten,
        'restaurant_visited': restaurantVisited,
        'phone_number': phoneNumber,
        'occupations': occupations,
        'address': address,
        'nickname': nickname,
      });

      if (patch.isEmpty) {
        return getUserProfile(sessionUserId);
      }

      final Map<String, dynamic>? updated = await _client
          .from('user_profile')
          .update(patch)
          .eq('user_id', sessionUserId)
          .select('*')
          .maybeSingle();

      if (updated != null) {
        return _mapUserProfile(updated);
      }

      await _createDefaultUserProfile(sessionUserId);

      final Map<String, dynamic>? updatedAfterCreate = await _client
          .from('user_profile')
          .update(patch)
          .eq('user_id', sessionUserId)
          .select('*')
          .maybeSingle();

      if (updatedAfterCreate == null) {
        throw const DataClientException(
          DataClientErrorKind.invalidResponse,
          message: 'Profile update returned empty response.',
        );
      }

      return _mapUserProfile(updatedAfterCreate);
    } on PostgrestException catch (e, st) {
      throw DataClientException(
        _mapPostgrestExceptionKind(e),
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } on AuthException catch (e, st) {
      throw DataClientException(
        DataClientErrorKind.notLoggedIn,
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      throw DataClientException(
        DataClientErrorKind.network,
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is DataClientException) rethrow;
      throw DataClientException(
        DataClientErrorKind.unknown,
        message: 'Unexpected error while updating user profile.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  static Future<UserTasteProfile> getCurrentTasteProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const DataClientException(
        DataClientErrorKind.notLoggedIn,
        message: 'No authenticated user in current session.',
      );
    }
    return getTasteProfile(userId);
  }

  /// Convenience wrapper for [setTasteProfile] using the current session user.
  static Future<UserTasteProfile> setCurrentTasteProfile({
    List<String>? cuisines,
    String? spiceLevel,
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    String? pricePreference,
    List<String>? favoriteDishes,
    List<String>? dislikes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const DataClientException(
        DataClientErrorKind.notLoggedIn,
        message: 'No authenticated user in current session.',
      );
    }
    return setTasteProfile(
      userId,
      cuisines: cuisines,
      spiceLevel: spiceLevel,
      dietaryRestrictions: dietaryRestrictions,
      allergies: allergies,
      pricePreference: pricePreference,
      favoriteDishes: favoriteDishes,
      dislikes: dislikes,
    );
  }

  /// Partially updates a user's `user_taste_profiles` row.
  ///
  /// - Only allows updating the current authenticated user's row.
  /// - Does not send null fields (so it won't overwrite existing values with NULL).
  /// - If the row doesn't exist yet, it will be created with defaults, then updated.
  static Future<UserTasteProfile> setTasteProfile(
    String userId, {
    List<String>? cuisines,
    String? spiceLevel,
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    String? pricePreference,
    List<String>? favoriteDishes,
    List<String>? dislikes,
  }) async {
    try {
      final sessionUserId = _client.auth.currentUser?.id;
      if (sessionUserId == null) {
        throw const DataClientException(
          DataClientErrorKind.notLoggedIn,
          message: 'No authenticated user in current session.',
        );
      }

      if (userId != sessionUserId) {
        throw const DataClientException(
          DataClientErrorKind.permissionDenied,
          message: 'Cannot update another user\'s taste profile.',
        );
      }

      final patch = _withoutNulls({
        'cuisines': cuisines,
        'spice_level': spiceLevel,
        'dietary_restrictions': dietaryRestrictions,
        'allergies': allergies,
        'price_preference': pricePreference,
        'favorite_dishes': favoriteDishes,
        'dislikes': dislikes,
      });

      if (patch.isEmpty) {
        return getTasteProfile(sessionUserId);
      }

      final Map<String, dynamic>? updated = await _client
          .from('user_taste_profiles')
          .update(patch)
          .eq('user_id', sessionUserId)
          .select('*')
          .maybeSingle();

      if (updated != null) {
        return _mapTasteProfile(updated);
      }

      await _createDefaultTasteProfile(sessionUserId);

      final Map<String, dynamic>? updatedAfterCreate = await _client
          .from('user_taste_profiles')
          .update(patch)
          .eq('user_id', sessionUserId)
          .select('*')
          .maybeSingle();

      if (updatedAfterCreate == null) {
        throw const DataClientException(
          DataClientErrorKind.invalidResponse,
          message: 'Taste profile update returned empty response.',
        );
      }

      return _mapTasteProfile(updatedAfterCreate);
    } on PostgrestException catch (e, st) {
      throw DataClientException(
        _mapPostgrestExceptionKind(e),
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } on AuthException catch (e, st) {
      throw DataClientException(
        DataClientErrorKind.notLoggedIn,
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      throw DataClientException(
        DataClientErrorKind.network,
        message: e.message,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is DataClientException) rethrow;
      throw DataClientException(
        DataClientErrorKind.unknown,
        message: 'Unexpected error while updating taste profile.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  static UserTasteProfile _mapTasteProfile(Map<String, dynamic> row) {
    try {
      return UserTasteProfile.fromJson(row);
    } catch (e, st) {
      throw DataClientException(
        DataClientErrorKind.invalidResponse,
        message: 'Failed to parse taste profile response.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  static UserProfile _mapUserProfile(Map<String, dynamic> row) {
    try {
      return UserProfile.fromJson(row);
    } catch (e, st) {
      throw DataClientException(
        DataClientErrorKind.invalidResponse,
        message: 'Failed to parse user profile response.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  static Future<Map<String, dynamic>> _createDefaultTasteProfile(
    String userId,
  ) async {
    // Create a minimal row; other columns remain NULL and timestamps use defaults.
    // Use upsert to avoid race conditions if multiple calls try to create.
    final Map<String, dynamic> created = await _client
        .from('user_taste_profiles')
        .upsert({'user_id': userId}, onConflict: 'user_id')
        .select('*')
        .single();

    return created;
  }

  static Future<Map<String, dynamic>> _createDefaultUserProfile(
    String userId,
  ) async {
    // favorites_* arrays are NOT NULL in this table, so provide empty lists.
    final Map<String, dynamic> created = await _client
        .from('user_profile')
        .upsert({
          'user_id': userId,
          'favorites_food_ids': <String>[],
          'favorites_restaurants_ids': <String>[],
        }, onConflict: 'user_id')
        .select('*')
        .single();

    return created;
  }

  static DataClientErrorKind _mapPostgrestExceptionKind(PostgrestException e) {
    // PostgREST codes vary by failure mode; keep mapping conservative.
    final code = e.code;
    final message = e.message.toLowerCase();

    // Common Postgres codes
    if (code == '42501' || message.contains('permission denied')) {
      return DataClientErrorKind.permissionDenied;
    }

    // Not logged in / auth related (often 401 bubbles up via PostgREST).
    if (message.contains('jwt') || message.contains('not authorized')) {
      return DataClientErrorKind.notLoggedIn;
    }

    return DataClientErrorKind.unknown;
  }

  static Map<String, dynamic> _withoutNulls(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    input.forEach((key, value) {
      if (value != null) result[key] = value;
    });
    return result;
  }
}
