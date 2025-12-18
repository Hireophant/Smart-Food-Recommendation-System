import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Trang hiển thị bản đồ và chỉ đường từ HCMUS đến quán ăn
class MapRoutingPage extends StatefulWidget {
  final String restaurantName;
  final LatLng restaurantLocation;

  const MapRoutingPage({
    super.key,
    required this.restaurantName,
    required this.restaurantLocation,
  });

  @override
  State<MapRoutingPage> createState() => _MapRoutingPageState();
}

class _MapRoutingPageState extends State<MapRoutingPage> {
  // HCMUS Location: 227 Nguyen Van Cu
  final LatLng _startLocation = const LatLng(10.762622, 106.681816);
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  /// Gọi API OSRM để lấy đường đi
  Future<void> _fetchRoute() async {
    // OSRM Public API (Demo only - Do not use for heavy production load)
    // URL format: http://router.project-osrm.org/route/v1/driving/{lon},{lat};{lon},{lat}?overview=full&geometries=geojson
    final startLon = _startLocation.longitude;
    final startLat = _startLocation.latitude;
    final endLon = widget.restaurantLocation.longitude;
    final endLat = widget.restaurantLocation.latitude;

    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final coordinates =
              data['routes'][0]['geometry']['coordinates'] as List;

          setState(() {
            _routePoints = coordinates.map((coord) {
              // GeoJSON is [lon, lat]
              return LatLng(coord[1], coord[0]);
            }).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Không tìm thấy đường đi';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi kết nối server bản đồ';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã có lỗi xảy ra: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉ đường'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _startLocation, // Center map roughly at start
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.frontend', // Replace with your app package
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
              // Markers
              MarkerLayer(
                markers: [
                  // Start Marker (HCMUS)
                  Marker(
                    point: _startLocation,
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Icon(Icons.school, color: Colors.blue, size: 40),
                        Text(
                          'HCMUS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // End Marker (Restaurant)
                  Marker(
                    point: widget.restaurantLocation,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                        Text(
                          widget.restaurantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Loaidng Indicator
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Info Box
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Từ: ĐH Khoa học Tự nhiên (227 Nguyễn Văn Cừ)',
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.restaurant, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Đến: ${widget.restaurantName}')),
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
