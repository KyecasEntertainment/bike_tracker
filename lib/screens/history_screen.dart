import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride_session.dart';
import '../providers/rides_provider.dart';
import '../utils/app_color_theme.dart';
import 'ride_detail_screen.dart';

/// Screen showing the history of completed rides.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmClearAll(context),
          ),
        ],
      ),
      body: Consumer<RidesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.rides.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Summary stats
              _buildSummaryStats(context, provider),
              
              // Rides list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.rides.length,
                  itemBuilder: (context, index) {
                    final ride = provider.rides[index];
                    return _RideCard(
                      ride: ride,
                      onTap: () => _openRideDetail(context, ride),
                      onDelete: () => _confirmDelete(context, provider, ride),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No rides yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your first ride!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, RidesProvider provider) {
    final stats = provider.getTotalStats();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Total Rides',
              '${stats['totalRides']}',
              Icons.directions_bike,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Distance',
              stats['formattedDistance'],
              Icons.straighten,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Duration',
              stats['formattedDuration'],
              Icons.timer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  void _openRideDetail(BuildContext context, RideSession ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailScreen(ride: ride),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    RidesProvider provider,
    RideSession ride,
  ) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ride'),
        content: Text(
          'Are you sure you want to delete this ride from ${ride.formattedStartTime}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRide(ride.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ride deleted'),
                  backgroundColor: semanticColors.danger,
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: semanticColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Rides'),
        content: const Text(
          'Are you sure you want to delete all rides? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<RidesProvider>().clearAllRides();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All rides deleted'),
                  backgroundColor: semanticColors.danger,
                ),
              );
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: semanticColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card widget for displaying a ride in the history list.
class _RideCard extends StatelessWidget {
  final RideSession ride;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RideCard({
    required this.ride,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_bike,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ride.formattedStartTime,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      Icons.straighten,
                      ride.formattedDistance,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      Icons.timer,
                      ride.formattedDuration,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      Icons.speed,
                      ride.formattedAverageSpeed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
