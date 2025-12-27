class UserProfile {
  const UserProfile({
    required this.userId,
    required this.favoritesFoodIds,
    required this.favoritesRestaurantsIds,
    required this.level,
    required this.dishEaten,
    required this.restaurantVisited,
    this.phoneNumber,
    this.occupations,
    this.address,
    this.nickname,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final List<String> favoritesFoodIds;
  final List<String> favoritesRestaurantsIds;
  final int level;
  final int dishEaten;
  final int restaurantVisited;
  final String? phoneNumber;
  final String? occupations;
  final String? address;
  final String? nickname;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static UserProfile fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: (json['user_id'] as String).toString(),
      favoritesFoodIds: _stringListOrEmpty(json['favorites_food_ids']),
      favoritesRestaurantsIds: _stringListOrEmpty(
        json['favorites_restaurants_ids'],
      ),
      level: _intOrDefault(json['level'], 1),
      dishEaten: _intOrDefault(json['dish_eaten'], 0),
      restaurantVisited: _intOrDefault(json['restaurant_visited'], 0),
      phoneNumber: json['phone_number'] as String?,
      occupations: json['occupations'] as String?,
      address: json['address'] as String?,
      nickname: json['nickname'] as String?,
      createdAt: _dateTimeOrNull(json['created_at']),
      updatedAt: _dateTimeOrNull(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'favorites_food_ids': favoritesFoodIds,
      'favorites_restaurants_ids': favoritesRestaurantsIds,
      'level': level,
      'dish_eaten': dishEaten,
      'restaurant_visited': restaurantVisited,
      'phone_number': phoneNumber,
      'occupations': occupations,
      'address': address,
      'nickname': nickname,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static List<String> _stringListOrEmpty(dynamic value) {
    if (value == null) return const <String>[];
    if (value is List) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  static int _intOrDefault(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime? _dateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
