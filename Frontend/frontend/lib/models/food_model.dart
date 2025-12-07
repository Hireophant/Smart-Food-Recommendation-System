/// Định nghĩa các model dùng trong app
/// Theo Guideline: Định nghĩa rõ Input/Output

/// Đại diện cho một mục ăn (Food Item)
class FoodItem {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String imageUrl; // Có thể là emoji hoặc URL thực
  final String? description;
  final double? price;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.imageUrl,
    this.description,
    this.price,
  });
}

/// Kết quả tìm kiếm từ Handler
class SearchResult {
  final List<FoodItem> items;
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
