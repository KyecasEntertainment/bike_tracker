import 'package:flutter/material.dart';

import 'theme_settings_page.dart';

class AppThemeSettingsScreen extends StatelessWidget {
  const AppThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: ThemeSettingsPage()),
    );
  }
}
