import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ride_session.dart';
import '../utils/app_color_theme.dart';

/// Service for managing local storage using Hive.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _rideBoxName = 'rides';
  static const String _settingsBoxName = 'app_settings';
  static const String _offlineModeKey = 'offline_map_mode';
  static const String _offlineRadiusKmKey = 'offline_map_radius_km';
  static const String _offlineCustomLatKey = 'offline_map_custom_lat';
  static const String _offlineCustomLngKey = 'offline_map_custom_lng';
  static const String _offlineOnlyModeEnabledKey = 'offline_only_mode_enabled';
  static const String _selectedThemeKey = 'selected_app_theme';
  static const String _activeRideIdKey = 'active_ride_id';

  Box<RideSession>? _rideBox;
  Box<dynamic>? _settingsBox;

  /// Initializes Hive and opens the ride box
  Future<void> initialize() async {
    // Get application documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    
    // Initialize Hive
    await Hive.initFlutter(appDocDir.path);
    
    // Register adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RideSessionAdapter());
    }

    // Open the rides box
    _rideBox = await Hive.openBox<RideSession>(_rideBoxName);

    // Open app settings box
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }

  /// Gets the rides box
  Box<RideSession> get rideBox {
    if (_rideBox == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    return _rideBox!;
  }

  Box<dynamic> get settingsBox {
    if (_settingsBox == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    return _settingsBox!;
  }

  Future<void> saveOfflineMapSettings({
    required String mode,
    required double radiusKm,
    double? customLatitude,
    double? customLongitude,
    required bool offlineOnlyModeEnabled,
  }) async {
    await settingsBox.put(_offlineModeKey, mode);
    await settingsBox.put(_offlineRadiusKmKey, radiusKm);
    await settingsBox.put(_offlineOnlyModeEnabledKey, offlineOnlyModeEnabled);

    if (customLatitude != null) {
      await settingsBox.put(_offlineCustomLatKey, customLatitude);
    }
    if (customLongitude != null) {
      await settingsBox.put(_offlineCustomLngKey, customLongitude);
    }
  }

  Map<String, dynamic> getOfflineMapSettings() {
    return {
      'mode': settingsBox.get(_offlineModeKey, defaultValue: 'current_location') as String,
      'radiusKm': (settingsBox.get(_offlineRadiusKmKey, defaultValue: 5.0) as num)
          .toDouble(),
      'customLatitude': (settingsBox.get(_offlineCustomLatKey) as num?)?.toDouble(),
      'customLongitude': (settingsBox.get(_offlineCustomLngKey) as num?)?.toDouble(),
      'offlineOnlyModeEnabled':
          settingsBox.get(_offlineOnlyModeEnabledKey, defaultValue: false) as bool,
    };
  }

  bool isOfflineOnlyModeEnabled() {
    return settingsBox.get(_offlineOnlyModeEnabledKey, defaultValue: false) as bool;
  }

  Future<void> saveSelectedTheme(AppThemeOption option) async {
    await settingsBox.put(_selectedThemeKey, option.storageValue);
  }

  AppThemeOption getSelectedTheme() {
    final value = settingsBox.get(_selectedThemeKey, defaultValue: 'dark') as String;
    return AppThemeOptionX.fromStorageValue(value);
  }

  Future<void> setActiveRideId(String rideId) async {
    await settingsBox.put(_activeRideIdKey, rideId);
  }

  String? getActiveRideId() {
    return settingsBox.get(_activeRideIdKey) as String?;
  }

  Future<void> clearActiveRideId() async {
    await settingsBox.delete(_activeRideIdKey);
  }

  /// Saves a ride session
  Future<void> saveRide(RideSession ride) async {
    await rideBox.put(ride.id, ride);
  }

  /// Gets a ride session by ID
  RideSession? getRide(String id) {
    return rideBox.get(id);
  }

  /// Gets all ride sessions
  List<RideSession> getAllRides() {
    return rideBox.values.toList();
  }

  /// Gets all completed ride sessions, sorted by start time (newest first)
  List<RideSession> getCompletedRides() {
    return rideBox.values
        .where((ride) => ride.isCompleted)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Deletes a ride session
  Future<void> deleteRide(String id) async {
    await rideBox.delete(id);
  }

  /// Clears all ride sessions
  Future<void> clearAllRides() async {
    await rideBox.clear();
  }

  /// Gets the count of saved rides
  int get rideCount => rideBox.length;

  /// Gets the count of completed rides
  int get completedRideCount {
    return rideBox.values.where((ride) => ride.isCompleted).length;
  }

  /// Closes the Hive box
  Future<void> close() async {
    await _rideBox?.close();
    await _settingsBox?.close();
  }
}
