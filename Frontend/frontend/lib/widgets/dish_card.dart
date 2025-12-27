import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish_model.dart';
import '../providers/favorites_provider.dart';

class DishCard extends StatelessWidget {
  final DishItem item;
  final VoidCallback onTap;
  final bool isHorizontal;

  const DishCard({
    super.key,
    required this.item,
    required this.onTap,
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
    final isFavorite = favoritesProvider.isDishFavorite(item.id);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(context, isDarkMode),
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildFavoriteButton(
                    context,
                    favoritesProvider,
                    isFavorite,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.white
                          : const Color(0xFF1E1E1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Tags
                  _buildTags(isDarkMode, item.tags),

                  const Spacer(),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 24,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Chọn",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isDishFavorite(item.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: _buildImage(context, isDarkMode),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
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
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTags(isDarkMode, item.tags),
                  ],
                ),
              ),
            ),
            // Right-most arrow or action? Or keep it simple
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool isDarkMode) {
    return item.imageUrl.startsWith('http')
        ? Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              final progress = loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null;
              return Container(
                color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              child: Center(
                child: Icon(
                  Icons.restaurant,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey,
                  size: 24,
                ),
              ),
            ),
          )
        : Image.asset(
            item.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              child: Icon(
                Icons.image_not_supported,
                color: isDarkMode ? Colors.grey[600] : Colors.grey,
              ),
            ),
          );
  }

  Widget _buildTags(bool isDarkMode, List<String> tags) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.take(2).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1ABC9C).withOpacity(0.2)
                : const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode
                  ? const Color(0xFF1ABC9C)
                  : const Color(0xFF009688),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFavoriteButton(
    BuildContext context,
    FavoritesProvider provider,
    bool isFavorite, {
    bool isSmall = false,
  }) {
    return Container(
      width: isSmall ? 28 : null,
      height: isSmall ? 28 : null,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.grey[600],
          size: isSmall ? 16 : 20,
        ),
        padding: const EdgeInsets.all(4), // Reduced padding
        constraints: const BoxConstraints(),
        onPressed: () {
          provider.toggleDish(item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFavorite
                    ? '${item.name} removed from favorites'
                    : '${item.name} added to favorites',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
