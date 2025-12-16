import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../models/food_model.dart';
import '../handlers/query_system.dart';
import '../widgets/restaurant_card.dart';
import 'restaurant_detail_page.dart';

class RestaurantListPage extends StatefulWidget {
  final DishItem dish;

  const RestaurantListPage({super.key, required this.dish});

  @override
  State<RestaurantListPage> createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  final QuerySystem _querySystem = QuerySystem();
  List<RestaurantItem> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await _querySystem.findRestaurantsByDish(widget.dish.id);
    setState(() {
      _restaurants = result.items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nhà hàng phục vụ",
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
            ),
            Text(
              widget.dish.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _restaurants.isEmpty
          ? Center(
              child: Text(
                "Không tìm thấy nhà hàng",
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = _restaurants[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SizedBox(
                    height: 240, // Fixed height for card
                    child: RestaurantCard(
                      item: restaurant,
                      onTap: () {
                        // Navigate to Restaurant Detail Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailPage(
                              restaurant: restaurant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
