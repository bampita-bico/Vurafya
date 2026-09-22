# Vurafya Mobile App

Flutter patient app for **Vurafya** by **VuraLabs**.

## Features

- Health dashboard with local stability scoring (works offline)
- Medical tab: trajectory and regime views (API or offline fallback)
- Gamified avatar stats linked to operating-band summaries
- Auth: email/password register and sign-in against the Vurafya API

## Prerequisites

- Flutter SDK (see `pubspec.yaml` for Dart SDK constraint)
- Android SDK for APK builds
- Vurafya backend reachable on your network (for login and sync)

## API URL (important)

Pass the API URL as a build-time setting; do not edit source files:

```bash
flutter run --dart-define=VURAFYA_API_URL=http://YOUR_LAN_IP:8000/api/v1
```

| Target | Base URL |
|--------|----------|
| Android emulator | `http://10.0.2.2:8000/api/v1` |
| Physical device | `http://<laptop-lan-ip>:8000/api/v1` |

Phone and API host must be on the **same Wi‑Fi**. Rebuild the APK after any IP change.

## Run (development)

```bash
flutter pub get
flutter run
```

## Build release APK

```bash
flutter pub get
flutter build apk --release --dart-define=VURAFYA_API_URL=https://api.example.com/api/v1
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Release signing requires an untracked `android/key.properties` with `storeFile`,
`storePassword`, `keyAlias`, and `keyPassword`. Debug keys are rejected for
release packaging. Copy canonical builds to `../releases/`.

## Install

```bash
adb install -r ../releases/Vurafya-v1.0.0-build4-vuralabs-2026-08-28-release.apk
```

Launcher name: **Vurafya** (`application-label` in manifest).

## Login

With backend running:

| Method | Details |
|--------|---------|
| Demo | `director.demo@vurafya.local` / `change-me-demo-password` |
| Register | **Sign Up** on the login screen |

No demo button on mobile — use credentials or register.

## Offline engine

`lib/core/engine/offline_edge_engine.dart` mirrors backend local Ψₛ logic, so
the app does not require Runtime or API connectivity. It only scores valid local
measurements; with no cached measurements it shows insufficient data rather than
inventing a stable patient state.

## Tests

```bash
flutter test
flutter analyze
```

Backend integration tests (from repo root):

```bash
python -m pytest tests/test_local_prediction.py
```

---

© 2026 **VuraLabs**
