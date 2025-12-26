import 'package:flutter/material.dart';
import '../models/filter_tag_model.dart';

/// Widget Advanced Filter với Tags
class AdvancedFilterSheet extends StatefulWidget {
  final List<FilterTag> availableTags;
  final List<String> selectedTagIds;
  final Function(List<String>) onApplyFilter;

  const AdvancedFilterSheet({
    super.key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onApplyFilter,
  });

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.selectedTagIds);
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTags.contains(tagId)) {
        _selectedTags.remove(tagId);
      } else {
        _selectedTags.add(tagId);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedTags.clear();
    });
  }

  void _applyFilters() {
    widget.onApplyFilter(_selectedTags);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ lọc nâng cao',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn các thẻ để lọc nhà hàng',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Tags Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag.id);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tag.icon != null) ...[
                      Icon(tag.icon, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Text(tag.label),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => _toggleTag(tag.id),
                selectedColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).primaryColor,
                backgroundColor: isDarkMode
                    ? const Color(0xFF3C3C3C)
                    : Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : (isDarkMode ? Colors.white : Colors.black87),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearAll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                    side: BorderSide(
                      color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                      width: 1.5,
                    ),
                  ),
                  child: const Text('Xóa tất cả'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Áp dụng (${_selectedTags.length})'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
