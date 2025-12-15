import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish_model.dart';
import '../providers/favorites_provider.dart';

class DishCard extends StatelessWidget {
  final DishItem item;
  final VoidCallback onTap;

  const DishCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isDishFavorite(item.id);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
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
            flex: 3, // Reduced flex for image to give more space to content
            child: Stack(
              fit: StackFit.expand,
              children: [
                item.imageUrl.startsWith('http')
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          child: Icon(
                            Icons.broken_image,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey,
                          ),
                        ),
                      )
                    : Image.asset(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey,
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
                        color: isFavorite ? Colors.red : Colors.grey[600],
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        favoritesProvider.toggleDish(item);
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
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(
                8.0,
              ), // Reduced padding to save space
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
                    maxLines: 1, // Shortened to 1 line to prevent overflow
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Tags
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: item.tags.take(2).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, // Slightly tighter tags
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1ABC9C).withValues(alpha: 0.2)
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
                  ),

                  const Spacer(),

                  // Button - Even smaller as requested
                  SizedBox(
                    width: double.infinity,
                    height: 24, // Reduced to 24px
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.deepOrange, // Orange Theme
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            4,
                          ), // Slightly sharper corners
                        ),
                        padding: EdgeInsets.zero,
                        minimumSize:
                            Size.zero, // Remove minimum size constraints
                        tapTargetSize: MaterialTapTargetSize
                            .shrinkWrap, // Remove touch target padding
                      ),
                      child: const Text(
                        "Chọn", // Vietnamese
                        style: TextStyle(
                          fontSize: 11, // Smaller font
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
}
