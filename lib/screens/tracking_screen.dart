import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ride_dashboard_stats.dart';
import '../providers/ride_tracking_provider.dart';
import '../providers/rides_provider.dart';
import '../utils/app_color_theme.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/tracking_button.dart';
import 'settings_screen.dart';

/// Home dashboard with current / latest ride statistics and personal bests.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RideTrackingProvider>().getCurrentPosition();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: 'Bike Tracker',
                    image: true,
                    child: ExcludeSemantics(
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('K',
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            )),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceContainerHighest,
                      foregroundColor: colors.onSurface,
                    ),
                    icon: const Icon(Icons.settings_outlined, size: 23),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer2<RideTrackingProvider, RidesProvider>(
                builder: (context, tracking, history, child) {
                  final stats = RideDashboardStats.fromRides(
                    history.rides,
                    currentDistance:
                        tracking.isIdle ? null : tracking.currentDistance,
                    currentAverageSpeed:
                        tracking.isIdle ? null : tracking.averageSpeed,
                  );
                  return LayoutBuilder(builder: (context, constraints) {
                    final roomy = constraints.maxHeight >= 650;
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 42),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: roomy ? 54 : 28),
                                  _buildTimerDisplay(tracking),
                                  SizedBox(height: roomy ? 64 : 32),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: DashboardStatCard(
                                        title: 'Distance',
                                        icon: Icons.route_outlined,
                                        value: (stats.distance / 1000)
                                            .toStringAsFixed(2),
                                        unit: 'km',
                                        description: tracking.isIdle
                                            ? 'Latest ride distance'
                                            : 'Current ride distance',
                                      )),
                                      const SizedBox(width: 18),
                                      Expanded(
                                          child: DashboardStatCard(
                                        title: 'Longest Distance',
                                        icon: Icons.emoji_events_outlined,
                                        value: (stats.longestDistance / 1000)
                                            .toStringAsFixed(2),
                                        unit: 'km',
                                        description:
                                            'Highest distance across all rides',
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: DashboardStatCard(
                                        title: 'Average Speed',
                                        icon: Icons.speed_outlined,
                                        value: stats.averageSpeed
                                            .toStringAsFixed(1),
                                        unit: 'km/h',
                                        description: tracking.isIdle
                                            ? 'Latest ride average speed'
                                            : 'Current ride average speed',
                                      )),
                                      const SizedBox(width: 18),
                                      Expanded(
                                          child: DashboardStatCard(
                                        title: 'Fastest Average Speed',
                                        icon: Icons.bolt_rounded,
                                        value: stats.fastestAverageSpeed
                                            .toStringAsFixed(1),
                                        unit: 'km/h',
                                        description:
                                            'Highest ride average speed across all rides',
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 40, bottom: 24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildControlButtons(tracking),
                                    if (!tracking.isIdle) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        tracking.isPaused
                                            ? 'Ride paused. Resume when you’re ready.'
                                            : 'Tracking your ride in the background.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(RideTrackingProvider provider) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final status = switch (provider.trackingState) {
      TrackingState.idle => 'READY TO RIDE',
      TrackingState.tracking => 'RECORDING',
      TrackingState.paused => 'PAUSED',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: semantic.heroBackground,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: semantic.heroBackground.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(children: [
        Text('Duration',
            style: TextStyle(
              color: semantic.heroNeonText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(provider.formattedDuration,
              style: TextStyle(
                color: semantic.heroNeonText,
                fontSize: 56,
                height: 1.1,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ),
        const SizedBox(height: 8),
        Text(status,
            style: TextStyle(
              color: semantic.heroNeonText,
              fontSize: 10,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
            )),
      ]),
    );
  }

  Widget _buildControlButtons(RideTrackingProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    if (provider.isIdle) {
      return TrackingButton(
        label: 'Start Ride',
        icon: Icons.play_arrow_rounded,
        color: colors.primary,
        onPressed: () => _startRide(provider),
        isLarge: true,
      );
    }
    return Row(children: [
      Expanded(
          child: TrackingButton(
        label: provider.isPaused ? 'Resume' : 'Pause',
        icon: provider.isPaused ? Icons.play_arrow_rounded : Icons.pause,
        color: provider.isPaused ? colors.primary : semantic.warning,
        onPressed: provider.isPaused ? provider.resumeRide : provider.pauseRide,
      )),
      const SizedBox(width: 12),
      Expanded(
          child: TrackingButton(
        label: 'Stop',
        icon: Icons.stop_rounded,
        color: semantic.danger,
        onPressed: () => _stopRide(provider),
      )),
    ]);
  }

  Future<void> _startRide(RideTrackingProvider provider) async {
    final success = await provider.startRide();
    if (!success && mounted) {
      final semantic = Theme.of(context).extension<AppSemanticColors>()!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'Could not start tracking. Please check location permissions.'),
        backgroundColor: semantic.danger,
      ));
    }
  }

  Future<void> _stopRide(RideTrackingProvider provider) async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${provider.formattedDistance}'),
            Text('Duration: ${provider.formattedDuration}'),
            const SizedBox(height: 16),
            const Text('Would you like to save this ride?'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Discard')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (shouldSave == true) {
      await provider.stopRide();
      if (mounted) {
        final semantic = Theme.of(context).extension<AppSemanticColors>()!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Ride saved successfully!'),
          backgroundColor: semantic.success,
        ));
      }
    } else if (shouldSave == false) {
      await provider.discardRide();
    }
  }
}
