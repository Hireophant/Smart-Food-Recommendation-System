import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish_model.dart';
import '../handlers/query_system.dart';
import '../widgets/dish_card.dart';
import '../providers/theme_provider.dart';
import 'restaurant_list_page.dart';
import 'settings_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'chat_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final QuerySystem _querySystem = QuerySystem();
  List<DishItem> _dishes = [];
  bool _isLoading = true;
  final Set<String> _selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dishes = await _querySystem.getAllDishes();
    setState(() {
      _dishes = dishes;
      _isLoading = false;
    });
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }
    final results = await _querySystem.searchDishes(query);
    setState(() {
      _dishes = results;
    });
  }

  void _onFilterSelected(String filter, bool selected) {
    setState(() {
      if (selected) {
        _selectedFilters.add(filter);
      } else {
        _selectedFilters.remove(filter);
      }
      _isLoading = true;
    });
    _loadData();
  }

  void _showAdvancedFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bộ lọc nâng cao',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    context,
                    title: 'Hương vị',
                    options: ['Cay', 'Ít cay', 'Ngọt', 'Mặn', 'Chua', 'Đậm đà'],
                  ),
                  const SizedBox(height: 16),
                  _buildFilterSection(
                    context,
                    title: 'Sở thích & Chế độ',
                    options: [
                      'Healthy',
                      'Chay',
                      'Thực dưỡng',
                      'Nhiều đạm',
                      'Đồ ăn nhanh',
                      'Vỉa hè',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFilterSection(
                    context,
                    title: 'Loại ẩm thực',
                    options: [
                      'Việt Nam',
                      'Thái Lan',
                      'Nhật Bản',
                      'Hàn Quốc',
                      'Âu Mỹ',
                      'Trung Hoa',
                      'Khác',
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Áp dụng',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(
    BuildContext context, {
    required String title,
    required List<String> options,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: options.map((option) {
            final isSelected = _selectedFilters.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (bool selected) =>
                  _onFilterSelected(option, selected),
              backgroundColor: isSelected
                  ? Colors.deepOrange.shade100
                  : (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
              selectedColor: Colors.deepOrange.shade200,
              checkmarkColor: Colors.deepOrange.shade900,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.deepOrange.shade900
                    : (isDarkMode ? Colors.white70 : Colors.black87),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Colors.deepOrange
                      : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _onDishSelected(DishItem dish) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantListPage(dish: dish)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: MediaQuery.of(context).size.width < 600
            ? null
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tìm kiếm món ngon',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
        actions: [
          // Show Navigation Links ONLY on Desktop (> 600 width)
          if (MediaQuery.of(context).size.width >= 600) ...[
            TextButton(
              onPressed: () {},
              child: Text(
                "Trang chủ",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                );
              },
              child: Text(
                "Yêu thích",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
              child: Text(
                "Tài khoản",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
          // Show Icons on Mobile (< 600 width)
          if (MediaQuery.of(context).size.width < 600) ...[
            IconButton(
              icon: const Icon(Icons.favorite),
              tooltip: "Yêu thích",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: "Tài khoản",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).primaryColor,
            ),
            tooltip: themeProvider.isDarkMode ? 'Chế độ sáng' : 'Chế độ tối',
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Hero Section
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1920',
                        ),
                        fit: BoxFit.cover,
                        opacity: 0.3,
                      ),
                      color: Colors.deepOrange, // Orange theme
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepOrange.withValues(alpha: 0.8),
                                Colors.orangeAccent.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Khám phá món ngon",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 3),
                                      blurRadius: 8,
                                      color: Colors.black87,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Tìm kiếm theo hương vị và nhà hàng gần bạn",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 4,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar Overlay
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2C2C2C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: "Tìm món ăn (vd: phở, bún bò)...",
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Advanced Filter Button
                        ElevatedButton.icon(
                          onPressed: () => _showAdvancedFilters(context),
                          icon: const Icon(Icons.tune, color: Colors.white),
                          label: Text(
                            _selectedFilters.isEmpty
                                ? "Sử dụng bộ lọc nâng cao"
                                : "Bộ lọc (${_selectedFilters.length})",
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Display selected filters chips if any
                  if (_selectedFilters.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: _selectedFilters.map((filter) {
                            return Chip(
                              label: Text(filter),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _onFilterSelected(filter, false),
                              backgroundColor: Colors.deepOrange.shade50,
                              labelStyle: TextStyle(
                                color: Colors.deepOrange.shade900,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Dish Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Đang hiển thị ${_dishes.length} món ăn",
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 2;
                            if (constraints.maxWidth > 1000)
                              crossAxisCount = 4;
                            else if (constraints.maxWidth > 600)
                              crossAxisCount = 3;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _dishes.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,
                                    childAspectRatio: 0.7,
                                  ),
                              itemBuilder: (context, index) {
                                final item = _dishes[index];
                                return DishCard(
                                  item: item,
                                  onTap: () => _onDishSelected(item),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatPage()),
          );
        },
        backgroundColor: Colors
            .transparent, // Transparent to show icon shape if needed, or keeping orange
        elevation: 0,
        child: Image.asset(
          'assets/images/ai_icon_orange.png',
          width: 56,
          height: 56,
        ), // Use custom icon
      ),
    );
  }
}
