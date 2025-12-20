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
}
