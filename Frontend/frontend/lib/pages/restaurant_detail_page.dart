import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../handlers/query_system.dart';

/// Màn hình Chi tiết Nhà hàng
/// Hiển thị thông tin tổng quan, ảnh bìa và danh sách thực đơn (Menu).
class RestaurantDetailPage extends StatefulWidget {
  final RestaurantItem restaurant;

  const RestaurantDetailPage({super.key, required this.restaurant});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final QuerySystem _querySystem = QuerySystem();
  List<MenuItem> _menu = [];
  bool _isLoading = true;

  // Filter State
  String _searchQuery = '';
  final Set<String> _selectedTags = {};

  final Map<String, List<String>> _filterCategories = {
    'Taste': ['Spicy', 'Mild', 'Sweet', 'Salty', 'Sour', 'Umami'],
    'Preferences': [
      'Healthy',
      'Vegetarian',
      'Vegan',
      'High-protein',
      'Fast food',
      'Street food',
    ],
    'Cuisine Type': [
      'Vietnamese',
      'Thai',
      'Japanese',
      'Korean',
      'Western',
      'Chinese',
      'Other',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final menu = await _querySystem.getMenu(widget.restaurant.id);
    setState(() {
      _menu = menu;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.restaurant.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image (Could be improved, keeping simple)
            if (widget.restaurant.imageUrl.startsWith('http'))
              Image.network(
                widget.restaurant.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.grey,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.restaurant.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${widget.restaurant.category} • ${widget.restaurant.distance}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText:
                            "Search by dish name (e.g. phở, bún bò, cơm tấm)...",
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter Sections
                  ..._filterCategories.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.value.map((tag) {
                              final isSelected = _selectedTags.contains(tag);
                              return FilterChip(
                                label: Text(tag),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTags.add(tag);
                                    } else {
                                      _selectedTags.remove(tag);
                                    }
                                  });
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor: Colors.teal.shade100,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.teal.shade900
                                      : Colors.grey[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.teal.shade200
                                        : Colors.transparent,
                                  ),
                                ),
                                showCheckmark: false,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    "Menu",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._getFilteredMenu().map((item) => _buildMenuItem(item)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MenuItem> _getFilteredMenu() {
    return _menu.where((item) {
      // Name Search
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      // Tags Filter: For now, we don't strictly filter mock data to ensure we show something
      return true;
    }).toList();
  }

  Widget _buildMenuItem(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              image: item.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(item.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.imageUrl == null
                ? const Icon(Icons.fastfood, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  item.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  "\$${item.price}",
                  style: const TextStyle(
                    color: Color(0xFF1ABC9C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1ABC9C),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
              elevation: 0,
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
