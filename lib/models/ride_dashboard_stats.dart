import 'ride_session.dart';

/// Home statistics, using the active ride or the latest completed ride.
class RideDashboardStats {
  final double distance;
  final double averageSpeed;
  final double longestDistance;
  final double fastestAverageSpeed;

  const RideDashboardStats._({
    required this.distance,
    required this.averageSpeed,
    required this.longestDistance,
    required this.fastestAverageSpeed,
  });

  factory RideDashboardStats.fromRides(
    Iterable<RideSession> rides, {
    double? currentDistance,
    double? currentAverageSpeed,
  }) {
    RideSession? latest;
    double longest = currentDistance ?? 0;
    double fastest = currentAverageSpeed ?? 0;

    for (final ride in rides.where((ride) => ride.isCompleted)) {
      if (latest == null || ride.startTime.isAfter(latest.startTime)) {
        latest = ride;
      }
      if (ride.totalDistance > longest) longest = ride.totalDistance;
      if (ride.averageSpeed > fastest) fastest = ride.averageSpeed;
    }

    return RideDashboardStats._(
      distance: currentDistance ?? latest?.totalDistance ?? 0,
      averageSpeed: currentAverageSpeed ?? latest?.averageSpeed ?? 0,
      longestDistance: longest,
      fastestAverageSpeed: fastest,
    );
  }
}
