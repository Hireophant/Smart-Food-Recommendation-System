import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish_model.dart';
import '../models/food_model.dart';
import '../providers/favorites_provider.dart';
import 'map_page.dart';

/// Trang Favorites - Hiển thị danh sách món ăn và nhà hàng yêu thích
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Yêu thích',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (favoritesProvider.totalFavorites > 0)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'clear_all') {
                  _showClearAllDialog(context, favoritesProvider);
                } else if (value == 'clear_dishes') {
                  _showClearDialog(context, favoritesProvider, isDishes: true);
                } else if (value == 'clear_restaurants') {
                  _showClearDialog(context, favoritesProvider, isDishes: false);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_dishes',
                  child: Row(
                    children: [
                      Icon(Icons.restaurant_menu, size: 20),
                      SizedBox(width: 8),
                      Text('Xóa tất cả món ăn'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_restaurants',
                  child: Row(
                    children: [
                      Icon(Icons.store, size: 20),
                      SizedBox(width: 8),
                      Text('Xóa tất cả nhà hàng'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: isDarkMode ? Colors.white : Colors.black,
          unselectedLabelColor: isDarkMode ? Colors.white54 : Colors.black54,
          tabs: [
            Tab(
              icon: const Icon(Icons.restaurant_menu),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Món ăn'),
                  const SizedBox(width: 4),
                  if (favoritesProvider.favoriteDishes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${favoritesProvider.favoriteDishes.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              icon: const Icon(Icons.store),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nhà hàng'),
                  const SizedBox(width: 4),
                  if (favoritesProvider.favoriteRestaurants.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${favoritesProvider.favoriteRestaurants.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDishesTab(context, favoritesProvider),
          _buildRestaurantsTab(context, favoritesProvider),
        ],
      ),
    );
  }

  Widget _buildDishesTab(BuildContext context, FavoritesProvider provider) {
    if (provider.favoriteDishes.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.restaurant_menu,
        title: 'Chưa có món ăn yêu thích',
        message: 'Hãy thêm món ăn vào danh sách yêu thích của bạn!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.favoriteDishes.length,
      itemBuilder: (context, index) {
        final dish = provider.favoriteDishes[index];
        return _buildDishCard(context, dish, provider);
      },
    );
  }

  Widget _buildRestaurantsTab(
    BuildContext context,
    FavoritesProvider provider,
  ) {
    if (provider.favoriteRestaurants.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.store,
        title: 'Chưa có nhà hàng yêu thích',
        message: 'Hãy thêm nhà hàng vào danh sách yêu thích của bạn!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.favoriteRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = provider.favoriteRestaurants[index];
        return _buildRestaurantCard(context, restaurant, provider);
      },
    );
  }

  Widget _buildDishCard(
    BuildContext context,
    DishItem dish,
    FavoritesProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to dish details or restaurant list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xem chi tiết cho ${dish.name}')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  dish.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant_menu, size: 40),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dish.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: dish.tags.take(3).map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () {
                  provider.removeDish(dish.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${dish.name} đã xóa khỏi yêu thích'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'Hoàn tác',
                        onPressed: () => provider.addDish(dish),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    RestaurantItem restaurant,
    FavoritesProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapPage(selectedRestaurant: restaurant),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                restaurant.imageUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.store, size: 60),
                  );
                },
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () {
                          provider.removeRestaurant(restaurant.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${restaurant.name} đã xóa khỏi yêu thích',
                              ),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'Hoàn tác',
                                onPressed: () =>
                                    provider.addRestaurant(restaurant),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    restaurant.category,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.rating}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' (${restaurant.ratingCount})',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.distance,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  if (restaurant.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: restaurant.tags.take(3).map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, FavoritesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả?'),
        content: const Text(
          'Hành động này sẽ xóa tất cả danh sách món ăn và nhà hàng yêu thích.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đã xóa tất cả')));
            },
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(
    BuildContext context,
    FavoritesProvider provider, {
    required bool isDishes,
  }) {
    final type = isDishes ? 'món ăn' : 'nhà hàng';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa tất cả ${isDishes ? 'Món ăn' : 'Nhà hàng'}?'),
        content: Text('Hành động này sẽ xóa tất cả $type yêu thích.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (isDishes) {
                provider.clearDishes();
              } else {
                provider.clearRestaurants();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Đã xóa tất cả $type')));
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
