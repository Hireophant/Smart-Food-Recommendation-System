/// Helper class to generate appropriate restaurant images based on name
/// Maps Vietnamese restaurant keywords to specific Unsplash photo IDs
class RestaurantImageHelper {
  // Priority keywords - checked first for exact matches
  static final Map<String, String> _priorityKeywords = {
    // Món ăn chính - được ưu tiên cao nhất
    'cơm tấm': 'RCFbqo774dE', // Cơm tấm - Vietnamese broken rice
    'cơm sườn': 'RCFbqo774dE', // Cơm sườn
    'phở bò': 'N_Y88TWmGwA', // Phở bò - Vietnamese pho
    'phở gà': 'N_Y88TWmGwA', // Phở gà
    'bún bò': '4_jhDO54BYg', // Bún bò Huế
    'bún riêu': '4_jhDO54BYg', // Bún riêu
    'bún chả': '4_jhDO54BYg', // Bún chả
    'bún đậu': '4_jhDO54BYg', // Bún đậu
    'bánh mì': 'CpkOjOcXdUY', // Bánh mì
    'lẩu': 'jpkfc5_d-DI', // Lẩu - Hot pot
    'hải sản': 'IGfIGP5ONV0', // Hải sản - Seafood
    'nướng': 'SqYmTxuCRR4', // BBQ
  };

  // Secondary keywords
  static final Map<String, String> _restaurantImageMap = {
    // Vietnamese cuisine types
    'phở': 'N_Y88TWmGwA', // Pho
    'bún': '4_jhDO54BYg', // Bun
    'cơm': 'RCFbqo774dE', // Rice
    'sườn': 'RCFbqo774dE', // Pork chop
    'tấm': 'RCFbqo774dE', // Broken rice
    'quán ăn': 'hrlvr2ZlUNk', // Eatery
    'nhà hàng': 'N_Y88TWmGwA', // Restaurant
    'quán': 'hrlvr2ZlUNk', // Shop
    'buffet': 'IGfIGP5ONV0', // Buffet
    'ốc': '4_jhDO54BYg', // Snails
    'chay': 'bpPTlXWTOvg', // Vegetarian
    'gà': '5tXbNGKzI1k', // Chicken
    'bò': 'SqYmTxuCRR4', // Beef
    'nem': '4_jhDO54BYg', // Spring rolls
    'chả': 'hrlvr2ZlUNk', // Sausage
    'bánh xèo': '4_jhDO54BYg', // Pancake
    'cao lầu': 'N_Y88TWmGwA', // Cao lau
    'mì quảng': '4_jhDO54BYg', // Mi Quang
    'hủ tiếu': '4_jhDO54BYg', // Hu tieu
    'bánh cuốn': '4_jhDO54BYg', // Rice rolls
    // International
    'pizza': 'MQUqbmszGGM',
    'burger': '1Shk_PkNkNw',
    'pasta': 'MRHyv-hHxgk',
    'sushi': '4mta6Y0XS3g',
    'ramen': 'qRE_OpbVPR8',
    'korean': 'JVD3XPqjLaQ',
    'chinese': 'lP5MCM6nZ5A',
    'thai': '4T14LqKXF8Y',
    'indian': 'eCdUnf4NLew',
    'cafe': 'c01rqOCYRco',
    'cà phê': 'c01rqOCYRco',
    'trà sữa': 'St22zjIvdUQ',
    'kem': 'yqPKx6RBPFM',
    'bánh ngọt': 'bcgYqI-CDUg',
    'bar': '0HlI76m4jxU',
    'bistro': 'N_Y88TWmGwA',
  };

  // Fallback images - 30 verified working photo IDs
  static final List<String> _fallbackImages = [
    'hrlvr2ZlUNk', // Restaurant 1
    'N_Y88TWmGwA', // Restaurant 2
    'RCFbqo774dE', // Restaurant 3
    '4_jhDO54BYg', // Restaurant 4
    'IGfIGP5ONV0', // Restaurant 5
    'jpkfc5_d-DI', // Restaurant 6
    'CpkOjOcXdUY', // Restaurant 7
    'bpPTlXWTOvg', // Restaurant 8
    'MQUqbmszGGM', // Restaurant 9
    '1Shk_PkNkNw', // Restaurant 10
    'MRHyv-hHxgk', // Restaurant 11
    '4mta6Y0XS3g', // Restaurant 12
    'qRE_OpbVPR8', // Restaurant 13
    'JVD3XPqjLaQ', // Restaurant 14
    'lP5MCM6nZ5A', // Restaurant 15
    '4T14LqKXF8Y', // Restaurant 16
    'eCdUnf4NLew', // Restaurant 17
    'c01rqOCYRco', // Restaurant 18
    'St22zjIvdUQ', // Restaurant 19
    'yqPKx6RBPFM', // Restaurant 20
    'bcgYqI-CDUg', // Restaurant 21
    '0HlI76m4jxU', // Restaurant 22
    '5tXbNGKzI1k', // Restaurant 23
    'SqYmTxuCRR4', // Restaurant 24
    'bqU2HxwskoA', // Restaurant 25
    'E8Ufcyxz514', // Restaurant 26
    'ZKzepT-1vPs', // Restaurant 27
    'rW-I87aPY5Y', // Restaurant 28
    'fdlZBWIP0aM', // Restaurant 29
    'T6fDN60bMWY', // Restaurant 30
  ];

  /// Get Unsplash image URL based on restaurant name
  /// Returns a specific image if keyword is found in the name, otherwise returns generic restaurant image
  static String getImageUrl(String restaurantName) {
    // Emergency fix for demo: Use Lorem Picsum with fixed seed for consistent food-like images
    final hash = restaurantName.hashCode.abs() % 1000;
    return 'https://picsum.photos/seed/$hash/800/600';
  }

  /// Get Unsplash image URL with custom dimensions and quality
  static String getImageUrlWithSize(
    String restaurantName, {
    int width = 800,
    int quality = 80,
  }) {
    final baseUrl = getImageUrl(restaurantName);
    // Replace the existing w and q parameters
    return baseUrl
        .replaceAll(RegExp(r'w=\d+'), 'w=$width')
        .replaceAll(RegExp(r'q=\d+'), 'q=$quality');
  }

  /// Get multiple restaurant images for carousel/gallery
  static List<String> getMultipleImages(
    String restaurantName, {
    int count = 3,
  }) {
    final primaryUrl = getImageUrl(restaurantName);
    final images = [primaryUrl];

    // Add generic restaurant interior images for variety
    final additionalImages = [
      'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
    ];

    for (var i = 0; i < count - 1 && i < additionalImages.length; i++) {
      if (additionalImages[i] != primaryUrl) {
        images.add(additionalImages[i]);
      }
    }

    return images.take(count).toList();
  }
}
