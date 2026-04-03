import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../utils/app_color_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _selectedTheme = StorageService().getSelectedTheme();
  }

  late AppThemeOption _selectedTheme;

  AppThemeOption get selectedTheme => _selectedTheme;

  ThemeData get themeData => AppColorTheme.themeFor(_selectedTheme);

  Future<void> setTheme(AppThemeOption option) async {
    if (_selectedTheme == option) return;
    _selectedTheme = option;
    await StorageService().saveSelectedTheme(option);
    notifyListeners();
  }
}
