import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Softens GPS jitter while keeping the recorded start and end in place.
List<LatLng> smoothRideRoute(List<LatLng> points) {
  if (points.length < 3) return List<LatLng>.of(points);

  final smoothed = <LatLng>[points.first];
  for (var index = 1; index < points.length - 1; index++) {
    final previous = points[index - 1];
    final current = points[index];
    final next = points[index + 1];
    smoothed.add(LatLng(
      (previous.latitude + 2 * current.latitude + next.latitude) / 4,
      (previous.longitude + 2 * current.longitude + next.longitude) / 4,
    ));
  }
  smoothed.add(points.last);
  return smoothed;
}
