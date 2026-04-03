import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../utils/app_color_theme.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'App Theme Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred app color theme.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<AppThemeOption>(
            value: themeProvider.selectedTheme,
            decoration: const InputDecoration(
              labelText: 'Color Theme',
              border: OutlineInputBorder(),
            ),
            items: AppThemeOption.values
                .map(
                  (theme) => DropdownMenuItem<AppThemeOption>(
                    value: theme,
                    child: Text(theme.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              context.read<ThemeProvider>().setTheme(value);
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Theme changes are applied instantly and remembered for the next app launch.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
