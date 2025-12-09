import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/food_model.dart';
import '../models/dish_model.dart';
import '../handlers/query_system.dart';
import 'restaurant_detail_page.dart';

/// Màn hình Bản đồ
/// Sử dụng Flutter Map và OpenStreetMap để hiển thị vị trí các nhà hàng.
/// Có thể nhận vào [selectedRestaurant] để tự động focus vào nhà hàng đó.
class MapPage extends StatefulWidget {
  final DishItem? selectedDish;
  final RestaurantItem? selectedRestaurant;
  final bool isConfirmationMode;

  const MapPage({
    super.key,
    this.selectedDish,
    this.selectedRestaurant,
    this.isConfirmationMode = false,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final QuerySystem _querySystem = QuerySystem();
  List<RestaurantItem> _restaurants = [];
  final MapController _mapController = MapController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.selectedRestaurant != null) {
      // If passing a specific restaurant, ensure it's in the list or added
      _restaurants.add(widget.selectedRestaurant!);
      // We'll zoom to it in build
    }
  }

  Future<void> _loadData() async {
    SearchResult result;
    if (widget.selectedDish != null) {
      result = await _querySystem.findRestaurantsByDish(
        widget.selectedDish!.id,
      );
    } else if (widget.selectedRestaurant != null) {
      // Just showing one restaurant
      result = SearchResult(items: [widget.selectedRestaurant!]);
    } else {
      // Default: show generic search or all (mock behavior)
      result = await _querySystem.search("all");
    }

    setState(() {
      _restaurants = result.items;
      _isLoading = false;
    });
  }

  void _onMarkerTap(RestaurantItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(item.name, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.category, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              "Rating: ${item.rating} (${item.ratingCount})",
              style: const TextStyle(color: Colors.amber),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text("Huỷ", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RestaurantDetailPage(restaurant: item),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Chọn", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Center map on Hanoi (default) or the selected restaurant
    final initialCenter = widget.selectedRestaurant != null
        ? LatLng(
            widget.selectedRestaurant!.latitude,
            widget.selectedRestaurant!.longitude,
          )
        : const LatLng(21.0285, 105.8542);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Restaurants nearby", style: TextStyle(fontSize: 16)),
            if (widget.selectedDish != null)
              Text(
                "Serving: ${widget.selectedDish!.name}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: widget.selectedRestaurant != null
                        ? 16.0
                        : 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smart_travel_system.frontend',
                      // Making tiles look a bit darker via ColorFilter is tricky directly here without custom client
                      // Just using standard OSM for now.
                    ),
                    MarkerLayer(
                      markers: _restaurants.map((item) {
                        return Marker(
                          point: LatLng(item.latitude, item.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _onMarkerTap(item),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Confirmation Overlay
                if (widget.isConfirmationMode &&
                    widget.selectedRestaurant != null)
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Card(
                      color: Colors.white,
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Selected: ${widget.selectedRestaurant!.name}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1ABC9C),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      // OK pressed -> Go to Menu (Detail Page)
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RestaurantDetailPage(
                                            restaurant:
                                                widget.selectedRestaurant!,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text("View Menu"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
