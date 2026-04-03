import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ride_tracking_provider.dart';
import 'providers/rides_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'screens/home_screen.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService().initialize();

  // Initialize background service
  await BackgroundService.initialize();

  // Initialize flutter_map_tile_caching
  await FMTCObjectBoxBackend().initialise();

  const cacheStore = FMTCStore('bike_tracker_cache');
  if (!await cacheStore.manage.ready) {
    await cacheStore.manage.create();
  }

  runApp(const BikeTrackerApp());
}

class BikeTrackerApp extends StatelessWidget {
  const BikeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RideTrackingProvider()),
        ChangeNotifierProvider(create: (_) => RidesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Bike Tracker',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
