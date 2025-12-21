import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish_model.dart';
import '../models/food_model.dart';
import '../providers/favorites_provider.dart';
import '../widgets/dish_card.dart';
import 'restaurant_detail_page.dart';
import 'restaurant_list_page.dart';

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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
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
    return DishCard(
      item: dish,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantListPage(dish: dish),
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    RestaurantItem restaurant,
    FavoritesProvider provider,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isFavorite = provider.isRestaurantFavorite(restaurant.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailPage(restaurant: restaurant),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Badges
            Stack(
              children: [
                // Image
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: restaurant.imageUrl.startsWith('http')
                        ? Image.network(
                            restaurant.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                child: Center(
                                  child: Icon(
                                    Icons.restaurant,
                                    size: 40,
                                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            restaurant.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                child: Center(
                                  child: Icon(
                                    Icons.restaurant,
                                    size: 40,
                                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: restaurant.isOpen
                          ? Colors.green.withValues(alpha: 0.9)
                          : Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      restaurant.isOpen ? 'Mở cửa' : 'Đóng cửa',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Distance Badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.distance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red[400] : Colors.grey[600],
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        if (isFavorite) {
                          provider.removeRestaurant(restaurant.id);
                        } else {
                          provider.addRestaurant(restaurant);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    restaurant.category,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${restaurant.ratingCount})',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      if (restaurant.priceLevel != null) ...[
                        const Spacer(),
                        Text(
                          restaurant.priceLevel!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.green[300] : Colors.green[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place,
                        size: 10,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          style: TextStyle(
                            fontSize: 9,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 10,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '7:00 - 22:00',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
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
