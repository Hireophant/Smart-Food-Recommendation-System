import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/gps/gps.dart';

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
  // Start Location will be fetched from GPS. Null initially.
  LatLng? _startLocation;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeLocationAndRoute();
  }

  Future<void> _initializeLocationAndRoute() async {
    try {
      final locationData = await LocationHelper.getCurrentLocation();
      if (mounted) {
        setState(() {
          _startLocation = LatLng(locationData['lat']!, locationData['lon']!);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Keep default location if error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí hiện tại: $e.'),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: () => _initializeLocationAndRoute(),
            ),
          ),
        );
        setState(() {
          _errorMessage = 'Không thể lấy vị trí. Vui lòng kiểm tra GPS.';
          _isLoading = false;
        });
      }
    }
    // Only fetch route if we have a start location
    if (_startLocation != null) {
      _fetchRoute();
    }
  }

  /// Tự động zoom map để hiển thị cả điểm bắt đầu và điểm đến
  void _fitBounds() {
    if (_routePoints.isNotEmpty) {
      // Tính bounds từ route points
      double minLat = _routePoints
          .map((p) => p.latitude)
          .reduce((a, b) => a < b ? a : b);
      double maxLat = _routePoints
          .map((p) => p.latitude)
          .reduce((a, b) => a > b ? a : b);
      double minLon = _routePoints
          .map((p) => p.longitude)
          .reduce((a, b) => a < b ? a : b);
      double maxLon = _routePoints
          .map((p) => p.longitude)
          .reduce((a, b) => a > b ? a : b);

      final bounds = LatLngBounds(
        LatLng(minLat, minLon),
        LatLng(maxLat, maxLon),
      );

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    } else {
      // Nếu không có route, tính bounds từ 2 điểm
      final bounds = LatLngBounds.fromPoints([
        _startLocation!,
        widget.restaurantLocation,
      ]);

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  /// Gọi API OSRM để lấy đường đi
  Future<void> _fetchRoute() async {
    // OSRM Public API (Demo only - Do not use for heavy production load)
    // URL format: http://router.project-osrm.org/route/v1/driving/{lon},{lat};{lon},{lat}?overview=full&geometries=geojson
    if (_startLocation == null) return;
    final startLon = _startLocation!.longitude;
    final startLat = _startLocation!.latitude;
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

          // Tự động zoom để hiển thị toàn bộ route
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitBounds();
          });
        } else {
          setState(() {
            _errorMessage = 'Không tìm thấy đường đi';
            _isLoading = false;
          });

          // Vẫn zoom để thấy 2 điểm dù không có route
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitBounds();
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi kết nối server bản đồ';
          _isLoading = false;
        });

        // Vẫn zoom để thấy 2 điểm dù có lỗi
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBounds();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã có lỗi xảy ra: $e';
        _isLoading = false;
      });

      // Vẫn zoom để thấy 2 điểm dù có lỗi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
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
          if (_startLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _startLocation!, // Center map roughly at start
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
                    // Start Marker (User Location)
                    Marker(
                      point: _startLocation!,
                      width: 80,
                      height: 80,
                      child: const Column(
                        children: [
                          Icon(Icons.my_location, color: Colors.blue, size: 40),
                          Text(
                            'Bạn ở đây',
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

          // Loading Indicator (Show when loading location OR route)
          if (_isLoading || _startLocation == null)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang lấy vị trí của bạn...'),
                ],
              ),
            ),

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
                    // Show Lat/Lon text for user to confirm
                    if (_startLocation != null)
                      Text(
                        'GPS: ${_startLocation!.latitude.toStringAsFixed(5)}, ${_startLocation!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Từ: Vị trí của bạn')),
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
