import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/food_model.dart';
import '../handlers/food_search_handler.dart';
import 'restaurant_detail_page.dart';

class MapPage extends StatefulWidget {
  final RestaurantItem? selectedRestaurant;

  const MapPage({super.key, this.selectedRestaurant});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MockFoodSearchHandler _handler = MockFoodSearchHandler();
  List<RestaurantItem> _restaurants = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.selectedRestaurant != null) {
      // Auto-show dialog after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onMarkerTap(widget.selectedRestaurant!);
      });
    }
  }

  Future<void> _loadData() async {
    final result = await _handler.getAllFoods();
    setState(() {
      _restaurants = result.items;
      // Ensure selected restaurant is in the list (if passing from search that might not be in getAllFoods default list)
      if (widget.selectedRestaurant != null &&
          !_restaurants.any((r) => r.id == widget.selectedRestaurant!.id)) {
        _restaurants.add(widget.selectedRestaurant!);
      }
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
            child: const Text("Chọn"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Center map on Hanoi or Selected Item
    final initialCenter = widget.selectedRestaurant != null
        ? LatLng(
            widget.selectedRestaurant!.latitude,
            widget.selectedRestaurant!.longitude,
          )
        : const LatLng(21.0285, 105.8542);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bản đồ"),
        backgroundColor: const Color(0xFF121212),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 15.0, // Closer zoom if selected
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
    );
  }
}
