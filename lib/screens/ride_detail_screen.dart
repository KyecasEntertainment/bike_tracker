import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import '../models/ride_session.dart';
import '../models/track_point.dart';
import '../services/storage_service.dart';
import '../utils/app_color_theme.dart';
import '../widgets/stats_card.dart';

/// Screen showing detailed view of a completed ride with trail map.
class RideDetailScreen extends StatefulWidget {
  final RideSession ride;

  const RideDetailScreen({
    super.key,
    required this.ride,
  });

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  static const double _sheetMinSize = 0.12;
  static const double _sheetInitialSize = 0.52;
  static const double _sheetMaxSize = 0.84;

  List<TrackPoint> _trackPoints = [];
  List<LatLng> _polylinePoints = [];
  List<LatLng> _animatedPolylinePoints = [];
  final MapController _mapController = MapController();
  Timer? _trackAnimationTimer;
  bool _isTrackAnimating = false;
  bool _isLoading = true;
  bool _isDownloadingOfflineMap = false;
  bool _isSheetCollapsed = false;
  static const FMTCStore _cache = FMTCStore('bike_tracker_cache');
  static const double _estimatedKbPerTile = 20;

  bool get _offlineOnlyModeEnabled =>
      StorageService().isOfflineOnlyModeEnabled();

  @override
  void initState() {
    super.initState();
    _loadTrackPoints();
  }

  void _loadTrackPoints() {
    // Get track points from ride
    _trackPoints = widget.ride.getTrackPoints();

    // Convert to LatLng for map
    _polylinePoints = _trackPoints.map((p) => p.toLatLng()).toList();
    _animatedPolylinePoints = _polylinePoints.length > 1
        ? [_polylinePoints.first]
        : List<LatLng>.from(_polylinePoints);

    setState(() {
      _isLoading = false;
    });

    _startTrackAnimation();
  }

  void _startTrackAnimation() {
    _trackAnimationTimer?.cancel();

    if (_polylinePoints.length <= 1) {
      setState(() {
        _isTrackAnimating = false;
        _animatedPolylinePoints = List<LatLng>.from(_polylinePoints);
      });
      return;
    }

    final totalPoints = _polylinePoints.length;
    final stepSize = (totalPoints / 180).ceil();

    setState(() {
      _isTrackAnimating = true;
      _animatedPolylinePoints = [_polylinePoints.first];
    });

    _trackAnimationTimer = Timer.periodic(const Duration(milliseconds: 33), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextCount = _animatedPolylinePoints.length + stepSize;
      final boundedCount = nextCount > totalPoints ? totalPoints : nextCount;

      setState(() {
        _animatedPolylinePoints = _polylinePoints.sublist(0, boundedCount);
      });

      if (boundedCount >= totalPoints) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isTrackAnimating = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        actions: [
          IconButton(
            icon: Icon(_isTrackAnimating ? Icons.play_disabled : Icons.replay),
            tooltip: _isTrackAnimating ? 'Animating route' : 'Replay route',
            onPressed: _isTrackAnimating ? null : _startTrackAnimation,
          ),
          IconButton(
            icon: _isDownloadingOfflineMap
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Download map offline',
            onPressed: _isDownloadingOfflineMap ? null : _downloadMapOffline,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final isCollapsed =
                    notification.extent <= (_sheetMinSize + 0.01);
                if (isCollapsed != _isSheetCollapsed) {
                  setState(() => _isSheetCollapsed = isCollapsed);
                }
                return false;
              },
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMap()),
                  DraggableScrollableSheet(
                    minChildSize: _sheetMinSize,
                    initialChildSize: _sheetInitialSize,
                    maxChildSize: _sheetMaxSize,
                    snap: true,
                    snapSizes: const [
                      _sheetMinSize,
                      _sheetInitialSize,
                      _sheetMaxSize
                    ],
                    builder: (context, scrollController) {
                      return _buildDraggableDetailsSheet(scrollController);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMap() {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;

    if (_polylinePoints.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Text('No trail data available'),
        ),
      );
    }

    // Calculate bounds for all points
    final bounds = _calculateBounds();

    // Get start and end points
    final startPoint = _polylinePoints.first;
    final currentEndPoint = _animatedPolylinePoints.isEmpty
        ? _polylinePoints.last
        : _animatedPolylinePoints.last;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _polylinePoints.first,
        initialZoom: 14,
        onMapReady: () {
          // Fit bounds when map is ready
          if (_polylinePoints.length > 1) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
            );
          }
        },
      ),
      children: [
        // Tile layer (OpenStreetMap)
        _buildRideTileLayer(),
        // Polyline layer (trail)
        PolylineLayer(
          polylines: [
            Polyline(
              points: _animatedPolylinePoints,
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 4,
            ),
          ],
        ),

        // Markers for start and end
        MarkerLayer(
          markers: [
            // Start marker (green)
            Marker(
              point: startPoint,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: semanticColors.trailStart,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
            // End marker (red)
            if (_animatedPolylinePoints.length > 1)
              Marker(
                point: currentEndPoint,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: semanticColors.trailEnd,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.flag,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDraggableDetailsSheet(ScrollController scrollController) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _isSheetCollapsed
          ? _buildCompactBottomSummary()
          : ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ride Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Distance',
                        value: widget.ride.formattedDistance,
                        icon: Icons.straighten,
                        color: semanticColors.statDistance,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        title: 'Duration',
                        value: widget.ride.formattedDuration,
                        icon: Icons.timer,
                        color: semanticColors.statDuration,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Avg Speed',
                        value: widget.ride.formattedAverageSpeed,
                        icon: Icons.speed,
                        color: semanticColors.statSpeed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        title: 'Points',
                        value: '${_trackPoints.length}',
                        icon: Icons.gps_fixed,
                        color: semanticColors.statPoints,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTimeInfo(context),
              ],
            ),
    );
  }

  Widget _buildCompactBottomSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _buildKeyMetric(
                  label: 'Speed (km/h)',
                  value: widget.ride.formattedAverageSpeed,
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKeyMetric(
                  label: 'Distance (km)',
                  value: widget.ride.formattedDistance,
                  icon: Icons.straighten,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildKeyMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TileLayer _buildRideTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      tileProvider: FMTCTileProvider(
        stores: {
          _cache.storeName: BrowseStoreStrategy.readUpdateCreate,
        },
        loadingStrategy: _offlineOnlyModeEnabled
            ? BrowseLoadingStrategy.cacheOnly
            : BrowseLoadingStrategy.cacheFirst,
      ),
      userAgentPackageName: 'com.biketracker.app',
      maxZoom: 19,
    );
  }

  Future<void> _downloadMapOffline() async {
    if (_polylinePoints.isEmpty) return;

    if (_offlineOnlyModeEnabled) {
      final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Turn off Offline Mode in settings to download new tiles.',
          ),
          backgroundColor: semanticColors.warning,
        ),
      );
      return;
    }

    final downloadBounds = _expandedBounds(_calculateBounds());
    final downloadRegion = RectangleRegion(downloadBounds).toDownloadable(
      minZoom: 12,
      maxZoom: 17,
      options: _buildRideTileLayer(),
    );

    final estimatedTiles = await _cache.download.countTiles(downloadRegion);
    final estimatedMb =
        ((estimatedTiles * _estimatedKbPerTile) / 1024).toStringAsFixed(1);
    if (!mounted) return;

    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Offline Map'),
        content: Text(
          'This will download about $estimatedTiles tiles for this ride area '
          '(zoom 12-17, approximately $estimatedMb MB). Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (shouldStart != true || !mounted) return;

    setState(() => _isDownloadingOfflineMap = true);

    final progress = ValueNotifier<DownloadProgress?>(null);
    final streams = _cache.download.startForeground(
      region: downloadRegion,
      skipExistingTiles: true,
      parallelThreads: 3,
      maxBufferLength: 100,
    );

    DownloadProgress? lastProgress;
    Object? failure;
    final finished = Completer<void>();
    late final StreamSubscription<DownloadProgress> subscription;

    subscription = streams.downloadProgress.listen(
      (event) {
        lastProgress = event;
        progress.value = event;
      },
      onError: (error, _) {
        failure = error;
        if (!finished.isCompleted) finished.complete();
      },
      onDone: () {
        if (!finished.isCompleted) finished.complete();
      },
      cancelOnError: true,
    );

    var dialogIsOpen = true;
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<DownloadProgress?>(
        valueListenable: progress,
        builder: (context, current, _) {
          final ratio = current == null
              ? null
              : (current.attemptedTilesCount / current.maxTilesCount)
                  .clamp(0.0, 1.0);
          final pct = current?.percentageProgress.toStringAsFixed(1) ?? '0.0';

          return AlertDialog(
            title: const Text('Downloading Offline Map'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: ratio),
                const SizedBox(height: 12),
                Text('$pct% complete'),
                const SizedBox(height: 6),
                Text(
                  current == null
                      ? 'Preparing download...'
                      : '${current.attemptedTilesCount}/${current.maxTilesCount} tiles',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await _cache.download.cancel();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Stop'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      dialogIsOpen = false;
    });

    await finished.future;
    if (dialogIsOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    await dialog;

    await subscription.cancel();
    progress.dispose();

    if (!mounted) return;
    setState(() => _isDownloadingOfflineMap = false);

    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offline map download failed: $failure')),
      );
      return;
    }

    final downloadedTiles = lastProgress?.flushedTilesCount ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Offline map ready ($downloadedTiles tiles).')),
    );
  }

  LatLngBounds _expandedBounds(LatLngBounds bounds) {
    final minLat = bounds.southWest.latitude;
    final maxLat = bounds.northEast.latitude;
    final minLng = bounds.southWest.longitude;
    final maxLng = bounds.northEast.longitude;

    final latPadding = ((maxLat - minLat).abs() * 0.15).clamp(0.001, 0.03);
    final lngPadding = ((maxLng - minLng).abs() * 0.15).clamp(0.001, 0.03);

    return LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  LatLngBounds _calculateBounds() {
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (final point in _polylinePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              context,
              'Started',
              widget.ride.formattedStartTime,
              Icons.play_arrow,
              semanticColors.success,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Ended',
              widget.ride.endTime != null
                  ? _formatDateTime(widget.ride.endTime!)
                  : 'N/A',
              Icons.flag,
              semanticColors.danger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _trackAnimationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}
