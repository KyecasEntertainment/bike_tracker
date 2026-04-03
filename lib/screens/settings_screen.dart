import 'package:flutter/material.dart';

import 'map_settings_screen.dart';
import 'app_theme_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('App Theme Settings'),
              subtitle: const Text('Choose Light, Dark, Green, or Blue theme'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AppThemeSettingsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Map Settings'),
              subtitle: const Text('Offline area, radius, and download options'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MapSettingsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
