# Bike Tracker

Bike Tracker is a Flutter app for recording bike rides with GPS, saving ride history locally, and reviewing completed routes on an OpenStreetMap-based map.

## What It Does

- Tracks bike rides with live duration, distance, and average speed.
- Shows current or latest ride statistics alongside longest distance and fastest ride average speed records.
- Supports start, pause, resume, stop, save, and discard ride flows.
- Keeps tracking active through an Android foreground service notification while a ride is running.
- Persists rides locally with Hive, including GPS points, distance, duration, start time, and end time.
- Restores an unfinished active ride on launch when possible.
- Shows completed ride history with total ride count, total distance, and total duration.
- Displays each saved ride on a map with an animated route replay, start marker, end marker, and ride statistics sheet.
- Caches OpenStreetMap tiles with `flutter_map_tile_caching`.
- Downloads offline map tiles either around a saved ride route or around a selected offline area.
- Provides map settings for current-location or custom-coordinate offline downloads, a 1-30 km radius, and offline-only map mode.
- Provides app theme settings with remembered Light, Dark, Green, and Blue themes.

## Main Screens

- **Home**: live ride timer, current or latest ride distance and average speed, personal bests, and ride controls.
- **History**: saved rides, aggregate totals, per-ride stats, delete-one, and clear-all actions.
- **Ride Details**: route map, animated trail replay, offline map download for the ride area, and ride statistics.
- **Settings**: app theme settings and map/offline tile settings.

## Tech Stack

- Flutter and Dart
- Provider for state management
- Hive for local ride and settings storage
- Geolocator for GPS permissions, current location, and distance calculation
- flutter_foreground_task for Android foreground tracking notifications
- flutter_map, latlong2, and OpenStreetMap tiles for maps
- flutter_map_tile_caching for cached and offline map tiles

## Permissions

The Android app requests:

- Internet access for online map tiles
- Fine/coarse/background location for ride tracking
- Foreground service permissions for background ride tracking
- Notification permission on Android 13+

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Generate Hive adapters after changing annotated models:

```bash
dart run build_runner build
```

## Project Notes

- Offline maps use OpenStreetMap raster tiles and the `bike_tracker_cache` tile store.
- Ride and settings data are stored on-device; there is no account, sync, or backend service.
- The share button in ride details is currently a placeholder.
- `PHASE_OFFLINE_MAP_OPTIMIZATION.md` contains planning notes for future offline tile download optimizations.
