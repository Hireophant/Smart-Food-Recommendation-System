import 'package:flutter/material.dart';
import 'constants/strings.dart';
import 'handlers/food_search_handler.dart';
import 'models/food_model.dart';
import 'widgets/food_widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: UIStrings.appBarTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const FoodSearchPage(),
    );
  }
}

class FoodSearchPage extends StatefulWidget {
  const FoodSearchPage({super.key});

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  late final FoodSearchHandler _handler;
  final TextEditingController _searchController = TextEditingController();
  SearchResult _searchResult = SearchResult.empty();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Handler - hiện tại là Mock, sau thay bằng API thực
    _handler = MockFoodSearchHandler();
    _loadAllFoods();
    _searchController.addListener(_onSearchChanged);
  }

  /// Tải tất cả các món ăn khi app khởi động
  Future<void> _loadAllFoods() async {
    setState(() => _isSearching = true);
    try {
      final result = await _handler.getAllFoods();
      setState(() => _searchResult = result);
    } catch (e) {
      setState(() => _searchResult = SearchResult.error(e.toString()));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  /// Tìm kiếm khi user gõ trong search bar
  void _onSearchChanged() async {
    final query = _searchController.text;

    setState(() => _isSearching = true);

    try {
      final result = await _handler.searchFoods(query);
      setState(() => _searchResult = result);
    } catch (e) {
      setState(() => _searchResult = SearchResult.error(e.toString()));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    _loadAllFoods();
  }

  /// Xử lý khi user click vào một mục ăn
  void _onFoodItemTap(FoodItem food) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${UIStrings.itemSelectedPrefix}${food.name}'),
        duration: const Duration(seconds: 1),
      ),
    );
    // TODO: Thêm logic điều hướng đến trang chi tiết sản phẩm sau
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(UIStrings.appBarTitle),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          FoodSearchBar(
            controller: _searchController,
            onChanged: (_) => _onSearchChanged(),
            onClear: _clearSearch,
          ),
          // Content Area
          Expanded(child: _buildContentArea()),
        ],
      ),
    );
  }

  /// Build content area dựa trên trạng thái
  Widget _buildContentArea() {
    // Loading state
    if (_isSearching && _searchResult.items.isEmpty) {
      return const LoadingState();
    }

    // Error state
    if (_searchResult.error != null) {
      return ErrorState(message: _searchResult.error, onRetry: _loadAllFoods);
    }

    // Empty state
    if (_searchResult.items.isEmpty) {
      return const EmptySearchState();
    }

    // Food list
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _searchResult.items.length,
      itemBuilder: (context, index) {
        final food = _searchResult.items[index];
        return FoodItemCard(food: food, onTap: () => _onFoodItemTap(food));
      },
    );
  }
}
