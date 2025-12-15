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
  // Use QuerySystem instead of direct Handler
  final QuerySystem _querySystem = QuerySystem(); // Facade
  List<DishItem> _dishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // State to track selected filters
  final Set<String> _selectedFilters = {};

  Future<void> _loadData() async {
    // Fetch dishes via Query System
    final dishes = await _querySystem.getAllDishes();
    setState(() {
      _dishes = dishes;
      _isLoading = false;
    });
  }

  // Search Handler
  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      _loadData(); // Reload all dishes if query is empty
      return;
    }

    // Call QuerySystem to search by name or tag
    final results = await _querySystem.searchDishes(query);
    setState(() {
      _dishes = results;
    });
  }

  // Helper to toggle filters and reload
  void _onFilterSelected(String filter, bool selected) {
    setState(() {
      if (selected) {
        _selectedFilters.add(filter);
      } else {
        _selectedFilters.remove(filter);
      }
      _isLoading = true; // Show loading while refetching
    });
    _loadData(); // Mock handler is fast, but good practice
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final isSelected = _selectedFilters.contains(option);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (bool selected) =>
                      _onFilterSelected(option, selected),
                  // Conditional Color for Selected State
                  backgroundColor: isSelected
                      ? Colors.green.shade100
                      : (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
                  selectedColor: Colors.green.shade200,
                  checkmarkColor: Colors.green.shade900,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.green.shade900
                        : (isDarkMode ? Colors.white70 : Colors.black87),
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.green
                          : (isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[300]!),
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
        title: MediaQuery.of(context).size.width < 600
            ? null
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
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
                    'FoodFinder',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
        actions: [
          // Show Navigation Links ONLY on Desktop (> 600 width)
          if (MediaQuery.of(context).size.width >= 600) ...[
            TextButton(
              onPressed: () {
                // Already on home page
              },
              child: Text(
                "Home",
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
                "Favorites",
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
                "Profile",
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],

          // Theme Toggle Button (Sun/Moon)
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).primaryColor,
            ),
            tooltip: themeProvider.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
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
                          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1920', // Food pattern or generic food background
                        ),
                        fit: BoxFit.cover,
                        opacity: 0.3,
                      ),
                      color: Color(0xFFFFC045), // Orange/Yellow
                    ),
                    child: Stack(
                      children: [
                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orangeAccent.withValues(alpha: 0.8),
                                Colors.amber.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Find your perfect dish",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 3),
                                      blurRadius: 8,
                                      color: Colors.black87,
                                    ),
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Filter by taste and discover restaurants near you",
                                style: TextStyle(
                                  fontSize: 18,
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

                  // Search Bar Overlay specific styling (Optional, keeping simple here)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 24,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2C2C2C)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.3
                                  : 0.05,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              "Search by dish name or tags (e.g. phở, spicy)...",
                          hintStyle: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[500]
                                : Colors.grey[600],
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Filter Sections
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterSection(
                          context,
                          title: 'Taste',
                          options: [
                            'Spicy',
                            'Mild',
                            'Sweet',
                            'Salty',
                            'Sour',
                            'Umami',
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFilterSection(
                          context,
                          title: 'Preferences',
                          options: [
                            'Healthy',
                            'Vegetarian',
                            'Vegan',
                            'High-protein',
                            'Fast food',
                            'Street food',
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFilterSection(
                          context,
                          title: 'Cuisine Type',
                          options: [
                            'Vietnamese',
                            'Thai',
                            'Japanese',
                            'Korean',
                            'Western',
                            'Chinese',
                            'Other',
                          ],
                        ),
                      ],
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
                          "Showing ${_dishes.length} dishes",
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
                                        0.7, // Taller cards to prevent overflow
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
        child: const CircleAvatar(
          backgroundImage: AssetImage('assets/images/ai_avatar.png'),
          radius: 28, // Fix size to fit FAB
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
