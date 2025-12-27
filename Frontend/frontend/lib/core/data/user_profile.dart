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

  /// A human-readable Vietnamese summary suitable for sending to an AI.
  ///
  /// Notes:
  /// - Does NOT include any IDs (including userId, food IDs, restaurant IDs).
  /// - If a field is null/empty, returns `unknown` for that field.
  /// - Includes both timestamps as `Created` and `Last Modified`.
  String toVietnameseReadableText() {
    final buffer = StringBuffer();

    buffer.writeln('Hồ sơ người dùng');
    buffer.writeln('Cấp độ: $level');
    buffer.writeln('Số món đã ăn: $dishEaten');
    buffer.writeln('Số nhà hàng đã ghé: $restaurantVisited');
    buffer.writeln('Số điện thoại: ${_stringOrUnknown(phoneNumber)}');
    buffer.writeln('Nghề nghiệp: ${_stringOrUnknown(occupations)}');
    buffer.writeln('Địa chỉ: ${_stringOrUnknown(address)}');
    buffer.writeln('Biệt danh: ${_stringOrUnknown(nickname)}');
    buffer.writeln('Created: ${_dateTimeToReadableOrUnknown(createdAt)}');
    buffer.writeln('Last Modified: ${_dateTimeToReadableOrUnknown(updatedAt)}');

    return buffer.toString().trim();
  }

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

  static String _stringOrUnknown(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'unknown';
    return trimmed;
  }

  static String _dateTimeToReadableOrUnknown(DateTime? value) {
    if (value == null) return 'unknown';
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}
