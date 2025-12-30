/// Helper để tạo URL ảnh món ăn phù hợp với tên món từ Unsplash
/// 
/// Sử dụng Unsplash API để lấy ảnh chất lượng cao
/// Map các từ khóa trong tên món sang query Unsplash phù hợp
class DishImageHelper {
  // Base URL cho Unsplash
  static const String _unsplashBase = 'https://images.unsplash.com/photo';

  /// Map keyword trong tên món -> Unsplash photo ID
  static final Map<String, String> _dishImageMap = {
    // Vietnamese dishes
    'phở': '1623246836362-91c8d86fae1e',  // Phở bò
    'bún': '1559003452-08c5dd8e9a1e',     // Bún bowl
    'cơm': '1512003867696-6d5ce6835040',  // Cơm tấm
    'bánh mì': '1591648032270-0a2e65f5c8dd', // Bánh mì
    'gỏi': '1546069901-ba9599a7e63c',     // Gỏi cuốn
    'nem': '1546069901-ba9599a7e63c',     // Spring rolls
    'chả': '1555963258-1067669b11dd',     // Chả giò
    'lẩu': '1631452180543-3e98a8d52d45',  // Hot pot
    
    // Common Vietnamese food keywords
    'sườn': '1512003867696-6d5ce6835040', // Cơm sườn
    'bò': '1623246836362-91c8d86fae1e',   // Beef dishes
    'gà': '1598515214146-dcf5e0bc5a8a',   // Chicken
    'hải sản': '1559181567-a1e0e30afc1e', // Seafood
    'tôm': '1559181567-a1e0e30afc1e',     // Shrimp
    'cá': '1559181567-a1e0e30afc1e',      // Fish
    'chay': '1540189549336-e6e99eba5ecd', // Vegetarian
    
    // International
    'pizza': '1565299624946-b28f40a0ae38',
    'burger': '1568901346375-23c9450c58cd',
    'pasta': '1621996346565-e3dbc646d9a9',
    'sushi': '1579584425555-c3ce17fd4351',
    'ramen': '1569718212165-3b8278d5f624',
    'steak': '1544025162-d76694265947',
    'salad': '1512621776951-a57141f2eefd',
    'sandwich': '1528735602780-2552fd87c9c2',
    'coffee': '1495474472287-4d71bcdd2085',
    'trà': '1556679343-c7306c1976bc',     // Tea
    'cafe': '1495474472287-4d71bcdd2085',
    
    // Desserts
    'kem': '1563805042-7684c019e1cb',     // Ice cream
    'bánh ngọt': '1578985545082-367b13c64ee9', // Dessert
    'chè': '1563805042-7684c019e1cb',     // Chè
  };

  /// Lấy URL ảnh phù hợp với tên món ăn
  /// 
  /// Ưu tiên:
  /// 1. Tìm keyword match trong tên món
  /// 2. Fallback: Dùng ảnh mặc định (food generic)
  static String getImageUrl(String dishName) {
    final nameLower = dishName.toLowerCase();
    
    // Tìm keyword match đầu tiên
    for (var entry in _dishImageMap.entries) {
      if (nameLower.contains(entry.key)) {
        return '$_unsplashBase-${entry.value}?w=400&q=80';
      }
    }
    
    // Fallback: Generic food image
    return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80';
  }

  /// Lấy URL ảnh với kích thước tùy chỉnh
  static String getImageUrlWithSize(String dishName, {int width = 400, int quality = 80}) {
    final baseUrl = getImageUrl(dishName);
    // Thay thế params
    return baseUrl.replaceFirst(RegExp(r'w=\d+'), 'w=$width')
                  .replaceFirst(RegExp(r'q=\d+'), 'q=$quality');
  }

  /// Lấy nhiều ảnh backup cho carousel/gallery
  static List<String> getMultipleImages(String dishName, {int count = 3}) {
    final List<String> images = [];
    final primary = getImageUrl(dishName);
    images.add(primary);
    
    // Add more generic food images as backup
    if (count > 1) {
      final backups = [
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&q=80',
        'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400&q=80',
        'https://images.unsplash.com/photo-1540189549336-e6e99eba5ecd?w=400&q=80',
      ];
      
      for (var i = 1; i < count && i <= backups.length; i++) {
        images.add(backups[i - 1]);
      }
    }
    
    return images;
  }
}
