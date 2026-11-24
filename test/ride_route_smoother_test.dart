import 'package:bike_tracker/utils/ride_route_smoother.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('smooths a GPS zigzag while preserving its endpoints', () {
    const route = [
      LatLng(0, 0),
      LatLng(1, 2),
      LatLng(2, 0),
      LatLng(3, 2),
      LatLng(4, 0),
    ];

    final smoothed = smoothRideRoute(route);

    expect(smoothed, hasLength(route.length));
    expect(smoothed.first, route.first);
    expect(smoothed.last, route.last);
    expect(smoothed[1].longitude, lessThan(route[1].longitude));
    expect(smoothed[2].longitude, greaterThan(route[2].longitude));
  });

  test('keeps short routes unchanged', () {
    const route = [LatLng(1, 2), LatLng(3, 4)];
    expect(smoothRideRoute(route), route);
  });
}
