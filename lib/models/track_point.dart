import 'package:latlong2/latlong.dart';

/// Represents a single GPS coordinate point recorded during a bike ride.
class TrackPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// Creates a TrackPoint from a Map (for Hive storage)
  factory TrackPoint.fromMap(Map<String, dynamic> map) {
    return TrackPoint(
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  /// Converts TrackPoint to a Map (for Hive storage)
  Map<String, dynamic> toMap() {
    return {
      'lat': latitude,
      'lng': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Returns a LatLng object for map display.
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  @override
  String toString() {
    return 'TrackPoint(lat: $latitude, lng: $longitude, timestamp: $timestamp)';
  }
}
