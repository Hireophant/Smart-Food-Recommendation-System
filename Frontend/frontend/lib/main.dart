import 'package:flutter/material.dart';
import 'pages/discover_page.dart';

/// Điểm khởi chạy của ứng dụng
void main() {
  runApp(const MyApp());
}

/// Widget gốc của ứng dụng (Root Widget)
/// Thiết lập Theme (Dark Mode) và màn hình trang chủ.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Food Recommendation',
      debugShowCheckedModeBanner: false,
      // Sử dụng Light Theme cho giao diện FoodFinder
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Light grey/white
        primaryColor: const Color(0xFF1ABC9C), // Teal
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1ABC9C),
          primary: const Color(0xFF1ABC9C),
          secondary: const Color(0xFF16A085),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      // Màn hình đầu tiên: Trang Khám phá
      home: const DiscoverPage(),
    );
  }
}
