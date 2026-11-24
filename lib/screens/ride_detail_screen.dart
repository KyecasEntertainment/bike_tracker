import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../models/ride_session.dart';
import '../models/track_point.dart';
import '../utils/app_color_theme.dart';
import '../utils/google_map_styles.dart';
import '../utils/ride_route_smoother.dart';
import '../widgets/ride_route_painter.dart';

/// Screen showing detailed view of a completed ride with trail map.
class RideDetailScreen extends StatefulWidget {
  final RideSession ride;

  const RideDetailScreen({super.key, required this.ride});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen>
    with SingleTickerProviderStateMixin {
  static const double _sheetMinSize = 0.17;
  static const double _sheetInitialSize = 0.54;
  static const double _sheetMaxSize = 0.9;

  List<TrackPoint> _trackPoints = [];
  List<LatLng> _polylinePoints = [];
  List<Offset>? _projectedRoute;
  late final AnimationController _playbackController;
  GoogleMapController? _mapController;
  int _projectionGeneration = 0;
  int _projectionRetries = 0;
  bool _isTrackAnimating = false;
  bool _isLoading = true;
  bool _isSheetCollapsed = false;
  bool _isCameraReady = false;
  bool _hasPlayedRoute = false;

  @override
  void initState() {
    super.initState();
    _playbackController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _isTrackAnimating = false);
            }
          });
    _loadTrackPoints();
  }

  void _loadTrackPoints() {
    // Get track points from ride
    _trackPoints = widget.ride.getTrackPoints();

    // Convert to LatLng for map
    _polylinePoints = smoothRideRoute(
      _trackPoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
    );
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _onCameraIdle() async {
    final controller = _mapController;
    if (controller == null || _isTrackAnimating || _polylinePoints.length < 2) {
      return;
    }

    final generation = ++_projectionGeneration;
    final pixelRatio = defaultTargetPlatform == TargetPlatform.android
        ? MediaQuery.devicePixelRatioOf(context)
        : 1.0;
    try {
      final coordinates = await Future.wait(
        _polylinePoints.map(controller.getScreenCoordinate),
      );
      if (!mounted || generation != _projectionGeneration) return;
      setState(() {
        _projectedRoute = coordinates
            .map((point) => Offset(point.x / pixelRatio, point.y / pixelRatio))
            .toList();
        _isCameraReady = true;
      });
      _projectionRetries = 0;
    } catch (_) {
      if (!mounted || generation != _projectionGeneration) return;
      setState(() {
        _projectedRoute = null;
        _isCameraReady = false;
      });
      if (_projectionRetries++ < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (mounted && generation == _projectionGeneration) {
          await _onCameraIdle();
        }
      }
    }
  }

  void _onCameraMoveStarted() {
    if (_isTrackAnimating) return;
    _projectionGeneration++;
    _projectionRetries = 0;
    if (_isCameraReady) {
      setState(() => _isCameraReady = false);
    }
  }

  void _startTrackAnimation() {
    if (!_isCameraReady || _projectedRoute == null) return;
    setState(() {
      _isTrackAnimating = true;
      _hasPlayedRoute = true;
    });
    _playbackController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              foregroundColor: colors.onSurface,
            ),
          ),
        ),
        leadingWidth: 64,
        title: Text(
          'Ride Details',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share ride',
              style: IconButton.styleFrom(
                foregroundColor: colors.onSurface,
              ),
              onPressed: () {
                // TODO: Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
            ),
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
                  if (_isCameraReady && _polylinePoints.length > 1)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            _isTrackAnimating ? null : _startTrackAnimation,
                        icon: Icon(
                          _isTrackAnimating
                              ? Icons.play_disabled
                              : _hasPlayedRoute
                                  ? Icons.replay
                                  : Icons.play_arrow,
                        ),
                        label: Text(
                          _isTrackAnimating
                              ? 'Playing route'
                              : _hasPlayedRoute
                                  ? 'Replay route'
                                  : 'Play route',
                        ),
                      ),
                    ),
                  DraggableScrollableSheet(
                    minChildSize: _sheetMinSize,
                    initialChildSize: _sheetInitialSize,
                    maxChildSize: _sheetMaxSize,
                    snap: true,
                    snapSizes: const [
                      _sheetMinSize,
                      _sheetInitialSize,
                      _sheetMaxSize,
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
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const Center(
        child: Text('Google Maps is available in the Android and iOS apps.'),
      );
    }

    if (_polylinePoints.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Text('No trail data available')),
      );
    }

    final startPoint = _polylinePoints.first;
    final brightness = Theme.of(context).brightness;
    final routeColor = brightness == Brightness.dark
        ? Theme.of(context).colorScheme.primary
        : AppColorTheme.lightActiveIcon;
    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: startPoint, zoom: 14),
          style: GoogleMapStyles.forBrightness(brightness),
          onMapCreated: (controller) {
            _mapController = controller;
            if (_polylinePoints.length > 1) {
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(_calculateBounds(), 50),
              );
            }
          },
          onCameraMoveStarted: _onCameraMoveStarted,
          onCameraIdle: _onCameraIdle,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          scrollGesturesEnabled: !_isTrackAnimating,
          zoomGesturesEnabled: !_isTrackAnimating,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomControlsEnabled: !_isTrackAnimating,
          polylines: _isTrackAnimating
              ? const <Polyline>{}
              : {
                  Polyline(
                    polylineId: const PolylineId('ride_track'),
                    points: _polylinePoints,
                    color: routeColor,
                    width: 8,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                    jointType: JointType.round,
                  ),
                },
        ),
        if (_isTrackAnimating && _projectedRoute != null)
          IgnorePointer(
            child: CustomPaint(
              painter: RideRoutePainter(
                points: _projectedRoute!,
                progress: _playbackController,
                color: routeColor,
                strokeWidth: 8,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDraggableDetailsSheet(ScrollController scrollController) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.outline, width: 1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            26,
            10,
            26,
            _isSheetCollapsed ? 8 + bottomInset : 28 + bottomInset,
          ),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (_isSheetCollapsed) ...[
              const SizedBox(height: 15),
              _buildCompactBottomSummary(),
            ] else ...[
              const SizedBox(height: 22),
              _buildSheetHeader(),
              const SizedBox(height: 22),
              _buildDistanceHero(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.timer_outlined,
                      label: 'DURATION',
                      value: widget.ride.formattedDuration,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.speed_outlined,
                      label: 'AVG SPEED',
                      value: widget.ride.formattedAverageSpeed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _buildTimeInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    final colors = Theme.of(context).colorScheme;
    final name = widget.ride.name?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RIDE SUMMARY',
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          name == null || name.isEmpty ? 'Your ride' : name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 25,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(widget.ride.startTime),
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDistanceHero() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.15),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, color: colors.onPrimary, size: 19),
              const SizedBox(width: 8),
              Text(
                'TOTAL DISTANCE',
                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: 11,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.ride.formattedDistance,
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 21),
          const SizedBox(height: 13),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBottomSummary() {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildKeyMetric('DISTANCE', widget.ride.formattedDistance),
        ),
        Container(width: 1, height: 42, color: colors.outline),
        const SizedBox(width: 20),
        Expanded(
          child: _buildKeyMetric(
            'AVG SPEED',
            widget.ride.formattedAverageSpeed,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetric(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
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
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RIDE TIMELINE',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 11,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outline, width: 1.2),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                context,
                'Started',
                _formatDateTime(widget.ride.startTime),
                Icons.play_arrow_rounded,
                semanticColors.trailStart,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: colors.outline, height: 1),
              ),
              _buildInfoRow(
                context,
                'Ended',
                widget.ride.endTime != null
                    ? _formatDateTime(widget.ride.endTime!)
                    : 'N/A',
                Icons.flag_outlined,
                semanticColors.trailEnd,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: colors.outline, height: 1),
              ),
              _buildInfoRow(
                context,
                'GPS points',
                '${_trackPoints.length} recorded',
                Icons.gps_fixed_rounded,
                colors.primary,
              ),
            ],
          ),
        ),
      ],
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
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d MMM yyyy, h:mm a').format(dateTime);
  }

  @override
  void dispose() {
    _playbackController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
