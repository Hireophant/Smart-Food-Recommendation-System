/// Định nghĩa các model dùng trong app
/// Theo Guideline: Định nghĩa rõ Input/Output
library;

/// Đại diện cho một nhà hàng/quán cafe (Restaurant Item)
/// Model đại diện cho một Nhà hàng hoặc Địa điểm ăn uống
class RestaurantItem {
  final String id;
  final String name;
  final String category; // e.g., "Cafe • Coffee • Beverages"
  final double rating;
  final int ratingCount;
  final String imageUrl; // URL ảnh (Network Image)
  final String address; // Địa chỉ nhà hàng
  final String? description;
  final String? priceLevel; // $ - $$$$
  final bool isOpen;
  final String distance; // e.g., "1.2 km"
  final String address; // Detailed address
  final List<String> tags; // e.g., ["Cozy", "Ba Dinh"]
  final double latitude; // Tọa độ Vĩ độ
  final double longitude; // Tọa độ Kinh độ

  RestaurantItem({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    this.ratingCount = 0,
    required this.imageUrl,
    required this.address,
    this.description,
    this.priceLevel,
    this.isOpen = true,
    this.distance = '0 km',
    this.address = '', // Default empty if not provided
    this.tags = const [],
    this.latitude = 21.0285, // Default Hanoi
    this.longitude = 105.8542,
  });
}

/// Model đại diện cho một món ăn trong Menu
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });
}

/// Kết quả tìm kiếm từ Handler
class SearchResult {
  final List<RestaurantItem> items;
  final bool isLoading;
  final String? error;

  SearchResult({required this.items, this.isLoading = false, this.error});

  /// Factory để tạo loading state
  factory SearchResult.loading() {
    return SearchResult(items: [], isLoading: true);
  }

  /// Factory để tạo error state
  factory SearchResult.error(String message) {
    return SearchResult(items: [], error: message);
  }

  /// Factory để tạo empty state
  factory SearchResult.empty() {
    return SearchResult(items: []);
  }
}
