import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/track_point.dart';

/// Service for handling GPS location tracking with permissions.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<TrackPoint> _trackPointController =
      StreamController<TrackPoint>.broadcast();

  /// Stream of track points for listeners
  Stream<TrackPoint> get trackPointStream => _trackPointController.stream;

  /// Current position stream subscription
  StreamSubscription<Position>? get positionStreamSubscription =>
      _positionStreamSubscription;

  /// Checks if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Checks and requests location permissions
  /// Returns true if permissions are granted
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return false;
    }

    // Check current permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return false;
    }

    // Permissions are granted
    return true;
  }

  /// Gets the current position
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Starts tracking location with specified interval
  /// [intervalSeconds] - time between location updates (default: 1 second)
  /// [distanceFilter] - minimum distance in meters before update (default: 0 meters)
  Future<bool> startTracking({
    int intervalSeconds = 1,
    int distanceFilter = 0,
  }) async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return false;

    // Stop any existing tracking
    await stopTracking();

    // Foreground notification is handled by BackgroundService.
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
      intervalDuration: Duration(seconds: intervalSeconds),
    );

    // Start position stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        final trackPoint = TrackPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        );
        _trackPointController.add(trackPoint);
      },
      onError: (error) {
        print('Error in position stream: $error');
      },
    );

    return true;
  }

  /// Stops tracking location
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Checks if currently tracking
  bool get isTracking => _positionStreamSubscription != null;

  /// Calculates distance between two coordinates in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calculates total distance from a list of track points
  double calculateTotalDistance(List<TrackPoint> points) {
    if (points.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 1; i < points.length; i++) {
      totalDistance += calculateDistance(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return totalDistance;
  }

  /// Opens app settings for location permissions
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Opens location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Disposes resources
  void dispose() {
    stopTracking();
    _trackPointController.close();
  }
}
