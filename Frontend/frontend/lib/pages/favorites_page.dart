import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../widgets/restaurant_card.dart';
import 'restaurant_detail_page.dart';

/// Trang Favorites - Hiển thị danh sách nhà hàng yêu thích
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Yêu thích',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (favoritesProvider.favoriteRestaurants.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa tất cả nhà hàng yêu thích?'),
                    content: const Text(
                      'Hành động này sẽ xóa tất cả nhà hàng yêu thích.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          favoritesProvider.clearRestaurants();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xóa tất cả nhà hàng'),
                            ),
                          );
                        },
                        child: const Text(
                          'Xóa',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _buildRestaurantsTab(context, favoritesProvider),
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

    // LIST VIEW
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.favoriteRestaurants.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final restaurant = provider.favoriteRestaurants[index];
        return RestaurantCard(
          item: restaurant,
          isHorizontal: true, // Enable horizontal mode
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RestaurantDetailPage(restaurant: restaurant),
              ),
            );
          },
        );
      },
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
}
