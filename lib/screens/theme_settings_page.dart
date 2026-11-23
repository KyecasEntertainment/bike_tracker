import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../utils/app_color_theme.dart';
import '../widgets/dashboard_components.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const DashboardPageHeader(
          title: 'App Theme',
          subtitle: 'Choose the look for your next ride.',
          showBackButton: true,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 32),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final option in AppThemeOption.values) ...[
              _ThemeOption(
                option: option,
                selected: option == themeProvider.selectedTheme,
                onTap: () => themeProvider.setTheme(option),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: colors.primary, size: 19),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Applied instantly. Remembered for your next ride.',
                      style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.5))),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final AppThemeOption option;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption(
      {required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final preview = AppColorTheme.themeFor(option);
    final description = switch (option) {
      AppThemeOption.light => 'Bright and clear',
      AppThemeOption.dark => 'Dark with lime accents',
    };
    return Semantics(
      selected: selected,
      button: true,
      child: DashboardSurface(
        onTap: onTap,
        borderColor: selected ? colors.primary : colors.outline,
        child: Row(children: [
          Container(
            width: 44,
            height: 52,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: preview.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.outline),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                      height: 15,
                      decoration: BoxDecoration(
                          color: preview.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Expanded(
                      child: Container(
                          decoration: BoxDecoration(
                              color:
                                  preview.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3)))),
                ]),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(option.label,
                    style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text(description,
                    style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4)),
              ])),
          const SizedBox(width: 12),
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? colors.primary : colors.outline, size: 23),
        ]),
      ),
    );
  }
}
