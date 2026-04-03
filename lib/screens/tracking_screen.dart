import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_tracking_provider.dart';
import 'settings_screen.dart';
import '../utils/app_color_theme.dart';
import '../widgets/stats_card.dart';
import '../widgets/tracking_button.dart';

/// Main tracking screen with start/stop/pause controls and live stats.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    // Get initial position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideTrackingProvider>().getCurrentPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bike Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<RideTrackingProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status indicator
                _buildStatusIndicator(provider),
                const SizedBox(height: 24),

                // Timer display
                _buildTimerDisplay(provider),
                const SizedBox(height: 32),

                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Distance',
                        value: provider.formattedDistance,
                        icon: Icons.straighten,
                        color: semanticColors.statDistance,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Avg Speed',
                        value: provider.formattedAverageSpeed,
                        icon: Icons.speed,
                        color: semanticColors.statSpeed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StatsCard(
                  title: 'Points Recorded',
                  value: '${provider.currentTrackPoints.length}',
                  icon: Icons.gps_fixed,
                  color: semanticColors.statPoints,
                ),
                const SizedBox(height: 32),

                // Control buttons
                _buildControlButtons(provider),
                const SizedBox(height: 24),

                // Background tracking info
                if (provider.isTracking || provider.isPaused)
                  _buildBackgroundTrackingInfo(),
                
                if (provider.isTracking || provider.isPaused)
                  const SizedBox(height: 24),

                // Instructions or status message
                if (provider.isIdle) _buildInstructions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(RideTrackingProvider provider) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;
    String status;
    Color color;
    IconData icon;

    switch (provider.trackingState) {
      case TrackingState.idle:
        status = 'Ready to Track';
        color = semanticColors.neutral;
        icon = Icons.radio_button_unchecked;
        break;
      case TrackingState.tracking:
        status = 'Tracking Active';
        color = semanticColors.success;
        icon = Icons.radio_button_checked;
        break;
      case TrackingState.paused:
        status = 'Paused';
        color = semanticColors.warning;
        icon = Icons.pause_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(RideTrackingProvider provider) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Duration',
            style: TextStyle(
              color: onPrimary.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.formattedDuration,
            style: TextStyle(
              color: onPrimary,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(RideTrackingProvider provider) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;

    if (provider.isIdle) {
      return TrackingButton(
        label: 'Start Ride',
        icon: Icons.play_arrow,
        color: semanticColors.success,
        onPressed: () => _startRide(provider),
        isLarge: true,
      );
    }

    return Row(
      children: [
        if (provider.isTracking)
          Expanded(
            child: TrackingButton(
              label: 'Pause',
              icon: Icons.pause,
              color: semanticColors.warning,
              onPressed: provider.pauseRide,
            ),
          ),
        if (provider.isPaused)
          Expanded(
            child: TrackingButton(
              label: 'Resume',
              icon: Icons.play_arrow,
              color: semanticColors.success,
              onPressed: provider.resumeRide,
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: TrackingButton(
            label: 'Stop',
            icon: Icons.stop,
            color: semanticColors.danger,
            onPressed: () => _stopRide(provider),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_bike,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready for your ride!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Start Ride" to begin tracking your route. '
            'Your location will be recorded every 5 seconds or 5 meters.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundTrackingInfo() {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: semanticColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: semanticColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            color: semanticColors.success,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background Tracking Active',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: semanticColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your ride will continue tracking even if you close the app. '
                  'A notification will appear in your notification bar.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRide(RideTrackingProvider provider) async {
    final success = await provider.startRide();
    if (!success && mounted) {
      final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start tracking. Please check location permissions.'),
          backgroundColor: semanticColors.danger,
        ),
      );
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
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      await provider.stopRide();
      if (mounted) {
        final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride saved successfully!'),
            backgroundColor: semanticColors.success,
          ),
        );
      }
    } else if (shouldSave == false) {
      await provider.discardRide();
    }
  }
}
