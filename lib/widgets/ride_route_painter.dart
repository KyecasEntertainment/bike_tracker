import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Draws a growing route without sending every animation frame to Google Maps.
class RideRoutePainter extends CustomPainter {
  RideRoutePainter({
    required this.points,
    required this.progress,
    required this.color,
    required this.strokeWidth,
  }) : super(repaint: progress) {
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
    }
    final metrics = path.computeMetrics().iterator;
    _metric = metrics.moveNext() ? metrics.current : null;
  }

  final List<Offset> points;
  final ValueListenable<double> progress;
  final Color color;
  final double strokeWidth;
  late final PathMetric? _metric;

  @override
  void paint(Canvas canvas, Size size) {
    final metric = _metric;
    if (metric == null) return;

    final visibleLength = metric.length * progress.value.clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(metric.extractPath(0, visibleLength), paint);
  }

  @override
  bool shouldRepaint(covariant RideRoutePainter oldDelegate) =>
      points != oldDelegate.points ||
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth;
}
