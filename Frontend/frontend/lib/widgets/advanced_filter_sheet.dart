import 'package:flutter/material.dart';
import '../models/filter_tag_model.dart';

/// Widget Advanced Filter với Tags, Distance, Taste, và Limit
class AdvancedFilterSheet extends StatefulWidget {
  final List<FilterTag> availableTags;
  final List<String> selectedTagIds;
  final double maxDistance; // km
  final List<String> selectedTastes;
  final int resultLimit; // NEW: Result limit
  final Function(List<String> tags, double distance, List<String> tastes, int limit)
      onApplyFilter;

  const AdvancedFilterSheet({
    super.key,
    required this.availableTags,
    required this.selectedTagIds,
    this.maxDistance = 10.0,
    this.selectedTastes = const [],
    this.resultLimit = 20, // NEW: Default to 20
    required this.onApplyFilter,
  });

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late List<String> _selectedTags;
  late double _maxDistance;
  late List<String> _selectedTastes;
  late int _resultLimit; // NEW: Result limit state

  // Danh sách khẩu vị có sẵn
  final List<Map<String, dynamic>> _availableTastes = [
    {'id': 'Chua', 'label': 'Chua', 'icon': Icons.local_bar},
    {'id': 'Cay', 'label': 'Cay', 'icon': Icons.whatshot},
    {'id': 'Mặn', 'label': 'Mặn', 'icon': Icons.grain},
    {'id': 'Ngọt', 'label': 'Ngọt', 'icon': Icons.cake},
    {'id': 'Béo', 'label': 'Béo', 'icon': Icons.bubble_chart},
    {'id': 'Healthy', 'label': 'Healthy', 'icon': Icons.spa},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.selectedTagIds);
    _maxDistance = widget.maxDistance;
    _selectedTastes = List.from(widget.selectedTastes);
    _resultLimit = widget.resultLimit; // NEW: Initialize result limit
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

  void _toggleTaste(String tasteId) {
    setState(() {
      if (_selectedTastes.contains(tasteId)) {
        _selectedTastes.remove(tasteId);
      } else {
        _selectedTastes.add(tasteId);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedTags.clear();
      _selectedTastes.clear();
      _maxDistance = 10.0; // Reset to default (within 0.5-50km range)
      _resultLimit = 20; // Reset to default
    });
  }

  void _applyFilters() {
    widget.onApplyFilter(_selectedTags, _maxDistance, _selectedTastes, _resultLimit);
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
      child: SingleChildScrollView(
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
              'Tùy chỉnh khoảng cách, khẩu vị và loại nhà hàng',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Distance Slider
            _buildSection(
              title: 'Khoảng cách tối đa',
              isDarkMode: isDarkMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_maxDistance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        _maxDistance < 50
                            ? 'Trong bán kính ${_maxDistance.toStringAsFixed(1)}km'
                            : 'Tối đa 50km',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxDistance,
                    min: 0.5,
                    max: 50.0,
                    divisions: 99,
                    activeColor: Theme.of(context).primaryColor,
                    inactiveColor: isDarkMode
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0.5 km',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        '50 km',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Result Limit Selector (NEW)
            _buildSection(
              title: 'Số lượng kết quả',
              isDarkMode: isDarkMode,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLimitChip(20, isDarkMode),
                  _buildLimitChip(50, isDarkMode),
                  _buildLimitChip(100, isDarkMode),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Taste Filter
            _buildSection(
              title: 'Khẩu vị',
              isDarkMode: isDarkMode,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTastes.map((taste) {
                  final isSelected = _selectedTastes.contains(taste['id']);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          taste['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(width: 4),
                        Text(taste['label'] as String),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => _toggleTaste(taste['id'] as String),
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: isDarkMode
                        ? const Color(0xFF3C3C3C)
                        : Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Category Tags
            _buildSection(
              title: 'Loại nhà hàng',
              isDarkMode: isDarkMode,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag.id);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tag.icon != null) ...[
                          Icon(
                            tag.icon,
                            size: 16,
                            color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(tag.label),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => _toggleTag(tag.id),
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: isDarkMode
                        ? const Color(0xFF3C3C3C)
                        : Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
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
                    child: Text(
                      'Áp dụng (${_selectedTags.length + _selectedTastes.length})',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitChip(int limit, bool isDarkMode) {
    final isSelected = _resultLimit == limit;
    return ChoiceChip(
      label: Text('$limit'),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _resultLimit = limit;
        });
      },
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: isDarkMode
          ? const Color(0xFF3C3C3C)
          : Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDarkMode ? Colors.white : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      showCheckmark: false,
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDarkMode,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
