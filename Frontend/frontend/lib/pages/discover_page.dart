import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../handlers/food_search_handler.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/filter_bar.dart';
import 'map_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // Use Handler
  final FoodSearchHandler _handler = MockFoodSearchHandler();
  SearchResult? _data;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await _handler.getAllFoods();
    setState(() {
      _data = result;
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _data = SearchResult.loading();
    });
    final result = await _handler.searchFoods(query);
    setState(() {
      _data = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark Background
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.blueAccent), // Logo placeholder
            SizedBox(width: 8),
            Text('SmartSys', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Login",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khám phá Ẩm thực',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tìm kiếm trải nghiệm ăn uống tuyệt vời',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  // Debounce could be added here
                  _search(val);
                },
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                  hintText: "Tìm phở, cơm tấm, cafe...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Filter Sort Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                const Text("Sắp xếp: ", style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Text("Mặc định", style: TextStyle(color: Colors.white)),
                      Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chips
          const FilterBar(),

          const SizedBox(height: 16),

          // Grid
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_data == null || _data!.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_data!.error != null) {
      return Center(
        child: Text(
          "Error: ${_data!.error}",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_data!.items.isEmpty) {
      return const Center(
        child: Text(
          "No restaurants found",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptive grid
        int crossAxisCount = 2;
        if (constraints.maxWidth > 900)
          crossAxisCount = 4;
        else if (constraints.maxWidth > 600)
          crossAxisCount = 3;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8, // Adjust for card height
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _data!.items.length,
          itemBuilder: (context, index) {
            return RestaurantCard(
              item: _data!.items[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MapPage(selectedRestaurant: _data!.items[index]),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
