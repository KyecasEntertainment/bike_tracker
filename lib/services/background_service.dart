import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:isolate';

const String kStopRideButtonId = 'stop_ride';
const String kStopRideRequestedKey = 'stop_ride_requested';
const String kRideStartEpochMsKey = 'ride_start_epoch_ms';
const String kRideDistanceMetersKey = 'ride_distance_meters';

String _formatDurationFromSeconds(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BikeTrackerTaskHandler());
}

class BikeTrackerTaskHandler extends TaskHandler {
  Future<void> _refreshNotificationFromStoredRide() async {
    final startEpochMs =
        await FlutterForegroundTask.getData<int>(key: kRideStartEpochMsKey);
    final distanceMeters = await FlutterForegroundTask.getData<double>(
      key: kRideDistanceMetersKey,
    );

    if (startEpochMs == null) return;

    final startedAt = DateTime.fromMillisecondsSinceEpoch(startEpochMs);
    final elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
    final km = ((distanceMeters ?? 0) / 1000).toStringAsFixed(2);
    final duration = _formatDurationFromSeconds(elapsedSeconds);

    await FlutterForegroundTask.updateService(
      notificationTitle: 'Bike Tracker',
      notificationText: 'Duration: $duration | Distance: $km km',
      callback: startCallback,
    );
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    await _refreshNotificationFromStoredRide();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    await _refreshNotificationFromStoredRide();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == kStopRideButtonId) {
      FlutterForegroundTask.saveData(key: kStopRideRequestedKey, value: true);
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}

/// Background service for tracking when the app is closed
class BackgroundService {
  /// Initializes the background service
  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'bike_tracker_channel',
        channelName: 'Bike Tracker Service',
        channelDescription: 'Notification for bike tracking background service',
        isSticky: true,
        buttons: const [
          NotificationButton(id: kStopRideButtonId, text: 'Stop'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Starts the foreground service with tracking
  static Future<bool> startService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        return true;
      }

      await FlutterForegroundTask.saveData(
        key: kStopRideRequestedKey,
        value: false,
      );
      await FlutterForegroundTask.saveData(
        key: kRideDistanceMetersKey,
        value: 0.0,
      );

      final result = await FlutterForegroundTask.startService(
        notificationTitle: 'Bike Tracker',
        notificationText: 'Duration: 00:00 | Distance: 0.00 km',
        callback: startCallback,
      );
      return result;
    } catch (e) {
      print('Error starting background service: $e');
      return false;
    }
  }

  /// Stops the foreground service
  static Future<bool> stopService() async {
    try {
      await FlutterForegroundTask.removeData(key: kRideStartEpochMsKey);
      await FlutterForegroundTask.removeData(key: kRideDistanceMetersKey);
      final result = await FlutterForegroundTask.stopService();
      return result;
    } catch (e) {
      print('Error stopping background service: $e');
      return false;
    }
  }

  /// Checks if the service is running
  static Future<bool> isServiceRunning() async {
    try {
      return await FlutterForegroundTask.isRunningService;
    } catch (e) {
      print('Error checking service status: $e');
      return false;
    }
  }

  /// Updates the notification text
  static Future<void> updateNotification({
    required String title,
    required String text,
  }) async {
    try {
      if (!await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
        callback: startCallback,
      );
    } catch (e) {
      print('Error updating notification: $e');
    }
  }

  static Future<void> setTrackingData({
    required DateTime rideStart,
    required double distanceMeters,
  }) async {
    try {
      await FlutterForegroundTask.saveData(
        key: kRideStartEpochMsKey,
        value: rideStart.millisecondsSinceEpoch,
      );
      await FlutterForegroundTask.saveData(
        key: kRideDistanceMetersKey,
        value: distanceMeters,
      );
    } catch (e) {
      print('Error saving tracking metadata: $e');
    }
  }

  static Future<bool> consumeStopRequestedFlag() async {
    try {
      final requested = await FlutterForegroundTask.getData<bool>(
        key: kStopRideRequestedKey,
      );
      if (requested == true) {
        await FlutterForegroundTask.saveData(
          key: kStopRideRequestedKey,
          value: false,
        );
        return true;
      }
    } catch (e) {
      print('Error reading stop requested flag: $e');
    }
    return false;
  }
}
