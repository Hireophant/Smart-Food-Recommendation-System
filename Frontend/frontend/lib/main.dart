import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/discover_page.dart';
import 'providers/theme_provider.dart';
import 'providers/favorites_provider.dart';

/// Điểm khởi chạy của ứng dụng
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Widget gốc của ứng dụng (Root Widget)
/// Thiết lập Theme (Dark/Light Mode) và màn hình trang chủ.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Smart Food Recommendation',
      debugShowCheckedModeBanner: false,
      // Sử dụng ThemeProvider để quản lý theme
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      // Màn hình đầu tiên: Trang Khám phá
      home: const DiscoverPage(),
    );
  }
}
