import 'package:intl/intl.dart';

/// Formats a duration in seconds to a human-readable string
String formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m ${secs}s';
  } else if (minutes > 0) {
    return '${minutes}m ${secs}s';
  }
  return '${secs}s';
}

/// Formats a distance in meters to a human-readable string
String formatDistance(double meters) {
  if (meters >= 1000) {
    final km = meters / 1000;
    return '${km.toStringAsFixed(2)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}

/// Formats a speed in m/s to km/h
String formatSpeed(double metersPerSecond) {
  final kmh = metersPerSecond * 3.6;
  return '${kmh.toStringAsFixed(1)} km/h';
}

/// Formats a DateTime to a readable date string
String formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

/// Formats a DateTime to a readable time string
String formatTime(DateTime date) {
  return DateFormat('h:mm a').format(date);
}

/// Formats a DateTime to a readable date and time string
String formatDateTime(DateTime date) {
  return DateFormat('MMM d, yyyy h:mm a').format(date);
}

/// Calculates the average speed from distance and duration
double calculateAverageSpeed(double distanceMeters, int durationSeconds) {
  if (durationSeconds == 0) return 0;
  final hours = durationSeconds / 3600;
  final km = distanceMeters / 1000;
  return km / hours;
}

/// Calculates pace (time per kilometer)
String calculatePace(int durationSeconds, double distanceMeters) {
  if (distanceMeters == 0) return '--:--';
  
  final km = distanceMeters / 1000;
  final secondsPerKm = durationSeconds / km;
  
  final minutes = secondsPerKm ~/ 60;
  final seconds = (secondsPerKm % 60).toInt();
  
  return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
}
