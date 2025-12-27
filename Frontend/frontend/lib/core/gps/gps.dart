import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';

class LocationHelper {
  
  /// Hàm này chỉ làm 1 việc: Lấy tọa độ và trả về Map {lat, lon}
  /// Nếu lỗi sẽ throw Exception để bên UI tự xử lý hiển thị.
  static Future<Map<String, double>> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Kiểm tra GPS có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ định vị (GPS) chưa được bật.');
    }

    // 2. Kiểm tra quyền truy cập
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền vị trí bị chặn vĩnh viễn. Hãy vào cài đặt để mở lại.');
    }

    // 3. Cấu hình độ chính xác (Tối ưu cho Desktop/Mobile)
    // Desktop dùng Low để tránh timeout, Mobile dùng High để chính xác
    LocationAccuracy accuracy = (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
        ? LocationAccuracy.low 
        : LocationAccuracy.high;

    // 4. Lấy vị trí
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
      timeLimit: const Duration(seconds: 10), // Timeout sau 10s
    );

    // 5. Trả về kết quả dạng Map
    return {
      'lat': position.latitude,
      'lon': position.longitude,
    };
  }
}