import 'package:flutter/material.dart';

import 'offline_map_settings_screen.dart';

class MapSettingsScreen extends StatelessWidget {
  const MapSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.outline),
    );
    return Scaffold(
      body: SafeArea(
        child: Theme(
          data: theme.copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: colors.surface,
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: inputBorder.copyWith(
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(color: colors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          child: const MapSettingsPage(),
        ),
      ),
    );
  }
}
