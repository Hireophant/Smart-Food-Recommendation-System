import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../core/supabase_handler.dart';

/// Provider quản lý reviews của user
///
/// NOTE: Hiện tại chỉ lưu trong memory (không persist)
/// Reviews sẽ mất khi restart app
class ReviewsProvider with ChangeNotifier {
  // Map: restaurantId -> list of user's reviews for that restaurant
  final Map<String, List<ReviewModel>> _userReviews = {};

  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;

  /// Lấy tổng số reviews của user
  int get totalReviewsCount {
    int total = 0;
    for (var reviews in _userReviews.values) {
      total += reviews.length;
    }
    return total;
  }

  /// Lấy reviews của user cho một nhà hàng cụ thể
  List<ReviewModel> getReviewsForRestaurant(String restaurantId) {
    return List.unmodifiable(_userReviews[restaurantId] ?? []);
  }

  /// Kiểm tra user đã review nhà hàng này chưa
  bool hasReviewedRestaurant(String restaurantId) {
    return _userReviews.containsKey(restaurantId) &&
        _userReviews[restaurantId]!.isNotEmpty;
  }

  /// Thêm review mới
  Future<void> addReview({
    required String restaurantId,
    required double rating,
    required String comment,
    List<String> images = const [],
  }) async {
    final user = SupabaseHandler().currentUser;
    if (user == null) {
      debugPrint('ReviewsProvider: No user logged in');
      return;
    }

    final review = ReviewModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: user.userMetadata?['full_name'] ?? user.email ?? 'User',
      userAvatar:
          user.userMetadata?['avatar_url'] ??
          'https://i.pravatar.cc/150?img=68',
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      images: images,
    );

    // Update local state
    if (!_userReviews.containsKey(restaurantId)) {
      _userReviews[restaurantId] = [];
    }
    _userReviews[restaurantId]!.add(review);

    notifyListeners();

    debugPrint(
      'ReviewsProvider: Added review for restaurant $restaurantId. Total reviews: $totalReviewsCount',
    );
    // NOTE: Reviews chỉ lưu trong memory, không persist vào database
  }

  /// Xóa review
  Future<void> removeReview(String restaurantId, String reviewId) async {
    if (!_userReviews.containsKey(restaurantId)) return;

    _userReviews[restaurantId]!.removeWhere((review) => review.id == reviewId);

    if (_userReviews[restaurantId]!.isEmpty) {
      _userReviews.remove(restaurantId);
    }

    notifyListeners();

    debugPrint(
      'ReviewsProvider: Removed review $reviewId from restaurant $restaurantId',
    );
    // NOTE: Reviews chỉ lưu trong memory, không persist vào database
  }

  /// Initialize provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Just mark as initialized - no database loading
      _isInitialized = true;
      debugPrint('ReviewsProvider: Initialized (memory only - no persistence)');
    } catch (e) {
      debugPrint('ReviewsProvider: Failed to initialize: $e');
    }
  }

  /// Reset provider khi user logout
  void reset() {
    _userReviews.clear();
    _isInitialized = false;
    notifyListeners();
  }
}
