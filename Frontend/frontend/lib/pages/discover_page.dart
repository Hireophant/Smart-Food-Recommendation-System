import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/dish_model.dart';
import '../models/food_model.dart';
import '../models/filter_tag_model.dart';
import '../handlers/query_system.dart';
import '../widgets/dish_card.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/advanced_filter_sheet.dart';
import '../providers/theme_provider.dart';
import 'restaurant_list_page.dart';
import 'restaurant_detail_page.dart';
import 'favorites_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';

/// Tag mặc định cho filter
final List<FilterTag> defaultTags = [
  FilterTag(id: 'vietnamese', label: 'Món Việt', icon: Icons.restaurant),
  FilterTag(id: 'asian', label: 'Món Á', icon: Icons.ramen_dining),
  FilterTag(id: 'western', label: 'Món Tây', icon: Icons.fastfood),
  FilterTag(id: 'cafe', label: 'Cafe', icon: Icons.local_cafe),
  FilterTag(id: 'dessert', label: 'Tráng miệng', icon: Icons.cake),
  FilterTag(id: 'vegan', label: 'Chay', icon: Icons.spa),
  FilterTag(id: 'cheap', label: 'Bình dân', icon: Icons.attach_money),
  FilterTag(id: 'luxury', label: 'Cao cấp', icon: Icons.diamond),
  FilterTag(id: 'cozy', label: 'Ấm cúng', icon: Icons.favorite),
  FilterTag(id: 'family', label: 'Gia đình', icon: Icons.family_restroom),
];

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // Use QuerySystem instead of direct Handler
  final QuerySystem _querySystem = QuerySystem(); // Facade
  final MapController _mapController = MapController();

  List<DishItem> _dishes = [];
  List<RestaurantItem> _allRestaurants = [];
  List<RestaurantItem> _filteredRestaurants = [];
  List<String> _selectedTags = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isMapLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('DiscoverPage: initState called. Starting data load...');
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      debugPrint('DiscoverPage: Fetching dishes...');
      // Fetch dishes via Query System
      final dishes = await _querySystem.getAllDishes();
      debugPrint('DiscoverPage: Dishes fetched (${dishes.length} items)');

      // Fetch restaurants for map
      final restaurantsResult = await _querySystem.search('all');
      debugPrint(
        'DiscoverPage: Restaurants fetched (${restaurantsResult.items.length} items)',
      );

      if (mounted) {
        setState(() {
          _dishes = dishes;
          _allRestaurants = restaurantsResult.items;
          _filteredRestaurants = restaurantsResult.items;
          _isLoading = false;
        });
        debugPrint('DiscoverPage: Loading complete, UI updated.');
      }
    } catch (e, stack) {
      debugPrint('DiscoverPage Error: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    // Simulate map loading delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isMapLoading = false;
        });
      }
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        // Filter theo search query
        final matchesSearch =
            _searchQuery.isEmpty ||
            restaurant.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            restaurant.category.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        // Filter theo tags
        final matchesTags =
            _selectedTags.isEmpty ||
            _selectedTags.any(
              (tag) => restaurant.tags.any(
                (restaurantTag) =>
                    restaurantTag.toLowerCase().contains(tag.toLowerCase()),
              ),
            );

        return matchesSearch && matchesTags;
      }).toList();
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFilterSheet(
        availableTags: defaultTags,
        selectedTagIds: _selectedTags,
        onApplyFilter: (tags) {
          setState(() {
            _selectedTags = tags;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _onMarkerTap(RestaurantItem restaurant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRestaurantQuickView(restaurant),
    );
  }

  Widget _buildRestaurantQuickView(RestaurantItem restaurant) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: restaurant.imageUrl.startsWith('http')
                ? Image.network(
                    restaurant.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 50),
                    ),
                  )
                : Image.asset(
                    restaurant.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 50),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            restaurant.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            restaurant.category,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                '${restaurant.rating} (${restaurant.ratingCount})',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.location_on,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                restaurant.distance,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RestaurantDetailPage(restaurant: restaurant),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Xem chi tiết'),
            ),
          ),
        ],
      ),
    );
  }

  void _onDishSelected(DishItem dish) {
    // Navigate to Restaurant List Page first
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1ABC9C), Color(0xFF16A085)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 22,
              ),
            ),
            if (MediaQuery.of(context).size.width > 600) ...[
              const SizedBox(width: 10),
              const Text(
                'Gợi Ý Món Ngon',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ],
        ),
        actions: [
          // Profile Avatar Button (New)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
                ),
              ),
            ),
          ),

          // Home Button với background
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.grey[800]!.withValues(alpha: 0.6) 
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.home,
                color: Color(0xFFFF6B35),
                size: 24,
              ),
              tooltip: 'Trang chủ',
              onPressed: () {
                // Already on home page
              },
            ),
          ),
          const SizedBox(width: 8),
          // Favorites Button với background
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.grey[800]!.withValues(alpha: 0.6) 
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.favorite,
                color: Colors.red[400],
                size: 24,
              ),
              tooltip: 'Yêu thích',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Theme Toggle Button (Sun/Moon) với background rõ ràng
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.grey[800]!.withValues(alpha: 0.6) 
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: themeProvider.isDarkMode ? Colors.amber[400] : Colors.grey[800],
                size: 24,
              ),
              tooltip: themeProvider.isDarkMode ? 'Chế độ sáng' : 'Chế độ tối',
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
          ),
          // Chatbot Button với icon đẹp hơn
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            tooltip: 'Trợ lý ảo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
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
                  // Map Section with Search & Filter
                  SizedBox(
                    height: 400,
                    child: Stack(
                      children: [
                        // Map
                        FlutterMap(
                          mapController: _mapController,
                          options: const MapOptions(
                            initialCenter: LatLng(
                              10.762622,
                              106.660172,
                            ), // Ho Chi Minh City
                            initialZoom: 12.0,
                            minZoom: 5.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                                  : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.foodfinder.app',
                            ),
                            MarkerLayer(
                              markers: _filteredRestaurants.map((restaurant) {
                                return Marker(
                                  point: LatLng(
                                    restaurant.latitude,
                                    restaurant.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () => _onMarkerTap(restaurant),
                                    child: Icon(
                                      Icons.location_on,
                                      color: Theme.of(context).primaryColor,
                                      size: 40,
                                      shadows: const [
                                        Shadow(
                                          blurRadius: 3,
                                          color: Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        // Map Loading Indicator
                        if (_isMapLoading)
                          Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.7),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Đang tải bản đồ...',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Search Bar & Filter Overlay
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            children: [
                              SearchBarWidget(
                                onSearch: _onSearch,
                                onFilterTap: _showFilterSheet,
                              ),
                              if (_selectedTags.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedTags.map((tag) {
                                      return Chip(
                                        label: Text(
                                          tag,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 16,
                                        ),
                                        onDeleted: () {
                                          setState(() {
                                            _selectedTags.remove(tag);
                                            _applyFilters();
                                          });
                                        },
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.1),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Results Count at Bottom
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[850]!.withValues(alpha: 0.95)
                                  : Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              "${_filteredRestaurants.length} nhà hàng",
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Conditional Body: Search Results (Restaurants) OR Dish Grid
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tìm thấy ${_filteredRestaurants.length} nhà hàng phù hợp",
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredRestaurants.length,
                            itemBuilder: (context, index) {
                              final restaurant = _filteredRestaurants[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: SizedBox(
                                  height: 240,
                                  child: RestaurantCard(
                                    item: restaurant,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RestaurantDetailPage(
                                            restaurant: restaurant,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    )
                  else
                    // Default Dish Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hiển thị ${_dishes.length} món ăn",
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Responsive Grid
                              int crossAxisCount = 2;
                              if (constraints.maxWidth > 1000) {
                                crossAxisCount = 4;
                              } else if (constraints.maxWidth > 600) {
                                crossAxisCount = 3;
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _dishes.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                      childAspectRatio:
                                          0.75, // Taller cards for image + content
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
    );
  }
}
