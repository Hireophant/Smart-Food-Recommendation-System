/// Handler cho tính năng tìm kiếm món ăn
/// Theo Guideline: "Wrapper Pattern" - Mock data trước, thay logic sau
import '../models/food_model.dart';

/// Handler giao tiếp giữa UI và Backend/Core
/// Hiện tại: Mock data
/// Sau này: Thay bằng gọi API thực hoặc Supabase
abstract class FoodSearchHandler {
  /// Tìm kiếm món ăn theo từ khóa
  /// Input: [query] - từ khóa tìm kiếm
  /// Output: [SearchResult] - danh sách kết quả và trạng thái
  Future<SearchResult> searchFoods(String query);

  /// Lấy danh sách tất cả các món ăn
  Future<SearchResult> getAllFoods();

  /// Lấy chi tiết của một món ăn
  Future<FoodItem?> getFoodDetails(String foodId);
}

/// Implementation hiện tại - Mock Data
/// TODO: Thay bằng API call thực khi Backend sẵn sàng
class MockFoodSearchHandler implements FoodSearchHandler {
  /// Mock data - tất cả các món ăn có sẵn
  static final List<FoodItem> _mockFoods = [
    FoodItem(
      id: '1',
      name: 'Pizza Margherita',
      category: 'Italian',
      rating: 4.5,
      imageUrl: '🍕',
      description: 'Classic Italian pizza with fresh basil',
      price: 12.99,
    ),
    FoodItem(
      id: '2',
      name: 'Sushi Platter',
      category: 'Japanese',
      rating: 4.8,
      imageUrl: '🍣',
      description: 'Assorted fresh sushi rolls',
      price: 18.50,
    ),
    FoodItem(
      id: '3',
      name: 'Burger Deluxe',
      category: 'American',
      rating: 4.2,
      imageUrl: '🍔',
      description: 'Juicy burger with premium ingredients',
      price: 9.99,
    ),
    FoodItem(
      id: '4',
      name: 'Pad Thai',
      category: 'Thai',
      rating: 4.6,
      imageUrl: '🍜',
      description: 'Authentic Thai street food noodles',
      price: 11.00,
    ),
    FoodItem(
      id: '5',
      name: 'Tacos Al Pastor',
      category: 'Mexican',
      rating: 4.4,
      imageUrl: '🌮',
      description: 'Traditional Mexican tacos',
      price: 10.50,
    ),
    FoodItem(
      id: '6',
      name: 'Biryani',
      category: 'Indian',
      rating: 4.7,
      imageUrl: '🍚',
      description: 'Fragrant Indian rice dish',
      price: 13.00,
    ),
    FoodItem(
      id: '7',
      name: 'Caesar Salad',
      category: 'Healthy',
      rating: 4.1,
      imageUrl: '🥗',
      description: 'Fresh and crispy Caesar salad',
      price: 8.50,
    ),
    FoodItem(
      id: '8',
      name: 'Ramen',
      category: 'Japanese',
      rating: 4.5,
      imageUrl: '🍲',
      description: 'Rich and creamy ramen broth',
      price: 11.50,
    ),
  ];

  @override
  Future<SearchResult> searchFoods(String query) async {
    // Giả lập API delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) {
      return SearchResult(items: _mockFoods);
    }

    final lowerQuery = query.toLowerCase();
    final results = _mockFoods
        .where(
          (food) =>
              food.name.toLowerCase().contains(lowerQuery) ||
              food.category.toLowerCase().contains(lowerQuery) ||
              (food.description?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .toList();

    return SearchResult(items: results);
  }

  @override
  Future<SearchResult> getAllFoods() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SearchResult(items: _mockFoods);
  }

  @override
  Future<FoodItem?> getFoodDetails(String foodId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockFoods.firstWhere((food) => food.id == foodId);
    } catch (e) {
      return null;
    }
  }
}
