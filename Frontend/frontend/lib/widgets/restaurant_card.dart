import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_model.dart';
import '../providers/favorites_provider.dart';

/// Widget hiển thị thẻ thông tin nhà hàng trong danh sách
/// Hiển thị: Ảnh, Tên, Danh mục, Đánh giá, và Trạng thái (Open/Close).
class RestaurantCard extends StatelessWidget {
  final RestaurantItem item;
  final VoidCallback? onTap;
  final bool isHorizontal;

  const RestaurantCard({
    super.key,
    required this.item,
    this.onTap,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalLayout(context);
    }
    return _buildVerticalLayout(context);
  }

  Widget _buildVerticalLayout(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isRestaurantFavorite(item.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                isDarkMode ? 0.3 : 0.05,
              ), // Softer shadow
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Image Container
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: _buildImage(isDarkMode),
                  ),
                  // Open Badge
                  if (item.isOpen)
                    Positioned(top: 8, left: 8, child: _buildOpenBadge()),
                  // Favorite Button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildFavoriteButton(
                      context,
                      favoritesProvider,
                      isFavorite,
                    ),
                  ),
                  // Distance Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildDistanceBadge(item.distance),
                  ),
                ],
              ),
            ),
            // Info Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1E1E1E),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tags
                        _buildTags(isDarkMode, item.tags),
                      ],
                    ),
                    // Footer: Rating and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRating(isDarkMode, item.rating, item.ratingCount),
                        Text(
                          item.priceLevel ?? '',
                          style: const TextStyle(
                            color: Colors
                                .green, // Price level green is standard (money)
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isRestaurantFavorite(item.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120, // Check height constraint
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Image
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: _buildImage(isDarkMode),
                  ),
                  if (item.isOpen)
                    Positioned(top: 8, left: 8, child: _buildOpenBadge()),
                  // Favorite Button (Small version)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildFavoriteButton(
                      context,
                      favoritesProvider,
                      isFavorite,
                      isSmall: true,
                    ),
                  ),
                ],
              ),
            ),

            // Right: Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category, // e.g. "Bánh Cuốn • Authentic"
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRating(isDarkMode, item.rating, item.ratingCount),
                        const SizedBox(width: 8),
                        Text(
                          item.priceLevel ?? '\$\$', // Show price level
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Distance and Status text
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.address, // Or a short address
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Open status text
                        Text(
                          "• ${item.isOpen ? 'Mở cửa' : 'Đóng cửa'}",
                          style: TextStyle(
                            fontSize: 11,
                            color: item.isOpen ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool isDarkMode) {
    return item.imageUrl.startsWith('http')
        ? Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
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
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    size: 40,
                  ),
                ),
              );
            },
          )
        : Image.asset(
            item.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    size: 40,
                  ),
                ),
              );
            },
          );
  }

  Widget _buildOpenBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Mở cửa',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDistanceBadge(String distance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        distance,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildFavoriteButton(
    BuildContext context,
    FavoritesProvider provider,
    bool isFavorite, {
    bool isSmall = false,
  }) {
    return Container(
      width: isSmall ? 32 : null,
      height: isSmall ? 32 : null,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.grey[600],
          size: isSmall ? 18 : 20,
        ),
        padding: const EdgeInsets.all(4), // Reduced padding
        constraints: const BoxConstraints(),
        onPressed: () {
          provider.toggleRestaurant(item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFavorite
                    ? 'Đã xóa ${item.name} khỏi yêu thích'
                    : 'Đã thêm ${item.name} vào yêu thích',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTags(bool isDarkMode, List<String> tags) {
    return Wrap(
      spacing: 4,
      children: tags.take(2).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.deepOrange.withOpacity(0.15)
                : Colors.deepOrange.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode
                  ? Colors.deepOrange.withOpacity(0.3)
                  : Colors.deepOrange.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: isDarkMode ? Colors.deepOrangeAccent : Colors.deepOrange,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRating(bool isDarkMode, double rating, int count) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 14),
        const SizedBox(width: 4),
        Text(
          '$rating ($count)',
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF1E1E1E),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
