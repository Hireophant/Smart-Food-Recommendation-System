import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Chế độ tối'),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              final provider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              provider.toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}
