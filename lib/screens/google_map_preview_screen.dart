import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';
import '../utils/google_map_styles.dart';

class MapSettingsPage extends StatefulWidget {
  const MapSettingsPage({super.key});

  @override
  State<MapSettingsPage> createState() => _MapSettingsPageState();
}

class _MapSettingsPageState extends State<MapSettingsPage> {
  static const LatLng _fallbackCenter = LatLng(14.5995, 120.9842);

  GoogleMapController? _mapController;
  LatLng _center = _fallbackCenter;
  bool _isFindingLocation = true;

  @override
  void initState() {
    super.initState();
    _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() => _isFindingLocation = true);
    final position = await LocationService().getCurrentPosition();
    if (!mounted) return;

    if (position != null) {
      _center = LatLng(position.latitude, position.longitude);
      await _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_center, 14));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get your current location.')),
      );
    }
    setState(() => _isFindingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildMap(),
        Positioned(
          top: 0,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Material(
                  color: colors.surface.withValues(alpha: 0.94),
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: colors.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(18),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    child: Text(
                      'Google Maps',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 18,
          bottom: 28,
          child: FloatingActionButton(
            onPressed: _isFindingLocation ? null : _moveToCurrentLocation,
            tooltip: 'Center on my location',
            child: _isFindingLocation
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
      ],
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

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _center, zoom: 12),
      style: GoogleMapStyles.forBrightness(Theme.of(context).brightness),
      onMapCreated: (controller) => _mapController = controller,
      myLocationButtonEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('map_preview_center'),
          position: _center,
        ),
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
