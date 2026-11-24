import 'dart:ui' as ui;

import 'package:bike_tracker/widgets/ride_route_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('route stroke grows between vertices on repaint', (tester) async {
    final progress = ValueNotifier<double>(0.5);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: 100,
            height: 100,
            child: ColoredBox(
              color: Colors.white,
              child: CustomPaint(
                painter: RideRoutePainter(
                  points: const [Offset(10, 50), Offset(90, 50)],
                  progress: progress,
                  color: Colors.green,
                  strokeWidth: 8,
                ),
              ),
            ),
          ),
        ),
      ),
    ));

    Future<Color> pixelAt(int x, int y) async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
              .buffer
              .asUint8List();
      final index = (y * image.width + x) * 4;
      final color = Color.fromARGB(
        bytes[index + 3],
        bytes[index],
        bytes[index + 1],
        bytes[index + 2],
      );
      image.dispose();
      return color;
    }

    expect((await tester.runAsync(() => pixelAt(30, 50)))?.toARGB32(),
        Colors.green.toARGB32());
    expect((await tester.runAsync(() => pixelAt(70, 50)))?.toARGB32(),
        Colors.white.toARGB32());

    progress.value = 1;
    await tester.pump();
    expect((await tester.runAsync(() => pixelAt(70, 50)))?.toARGB32(),
        Colors.green.toARGB32());
    progress.dispose();
  });
}
