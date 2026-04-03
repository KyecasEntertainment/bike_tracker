import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../utils/app_color_theme.dart';

enum OfflineAreaMode {
  currentLocation,
  customCenter,
}

class MapSettingsPage extends StatefulWidget {
  const MapSettingsPage({super.key});

  @override
  State<MapSettingsPage> createState() => _MapSettingsPageState();
}

class _MapSettingsPageState extends State<MapSettingsPage> {
  static const FMTCStore _cache = FMTCStore('bike_tracker_cache');
  static const LatLng _fallbackCenter = LatLng(14.5995, 120.9842);
  static const double _estimatedKbPerTile = 20;

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final MapController _previewMapController = MapController();

  OfflineAreaMode _mode = OfflineAreaMode.currentLocation;
  double _radiusKm = 5;
  bool _isSaving = false;
  bool _isDownloading = false;
  bool _isResolvingPreview = true;
  bool _offlineOnlyModeEnabled = false;
  LatLng? _previewCenter;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    unawaited(_initialisePreviewCenter());
  }

  void _loadSettings() {
    final settings = StorageService().getOfflineMapSettings();
    final modeValue = settings['mode'] as String;
    final lat = settings['customLatitude'] as double?;
    final lng = settings['customLongitude'] as double?;

    _mode = modeValue == 'custom_center'
        ? OfflineAreaMode.customCenter
        : OfflineAreaMode.currentLocation;
    _radiusKm = settings['radiusKm'] as double;
    _offlineOnlyModeEnabled = settings['offlineOnlyModeEnabled'] as bool? ?? false;

    if (lat != null && lng != null) {
      _latController.text = lat.toStringAsFixed(6);
      _lngController.text = lng.toStringAsFixed(6);
      _previewCenter = LatLng(lat, lng);
    }
  }

  Future<void> _initialisePreviewCenter() async {
    if (_mode == OfflineAreaMode.customCenter && _previewCenter != null) {
      if (!mounted) return;
      setState(() => _isResolvingPreview = false);
      return;
    }

    final position = await LocationService().getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _previewCenter = position == null
          ? (_previewCenter ?? _fallbackCenter)
          : LatLng(position.latitude, position.longitude);
      _isResolvingPreview = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _previewCenter == null) return;
      _previewMapController.move(_previewCenter!, _zoomForRadiusKm(_radiusKm));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Map Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which area should be downloaded for offline map usage.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Offline Mode'),
            subtitle: const Text(
              'Use downloaded map tiles only. No online OSM fetching.',
            ),
            value: _offlineOnlyModeEnabled,
            onChanged: (value) {
              setState(() {
                _offlineOnlyModeEnabled = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Offline Area',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<OfflineAreaMode>(
              segments: const [
                ButtonSegment(
                  value: OfflineAreaMode.currentLocation,
                  label: Text('From My Location'),
                  icon: Icon(Icons.my_location),
                ),
                ButtonSegment(
                  value: OfflineAreaMode.customCenter,
                  label: Text('Custom Part of Map'),
                  icon: Icon(Icons.place),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                unawaited(_handleModeChange(selection.first));
              },
            ),
          const SizedBox(height: 12),
          _buildMapPreview(),
          const SizedBox(height: 20),
          Text(
            'Radius: ${_radiusKm.toStringAsFixed(1)} km',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
              min: 1,
              max: 30,
              divisions: 58,
              value: _radiusKm,
              label: '${_radiusKm.toStringAsFixed(1)} km',
              onChanged: (value) {
                setState(() {
                  _radiusKm = value;
                });
                if (_previewCenter != null) {
                  _previewMapController.move(
                    _previewCenter!,
                    _zoomForRadiusKm(_radiusKm),
                  );
                }
              },
            ),
          if (_mode == OfflineAreaMode.customCenter) ...[
            const SizedBox(height: 16),
            TextField(
                controller: _latController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g. 14.599512',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _syncPreviewCenterFromInputs(),
              ),
            const SizedBox(height: 12),
            TextField(
                controller: _lngController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g. 120.984222',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _syncPreviewCenterFromInputs(),
              ),
            const SizedBox(height: 8),
            Text(
                'Tip: You can paste coordinates of the exact part of map '
                'you want available offline, or tap the map to place the marker.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: _isDownloading ? null : _downloadNow,
              icon: _isDownloading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_for_offline_outlined),
              label: Text(_isDownloading
                  ? 'Downloading Offline Map...'
                  : 'Download Offline Map Now'),
            ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final parsedCustom = _parseCustomCenterIfNeeded(showError: true);
    if (_mode == OfflineAreaMode.customCenter && parsedCustom == null) {
      return;
    }

    setState(() => _isSaving = true);
    await StorageService().saveOfflineMapSettings(
      mode: _mode == OfflineAreaMode.currentLocation
          ? 'current_location'
          : 'custom_center',
      radiusKm: _radiusKm,
      customLatitude: parsedCustom?.latitude,
      customLongitude: parsedCustom?.longitude,
      offlineOnlyModeEnabled: _offlineOnlyModeEnabled,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map download settings saved.')),
    );
  }

  Future<void> _downloadNow() async {
    if (_offlineOnlyModeEnabled) {
      final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Turn off Offline Mode to download new tiles from OSM.',
          ),
          backgroundColor: semanticColors.warning,
        ),
      );
      return;
    }

    final center = await _resolveCenter();
    if (center == null || !mounted) return;

    setState(() => _isDownloading = true);

    final tileLayer = _buildTileLayer();
    final region = CircleRegion(center, _radiusKm).toDownloadable(
      minZoom: 12,
      maxZoom: 17,
      options: tileLayer,
    );

    final estimate = await _cache.download.countTiles(region);
    final estimatedMb = ((estimate * _estimatedKbPerTile) / 1024).toStringAsFixed(1);
    if (!mounted) return;

    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Offline Map'),
        content: Text(
          'This will save about $estimate tiles in a '
          '${_radiusKm.toStringAsFixed(1)} km radius '
          '(approximately $estimatedMb MB). Continue?',
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

    if (shouldStart != true || !mounted) {
      setState(() => _isDownloading = false);
      return;
    }

    final progress = ValueNotifier<DownloadProgress?>(null);
    final streams = _cache.download.startForeground(
      region: region,
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
    setState(() => _isDownloading = false);

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

  Widget _buildMapPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _mode == OfflineAreaMode.customCenter
              ? 'Tap map to set custom center'
              : 'Preview of area around your location',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 300,
            child: _isResolvingPreview || _previewCenter == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _previewMapController,
                    options: MapOptions(
                      initialCenter: _previewCenter!,
                      initialZoom: _zoomForRadiusKm(_radiusKm),
                      onTap: _mode == OfflineAreaMode.customCenter
                          ? (_, point) => _setCustomCenter(point)
                          : null,
                    ),
                    children: [
                      _buildTileLayer(),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _previewCenter!,
                            radius: _radiusKm * 1000,
                            useRadiusInMeter: true,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.18),
                            borderStrokeWidth: 2,
                            borderColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _previewCenter!,
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.place,
                              size: 36,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleModeChange(OfflineAreaMode mode) async {
    setState(() => _mode = mode);

    if (mode == OfflineAreaMode.customCenter) {
      _syncPreviewCenterFromInputs();
      return;
    }

    final position = await LocationService().getCurrentPosition();
    if (!mounted) return;

    final center = position == null
        ? (_previewCenter ?? _fallbackCenter)
        : LatLng(position.latitude, position.longitude);

    setState(() {
      _previewCenter = center;
    });

    _previewMapController.move(center, _zoomForRadiusKm(_radiusKm));
  }

  void _setCustomCenter(LatLng point) {
    _latController.text = point.latitude.toStringAsFixed(6);
    _lngController.text = point.longitude.toStringAsFixed(6);

    setState(() {
      _previewCenter = point;
    });
    _previewMapController.move(point, _zoomForRadiusKm(_radiusKm));
  }

  void _syncPreviewCenterFromInputs() {
    final parsed = _parseCustomCenterIfNeeded(showError: false);
    if (parsed == null || !mounted) return;

    setState(() {
      _previewCenter = parsed;
    });
    _previewMapController.move(parsed, _zoomForRadiusKm(_radiusKm));
  }

  double _zoomForRadiusKm(double radiusKm) {
    if (radiusKm <= 1.5) return 14.5;
    if (radiusKm <= 3) return 13.6;
    if (radiusKm <= 5) return 12.8;
    if (radiusKm <= 8) return 12.2;
    if (radiusKm <= 12) return 11.6;
    if (radiusKm <= 18) return 11.0;
    return 10.4;
  }

  Future<LatLng?> _resolveCenter() async {
    if (_mode == OfflineAreaMode.customCenter) {
      return _parseCustomCenterIfNeeded(showError: true);
    }

    final position = await LocationService().getCurrentPosition();
    if (position == null && mounted) {
      final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get your current location.'),
          backgroundColor: semanticColors.danger,
        ),
      );
      return null;
    }

    return LatLng(position!.latitude, position.longitude);
  }

  LatLng? _parseCustomCenterIfNeeded({required bool showError}) {
    if (_mode != OfflineAreaMode.customCenter) return null;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    final isValid = lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;

    if (!isValid) {
      if (showError && mounted) {
        final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enter valid latitude/longitude values.'),
            backgroundColor: semanticColors.danger,
          ),
        );
      }
      return null;
    }

    return LatLng(lat, lng);
  }

  TileLayer _buildTileLayer() {
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

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _previewMapController.dispose();
    super.dispose();
  }
}
