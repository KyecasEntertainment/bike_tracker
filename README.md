# Bike Tracker

Bike Tracker is a Flutter app for recording bike rides with GPS, saving ride history locally, and reviewing completed routes on Google Maps.

## What It Does

- Tracks bike rides with live duration, distance, and average speed.
- Shows current or latest ride statistics alongside longest distance and fastest ride average speed records.
- Supports start, pause, resume, stop, save, and discard ride flows.
- Keeps tracking active through an Android foreground service notification while a ride is running.
- Persists rides locally with Hive, including GPS points, distance, duration, start time, and end time.
- Restores an unfinished active ride on launch when possible.
- Shows completed ride history with total ride count, total distance, and total duration.
- Displays recorded ride routes on Google Maps with animated route replay and start/end markers.
- Provides a Google Maps preview centered on the current location.
- Provides app theme settings with remembered Light, Dark, Green, and Blue themes.

## Main Screens

- **Home**: live ride timer, current or latest ride distance and average speed, personal bests, and ride controls.
- **History**: saved rides, aggregate totals, per-ride stats, delete-one, and clear-all actions.
- **Ride Details**: Google Maps route view, animated trail replay, and ride statistics.
- **Settings**: app theme settings and a Google Maps preview.

## Tech Stack

- Flutter and Dart
- Provider for state management
- Hive for local ride and settings storage
- Geolocator for GPS permissions, current location, and distance calculation
- flutter_foreground_task for Android foreground tracking notifications
- google_maps_flutter for maps
- latlong2 for recorded GPS coordinates

## Permissions

The Android app requests:

- Internet access for Google Maps
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

## Google Maps Cloud Setup

1. In Google Cloud Console, select the project that owns the map key, enable billing, and enable **Maps SDK for Android**. Enable **Maps SDK for iOS** too if building for iOS.
2. Create a separate restricted API key for each mobile platform. Restrict the Android key to package `com.kyecas.bike_tracker` and its signing SHA-1 fingerprint; run `cd android; .\gradlew signingReport` to find the debug fingerprint. Restrict the iOS key to bundle ID `com.kyecas.bike_tracker`. Restrict each key to its corresponding Maps SDK. [Google key security guidance](https://developers.google.com/maps/api-security-best-practices)
3. Grant the developer or build identity `Secret Manager Secret Accessor` access to the key secret. Retrieve it during the build and pass it through the platform environment variable; do not commit it in Dart code or a checked-in config file. [Access Secret Manager versions](https://cloud.google.com/secret-manager/docs/access-secret-version)

On Windows PowerShell, install the Google Cloud CLI, open a new terminal, and run `gcloud auth login` first. Then load an Android key into the current shell and run the app:

```powershell
$env:GOOGLE_MAPS_ANDROID_API_KEY = gcloud secrets versions access latest --secret="YOUR_ANDROID_KEY_SECRET" --project="YOUR_PROJECT_ID"
flutter run
```

For an iOS build, use the separate iOS key as `GOOGLE_MAPS_IOS_API_KEY`. The key is included in the compiled app, so platform and API restrictions are still required; Secret Manager keeps it out of source control and supplies it to the build.

## Project Notes

- Google Maps requires an API key configured for the target platform and a Google Cloud project with billing enabled.
- Android reads `GOOGLE_MAPS_ANDROID_API_KEY` (or `GOOGLE_MAPS_API_KEY`) from the build environment. iOS reads `GOOGLE_MAPS_IOS_API_KEY` from the build environment.
- Restrict each API key to the matching app identifier and Maps SDK. Keep the key out of source control; a mobile Maps API key is delivered in the app binary and must be protected with platform and API restrictions.
- Google Maps rendering is configured for Android and iOS. Web and desktop builds currently show a platform notice because web key setup and native desktop map support are not configured.
- Ride and settings data are stored on-device; there is no account, sync, or backend service.
- The share button in ride details is currently a placeholder.
