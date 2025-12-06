import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Search',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const FoodSearchPage(),
    );
  }
}

class FoodSearchPage extends StatefulWidget {
  const FoodSearchPage({super.key});

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _filteredFoods = [];
  List<FoodItem> allFoods = [
    FoodItem(
      name: 'Pizza Margherita',
      category: 'Italian',
      rating: 4.5,
      image: '🍕',
    ),
    FoodItem(
      name: 'Sushi Platter',
      category: 'Japanese',
      rating: 4.8,
      image: '🍣',
    ),
    FoodItem(
      name: 'Burger Deluxe',
      category: 'American',
      rating: 4.2,
      image: '🍔',
    ),
    FoodItem(name: 'Pad Thai', category: 'Thai', rating: 4.6, image: '🍜'),
    FoodItem(
      name: 'Tacos Al Pastor',
      category: 'Mexican',
      rating: 4.4,
      image: '🌮',
    ),
    FoodItem(name: 'Biryani', category: 'Indian', rating: 4.7, image: '🍚'),
    FoodItem(
      name: 'Caesar Salad',
      category: 'Healthy',
      rating: 4.1,
      image: '🥗',
    ),
    FoodItem(name: 'Ramen', category: 'Japanese', rating: 4.5, image: '🍲'),
  ];

  @override
  void initState() {
    super.initState();
    _filteredFoods = allFoods;
    _searchController.addListener(_filterFoods);
  }

  void _filterFoods() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFoods = allFoods
          .where(
            (food) =>
                food.name.toLowerCase().contains(query) ||
                food.category.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Search'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for food or cuisine...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterFoods();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: _filteredFoods.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          'No foods found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching for a different cuisine or food name',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = _filteredFoods[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: Text(
                            food.image,
                            style: const TextStyle(fontSize: 40),
                          ),
                          title: Text(
                            food.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(food.category),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                food.rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Selected: ${food.name}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class FoodItem {
  final String name;
  final String category;
  final double rating;
  final String image;

  FoodItem({
    required this.name,
    required this.category,
    required this.rating,
    required this.image,
  });
}
