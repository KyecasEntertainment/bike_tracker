import 'package:bike_tracker/models/ride_session.dart';
import 'package:bike_tracker/providers/ride_tracking_provider.dart';
import 'package:bike_tracker/providers/rides_provider.dart';
import 'package:bike_tracker/providers/theme_provider.dart';
import 'package:bike_tracker/screens/home_screen.dart';
import 'package:bike_tracker/utils/app_color_theme.dart';
import 'package:bike_tracker/widgets/dashboard_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class TestTracking extends ChangeNotifier implements RideTrackingProvider {
  TrackingState state = TrackingState.idle;
  double distance = 0;
  double speed = 0;
  VoidCallback? onSave;

  @override
  TrackingState get trackingState => state;
  @override
  bool get isIdle => state == TrackingState.idle;
  @override
  bool get isTracking => state == TrackingState.tracking;
  @override
  bool get isPaused => state == TrackingState.paused;
  @override
  double get currentDistance => distance;
  @override
  double get averageSpeed => speed;
  @override
  String get formattedDuration => isIdle ? '00:00' : '12:34';
  @override
  String get formattedDistance => '${(distance / 1000).toStringAsFixed(2)} km';
  @override
  Future<LatLng?> getCurrentPosition() async => null;
  @override
  Future<bool> startRide() async {
    state = TrackingState.tracking;
    notifyListeners();
    return true;
  }

  @override
  void pauseRide() {
    state = TrackingState.paused;
    notifyListeners();
  }

  @override
  void resumeRide() {
    state = TrackingState.tracking;
    notifyListeners();
  }

  @override
  Future<void> stopRide() async {
    onSave?.call();
    state = TrackingState.idle;
    notifyListeners();
  }

  @override
  Future<void> discardRide() async {
    state = TrackingState.idle;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestHistory extends RidesProvider {
  final saved = <RideSession>[];
  int loads = 0;
  @override
  List<RideSession> get rides => saved;
  @override
  Future<void> loadRides() async {
    loads++;
    notifyListeners();
  }

  @override
  Map<String, dynamic> getTotalStats() {
    final distance =
        saved.fold(0.0, (total, ride) => total + ride.totalDistance);
    final duration = saved.fold(0, (total, ride) => total + ride.totalDuration);
    return {
      'totalRides': saved.length,
      'formattedDistance': '${(distance / 1000).toStringAsFixed(2)} km',
      'formattedDuration':
          '${duration ~/ 3600} h ${(duration % 3600) ~/ 60} min',
    };
  }

  @override
  Future<void> deleteRide(String id) async {
    saved.removeWhere((ride) => ride.id == id);
    notifyListeners();
  }

  @override
  Future<void> clearAllRides() async {
    saved.clear();
    notifyListeners();
  }
}

class TestTheme extends ChangeNotifier implements ThemeProvider {
  @override
  AppThemeOption selectedTheme = AppThemeOption.dark;
  @override
  ThemeData get themeData => AppColorTheme.themeFor(selectedTheme);
  @override
  Future<void> setTheme(AppThemeOption option) async {
    selectedTheme = option;
    notifyListeners();
  }
}

DashboardStatCard stat(WidgetTester tester, String title) => tester
    .widgetList<DashboardStatCard>(find.byType(DashboardStatCard))
    .singleWhere((card) => card.title == title);

Future<void> pumpHome(
    WidgetTester tester, TestTracking tracking, TestHistory history,
    {Size size = const Size(393, 852), double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<RideTrackingProvider>.value(value: tracking),
      ChangeNotifierProvider<RidesProvider>.value(value: history),
      ChangeNotifierProvider<ThemeProvider>(create: (_) => TestTheme()),
    ],
    child: MaterialApp(
      theme: AppColorTheme.themeFor(AppThemeOption.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const HomeScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('latest ride, live values, pause and save refresh on home',
      (tester) async {
    final tracking = TestTracking();
    final history = TestHistory();
    history.saved.add(RideSession(
        id: 'old',
        startTime: DateTime(2026, 11, 1),
        isCompleted: true,
        totalDistance: 10000,
        totalDuration: 1800));
    tracking.onSave = () => history.saved.add(RideSession(
        id: 'new',
        startTime: DateTime(2026, 11, 2),
        isCompleted: true,
        totalDistance: tracking.distance,
        totalDuration: 3600));
    await pumpHome(tester, tracking, history);
    expect(stat(tester, 'Distance').value, '10.00');
    expect(stat(tester, 'Average Speed').value, '20.0');
    expect(find.text('00:00'), findsOneWidget);
    await tester.tap(find.text('Start Ride'));
    await tester.pumpAndSettle();
    expect(stat(tester, 'Distance').value, '0.00');
    tracking.distance = 25000;
    tracking.speed = 25;
    tracking.notifyListeners();
    await tester.pumpAndSettle();
    expect(stat(tester, 'Longest Distance').value, '25.00');
    expect(stat(tester, 'Fastest Average Speed').value, '25.0');
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('PAUSED'), findsOneWidget);
    expect(stat(tester, 'Distance').value, '25.00');
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(history.loads, 2);
    expect(stat(tester, 'Distance').value, '25.00');
    expect(stat(tester, 'Average Speed').value, '25.0');
    expect(find.text('00:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screen and large text scroll without overflowing',
      (tester) async {
    await pumpHome(tester, TestTracking(), TestHistory(),
        size: const Size(320, 640), scale: 1.8);
    expect(find.byType(DashboardStatCard), findsNWidgets(4));
    await tester.ensureVisible(find.text('Start Ride'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation selects only icon and label, and settings opens',
      (tester) async {
    await pumpHome(tester, TestTracking(), TestHistory());
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.indicatorColor, Colors.transparent);
    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);
    expect(find.text('No rides yet'), findsOneWidget);
    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history keeps deletion confirmation and updates totals',
      (tester) async {
    final history = TestHistory();
    history.saved.add(RideSession(
      id: 'saved',
      startTime: DateTime(2026, 11, 23),
      isCompleted: true,
      totalDistance: 24650,
      totalDuration: 4200,
    ));
    await pumpHome(tester, TestTracking(), history);
    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();
    expect(find.text('24.65 km'), findsWidgets);
    await tester.scrollUntilVisible(find.byTooltip('Delete ride'), 200);
    await tester.tap(find.byTooltip('Delete ride'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(history.saved, hasLength(1));
    await tester.tap(find.byTooltip('Delete ride'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(history.saved, isEmpty);
    expect(find.text('No rides yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history and settings support small screens and large text',
      (tester) async {
    final history = TestHistory();
    history.saved.add(RideSession(
      id: 'long',
      startTime: DateTime(2026, 11, 23),
      name: 'A long ride through the mountains',
      isCompleted: true,
      totalDistance: 123456,
      totalDuration: 15000,
    ));
    await pumpHome(tester, TestTracking(), history,
        size: const Size(320, 640), scale: 1.8);
    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Avg speed'), 250);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('App Theme Settings'), 200);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('App Theme Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('App Theme Settings'));
    await tester.pumpAndSettle();
    expect(find.text('App Theme'), findsOneWidget);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    final themeContext = tester.element(find.text('Light'));
    expect(
        themeContext.read<ThemeProvider>().selectedTheme, AppThemeOption.light);
    expect(tester.takeException(), isNull);
  });
}
