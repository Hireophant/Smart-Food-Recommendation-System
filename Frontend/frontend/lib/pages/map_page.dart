import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';
import '../models/dish_model.dart';
import '../handlers/query_system.dart';

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

  // Current Location (University of Science, VNU-HCM)
  final LatLng _currentLocation = const LatLng(10.7628, 106.6825);
  List<LatLng> _routePoints = [];
  RestaurantItem? _selectedItemForRoute;

  @override
  void initState() {
    super.initState();
    _loadData();
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

    // Auto routing if selected (must be done after Map is rendered)
    if (widget.selectedRestaurant != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRoute(widget.selectedRestaurant!);
      });
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final startLon = start.longitude;
    final startLat = start.latitude;
    final endLon = end.longitude;
    final endLat = end.latitude;

    // OSRM Public API (Driving)
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          setState(() {
            _routePoints = coordinates.map((coord) {
              return LatLng(coord[1], coord[0]); // GeoJSON is [lon, lat]
            }).toList();
          });

          // Zoom to fit bounds
          if (_routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(_routePoints);
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
            );
          }
        }
      } else {
        debugPrint('OSRM Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Routing Exception: $e');
      // Fallback to straight line if error
      setState(() {
        _routePoints = [start, end];
      });
    }
  }

  void _showRoute(RestaurantItem item) {
    setState(() {
      _selectedItemForRoute = item;
      // Clear previous route while loading
      _routePoints = [];
    });

    _fetchRoute(_currentLocation, LatLng(item.latitude, item.longitude));
  }

  void _onMarkerTap(RestaurantItem item) {
    _showRoute(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Map & Routing", style: TextStyle(fontSize: 16)),
            if (widget.selectedDish != null)
              Text(
                "Finding: ${widget.selectedDish!.name}",
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
                    initialCenter: _currentLocation,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smart_travel_system.frontend',
                      // Making tiles look a bit darker via ColorFilter is tricky directly here without custom client
                      // Just using standard OSM for now.
                    ),
                    // Route Polyline
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    // Current Location Marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blueAccent,
                            size: 30,
                          ),
                        ),
                        ..._restaurants.map((item) {
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
                        }),
                      ],
                    ),
                  ],
                ),
                // Routing Info Card
                if (_selectedItemForRoute != null)
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
                              "Routing to: ${_selectedItemForRoute!.name}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text("15 min"),
                                SizedBox(width: 16),
                                Icon(
                                  Icons.straighten,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text("2.5 km"),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Simulate "Start Navigation"
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Starting Turn-by-Turn Navigation...',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.navigation),
                              label: const Text("Start"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                              ),
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
