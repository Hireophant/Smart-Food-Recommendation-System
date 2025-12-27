import '../handlers/food_search_handler.dart';
import '../models/food_model.dart';
import '../models/dish_model.dart';
import '../models/chat_message_model.dart';
import 'chat_handler.dart';

/// Query System - Trung tâm điều phối (Facade Pattern)
///
/// Vai trò:
/// - Đứng giữa UI và các Handlers logic (Backend/Core).
/// - UI chỉ cần gọi hàm của QuerySystem, không cần biết Handler nào xử lý.
/// - Giúp dễ dàng thay thế logic bên dưới (ví dụ: chuyển từ Mock sang Real API) mà không cần sửa code UI.
///
/// Xem thêm: Guideline.md -> Mục 6. Query System
class QuerySystem {
  // Singleton pattern (Optional but recommended for central access)
  static final QuerySystem _instance = QuerySystem._internal();
  factory QuerySystem() => _instance;
  QuerySystem._internal();

  // Dependency Injection could be used here for better testing
  // For now, we initialize the default handler.
  final FoodSearchHandler _foodHandler = FoodSearchHandlerImpl();

  // =========================================================================
  // DISH & DISCOVERY
  // =========================================================================

  /// Lấy danh sách món ăn đề xuất (Cho màn hình Home/DiscoverPage)
  Future<List<DishItem>> getAllDishes() {
    return _foodHandler.getAllDishes();
  }

  /// Tìm kiếm món ăn theo tên hoặc tag (Cho thanh search ở Home)
  Future<List<DishItem>> searchDishes(String query) {
    return _foodHandler.searchDishes(query);
  }

  /// Tìm kiếm món ăn hoặc nhà hàng (Cho chức năng Search)
  Future<SearchResult> search(String query) {
    return _foodHandler.searchFoods(query);
  }

  // =========================================================================
  // RESTAURANTS & MENU
  // =========================================================================

  /// Tìm nhà hàng bán món cụ thể (Khi chọn món ở Home -> RestaurantListPage)
  Future<SearchResult> findRestaurantsByDish(String dishName) {
    // Logic phức tạp hơn có thể nằm ở đây (ví dụ: logging, analytics)
    return _foodHandler.getRestaurantsByDish(dishName);
  }

  /// Lấy menu của nhà hàng (Cho RestaurantDetailPage)
  //Future<List<MenuItem>> getMenu(String restaurantId) {
    //return _foodHandler.getMenu(restaurantId);
  //}

  /// Lấy chi tiết thông tin nhà hàng (Nếu cần thiết cho Deep Link hoặc reload)
  //Future<RestaurantItem?> getRestaurantDetails(String restaurantId) {
    //return _foodHandler.getFoodDetails(restaurantId);
  //}
  // =========================================================================
  // CHATBOT
  // =========================================================================

  // =========================================================================
  // CHATBOT
  // =========================================================================

  /// Gửi tin nhắn tới AI Chatbot
  Future<BotResponse> sendChatMessage(String message) {
    return ChatHandler.sendMessage(message);
  }

  /// Lấy tin nhắn chào mừng
  BotResponse getWelcomeMessage() {
    return ChatHandler.getWelcomeMessage();
  }
}
