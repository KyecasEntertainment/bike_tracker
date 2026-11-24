import 'package:bike_tracker/models/ride_session.dart';
import 'package:bike_tracker/screens/ride_detail_screen.dart';
import 'package:bike_tracker/utils/app_color_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ride details sheet can collapse and reopen', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ride = RideSession(
      id: 'test-ride',
      startTime: DateTime(2026, 11, 24, 8),
      endTime: DateTime(2026, 11, 24, 8, 30),
      totalDistance: 8500,
      totalDuration: 1800,
      name: 'Morning loop',
    );
    await tester.pumpWidget(MaterialApp(
      theme: AppColorTheme.themeFor(AppThemeOption.dark),
      home: RideDetailScreen(ride: ride),
    ));

    expect(find.text('Morning loop'), findsOneWidget);
    expect(find.text('8.50 km'), findsOneWidget);

    await tester.drag(find.text('Morning loop'), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('AVG SPEED'), findsOneWidget);
    expect(find.text('RIDE SUMMARY'), findsNothing);

    await tester.drag(find.text('AVG SPEED'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Morning loop'), findsOneWidget);
    expect(find.text('RIDE SUMMARY'), findsOneWidget);
  });
}
