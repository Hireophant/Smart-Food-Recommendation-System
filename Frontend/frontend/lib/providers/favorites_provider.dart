import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../models/food_model.dart';

/// Provider quản lý danh sách yêu thích
/// Sử dụng ChangeNotifier để thông báo UI khi có thay đổi
class FavoritesProvider with ChangeNotifier {
  // Danh sách món ăn yêu thích
  final List<DishItem> _favoriteDishes = [];
  
  // Danh sách nhà hàng yêu thích
  final List<RestaurantItem> _favoriteRestaurants = [];

  // Getters
  List<DishItem> get favoriteDishes => List.unmodifiable(_favoriteDishes);
  List<RestaurantItem> get favoriteRestaurants => List.unmodifiable(_favoriteRestaurants);
  
  int get totalFavorites => _favoriteDishes.length + _favoriteRestaurants.length;

  /// Kiểm tra món ăn đã được yêu thích chưa
  bool isDishFavorite(String dishId) {
    return _favoriteDishes.any((dish) => dish.id == dishId);
  }

  /// Kiểm tra nhà hàng đã được yêu thích chưa
  bool isRestaurantFavorite(String restaurantId) {
    return _favoriteRestaurants.any((restaurant) => restaurant.id == restaurantId);
  }

  /// Thêm món ăn vào danh sách yêu thích
  void addDish(DishItem dish) {
    if (!isDishFavorite(dish.id)) {
      _favoriteDishes.add(dish);
      notifyListeners();
    }
  }

  /// Xóa món ăn khỏi danh sách yêu thích
  void removeDish(String dishId) {
    _favoriteDishes.removeWhere((dish) => dish.id == dishId);
    notifyListeners();
  }

  /// Toggle món ăn yêu thích
  void toggleDish(DishItem dish) {
    if (isDishFavorite(dish.id)) {
      removeDish(dish.id);
    } else {
      addDish(dish);
    }
  }

  /// Thêm nhà hàng vào danh sách yêu thích
  void addRestaurant(RestaurantItem restaurant) {
    if (!isRestaurantFavorite(restaurant.id)) {
      _favoriteRestaurants.add(restaurant);
      notifyListeners();
    }
  }

  /// Xóa nhà hàng khỏi danh sách yêu thích
  void removeRestaurant(String restaurantId) {
    _favoriteRestaurants.removeWhere((restaurant) => restaurant.id == restaurantId);
    notifyListeners();
  }

  /// Toggle nhà hàng yêu thích
  void toggleRestaurant(RestaurantItem restaurant) {
    if (isRestaurantFavorite(restaurant.id)) {
      removeRestaurant(restaurant.id);
    } else {
      addRestaurant(restaurant);
    }
  }

  /// Xóa tất cả yêu thích
  void clearAll() {
    _favoriteDishes.clear();
    _favoriteRestaurants.clear();
    notifyListeners();
  }

  /// Xóa tất cả món ăn yêu thích
  void clearDishes() {
    _favoriteDishes.clear();
    notifyListeners();
  }

  /// Xóa tất cả nhà hàng yêu thích
  void clearRestaurants() {
    _favoriteRestaurants.clear();
    notifyListeners();
  }
}
