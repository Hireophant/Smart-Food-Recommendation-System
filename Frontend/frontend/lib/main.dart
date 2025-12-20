import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/auth_gate.dart';
import 'providers/theme_provider.dart';
import 'providers/favorites_provider.dart';
import 'core/supabase_handler.dart';

/// Điểm khởi chạy của ứng dụng
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseHandler.initialize();

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
      // Màn hình đầu tiên: Trang Khám phá (AuthGate sẽ kiểm tra JWT để điều hướng)
      home: const AuthGate(),
    );
  }
}
