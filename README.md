# 🚌 Monion — Bus Security & Student Verification System

> Built by **VINEX** for **NINU University**  
> Version `1.0.0` · Flutter · Android & iOS

---

## What is Monion?

Monion is a mobile app that helps university bus drivers track which students board and exit the bus each trip. Using QR/barcode scanning of student national IDs, it creates a real-time digital log of every student's IN and OUT status per session. Admins can review all sessions, view recordings, and export data.

---

## Features

### Driver Role
- **Login** with name and bus plate number (no password needed)
- **Start a session** — choose direction (To University / From University)
- **Scan students IN** via QR/barcode scanner using the phone camera
- **Scan students OUT** — same scan toggles the student to OUT status
- **Manual scan management** — manually mark students in/out, view the full list
- **Front camera recording** — records the bus interior during the trip
- **WiFi camera (RTSP)** — live preview from an IMOU Ranger Pro IP camera via RTSP stream
- **Hotspot setup** — configure the phone's hotspot to connect the WiFi camera
- **End session** — closes the trip and saves all data

### Admin Role
- **Login** with username/password (`admin` / `admin123` by default)
- **View all sessions** — searchable and filterable list of every trip
- **Session detail** — see every student scanned in/out with timestamps
- **Recordings browser** — view front camera and WiFi camera recording logs
- **Export data** — CSV and PDF export (Phase 2)
- **Stats overview** — total sessions, active sessions, completed sessions

---

## App Architecture

```
lib/
├── main.dart                    # App entry point + SplashScreen
├── models/
│   ├── driver.dart              # Driver data model
│   ├── session.dart             # Bus trip session model
│   ├── scan.dart                # Student scan model (IN/OUT)
│   └── recording.dart          # Video recording model
├── screens/
│   ├── login_screen.dart        # Driver + Admin login (tabbed)
│   ├── splash_screen.dart       # Animated splash with VINEX logo
│   ├── driver/
│   │   ├── driver_dashboard.dart        # Main driver home screen
│   │   ├── scanner_screen.dart          # QR/barcode scanner
│   │   ├── camera_recording_screen.dart # Start front camera recording
│   │   ├── camera_view_screen.dart      # Split-screen camera preview
│   │   ├── manual_scan_management.dart  # Manual student IN/OUT control
│   │   └── hotspot_setup_screen.dart    # WiFi hotspot configuration
│   └── admin/
│       ├── admin_dashboard.dart         # Sessions list + search + stats
│       ├── session_detail_screen.dart   # Per-session scan data
│       ├── recordings_screen.dart       # Browse all recordings
│       ├── recording_view.dart          # Redirects to recordings screen
│       └── video_player_screen.dart     # Video playback (Phase 2)
├── services/
│   ├── database_service.dart    # SQLite — all DB operations (singleton)
│   ├── camera_service.dart      # Front camera init + recording control
│   ├── recording_service.dart   # Coordinates front + RTSP recording
│   ├── rtsp_service.dart        # RTSP stream via media_kit + session logs
│   ├── export_service.dart      # CSV/PDF export
│   └── hotspot_manager.dart     # Native hotspot control (MethodChannel)
├── widgets/
│   ├── custom_button.dart       # Primary / Secondary / Danger buttons
│   ├── custom_card.dart         # Card, InfoCard, SessionCard
│   └── status_badge.dart        # IN / OUT status pill badges
├── theme/
│   └── app_theme.dart           # Material 3 theme (VINEX blue)
└── utils/
    └── constants.dart           # Colors, text styles, app-wide constants
```

---

## Database Schema

Monion uses **SQLite** (via `sqflite`) with 4 tables:

| Table | Purpose |
|---|---|
| `sessions` | One row per bus trip — driver, plate, direction, times, scan counts |
| `scans` | One row per student per session — national ID, IN time, OUT time |
| `drivers` | Known drivers (name + bus plate, auto-created on first login) |
| `recordings` | Front camera and WiFi camera recording metadata |

Key logic: each student gets **one scan record per session**. Scanning IN creates it; scanning OUT updates `scan_type` to `'OUT'` and sets `scan_out_time`. Duplicate scans are handled gracefully.

---

## Setup & Build

### Prerequisites

- **Flutter SDK** `>=3.0.0` — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** or **VS Code** with Flutter plugin
- **Android device** or emulator (API 21+)
- For iOS: macOS with Xcode 14+

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/monion-scanner.git
cd monion-scanner
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run on Android (debug)

```bash
flutter run
```

### 4. Build release APK

```bash
flutter build apk --release
```

The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### 5. Build release App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

### 6. Run on iOS (requires macOS + Xcode)

```bash
cd ios && pod install && cd ..
flutter run
```

---

## Android Signing (Release Build)

The project expects a `key.properties` file at `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=PATH_TO_YOUR_KEYSTORE.jks
```

To generate a keystore:

```bash
keytool -genkey -v -keystore monion_release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias monion_key
```

> ⚠️ Never commit `key.properties` or `.jks` files to version control.

---

## WiFi Camera Setup (RTSP)

Monion supports live preview from an **IMOU Ranger Pro** IP camera.

1. Connect the IMOU camera to power and configure via the IMOU Life app
2. Set a static IP on the camera: `192.168.90.66`
3. Enable RTSP in the camera settings
4. Set RTSP credentials: user `admin`, password `MyCamStream123`
5. In the app, go to **Hotspot Setup** and enable the phone hotspot
6. Connect the camera to the phone's hotspot network
7. Navigate to **Camera View** — the RTSP stream should appear automatically

RTSP URL format used:
```
rtsp://admin:MyCamStream123@192.168.90.66:554/cam/realmonitor?channel=1&subtype=0
```

> To change the camera IP or credentials, edit `rtsp_service.dart` and `camera_view_screen.dart`.

---

## Default Credentials

| Role | Username | Password |
|---|---|---|
| Admin | `admin` | `admin123` |
| Driver | *(any name)* | *(any bus plate)* |

> ⚠️ **Change the admin credentials before production deployment.** They are currently hardcoded in `lib/utils/constants.dart`.

---

## Permissions Required

| Permission | Reason |
|---|---|
| `CAMERA` | QR scanning + front camera recording |
| `RECORD_AUDIO` | Audio in front camera recordings |
| `INTERNET` | RTSP stream from WiFi camera |
| `ACCESS_WIFI_STATE` / `CHANGE_WIFI_STATE` | Hotspot management |
| `ACCESS_FINE_LOCATION` | Required by Android for WiFi scanning |
| `READ/WRITE_EXTERNAL_STORAGE` | Saving recordings (Android ≤12) |
| `READ_MEDIA_VIDEO` | Reading recordings (Android 13+) |

---

## Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `mobile_scanner` | ^5.2.3 | QR/barcode scanning |
| `sqflite` | ^2.3.3 | Local SQLite database |
| `camera` | ^0.10.5+5 | Front camera recording |
| `media_kit` | ^1.1.10 | RTSP stream playback |
| `media_kit_video` | ^1.2.4 | Video rendering widget |
| `permission_handler` | ^11.3.1 | Runtime permissions |
| `path_provider` | ^2.1.4 | App storage directory |
| `pdf` | ^3.11.1 | PDF export |
| `csv` | ^6.0.0 | CSV export |
| `intl` | ^0.19.0 | Date formatting |
| `provider` | ^6.1.2 | State management |

---

## Development Phases

| Phase | Status | Features |
|---|---|---|
| **Phase 1** | ✅ Complete | Scanning, sessions, SQLite, front camera recording, RTSP preview, session logs |
| **Phase 2** | 🔜 Planned | Full video playback (`chewie` + `video_player`), RTSP recording via FFmpeg, CSV/PDF export |
| **Phase 3** | 🔜 Planned | Student photo capture, cloud sync, push notifications |

---

## Known Issues & Notes

- **RTSP recording** currently logs session metadata only (not actual video). Real RTSP-to-file recording requires FFmpeg native integration (Phase 2).
- **Hotspot control** uses a native `MethodChannel` (`com.vinex.monion/hotspot`). The native Android side must be implemented in `MainActivity.kt` for this to work.
- **Admin credentials** are hardcoded — move to secure storage or a backend in production.
- **`SplashScreen`** is defined in both `main.dart` and `splash_screen.dart` — the one in `main.dart` is actually used; the `splash_screen.dart` file is a duplicate that should be cleaned up.

---

## Project Info

- **App name:** Monion
- **Package ID:** `com.vinex.monion_scanner`
- **Company:** VINEX
- **Client:** NINU University
- **Platform:** Android (primary), iOS (supported)
- **Min Android SDK:** API 21 (Android 5.0)
- **Target Android SDK:** API 36

---

## License

Private — © VINEX. All rights reserved.
