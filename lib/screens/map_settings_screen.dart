import 'package:flutter/material.dart';

import 'offline_map_settings_screen.dart';

class MapSettingsScreen extends StatelessWidget {
  const MapSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Settings'),
      ),
      body: const MapSettingsPage(),
    );
  }
}
