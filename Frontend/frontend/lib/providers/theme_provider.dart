import 'package:flutter/material.dart';

/// Provider quản lý Dark/Light Mode
/// Sử dụng ChangeNotifier để thông báo UI khi theme thay đổi
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Toggle giữa Dark và Light mode
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners(); // Thông báo cho UI rebuild
  }

  /// Set theme mode cụ thể
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Light Theme
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'SF Pro Display', // Fallback to system font if not available
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF9500), // Apple Orange
      primary: const Color(0xFFFF9500),
      secondary: const Color(0xFF34C759), // Apple Green for success/accents
      surface: const Color(0xFFF2F2F7), // Apple Light Gray Background
      background: const Color(0xFFF2F2F7),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    appBarTheme: const AppBarTheme(
      backgroundColor:
          Colors.white, // Transparent/Glass effect handled in UI usually
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.black),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFFFF9500),
      unselectedItemColor: Color(0xFF8E8E93), // Apple Gray
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 0,
    ),
  );

  // Dark Theme
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'SF Pro Display',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF9500),
      primary: const Color(0xFFFF9500),
      secondary: const Color(0xFF30D158),
      surface: const Color(0xFF1C1C1E), // Apple Dark Gray
      background: const Color(0xFF000000),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1C1C1E),
      selectedItemColor: Color(0xFFFF9500),
      unselectedItemColor: Color(0xFF8E8E93),
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 0,
    ),
  );
}
