class Food {
  const Food({
    required this.id,
    required this.dishName,
    required this.category,
    required this.kieuTenMon,
    required this.loai,
    required this.tags,
  });

  final String id;
  final String dishName;
  final String category;
  final String kieuTenMon;
  final String loai;
  final List<String> tags;

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id']?.toString() ?? '',
      dishName: json['dish_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      kieuTenMon: json['kieu_ten_mon']?.toString() ?? '',
      loai: json['loai']?.toString() ?? '',
      tags:
          (json['tags'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }
}

class FoodSearchParams {
  FoodSearchParams({
    this.query,
    this.category,
    this.loai,
    this.kieuTenMon,
    this.tags,
    this.limit = 20,
  });

  final String? query;
  final String? category;
  final String? loai;
  final String? kieuTenMon;
  final String? tags;
  final int limit;

  void validate() {
    if (limit < 1 || limit > 200) {
      throw ArgumentError('limit must be between 1 and 200.');
    }
  }

  Map<String, Object?> toQuery() {
    return {
      'query': query,
      'category': category,
      'loai': loai,
      'kieu_ten_mon': kieuTenMon,
      'tags': tags,
      'limit': limit,
    };
  }
}

class FoodsByIdsParams {
  FoodsByIdsParams({required this.ids, this.limit = 100});

  final List<String> ids;
  final int limit;

  void validate() {
    if (ids.isEmpty) {
      throw ArgumentError('ids must contain at least 1 item.');
    }
    if (ids.length > 200) {
      throw ArgumentError('ids must contain at most 200 items.');
    }
    if (limit < 1 || limit > 200) {
      throw ArgumentError('limit must be between 1 and 200.');
    }
    final cleaned = ids
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.length != ids.length) {
      throw ArgumentError('ids cannot contain empty items.');
    }
  }

  Map<String, Object?> toQuery() {
    return {
      'ids': ids.map((e) => e.trim()).toList(growable: false),
      'limit': limit,
    };
  }
}
