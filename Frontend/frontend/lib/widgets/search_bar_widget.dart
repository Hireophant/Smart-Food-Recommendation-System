import 'package:flutter/material.dart';

/// Widget Search Bar với Advanced Filter
class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback? onFilterTap;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.onFilterTap,
    this.hintText = 'Tìm kiếm nhà hàng, món ăn...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
                border: InputBorder.none,
              ),
              onSubmitted: widget.onSearch,
            ),
          ),
          if (widget.onFilterTap != null)
            IconButton(
              icon: Icon(Icons.tune, color: Theme.of(context).primaryColor),
              onPressed: widget.onFilterTap,
              tooltip: 'Bộ lọc nâng cao',
            ),
        ],
      ),
    );
  }
}
