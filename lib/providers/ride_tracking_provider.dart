import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/ride_session.dart';
import '../models/track_point.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/background_service.dart';

/// Enum representing the tracking state
enum TrackingState {
  idle, // Not tracking
  tracking, // Currently tracking
  paused, // Tracking paused
}

/// Provider for managing ride tracking state and data.
class RideTrackingProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();

  // State
  TrackingState _trackingState = TrackingState.idle;
  RideSession? _currentRide;
  List<TrackPoint> _currentTrackPoints = [];
  LatLng? _currentPosition;

  // Stats
  double _currentDistance = 0;
  int _currentDuration = 0;

  // Timer for duration tracking
  Timer? _durationTimer;
  int _persistTickCounter = 0;

  // Stream subscription
  StreamSubscription<TrackPoint>? _trackPointSubscription;

  RideTrackingProvider() {
    _restoreActiveRide();
  }

  // Getters
  TrackingState get trackingState => _trackingState;
  bool get isTracking => _trackingState == TrackingState.tracking;
  bool get isPaused => _trackingState == TrackingState.paused;
  bool get isIdle => _trackingState == TrackingState.idle;
  RideSession? get currentRide => _currentRide;
  List<TrackPoint> get currentTrackPoints => _currentTrackPoints;
  LatLng? get currentPosition => _currentPosition;
  double get currentDistance => _currentDistance;
  int get currentDuration => _currentDuration;

  /// Returns formatted duration string (HH:MM:SS)
  String get formattedDuration {
    final hours = _currentDuration ~/ 3600;
    final minutes = (_currentDuration % 3600) ~/ 60;
    final seconds = _currentDuration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns formatted distance string (km with 2 decimal places)
  String get formattedDistance {
    final km = _currentDistance / 1000;
    return '${km.toStringAsFixed(2)} km';
  }

  /// Returns average speed in km/h
  double get averageSpeed {
    if (_currentDuration == 0) return 0;
    final hours = _currentDuration / 3600;
    final km = _currentDistance / 1000;
    return km / hours;
  }

  /// Returns formatted average speed string
  String get formattedAverageSpeed {
    return '${averageSpeed.toStringAsFixed(1)} km/h';
  }

  /// Gets the current position
  Future<LatLng?> getCurrentPosition() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      _currentPosition = LatLng(position.latitude, position.longitude);
      notifyListeners();
    }
    return _currentPosition;
  }

  /// Starts a new ride tracking session
  Future<bool> startRide() async {
    if (_trackingState != TrackingState.idle) return false;

    // Create new ride session
    _currentRide = RideSession(
      id: _uuid.v4(),
      startTime: DateTime.now(),
    );

    // Clear previous data
    _currentTrackPoints = [];
    _currentDistance = 0;
    _currentDuration = 0;

    // Start location tracking
    final success = await _locationService.startTracking(
      intervalSeconds: 1,
      distanceFilter: 0,
    );
    if (!success) {
      _currentRide = null;
      return false;
    }

    // Listen to track points
    _trackPointSubscription = _locationService.trackPointStream.listen(
      _onNewTrackPoint,
    );

    // Start duration timer
    _currentDuration = 0;
    _startDurationTimer();

    _trackingState = TrackingState.tracking;

    // Start background service for persistent tracking
    try {
      await BackgroundService.setTrackingData(
        rideStart: _currentRide!.startTime,
        distanceMeters: _currentDistance,
      );
      await BackgroundService.startService();
      await _updateLiveNotification();
    } catch (e) {
      print('Error starting background service: $e');
    }

    notifyListeners();

    // Save initial ride
    await _storageService.saveRide(_currentRide!);
    await _storageService.setActiveRideId(_currentRide!.id);

    return true;
  }

  /// Pauses the current ride tracking
  void pauseRide() {
    if (_trackingState != TrackingState.tracking) return;

    _trackingState = TrackingState.paused;
    _durationTimer?.cancel();
    _trackPointSubscription?.pause();

    _currentRide?.updateDuration(_currentDuration);
    _currentRide?.updateDistance(_currentDistance);
    _currentRide?.save();

    notifyListeners();
  }

  /// Resumes the current ride tracking
  void resumeRide() {
    if (_trackingState != TrackingState.paused) return;

    _trackingState = TrackingState.tracking;
    _startDurationTimer();
    _trackPointSubscription?.resume();

    _updateLiveNotification();

    notifyListeners();
  }

  /// Stops and saves the current ride
  Future<void> stopRide() async {
    if (_trackingState == TrackingState.idle) return;

    // Stop background service
    try {
      await BackgroundService.stopService();
    } catch (e) {
      print('Error stopping background service: $e');
    }

    // Stop tracking
    await _locationService.stopTracking();
    await _trackPointSubscription?.cancel();
    _trackPointSubscription = null;
    _durationTimer?.cancel();

    // Finalize ride
    if (_currentRide != null) {
      _currentRide!.updateDistance(_currentDistance);
      _currentRide!.updateDuration(_currentDuration);
      _currentRide!.complete();
    }

    // Reset state
    _trackingState = TrackingState.idle;
    _currentRide = null;
    _currentTrackPoints = [];
    _currentDistance = 0;
    _currentDuration = 0;
    await _storageService.clearActiveRideId();
    notifyListeners();
  }

  /// Handles a new track point from the location service
  void _onNewTrackPoint(TrackPoint point) {
    if (_trackingState != TrackingState.tracking) return;

    // Update current position
    _currentPosition = LatLng(point.latitude, point.longitude);

    // Add point to list
    _currentTrackPoints.add(point);

    // Add point to ride session
    _currentRide?.addPoint(point);

    // Calculate distance
    if (_currentTrackPoints.length > 1) {
      final prevPoint = _currentTrackPoints[_currentTrackPoints.length - 2];
      final distance = _locationService.calculateDistance(
        prevPoint.latitude,
        prevPoint.longitude,
        point.latitude,
        point.longitude,
      );
      _currentDistance += distance;
      _currentRide?.updateDistance(_currentDistance);
      BackgroundService.setTrackingData(
        rideStart: _currentRide?.startTime ?? DateTime.now(),
        distanceMeters: _currentDistance,
      );
    }

    // Save ride periodically (every 10 points)
    if (_currentTrackPoints.length % 10 == 0 && _currentRide != null) {
      _currentRide!.updateDistance(_currentDistance);
      _currentRide!.updateDuration(_currentDuration);
      _currentRide!.save();

      _updateLiveNotification();
    }

    notifyListeners();
  }

  /// Starts the duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_trackingState != TrackingState.tracking) return;

      _syncDurationFromRideStart();
      _currentRide?.updateDuration(_currentDuration);
      _persistTickCounter++;

      if (_persistTickCounter % 5 == 0) {
        _currentRide?.updateDistance(_currentDistance);
        await _currentRide?.save();
      }

      await _updateLiveNotification();

      final stopRequested = await BackgroundService.consumeStopRequestedFlag();
      if (stopRequested) {
        await stopRide();
        return;
      }

      notifyListeners();
    });
  }

  /// Discards the current ride without saving
  Future<void> discardRide() async {
    // Stop background service
    try {
      await BackgroundService.stopService();
    } catch (e) {
      print('Error stopping background service: $e');
    }

    await _locationService.stopTracking();
    await _trackPointSubscription?.cancel();
    _trackPointSubscription = null;
    _durationTimer?.cancel();

    // Delete the ride from storage if it exists
    if (_currentRide != null) {
      await _storageService.deleteRide(_currentRide!.id);
    }

    // Reset state
    _trackingState = TrackingState.idle;
    _currentRide = null;
    _currentTrackPoints = [];
    _currentDistance = 0;
    _currentDuration = 0;
    await _storageService.clearActiveRideId();

    notifyListeners();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _trackPointSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _restoreActiveRide() async {
    final activeRideId = _storageService.getActiveRideId();
    if (activeRideId == null) return;

    final activeRide = _storageService.getRide(activeRideId);
    if (activeRide == null || activeRide.isCompleted) {
      await _storageService.clearActiveRideId();
      return;
    }

    final stopRequested = await BackgroundService.consumeStopRequestedFlag();
    if (stopRequested) {
      activeRide.updateDistance(activeRide.totalDistance);
      activeRide.updateDuration(activeRide.totalDuration);
      activeRide.complete();
      await _storageService.clearActiveRideId();
      return;
    }

    _currentRide = activeRide;
    _currentTrackPoints = activeRide.getTrackPoints();
    _currentDistance = activeRide.totalDistance;
    _syncDurationFromRideStart();
    _trackingState = TrackingState.tracking;
    notifyListeners();

    final started = await _locationService.startTracking(
      intervalSeconds: 1,
      distanceFilter: 0,
    );
    if (started) {
      _trackPointSubscription?.cancel();
      _trackPointSubscription = _locationService.trackPointStream.listen(
        _onNewTrackPoint,
      );
      _startDurationTimer();
      await BackgroundService.setTrackingData(
        rideStart: _currentRide!.startTime,
        distanceMeters: _currentDistance,
      );
      await BackgroundService.startService();
      await _updateLiveNotification();
      return;
    }

    _trackingState = TrackingState.paused;
    notifyListeners();
  }

  Future<void> _updateLiveNotification() async {
    _syncDurationFromRideStart();
    final km = (_currentDistance / 1000).toStringAsFixed(2);
    await BackgroundService.updateNotification(
      title: 'Bike Tracker',
      text: 'Duration: $formattedDuration | Distance: $km km',
    );
  }

  void _syncDurationFromRideStart() {
    final ride = _currentRide;
    if (ride == null) {
      _currentDuration = 0;
      return;
    }

    final elapsed = DateTime.now().difference(ride.startTime).inSeconds;
    _currentDuration = elapsed < 0 ? 0 : elapsed;
  }
}
