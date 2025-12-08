import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';

/// Handler giao tiếp giữa UI và Backend/Core
abstract class FoodSearchHandler {
  /// Tìm kiếm nhà hàng theo từ khóa
  Future<SearchResult> searchFoods(String query);

  /// Lấy danh sách tất cả nhà hàng
  Future<SearchResult> getAllFoods();

  /// Lấy chi tiết
  Future<RestaurantItem?> getFoodDetails(String id);

  /// Lấy menu
  Future<List<MenuItem>> getMenu(String id);
}

/// Implementation hiện tại - Mock Data kết hợp OSM Search
///
/// Class này giả lập việc gọi API từ Backend.
/// - Dữ liệu cứng (Hardcoded) được dùng để hiển thị các quán mẫu đẹp mắt.
/// - Tích hợp gọi API OpenStreetMap (Nominatim) để tìm kiếm địa điểm thực tế.
class MockFoodSearchHandler implements FoodSearchHandler {
  /// Mock data - matches the screenshot
  static final List<RestaurantItem> _mockFoods = [
    RestaurantItem(
      id: '1',
      name: 'THAIYEN CAFE Quan Thanh',
      category: 'Cafe • Coffee • Beverages',
      rating: 4.7,
      ratingCount: 143,
      imageUrl:
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=600',
      description: 'Cozy • Ba Dinh',
      priceLevel: '\$\$',
      isOpen: true,
      distance: '1.2 km',
      tags: ['Cozy', 'Ba Dinh'],
      latitude: 21.0365,
      longitude: 105.8432,
    ),
    RestaurantItem(
      id: '2',
      name: 'Cafe de Flore 46',
      category: 'Cafe • French • Pastries',
      rating: 4.7,
      ratingCount: 154,
      imageUrl:
          'https://images.unsplash.com/photo-1559339352-11d035aa65de?q=80&w=600',
      description: 'Premium • Romantic',
      priceLevel: '\$\$\$',
      isOpen: true,
      distance: '0.8 km',
      tags: ['Premium', 'Romantic'],
      latitude: 21.0335,
      longitude: 105.8500,
    ),
    RestaurantItem(
      id: '3',
      name: 'Le Petit Café',
      category: 'Cafe • European • Desserts',
      rating: 4.8,
      ratingCount: 312,
      imageUrl:
          'https://images.unsplash.com/photo-1498804103079-a6351b050096?q=80&w=600',
      description: 'Quiet • Books',
      priceLevel: '\$\$',
      isOpen: true,
      distance: '2.3 km',
      tags: ['Quiet', 'Books'],
      latitude: 21.0250,
      longitude: 105.8400,
    ),
    RestaurantItem(
      id: '4',
      name: 'Vi Ha Noi Restaurant & Cafe',
      category: 'Vietnamese • Pho • Traditional',
      rating: 4.6,
      ratingCount: 187,
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=600',
      description: 'Authentic • Local',
      priceLevel: '\$\$',
      isOpen: true,
      distance: '1.5 km',
      tags: ['Authentic', 'Local'],
      latitude: 21.0380,
      longitude: 105.8450,
    ),
    RestaurantItem(
      id: '5',
      name: 'Garden Coffee Doi Can',
      category: 'Cafe • Garden • Outdoor Seating',
      rating: 4.4,
      ratingCount: 421,
      imageUrl:
          'https://images.unsplash.com/photo-1505935428862-770b6f24f629?q=80&w=600',
      description: 'Garden • Relaxing',
      priceLevel: '\$\$',
      isOpen: true,
      distance: '1.9 km',
      tags: ['Garden', 'Relaxing'],
      latitude: 21.0340,
      longitude: 105.8280,
    ),
    RestaurantItem(
      id: '6',
      name: 'Vua. Ca Phe',
      category: 'Cafe • Specialty Coffee • Modern',
      rating: 4.9,
      ratingCount: 576,
      imageUrl:
          'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?q=80&w=600',
      description: 'Top Rated • Specialty',
      priceLevel: '\$\$',
      isOpen: true,
      distance: '1.1 km',
      tags: ['Top Rated', 'Specialty'],
      latitude: 21.0300,
      longitude: 105.8550,
    ),
    RestaurantItem(
      id: '7',
      name: 'Song Sanh Café & Roastery',
      category: 'Cafe • Roastery • Specialty Coffee',
      rating: 4.7,
      ratingCount: 398,
      imageUrl:
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=600',
      description: 'Roastery • Artisan',
      priceLevel: '\$\$',
      isOpen: true,
      distance: '1.8 km',
      tags: ['Roastery', 'Artisan'],
      latitude: 21.0290,
      longitude: 105.8480,
    ),
    RestaurantItem(
      id: '8',
      name: 'Highlands Coffee Quan Thanh',
      category: 'Cafe • Vietnamese Coffee • Beverages',
      rating: 4.1,
      ratingCount: 2145,
      imageUrl:
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=600',
      description: 'Popular • WiFi',
      priceLevel: '\$\$',
      isOpen: true,
      distance: '1.3 km',
      tags: ['Popular', 'WiFi'],
      latitude: 21.0370,
      longitude: 105.8420,
    ),
  ];

  @override
  @override
  Future<SearchResult> searchFoods(String query) async {
    // 1. Search in local mock data
    final lowerQuery = query.toLowerCase();
    final localResults = _mockFoods
        .where(
          (restaurant) =>
              restaurant.name.toLowerCase().contains(lowerQuery) ||
              restaurant.category.toLowerCase().contains(lowerQuery) ||
              (restaurant.description?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              restaurant.tags.any(
                (tag) => tag.toLowerCase().contains(lowerQuery),
              ),
        )
        .toList();

    // 2. Search in OSM (if query is long enough)
    if (query.length > 2) {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=vn',
        );

        // Add User-Agent as required by Nominatim
        final response = await http.get(
          url,
          headers: {'User-Agent': 'SmartFoodApp/1.0'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final osmResults = data.map((item) {
            return RestaurantItem(
              id: 'osm_${item['place_id']}',
              name:
                  item['display_name']?.split(',').first ?? 'Unknown Location',
              category: item['type'] ?? 'Place',
              rating: 4.0, // Default rating for OSM
              ratingCount: 10,
              imageUrl:
                  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=600', // Random food image
              description: item['display_name'],
              priceLevel: '\$\$',
              isOpen: true,
              distance: 'Unknown',
              tags: ['OSM Result'],
              latitude: double.parse(item['lat']),
              longitude: double.parse(item['lon']),
            );
          }).toList();

          localResults.addAll(osmResults);
        }
      } catch (e) {
        print('OSM Search Error: $e');
        // Ignore error and return local results
      }
    }

    return SearchResult(items: localResults);
  }

  @override
  Future<SearchResult> getAllFoods() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SearchResult(items: _mockFoods);
  }

  @override
  Future<RestaurantItem?> getFoodDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockFoods.firstWhere((restaurant) => restaurant.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<MenuItem>> getMenu(String restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock menu - Generic items for now
    return [
      MenuItem(
        id: '1',
        name: 'Signature Coffee',
        description: 'Best in town',
        price: 4.5,
        imageUrl:
            'https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=300',
      ),
      MenuItem(
        id: '2',
        name: 'Croissant',
        description: 'Buttery goodness',
        price: 3.0,
        imageUrl:
            'https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=300',
      ),
      MenuItem(
        id: '3',
        name: 'Pho Bo',
        description: 'Traditional Beef Noodle',
        price: 6.0,
        imageUrl:
            'https://images.unsplash.com/photo-1582878826618-c05326eff950?q=80&w=300',
      ),
    ];
  }
}
