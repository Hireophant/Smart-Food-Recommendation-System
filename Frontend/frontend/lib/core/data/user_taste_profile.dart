class UserTasteProfile {
  const UserTasteProfile({
    required this.userId,
    this.cuisines,
    this.spiceLevel,
    this.dietaryRestrictions,
    this.allergies,
    this.pricePreference,
    this.favoriteDishes,
    this.dislikes,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final List<String>? cuisines;
  final String? spiceLevel;
  final List<String>? dietaryRestrictions;
  final List<String>? allergies;
  final String? pricePreference;
  final List<String>? favoriteDishes;
  final List<String>? dislikes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// A human-readable Vietnamese summary suitable for sending to an AI.
  ///
  /// Notes:
  /// - Does NOT include any IDs (including userId).
  /// - If a field is null/empty, returns `unknown` for that field.
  /// - Includes both timestamps as `Created` and `Last Modified`.
  String toVietnameseReadableText() {
    final buffer = StringBuffer();

    buffer.writeln('Hồ sơ khẩu vị người dùng');
    buffer.writeln(
      'Ẩm thực ưa thích: ${_stringListToReadableOrUnknown(cuisines)}',
    );
    buffer.writeln('Mức độ cay: ${_stringOrUnknown(spiceLevel)}');
    buffer.writeln(
      'Hạn chế ăn uống: ${_stringListToReadableOrUnknown(dietaryRestrictions)}',
    );
    buffer.writeln('Dị ứng: ${_stringListToReadableOrUnknown(allergies)}');
    buffer.writeln('Mức giá ưu tiên: ${_stringOrUnknown(pricePreference)}');
    buffer.writeln(
      'Món yêu thích: ${_stringListToReadableOrUnknown(favoriteDishes)}',
    );
    buffer.writeln('Không thích: ${_stringListToReadableOrUnknown(dislikes)}');
    buffer.writeln('Created: ${_dateTimeToReadableOrUnknown(createdAt)}');
    buffer.writeln('Last Modified: ${_dateTimeToReadableOrUnknown(updatedAt)}');

    return buffer.toString().trim();
  }

  static UserTasteProfile fromJson(Map<String, dynamic> json) {
    return UserTasteProfile(
      userId: (json['user_id'] as String).toString(),
      cuisines: _stringListOrNull(json['cuisines']),
      spiceLevel: json['spice_level'] as String?,
      dietaryRestrictions: _stringListOrNull(json['dietary_restrictions']),
      allergies: _stringListOrNull(json['allergies']),
      pricePreference: json['price_preference'] as String?,
      favoriteDishes: _stringListOrNull(json['favorite_dishes']),
      dislikes: _stringListOrNull(json['dislikes']),
      createdAt: _dateTimeOrNull(json['created_at']),
      updatedAt: _dateTimeOrNull(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'cuisines': cuisines,
      'spice_level': spiceLevel,
      'dietary_restrictions': dietaryRestrictions,
      'allergies': allergies,
      'price_preference': pricePreference,
      'favorite_dishes': favoriteDishes,
      'dislikes': dislikes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static List<String>? _stringListOrNull(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return null;
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

  static String _stringListToReadableOrUnknown(List<String>? values) {
    if (values == null) return 'unknown';
    final cleaned = values
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (cleaned.isEmpty) return 'unknown';
    return cleaned.join(', ');
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
