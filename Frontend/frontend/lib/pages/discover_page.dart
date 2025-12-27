import 'package:flutter/material.dart';

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

import 'restaurant_list_page.dart';
import 'restaurant_detail_page.dart';

/// Tag mặc định cho filter
final List<FilterTag> defaultTags = [
  FilterTag(id: 'vietnamese', label: 'Món Việt', icon: Icons.restaurant),
  FilterTag(id: 'asian', label: 'Món Á', icon: Icons.ramen_dining),
  FilterTag(id: 'western', label: 'Món Tây', icon: Icons.fastfood),
  FilterTag(id: 'Chua', label: 'Chua', icon: Icons.local_bar), // Lemon/Drink
  FilterTag(id: 'Cay', label: 'Cay', icon: Icons.whatshot), // Spicy
  FilterTag(id: 'Mặn', label: 'Mặn', icon: Icons.grain), // Salt
  FilterTag(id: 'Ngọt', label: 'Ngọt', icon: Icons.cake), // Sweet
  FilterTag(id: 'Béo', label: 'Béo', icon: Icons.bubble_chart), // Fatty
  FilterTag(id: 'cafe', label: 'Cafe', icon: Icons.local_cafe),
  FilterTag(id: 'dessert', label: 'Tráng miệng', icon: Icons.icecream),
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
    // No redundant ThemeProvider check if not used for toggling anymore here,
    // but useful for checking isDarkMode for UI colors.
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // No AppBar - Full screen experience
      body: Stack(
        children: [
          Column(
            children: [
              // Map Section - Taller for better view
              SizedBox(
                height:
                    MediaQuery.of(context).size.height * 0.45, // 45% of screen
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: LatLng(10.762622, 106.660172),
                        initialZoom: 13.0,
                        minZoom: 5.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: isDarkMode
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
                              width: 48, // Larger markers
                              height: 48,
                              child: GestureDetector(
                                onTap: () => _onMarkerTap(restaurant),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons
                                        .restaurant, // Or custom icon based on category
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // Loading Indicator
                    if (_isMapLoading)
                      Container(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.5)
                            : Colors.white.withOpacity(0.5),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),

              // Spacing matching the overlap
              SizedBox(height: 0),
            ],
          ),

          // Draggable/Scrollable Content Sheet
          // Using a simple DraggableScrollableSheet for the "Apple Maps" feel
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.55,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar for visual cue
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Kết quả tìm kiếm'
                                : 'Gợi ý cho bạn',
                            style: TextStyle(
                              fontSize: 22, // Apple Large Title
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${_searchQuery.isNotEmpty ? _filteredRestaurants.length : _dishes.length} ${_searchQuery.isNotEmpty ? "nhà hàng" : "món ăn"}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_searchQuery.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = _filteredRestaurants[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: SizedBox(
                                height: 260, // Taller for better visual
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
                        )
                      else
                        // Dish Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 2;
                            if (constraints.maxWidth > 600) crossAxisCount = 3;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _dishes.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.72,
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

                      // Bottom padding for navigation bar
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating Header (Search & Filter)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchBarWidget(
                  onSearch: _onSearch,
                  onFilterTap: _showFilterSheet,
                ),
                if (_selectedTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _selectedTags.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedTags.remove(tag);
                                _applyFilters();
                              });
                            },
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide.none,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
