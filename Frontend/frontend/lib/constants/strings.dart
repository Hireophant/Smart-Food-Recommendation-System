/// Tất cả các string constants dùng trong UI
/// Theo Guideline: Không hardcode text trong code giao diện
class UIStrings {
  // AppBar
  static const String appBarTitle = 'Food Search';

  // Search Bar
  static const String searchHint = 'Search for food or cuisine...';
  static const String clearButtonTooltip = 'Clear search';

  // Empty State
  static const String emptyStateIcon = '🔍';
  static const String emptyStateTitle = 'No foods found';
  static const String emptyStateSubtitle =
      'Try searching for a different cuisine or food name';

  // SnackBar
  static const String itemSelectedPrefix = 'Selected: ';

  // Rating
  static const String ratingIcon = '⭐';

  // Loading State
  static const String loadingMessage = 'Loading foods...';

  // Error State
  static const String errorMessage = 'Something went wrong';
  static const String errorRetryButton = 'Retry';
}
