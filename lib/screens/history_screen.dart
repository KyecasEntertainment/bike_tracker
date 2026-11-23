import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/ride_session.dart';
import '../providers/rides_provider.dart';
import '../widgets/dashboard_components.dart';
import 'ride_detail_screen.dart';
import 'settings_screen.dart';

/// Saved rides, using the same surfaces and accents as the home dashboard.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer<RidesProvider>(builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: provider.loadRides,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: DashboardPageHeader(
                    title: 'Ride History',
                    subtitle: 'Every ride. Every kilometer.',
                    action: DashboardIconButton(
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ),
                ),
                if (provider.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    sliver: SliverToBoxAdapter(
                        child:
                            _HistorySummary(stats: provider.getTotalStats())),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(26, 28, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: Row(children: [
                        Expanded(
                            child: Text('Recent rides',
                                style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ))),
                        if (provider.rides.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear all rides',
                            icon: const Icon(Icons.delete_sweep_outlined),
                            color: colors.onSurfaceVariant,
                            onPressed: () =>
                                _confirmClearAll(context, provider),
                          ),
                      ]),
                    ),
                  ),
                  if (provider.rides.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(26, 0, 26, 32),
                      sliver:
                          SliverToBoxAdapter(child: _buildEmptyState(context)),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(26, 0, 26, 24),
                      sliver: SliverList.builder(
                        itemCount: provider.rides.length,
                        itemBuilder: (context, index) {
                          final ride = provider.rides[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _RideCard(
                              ride: ride,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) =>
                                        RideDetailScreen(ride: ride)),
                              ),
                              onDelete: () =>
                                  _confirmDelete(context, provider, ride),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DashboardSurface(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(children: [
        Icon(Icons.route_outlined, color: colors.primary, size: 36),
        const SizedBox(height: 20),
        Text('No rides yet',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
            'Your next adventure starts on Home.\nTap Start Ride to record your first ride.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: colors.onSurfaceVariant, fontSize: 14, height: 1.6)),
      ]),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, RidesProvider provider, RideSession ride) async {
    final confirmed = await _showDeleteDialog(
      context,
      title: 'Delete Ride',
      message:
          'Delete the ride from ${ride.formattedStartTime}? This cannot be undone.',
      action: 'Delete',
    );
    if (confirmed != true || !context.mounted) return;
    await provider.deleteRide(ride.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Ride deleted')));
  }

  Future<void> _confirmClearAll(
      BuildContext context, RidesProvider provider) async {
    final confirmed = await _showDeleteDialog(
      context,
      title: 'Clear All Rides',
      message:
          'Are you sure you want to delete all rides? This action cannot be undone.',
      action: 'Clear All',
    );
    if (confirmed != true || !context.mounted) return;
    await provider.clearAllRides();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('All rides deleted')));
  }

  Future<bool?> _showDeleteDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: Text(action),
            ),
          ],
        ),
      );
}

class _HistorySummary extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _HistorySummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: colors.primary.withValues(alpha: 0.15), blurRadius: 18)
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.onPrimary),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.route_outlined, color: colors.onPrimary, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text('ALL-TIME DISTANCE',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ))),
          ]),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(stats['formattedDistance'] as String,
                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ),
          const SizedBox(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: _summaryItem(
                    context, 'Total rides', '${stats['totalRides']}')),
            const SizedBox(width: 20),
            Expanded(
                child: _summaryItem(context, 'Ride time',
                    stats['formattedDuration'] as String)),
          ]),
        ]),
      ),
    );
  }

  Widget _summaryItem(BuildContext context, String label, String value) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      );
}

class _RideCard extends StatelessWidget {
  final RideSession ride;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _RideCard(
      {required this.ride, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = ride.name?.trim();
    return DashboardSurface(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.directions_bike_outlined, color: colors.primary, size: 23),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    name == null || name.isEmpty
                        ? DateFormat('EEE, d MMM').format(ride.startTime)
                        : name,
                    style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(DateFormat('d MMM yyyy · h:mm a').format(ride.startTime),
                    style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4)),
              ])),
          IconButton(
            tooltip: 'Delete ride',
            icon: const Icon(Icons.delete_outline_rounded, size: 21),
            color: colors.onSurfaceVariant,
            onPressed: onDelete,
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Divider(color: colors.outline, height: 1),
        ),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth < 280 ||
                  MediaQuery.textScalerOf(context).scale(12) > 16
              ? 2
              : 3;
          final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
          return Wrap(spacing: 16, runSpacing: 16, children: [
            SizedBox(
                width: width,
                child: _metric(context, Icons.route_outlined, 'Distance',
                    ride.formattedDistance)),
            SizedBox(
                width: width,
                child: _metric(context, Icons.timer_outlined, 'Duration',
                    ride.formattedDuration)),
            SizedBox(
                width: width,
                child: _metric(context, Icons.speed_outlined, 'Avg speed',
                    ride.formattedAverageSpeed)),
          ]);
        }),
      ]),
    );
  }

  Widget _metric(
      BuildContext context, IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 17, color: colors.primary),
      const SizedBox(height: 7),
      FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600))),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              color: colors.onSurfaceVariant, fontSize: 11, height: 1.3)),
    ]);
  }
}
