import 'package:flutter/material.dart';
import '../core/supabase_handler.dart';
import '../core/data/data_client.dart';
import '../core/data/user_profile.dart';
import 'package:provider/provider.dart';
import '../providers/reviews_provider.dart';

/// Model cho stats hiển thị ở Profile Page
class UserStats {
  final int ratedCount;
  final int favoritesCount;
  final int checkInCount;

  const UserStats({
    required this.ratedCount,
    required this.favoritesCount,
    required this.checkInCount,
  });

  factory UserStats.empty() {
    return const UserStats(ratedCount: 0, favoritesCount: 0, checkInCount: 0);
  }
}

/// Handler quản lý thông tin User Profile
///
/// Theo Decoupled Development Guidelines:
/// - UI chỉ cần gọi Handler này để lấy dữ liệu
/// - Handler tự quyết định: lấy từ Supabase hoặc mock data
/// - **UPDATED:** Now using REAL Supabase queries (NO MOCK DATA)
class UserHandler {
  UserHandler._();

  /// Lấy stats của user hiện tại để hiển thị ở Profile Page
  ///
  /// **REAL DATA IMPLEMENTATION:**
  /// - "Favorites": Count from user_profile.favorites_*_ids arrays
  /// - "Check-in": From user_profile.restaurant_visited field
  /// - "Rated": Count from ReviewsProvider (local state only)
  static Future<UserStats> getUserStats(BuildContext? context) async {
    final user = SupabaseHandler().currentUser;

    if (user == null) {
      debugPrint('UserHandler: No user logged in, returning empty stats');
      return UserStats.empty();
    }

    try {
      // Get user profile from Supabase (REAL DATA)
      final profile = await DataClient.getUserProfile(user.id);

      // Count favorites - chỉ tính restaurants (bỏ món ăn)
      final favoritesCount = profile.favoritesRestaurantsIds.length;

      // Get check-in count
      final checkInCount = profile.restaurantVisited;

      // Get reviews count from provider (if context available)
      int ratedCount = 0;
      if (context != null) {
        try {
          final reviewsProvider = Provider.of<ReviewsProvider>(context, listen: false);
          ratedCount = reviewsProvider.totalReviewsCount;
        } catch (e) {
          debugPrint('UserHandler: Could not get ReviewsProvider: $e');
        }
      }

      return UserStats(
        ratedCount: ratedCount,
        favoritesCount: favoritesCount,
        checkInCount: checkInCount,
      );
    } catch (e) {
      debugPrint('UserHandler: Failed to fetch user stats: $e');
      // Return empty stats on error (not mock - just zeros)
      return UserStats.empty();
    }
  }

  /// Lấy UserProfile đầy đủ từ Supabase
  static Future<UserProfile?> getUserProfile() async {
    final user = SupabaseHandler().currentUser;

    if (user == null) {
      debugPrint('UserHandler: No user logged in');
      return null;
    }

    try {
      return await DataClient.getUserProfile(user.id);
    } catch (e) {
      debugPrint('UserHandler: Failed to fetch user profile: $e');
      return null;
    }
  }

  /// Update một phần thông tin user profile
  ///
  /// Chỉ update các field được truyền vào (không null)
  static Future<UserProfile?> updateUserProfile({
    String? nickname,
    String? phoneNumber,
    String? address,
    String? occupations,
  }) async {
    final user = SupabaseHandler().currentUser;

    if (user == null) {
      debugPrint('UserHandler: No user logged in');
      return null;
    }

    try {
      return await DataClient.setUserProfile(
        user.id,
        nickname: nickname,
        phoneNumber: phoneNumber,
        address: address,
        occupations: occupations,
      );
    } catch (e) {
      debugPrint('UserHandler: Failed to update user profile: $e');
      return null;
    }
  }

  /// Increment check-in count
  /// Call this when user checks in at a restaurant
  static Future<void> incrementCheckIn() async {
    final user = SupabaseHandler().currentUser;

    if (user == null) {
      debugPrint('UserHandler: No user logged in');
      return;
    }

    try {
      final profile = await DataClient.getUserProfile(user.id);
      await DataClient.setUserProfile(
        user.id,
        restaurantVisited: profile.restaurantVisited + 1,
      );
    } catch (e) {
      debugPrint('UserHandler: Failed to increment check-in: $e');
    }
  }
}
