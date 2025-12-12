import '../models/dish_model.dart';
// import '../models/food_model.dart'; // Ensure data models are imported if needed

/// Handler specialized for Dish operations
abstract class DishHandler {
  Future<List<DishItem>> getAllDishes({List<String> filters = const []});
}

class MockDishHandler implements DishHandler {
  @override
  Future<List<DishItem>> getAllDishes({List<String> filters = const []}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final allDishes = [
      DishItem(
        id: '1',
        name: 'Phở Bò',
        description: 'Traditional Vietnamese beef noodle soup',
        imageUrl:
            'https://images.unsplash.com/photo-1582878826618-c05326eff950?q=80&w=600',
        tags: ['Umami', 'Mild', 'Vietnamese'],
      ),
      DishItem(
        id: '2',
        name: 'Bún Bò Huế',
        description: 'Spicy beef noodle soup from Hue',
        imageUrl:
            'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?q=80&w=600',
        tags: ['Spicy', 'Umami', 'Vietnamese'],
      ),
      DishItem(
        id: '3',
        name: 'Cơm Tấm',
        description: 'Broken rice with grilled pork chop',
        imageUrl:
            'https://images.unsplash.com/photo-1541518763669-27fef04b14ea?q=80&w=600',
        tags: ['Salty', 'Sweet', 'Vietnamese'],
      ),
      DishItem(
        id: '4',
        name: 'Pad Thai',
        description: 'Stir-fried rice noodles with shrimp',
        imageUrl:
            'https://images.unsplash.com/photo-1559314809-0d155014e29e?q=80&w=600',
        tags: ['Sweet', 'Sour', 'Thai'],
      ),
      DishItem(
        id: '5',
        name: 'Tom Yum Goong',
        description: 'Hot and sour Thai soup',
        imageUrl:
            'https://images.unsplash.com/photo-1548681528-6a5c45b66b42?q=80&w=600',
        tags: ['Spicy', 'Sour', 'Thai'],
      ),
      DishItem(
        id: '6',
        name: 'Sushi Platter',
        description: 'Assorted fresh sushi',
        imageUrl:
            'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?q=80&w=600',
        tags: ['Umami', 'Mild', 'Japanese'],
      ),
      DishItem(
        id: '7',
        name: 'Ramen',
        description: 'Japanese noodle soup',
        imageUrl:
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=600',
        tags: ['Umami', 'Salty', 'Japanese'],
      ),
      DishItem(
        id: '8',
        name: 'Bibimbap',
        description: 'Korean mixed rice bowl',
        imageUrl:
            'https://images.unsplash.com/photo-1596797038530-2c107229654b?q=80&w=600',
        tags: ['Spicy', 'Umami', 'Korean'],
      ),
    ];

    if (filters.isEmpty) {
      return allDishes;
    }

    // Case-insensitive filtering
    final lowerFilters = filters.map((e) => e.toLowerCase()).toList();
    return allDishes.where((dish) {
      return dish.tags.any((tag) => lowerFilters.contains(tag.toLowerCase()));
    }).toList();
  }
}
