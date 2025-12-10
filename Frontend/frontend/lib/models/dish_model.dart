class DishItem {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> tags; // e.g., ["Spicy", "Soup"]
  final String description;

  DishItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.tags,
    required this.description,
  });
}
