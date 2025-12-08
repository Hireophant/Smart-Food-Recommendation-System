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
      // Sử dụng Dark Theme cho giao diện hiện đại
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.orange,
        ),
      ),
      // Màn hình đầu tiên: Trang Khám phá
      home: const DiscoverPage(),
    );
  }
}
