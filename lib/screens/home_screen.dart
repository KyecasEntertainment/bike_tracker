import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rides_provider.dart';
import '../providers/ride_tracking_provider.dart';
import 'tracking_screen.dart';
import 'history_screen.dart';

/// Main home screen with bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  RideTrackingProvider? _trackingProvider;
  bool _hadActiveRide = false;

  final List<Widget> _screens = const [
    TrackingScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load rides when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RidesProvider>().loadRides();
      _trackingProvider = context.read<RideTrackingProvider>();
      _hadActiveRide = !_trackingProvider!.isIdle;
      _trackingProvider!.addListener(_onTrackingChanged);
    });
  }

  void _onTrackingChanged() {
    final hasActiveRide = !_trackingProvider!.isIdle;
    if (_hadActiveRide && !hasActiveRide) {
      context.read<RidesProvider>().loadRides();
    }
    _hadActiveRide = hasActiveRide;
  }

  @override
  void dispose() {
    _trackingProvider?.removeListener(_onTrackingChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        indicatorColor: Colors.transparent,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Refresh rides when switching to history tab
          if (index == 1) {
            context.read<RidesProvider>().loadRides();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_outlined),
            label: 'HOME',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'HISTORY',
          ),
        ],
      ),
    );
  }
}
