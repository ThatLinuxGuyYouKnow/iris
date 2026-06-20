# Iris

Iris is a Flutter-based campus navigation app built for visually impaired users. It combines voice control, camera-assisted scene narration, GPS-aware routing, and community hazard reporting across web, mobile, and desktop targets.

## What it does

- Voice commands with speech-to-text and text-to-speech feedback
- A `Where am I?` flow that combines GPS, reverse geocoding, and camera narration
- Campus route planning on an interactive map
- Live obstacle detection in the browser/PWA camera view
- Saved routes and hazard storage with Hive
- A community section for shared navigation updates

## Tech Stack

- Flutter
- Provider for app state
- `flutter_map` and `latlong2` for routing maps
- Hive CE for local storage
- Web APIs for browser-based speech, camera, and location features
- Netlify Functions for server-side proxying of AI and location services

## Requirements

- Flutter SDK 3.41.x or newer
- Dart 3.11.x
- Android Studio, Xcode, or a browser depending on your target platform
- For production AI and geocoding features:
  - `GEMINI_API_KEY`
  - `OPENCODE_API_KEY`
  - `RAPIDAPI_KEY`

## Setup

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Run the app locally:

   ```bash
   flutter run
   ```

3. Run on the web if you want the camera and browser-based services:

   ```bash
   flutter run -d chrome
   ```

## Environment Variables

Iris supports two modes for API access:

- Direct mode: pass keys with `--dart-define`
- Proxy mode: use Netlify serverless functions in production

Common local examples:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key
flutter run --dart-define=OPENCODE_API_KEY=your_key
flutter run --dart-define=RAPIDAPI_KEY=your_key
```

In production, the Netlify functions at `/api/gemini`, `/api/narration`, and `/api/whereami` keep those keys server-side.

## Build

Android, iOS, macOS, Linux, and Windows builds use the standard Flutter commands:

```bash
flutter build apk
flutter build ios
flutter build macos
flutter build linux
flutter build windows
```

For web:

```bash
flutter build web --release
```

## Netlify Deployment

The repo includes `netlify.toml` and a custom build script for the web app.

- Build command: `bash scripts/build-netlify.sh`
- Publish directory: `build/web`
- Functions directory: `netlify/functions`

The Netlify setup also rewrites:

- `/api/gemini` -> `/.netlify/functions/gemini`
- `/api/whereami` -> `/.netlify/functions/whereami`
- `/api/narration` -> `/.netlify/functions/narration`

## Tests

Run the test suite with:

```bash
flutter test
```

## Notes

- The app is designed to work well as a web/PWA experience because browser APIs are used for speech recognition, camera access, and geolocation.
- `RouteStore` uses Hive so saved routes and hazards work across web and native platforms.
- Some AI-assisted features depend on external services and may degrade gracefully when those services are unavailable.
