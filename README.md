# Ambient Doodle Pro

Ambient Doodle Pro is a full-screen Flutter drawing app with realtime Firebase sync, a floating tool palette, and gallery export.

## Features

- Fullscreen immersive drawing canvas
- Pen, sketch, marker, and eraser tools
- Color picker and adjustable stroke styles
- Undo and clear actions
- Realtime cloud sync with Firebase Realtime Database
- Save doodles to device gallery

## Tech Stack

- Flutter
- `flutter_drawing_board`
- Firebase (`firebase_core`, `firebase_database`)
- `wakelock_plus`
- `gal`
- `flutter_colorpicker`

## Prerequisites

- Flutter SDK 3.9+
- Android Studio (or Android SDK + adb)
- A connected Android device or emulator
- Firebase project configuration (optional but recommended for sync)

## Setup

1. Install dependencies:

```bash
flutter pub get
```

2. (Optional) Configure Firebase:
- Add your Android `google-services.json` to `android/app/`
- Ensure Firebase is enabled for Realtime Database

3. Run the app:

```bash
flutter run
```

## Testing

Run tests with:

```bash
flutter test
```

## Build Smaller Android Artifacts

Use ABI-split release APKs so each device downloads only its CPU architecture:

```bash
flutter build apk --release --split-per-abi
```

Output files are generated under `build/app/outputs/flutter-apk/`.

For Play Store distribution, prefer an Android App Bundle:

```bash
flutter build appbundle --release
```

## Project Structure

- `lib/main.dart` - app bootstrap and theme setup
- `lib/widgets/canvas_screen.dart` - main drawing screen
- `lib/widgets/floating_toolbar.dart` - floating controls UI
- `lib/services/firebase_sync_service.dart` - realtime cloud sync logic
- `lib/models/drawing_tool.dart` - drawing tool model/types

## Notes

- Firebase initialization is wrapped in a safe `try/catch`, so the app can still run locally without Firebase config.
- Gallery save requires media permissions on device.
