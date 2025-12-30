import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/core/gps/gps.dart';
import 'package:latlong2/latlong.dart';
import '../models/filter_tag_model.dart';
import '../models/food_model.dart';
import '../handlers/query_system.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/advanced_filter_sheet.dart';

import 'restaurant_detail_page.dart';

/// Tag mặc định cho filter (top tags from database)
final List<FilterTag> defaultTags = [
  FilterTag(
    id: 'địa điểm ăn uống',
    label: 'Địa điểm ăn uống',
    icon: Icons.restaurant,
  ),
  FilterTag(id: 'hải sản', label: 'Hải sản', icon: Icons.set_meal),
  FilterTag(id: 'nhậu', label: 'Nhậu', icon: Icons.local_bar),
  FilterTag(id: 'gia đình', label: 'Gia đình', icon: Icons.family_restroom),
  FilterTag(id: 'chay', label: 'Chay', icon: Icons.spa),
  FilterTag(id: 'vegan', label: 'Vegan', icon: Icons.eco),
  FilterTag(id: 'thịt nướng', label: 'Thịt nướng', icon: Icons.outdoor_grill),
  FilterTag(id: 'hàn quốc', label: 'Hàn Quốc', icon: Icons.food_bank),
  FilterTag(id: 'miền tây', label: 'Miền Tây', icon: Icons.rice_bowl),
  FilterTag(id: 'bia', label: 'Bia', icon: Icons.sports_bar),
  FilterTag(id: 'bbq', label: 'BBQ', icon: Icons.outdoor_grill),
  FilterTag(id: 'cơm tấm', label: 'Cơm tấm', icon: Icons.rice_bowl),
  FilterTag(id: 'hà nội', label: 'Hà Nội', icon: Icons.location_city),
  FilterTag(id: 'tinh tế', label: 'Tinh tế', icon: Icons.diamond),
  FilterTag(id: 'lai rai', label: 'Lai rai', icon: Icons.restaurant_menu),
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

  List<RestaurantItem> _allRestaurants = [];
  List<RestaurantItem> _filteredRestaurants = [];
  List<String> _selectedTags = [];
  List<String> _selectedTastes = []; // NEW: Taste filter
  String _searchQuery = '';
  double _maxDistanceKm = 10.0; // NEW: Distance filter (default 10km)
  int _searchLimit = 100;
  bool _isLoading = true;
  bool _isMapLoading = true;
  double? _userLat, _userLon;

  @override
  void initState() {
    super.initState();
    debugPrint('DiscoverPage: initState called. Starting data load...');
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Get user location first
      double? lat, lon;
      try {
        var location = await LocationHelper.getCurrentLocation();
        lat = location['lat'];
        lon = location['lon'];
      } catch (e) {
        lat = null;
        lon = null;
      }

      setState(() {
        _userLat = lat;
        _userLon = lon;
      });

      debugPrint('DiscoverPage: Fetching restaurants...');
      // Fetch restaurants via Query System
      final restaurantsResult = await _querySystem.getAllRestaurants(
        userLat: lat,
        userLon: lon,
        limit: _searchLimit,
      );
      debugPrint(
        'DiscoverPage: Restaurants fetched (${restaurantsResult.items.length} items)',
      );

      if (mounted) {
        setState(() {
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

    setState(() {
      _isMapLoading = false;
    });
  }

  Future<SearchResult> _searchRestaurants({String? query, String? tag}) async {
    double? lat = _userLat;
    double? lon = _userLon;

    // Use client-side filtering for distance and taste
    var searchRestaurant = await _querySystem.searchWithClientFiltering(
      query: _searchQuery,
      tag: _selectedTags.isEmpty
          ? null
          : _selectedTags.map((s) => s.toLowerCase()).join('|'),
      userLat: lat,
      userLon: lon,
      maxDistanceKm: _maxDistanceKm,
      tastes: _selectedTastes.isEmpty ? null : _selectedTastes,
      limit: _searchLimit,
    );

    return searchRestaurant;
  }

  Future<void> _applyFilters() async {
    var searchRestaurant = await _searchRestaurants(
      query: _searchQuery,
      tag: _selectedTags.join('|'),
    );
    setState(() {
      _filteredRestaurants = searchRestaurant.items;
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
        maxDistance: _maxDistanceKm,
        selectedTastes: _selectedTastes,
        resultLimit: _searchLimit, // NEW: Pass current limit
        onApplyFilter: (tags, distance, tastes, limit) {
          // NEW: Accept limit parameter
          setState(() {
            _selectedTags = tags;
            _maxDistanceKm = distance;
            _selectedTastes = tastes;
            _searchLimit = limit; // NEW: Update limit
          });
          _applyFilters();
        },
      ),
    );
  }

  bool _isSearchApplied() {
    return _searchQuery.isNotEmpty ||
        _selectedTags.isNotEmpty ||
        _selectedTastes.isNotEmpty ||
        _maxDistanceKm < 100;
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
                      options: MapOptions(
                        initialCenter: LatLng(
                          _userLat ?? 10.762622,
                          _userLon ?? 106.660172,
                        ),
                        initialZoom: 13.0,
                        minZoom: 5.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.foodfinder.app',
                        ),
                        // User location marker (blue pin)
                        if (_userLat != null && _userLon != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_userLat!, _userLon!),
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        // Restaurant markers
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
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
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
                            ? Colors.black.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.5),
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
                      color: Colors.black.withValues(alpha: 0.1),
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
                            _isSearchApplied()
                                ? 'Kết quả tìm kiếm'
                                : 'Gợi ý nhà hàng',
                            style: TextStyle(
                              fontSize: 22, // Apple Large Title
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${_isSearchApplied() ? _filteredRestaurants.length : _allRestaurants.length} nhà hàng',
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
                      else if (_isSearchApplied())
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 2;
                            if (constraints.maxWidth > 600) crossAxisCount = 3;
                            if (constraints.maxWidth > 900) crossAxisCount = 4;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredRestaurants.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.72,
                                  ),
                              itemBuilder: (context, index) {
                                final restaurant = _filteredRestaurants[index];
                                return RestaurantCard(
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
                                );
                              },
                            );
                          },
                        )
                      else
                        // Restaurant Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 2;
                            if (constraints.maxWidth > 600) crossAxisCount = 3;
                            if (constraints.maxWidth > 900) crossAxisCount = 4;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _allRestaurants.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.72,
                                  ),
                              itemBuilder: (context, index) {
                                final restaurant = _allRestaurants[index];
                                return RestaurantCard(
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
                            ).primaryColor.withValues(alpha: 0.1),
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
