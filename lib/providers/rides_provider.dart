import 'package:flutter/material.dart';
import '../models/ride_session.dart';
import '../services/storage_service.dart';

/// Provider for managing ride history.
class RidesProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  List<RideSession> _rides = [];
  bool _isLoading = false;

  // Getters
  List<RideSession> get rides => _rides;
  bool get isLoading => _isLoading;
  int get rideCount => _rides.length;

  /// Loads all completed rides from storage
  Future<void> loadRides() async {
    _isLoading = true;
    notifyListeners();

    try {
      _rides = _storageService.getCompletedRides();
    } catch (e) {
      debugPrint('Error loading rides: $e');
      _rides = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Gets a specific ride by ID
  RideSession? getRideById(String id) {
    try {
      return _rides.firstWhere((ride) => ride.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Deletes a ride by ID
  Future<void> deleteRide(String id) async {
    await _storageService.deleteRide(id);
    _rides.removeWhere((ride) => ride.id == id);
    notifyListeners();
  }

  /// Clears all rides
  Future<void> clearAllRides() async {
    await _storageService.clearAllRides();
    _rides = [];
    notifyListeners();
  }

  /// Calculates total statistics across all rides
  Map<String, dynamic> getTotalStats() {
    double totalDistance = 0;
    int totalDuration = 0;
    int totalRides = _rides.length;

    for (final ride in _rides) {
      totalDistance += ride.totalDistance;
      totalDuration += ride.totalDuration;
    }

    return {
      'totalRides': totalRides,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'formattedDistance': '${(totalDistance / 1000).toStringAsFixed(2)} km',
      'formattedDuration': _formatDuration(totalDuration),
    };
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '$hours h ${minutes} min';
    }
    return '$minutes min';
  }
}
