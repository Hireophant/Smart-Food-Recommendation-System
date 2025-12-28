import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../models/food_model.dart';
import '../core/data/data_client.dart';
import '../core/supabase_handler.dart';

/// Provider quản lý danh sách yêu thích
/// Sử dụng ChangeNotifier để thông báo UI khi có thay đổi
/// 
/// Theo Decoupled Development Guidelines:
/// - Handler này xử lý logic đồng bộ với Supabase
/// - UI chỉ cần gọi các method này, không trực tiếp giao tiếp với Supabase
class FavoritesProvider with ChangeNotifier {
  // Danh sách món ăn yêu thích (local cache)
  final List<DishItem> _favoriteDishes = [];

  // Danh sách nhà hàng yêu thích (local cache)
  final List<RestaurantItem> _favoriteRestaurants = [];

  // Danh sách ID từ Supabase (nguồn sự thật)
  List<String> _favoriteDishIds = [];
  List<String> _favoriteRestaurantIds = [];

  bool _isInitialized = false;
  bool _isSyncing = false;

  // Getters
  List<DishItem> get favoriteDishes => List.unmodifiable(_favoriteDishes);
  List<RestaurantItem> get favoriteRestaurants =>
      List.unmodifiable(_favoriteRestaurants);

  int get totalFavorites =>
      _favoriteDishes.length + _favoriteRestaurants.length;

  int get favoriteDishesCount => _favoriteDishIds.length;
  int get favoriteRestaurantsCount => _favoriteRestaurantIds.length;
  int get totalFavoritesCount => _favoriteDishIds.length + _favoriteRestaurantIds.length;

  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;

  /// Khởi tạo Provider - load favorites từ Supabase
  /// Nên gọi khi user login thành công
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await loadFromSupabase();
      _isInitialized = true;
    } catch (e) {
      debugPrint('FavoritesProvider: Failed to initialize: $e');
      // Không throw error - cho phép app chạy với empty favorites
    }
  }

  /// Load danh sách favorites từ Supabase
  Future<void> loadFromSupabase() async {
    final user = SupabaseHandler().currentUser;
    if (user == null) {
      debugPrint('FavoritesProvider: No user logged in');
      return;
    }

    try {
      _isSyncing = true;
      notifyListeners();

      final profile = await DataClient.getUserProfile(user.id);
      _favoriteDishIds = List.from(profile.favoritesFoodIds);
      _favoriteRestaurantIds = List.from(profile.favoritesRestaurantsIds);

      debugPrint('FavoritesProvider: Loaded ${_favoriteDishIds.length} dishes, ${_favoriteRestaurantIds.length} restaurants');
    } catch (e) {
      debugPrint('FavoritesProvider: Failed to load from Supabase: $e');
      // Giữ nguyên dữ liệu cũ nếu có lỗi
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync favorites lên Supabase
  Future<void> _syncToSupabase() async {
    final user = SupabaseHandler().currentUser;
    if (user == null) {
      debugPrint('FavoritesProvider: No user logged in, skip sync');
      return;
    }

    try {
      await DataClient.setUserProfile(
        user.id,
        favoritesFoodIds: _favoriteDishIds,
        favoritesRestaurantsIds: _favoriteRestaurantIds,
      );
      debugPrint('FavoritesProvider: Synced to Supabase successfully');
    } catch (e) {
      debugPrint('FavoritesProvider: Failed to sync to Supabase: $e');
      // Không throw - để user tiếp tục dùng app
    }
  }

  /// Kiểm tra món ăn đã được yêu thích chưa
  bool isDishFavorite(String dishId) {
    return _favoriteDishIds.contains(dishId);
  }

  /// Kiểm tra nhà hàng đã được yêu thích chưa
  bool isRestaurantFavorite(String restaurantId) {
    return _favoriteRestaurantIds.contains(restaurantId);
  }

  /// Thêm món ăn vào danh sách yêu thích
  Future<void> addDish(DishItem dish) async {
    if (isDishFavorite(dish.id)) return;

    // Update local state immediately (Optimistic UI)
    _favoriteDishIds.add(dish.id);
    if (!_favoriteDishes.any((d) => d.id == dish.id)) {
      _favoriteDishes.add(dish);
    }
    notifyListeners();

    // Sync to Supabase in background
    await _syncToSupabase();
  }

  /// Xóa món ăn khỏi danh sách yêu thích
  Future<void> removeDish(String dishId) async {
    if (!isDishFavorite(dishId)) return;

    // Update local state immediately (Optimistic UI)
    _favoriteDishIds.remove(dishId);
    _favoriteDishes.removeWhere((dish) => dish.id == dishId);
    notifyListeners();

    // Sync to Supabase in background
    await _syncToSupabase();
  }

  /// Toggle món ăn yêu thích
  Future<void> toggleDish(DishItem dish) async {
    if (isDishFavorite(dish.id)) {
      await removeDish(dish.id);
    } else {
      await addDish(dish);
    }
  }

  /// Thêm nhà hàng vào danh sách yêu thích
  Future<void> addRestaurant(RestaurantItem restaurant) async {
    if (isRestaurantFavorite(restaurant.id)) return;

    // Update local state immediately (Optimistic UI)
    _favoriteRestaurantIds.add(restaurant.id);
    if (!_favoriteRestaurants.any((r) => r.id == restaurant.id)) {
      _favoriteRestaurants.add(restaurant);
    }
    notifyListeners();

    // Sync to Supabase in background
    await _syncToSupabase();
  }

  /// Xóa nhà hàng khỏi danh sách yêu thích
  Future<void> removeRestaurant(String restaurantId) async {
    if (!isRestaurantFavorite(restaurantId)) return;

    // Update local state immediately (Optimistic UI)
    _favoriteRestaurantIds.remove(restaurantId);
    _favoriteRestaurants.removeWhere(
      (restaurant) => restaurant.id == restaurantId,
    );
    notifyListeners();

    // Sync to Supabase in background
    await _syncToSupabase();
  }

  /// Toggle nhà hàng yêu thích
  Future<void> toggleRestaurant(RestaurantItem restaurant) async {
    if (isRestaurantFavorite(restaurant.id)) {
      await removeRestaurant(restaurant.id);
    } else {
      await addRestaurant(restaurant);
    }
  }

  /// Xóa tất cả yêu thích
  Future<void> clearAll() async {
    _favoriteDishIds.clear();
    _favoriteRestaurantIds.clear();
    _favoriteDishes.clear();
    _favoriteRestaurants.clear();
    notifyListeners();

    await _syncToSupabase();
  }

  /// Xóa tất cả món ăn yêu thích
  Future<void> clearDishes() async {
    _favoriteDishIds.clear();
    _favoriteDishes.clear();
    notifyListeners();

    await _syncToSupabase();
  }

  /// Xóa tất cả nhà hàng yêu thích
  Future<void> clearRestaurants() async {
    _favoriteRestaurantIds.clear();
    _favoriteRestaurants.clear();
    notifyListeners();

    await _syncToSupabase();
  }

  /// Reset provider khi user logout
  void reset() {
    _favoriteDishIds.clear();
    _favoriteRestaurantIds.clear();
    _favoriteDishes.clear();
    _favoriteRestaurants.clear();
    _isInitialized = false;
    _isSyncing = false;
    notifyListeners();
  }
}
