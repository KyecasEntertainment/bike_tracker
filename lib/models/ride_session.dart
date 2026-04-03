import 'package:hive/hive.dart';
import 'track_point.dart';

part 'ride_session.g.dart';

/// Represents a complete bike ride session with all recorded data.
@HiveType(typeId: 0)
class RideSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  DateTime? endTime;

  @HiveField(3)
  List<Map<String, dynamic>> points;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  double totalDistance; // in meters

  @HiveField(6)
  int totalDuration; // in seconds

  @HiveField(7)
  String? name;

  RideSession({
    required this.id,
    required this.startTime,
    this.endTime,
    List<Map<String, dynamic>>? points,
    this.isCompleted = false,
    this.totalDistance = 0,
    this.totalDuration = 0,
    this.name,
  }) : points = points ?? [];

  /// Adds a track point to the session
  void addPoint(TrackPoint point) {
    points.add(point.toMap());
  }

  /// Returns all track points as TrackPoint objects
  List<TrackPoint> getTrackPoints() {
    return points.map((p) => TrackPoint.fromMap(p)).toList();
  }

  /// Calculates and updates the total distance
  void updateDistance(double distance) {
    totalDistance = distance;
  }

  /// Updates the total duration
  void updateDuration(int duration) {
    totalDuration = duration;
  }

  /// Marks the session as completed
  void complete() {
    endTime = DateTime.now();
    isCompleted = true;
    save(); // HiveObject's save method
  }

  /// Returns formatted duration string (HH:MM:SS)
  String get formattedDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    final seconds = totalDuration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns formatted distance string (km with 2 decimal places)
  String get formattedDistance {
    final km = totalDistance / 1000;
    return '${km.toStringAsFixed(2)} km';
  }

  /// Returns average speed in km/h
  double get averageSpeed {
    if (totalDuration == 0) return 0;
    final hours = totalDuration / 3600;
    final km = totalDistance / 1000;
    return km / hours;
  }

  /// Returns formatted average speed string
  String get formattedAverageSpeed {
    return '${averageSpeed.toStringAsFixed(1)} km/h';
  }

  /// Returns formatted start time string
  String get formattedStartTime {
    return '${startTime.day}/${startTime.month}/${startTime.year} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'RideSession(id: $id, startTime: $startTime, points: ${points.length}, distance: $totalDistance, duration: $totalDuration)';
  }
}
