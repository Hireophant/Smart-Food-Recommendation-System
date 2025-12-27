import '../models/food_model.dart';

/// Handler responsible for managing navigation history operations
abstract class NavigationHistoryHandler {
  List<RestaurantItem> getHistory();
  void addToHistory(RestaurantItem item);
  void clearHistory();
}

/// Implementation of [NavigationHistoryHandler] using in-memory storage (singleton)
class MockNavigationHistoryHandler implements NavigationHistoryHandler {
  static final MockNavigationHistoryHandler _instance =
      MockNavigationHistoryHandler._internal();

  factory MockNavigationHistoryHandler() {
    return _instance;
  }

  MockNavigationHistoryHandler._internal();

  // In-memory storage for navigation history
  final List<RestaurantItem> _navigationHistory = [];

  @override
  List<RestaurantItem> getHistory() {
    return List.unmodifiable(_navigationHistory);
  }

  @override
  void addToHistory(RestaurantItem item) {
    // Remove if exists to move to top
    _navigationHistory.removeWhere((element) => element.id == item.id);
    _navigationHistory.insert(0, item);

    // Limit to 20 items
    if (_navigationHistory.length > 20) {
      _navigationHistory.removeLast();
    }
  }

  @override
  void clearHistory() {
    _navigationHistory.clear();
  }
}
