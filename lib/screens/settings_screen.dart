import 'package:flutter/material.dart';

import '../widgets/dashboard_components.dart';
import 'map_settings_screen.dart';
import 'app_theme_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(children: [
          const DashboardPageHeader(
            title: 'Settings',
            subtitle: 'A little setup. A better ride.',
            showBackButton: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 32),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                            color: colors.primary.withValues(alpha: 0.15),
                            blurRadius: 18)
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tune_rounded,
                              color: colors.onPrimary, size: 26),
                          const SizedBox(height: 16),
                          Text('Ride your way.',
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              )),
                          const SizedBox(height: 8),
                          Text('Set your look. Explore your map.',
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 14,
                                height: 1.5,
                              )),
                        ]),
                  ),
                  const SizedBox(height: 30),
                  Text('PREFERENCES',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 16),
                  _SettingsOption(
                    icon: Icons.palette_outlined,
                    title: 'App Theme Settings',
                    subtitle: 'Find the look that feels like you.',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const AppThemeSettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsOption(
                    icon: Icons.map_outlined,
                    title: 'Map Settings',
                    subtitle: 'View Google Maps around your location.',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const MapSettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: 28),
                  DashboardSurface(
                    borderColor: colors.outline,
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.phone_android_outlined,
                              color: colors.onSurfaceVariant, size: 21),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  'Your rides are saved on this device, ready whenever you are.',
                                  style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 12,
                                      height: 1.6))),
                        ]),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }
}

class _SettingsOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingsOption(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DashboardSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: colors.primary, size: 24),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 13, height: 1.5)),
        ])),
        const SizedBox(width: 12),
        Icon(Icons.arrow_forward_rounded, color: colors.primary, size: 21),
      ]),
    );
  }
}
