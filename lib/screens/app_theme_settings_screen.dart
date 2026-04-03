import 'package:flutter/material.dart';

import 'theme_settings_page.dart';

class AppThemeSettingsScreen extends StatelessWidget {
  const AppThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Theme Settings'),
      ),
      body: const ThemeSettingsPage(),
    );
  }
}
