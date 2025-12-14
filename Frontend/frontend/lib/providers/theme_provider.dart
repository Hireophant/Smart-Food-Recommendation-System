import 'package:flutter/material.dart';

/// Provider quản lý Dark/Light Mode
/// Sử dụng ChangeNotifier để thông báo UI khi theme thay đổi
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Toggle giữa Dark và Light mode
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Thông báo cho UI rebuild
  }

  /// Set theme mode cụ thể
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Light Theme
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Light grey/white
      primaryColor: const Color(0xFF1ABC9C), // Teal
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1ABC9C),
        primary: const Color(0xFF1ABC9C),
        secondary: const Color(0xFF16A085),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }

  /// Dark Theme
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212), // Dark background
      primaryColor: const Color(0xFF1ABC9C), // Keep teal accent
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1ABC9C),
        primary: const Color(0xFF1ABC9C),
        secondary: const Color(0xFF16A085),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}
