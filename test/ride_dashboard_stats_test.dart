import 'package:bike_tracker/models/ride_dashboard_stats.dart';
import 'package:bike_tracker/models/ride_session.dart';
import 'package:flutter_test/flutter_test.dart';

RideSession ride(String id, int day, double distance, int seconds) =>
    RideSession(
      id: id,
      startTime: DateTime(2026, 11, day),
      isCompleted: true,
      totalDistance: distance,
      totalDuration: seconds,
    );

void main() {
  test('no rides yields zero for all four statistics', () {
    final stats = RideDashboardStats.fromRides([]);
    expect(stats.distance, 0);
    expect(stats.averageSpeed, 0);
    expect(stats.longestDistance, 0);
    expect(stats.fastestAverageSpeed, 0);
  });

  test('latest ride and independent records work with unsorted history', () {
    final stats = RideDashboardStats.fromRides([
      ride('fastest', 1, 15000, 1800),
      ride('latest', 3, 10000, 3600),
      ride('longest', 2, 50000, 10000),
      RideSession(
          id: 'unfinished',
          startTime: DateTime(2026, 11, 4),
          totalDistance: 999000,
          totalDuration: 1),
    ]);
    expect(stats.distance, 10000);
    expect(stats.averageSpeed, 10);
    expect(stats.longestDistance, 50000);
    expect(stats.fastestAverageSpeed, 30);
  });

  test('a new active ride shows zero instead of the previous ride', () {
    final stats = RideDashboardStats.fromRides(
      [ride('saved', 1, 10000, 1800)],
      currentDistance: 0,
      currentAverageSpeed: 0,
    );
    expect(stats.distance, 0);
    expect(stats.averageSpeed, 0);
    expect(stats.longestDistance, 10000);
    expect(stats.fastestAverageSpeed, 20);
  });

  test('active ride can set both records; discarded values do not persist', () {
    final history = [ride('saved', 1, 10000, 1800)];
    final active = RideDashboardStats.fromRides(history,
        currentDistance: 20000, currentAverageSpeed: 25);
    expect(active.longestDistance, 20000);
    expect(active.fastestAverageSpeed, 25);
    final idle = RideDashboardStats.fromRides(history);
    expect(idle.distance, 10000);
    expect(idle.longestDistance, 10000);
    expect(idle.fastestAverageSpeed, 20);
  });

  test('rides with zero duration have a finite zero average speed', () {
    final stats = RideDashboardStats.fromRides([ride('zero', 1, 1000, 0)]);
    expect(stats.averageSpeed, 0);
    expect(stats.fastestAverageSpeed, 0);
  });
}
