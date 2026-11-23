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
