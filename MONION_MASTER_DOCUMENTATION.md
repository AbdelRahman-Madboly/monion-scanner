# MONION COMPLETE SYSTEM - MASTER DOCUMENTATION

**Version:** 2.0.0  
**Company:** VINEX  
**Client:** NINU University  
**Project Type:** Mobile Application (Android)  
**Last Updated:** January 18, 2025

---

## 📋 **TABLE OF CONTENTS**

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Current Implementation (Phase 1)](#current-implementation-phase-1)
4. [Pending Features (Phase 2)](#pending-features-phase-2)
5. [Technology Stack](#technology-stack)
6. [Project Structure](#project-structure)
7. [Database Schema](#database-schema)
8. [Feature Specifications](#feature-specifications)
9. [Implementation Roadmap](#implementation-roadmap)
10. [Code Examples](#code-examples)
11. [Testing Requirements](#testing-requirements)
12. [Deployment Guide](#deployment-guide)
13. [Appendices](#appendices)

---

## 🎯 **EXECUTIVE SUMMARY**

### Project Overview

**Monion** is a comprehensive bus security and student verification system designed for NINU University buses operated by VINEX company. The system combines:

- **Real-time video recording** from multiple camera sources
- **Barcode scanning** for student National ID verification
- **Session management** for tracking bus trips
- **Admin dashboard** for data review and reporting
- **Data export** capabilities (CSV/PDF)

### Business Objectives

1. **Safety & Security**: Record all bus trips for accountability
2. **Student Tracking**: Verify and log student boarding/exiting
3. **Compliance**: Maintain detailed audit trails
4. **Efficiency**: Streamline driver and admin workflows
5. **Reporting**: Generate comprehensive trip reports

### Key Stakeholders

- **Drivers**: Use the app to manage trips and scan students
- **Administrators**: Review sessions, access videos, generate reports
- **VINEX Management**: Monitor system performance
- **NINU University**: Ensure student safety and compliance

---

## 🏗️ **SYSTEM ARCHITECTURE**

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    MONION MOBILE APP                        │
│                     (Flutter/Android)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐     │
│  │    Driver     │  │     Admin     │  │   Camera     │     │
│  │    Module     │  │    Module     │  │   Module     │     │
│  └───────────────┘  └───────────────┘  └──────────────┘     │
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐     │
│  │   Scanner     │  │   Database    │  │   Export     │     │
│  │   Module      │  │   Service     │  │   Service    │     │
│  └───────────────┘  └───────────────┘  └──────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
  ┌─────────────┐      ┌──────────┐      ┌────────────────┐
  │ Phone       │      │  SQLite  │      │  File System   │
  │ Camera      │      │ Database │      │ (Videos/Exports│
  └─────────────┘      └──────────┘      └────────────────┘
         │
         ▼
  ┌─────────────┐
  │ WiFi Camera │
  │ (Imou RTSP) │
  └─────────────┘
```

### Data Flow Diagram

```
Driver Login → Start Session → Begin Recording (Both Cameras)
                    ↓
        Student Boards → Scan Barcode → Save to Database
                    ↓
           Trip Continues → Continuous Recording
                    ↓
        Student Exits → Scan OUT → Update Database
                    ↓
         Trip Complete → Stop Recording → Save Videos
                    ↓
         Admin Review → View Sessions → Export Data/Videos
```

### Component Interaction

```mermaid
graph TD
    A[Driver App] -->|Start Session| B[Session Service]
    B -->|Create Session| C[Database]
    B -->|Start Recording| D[Camera Service]
    D -->|Record Front| E[Phone Camera]
    D -->|Record WiFi| F[RTSP Stream]
    A -->|Scan Student| G[Scanner Service]
    G -->|Validate ID| H[Validation]
    H -->|Save Scan| C
    I[Admin App] -->|View Sessions| C
    I -->|Export Data| J[Export Service]
    J -->|Generate CSV/PDF| K[File System]
    I -->|View Videos| F
```

---

## ✅ **CURRENT IMPLEMENTATION (PHASE 1)**

### Implemented Features

#### 1. **Authentication System**
- ✅ Dual login (Driver/Admin)
- ✅ Driver: Name + Bus Plate
- ✅ Admin: Username + Password
- ✅ Persistent credentials
- ✅ Auto-logout on session end

**Files:**
- `lib/screens/login_screen.dart`
- `lib/services/database_service.dart` (driver storage)

#### 2. **Session Management**
- ✅ Start session with direction (To/From University)
- ✅ Automatic timestamp recording
- ✅ Real-time duration tracking
- ✅ End session with confirmation
- ✅ Session status (Active/Completed)

**Files:**
- `lib/models/session.dart`
- `lib/screens/driver/driver_dashboard.dart`
- `lib/services/database_service.dart` (session CRUD)

#### 3. **Barcode Scanner**
- ✅ 1D/2D barcode support
- ✅ Center-area scanning (optimized performance)
- ✅ 14-digit National ID validation
- ✅ IN/OUT mode toggle
- ✅ Duplicate scan prevention
- ✅ Real-time scan statistics
- ✅ Recent scans list (last 10)
- ✅ Flashlight control
- ✅ Success/Error popups
- ✅ Scan overlay with corner markers

**Files:**
- `lib/screens/driver/scanner_screen.dart`
- `lib/services/database_service.dart` (scan storage)

#### 4. **Admin Dashboard**
- ✅ View all sessions
- ✅ Search by driver/bus plate
- ✅ Filter by direction
- ✅ Session statistics overview
- ✅ Pull-to-refresh
- ✅ Session detail view
- ✅ View all scans per session
- ✅ Delete individual scans
- ✅ Filter scans (IN/OUT/All)

**Files:**
- `lib/screens/admin/admin_dashboard.dart`
- `lib/screens/admin/session_detail_screen.dart`

#### 5. **Data Export**
- ✅ CSV export (All sessions)
- ✅ CSV export (Single session with details)
- ✅ PDF export (Professional report)
- ✅ Save to Downloads folder (`/storage/emulated/0/Download/`)
- ✅ Success dialog with file path
- ✅ Export from Admin Dashboard
- ✅ Export from Session Detail

**Files:**
- `lib/services/export_service.dart`

#### 6. **UI/UX**
- ✅ Material Design 3
- ✅ VINEX brand colors (#2B7EF4)
- ✅ Custom widgets (buttons, cards, badges)
- ✅ Loading states
- ✅ Error handling
- ✅ Toast notifications
- ✅ Empty states
- ✅ Portrait mode only

**Files:**
- `lib/theme/app_theme.dart`
- `lib/utils/constants.dart`
- `lib/widgets/*.dart`

#### 7. **Database**
- ✅ SQLite local storage
- ✅ Three tables: sessions, scans, drivers
- ✅ Foreign key relationships
- ✅ Automatic data updates
- ✅ Cascade delete

**Files:**
- `lib/services/database_service.dart`

---

## 🚧 **PENDING FEATURES (PHASE 2)**

### Critical Features (High Priority)

#### 1. **Video Recording System** 🎥

##### Front Camera Recording
**Purpose**: Record from phone's front-facing camera during active session

**Requirements**:
- Auto-start recording when session starts
- Stop when session ends
- Save to `/DCIM/Monion/Front/`
- File naming: `Session_{id}_Front_{timestamp}.mp4`
- Show recording indicator (REC badge)
- Quality: 720p minimum, 1080p preferred
- Include audio

**Implementation**:
```dart
// lib/services/camera_service.dart
class CameraService {
  CameraController? _controller;
  bool _isRecording = false;
  
  Future<void> startRecording(int sessionId) async {
    // Initialize front camera
    // Start recording
    // Update UI with recording status
  }
  
  Future<String?> stopRecording() async {
    // Stop recording
    // Save file
    // Return file path
  }
}
```

**Database Schema Addition**:
```sql
CREATE TABLE recordings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  camera_type TEXT NOT NULL,  -- 'FRONT' or 'WIFI'
  file_path TEXT NOT NULL,
  file_size INTEGER,
  duration INTEGER,
  start_time TEXT NOT NULL,
  end_time TEXT,
  FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

**Packages Needed**:
```yaml
dependencies:
  camera: ^0.10.5+5
```

---

##### WiFi Camera (RTSP) Recording
**Purpose**: Stream and record from Imou WiFi camera mounted on bus

**RTSP Details**:
- URL: `rtsp://admin:MyCamStream123@192.168.137.75:554/cam/realmonitor?channel=1&subtype=0`
- Protocol: RTSP
- Codec: H.264
- Resolution: 1080p
- Network: WiFi Hotspot from phone

**Requirements**:
- Connect to RTSP stream when session starts
- Continuous recording with session segmentation
- Save to `/DCIM/Monion/WiFi/`
- File naming: `Session_{id}_WiFi_{timestamp}.mp4`
- Handle network interruptions
- Auto-reconnect if connection drops
- Show connection status

**Implementation Approach**:

**Option A: FFmpeg Native (Complex but Powerful)**
- Use FFmpeg for RTSP capture and encoding
- Requires NDK and native code
- See `ffmpeg_rtsp_readme.md` for full guide
- Best video quality and control

**Option B: Plugin-based (Simpler)**
```yaml
dependencies:
  media_kit: ^1.1.10
  media_kit_video: ^1.2.4
  flutter_vlc_player: ^7.4.0
```

```dart
// lib/services/rtsp_service.dart
class RTSPService {
  static const String rtspUrl = 'rtsp://admin:MyCamStream123@192.168.137.75:554/...';
  
  Future<void> startStream() async {
    // Connect to RTSP
    // Display preview
  }
  
  Future<void> startRecording(int sessionId) async {
    // Start capturing stream
    // Save to file
  }
  
  Future<void> stopRecording() async {
    // Stop capture
    // Finalize file
  }
}
```

**Network Configuration**:
1. Phone creates WiFi hotspot
2. Camera connects to phone's hotspot
3. Camera IP: `192.168.137.75`
4. App connects to camera via RTSP
5. Recording starts automatically

---

#### 2. **Manual Entry Screen** 📝

**Purpose**: Backup input method when scanner fails

**Requirements**:
- Keyboard input for 14-digit National ID
- Real-time validation as user types
- Show error if not 14 digits
- Show error if not all numbers
- Same IN/OUT logic as scanner
- Same success/error popups

**UI Design**:
```
┌──────────────────────────────┐
│  Manual Entry                │
│  ┌────────────────────────┐  │
│  │ National ID            │  │
│  │ [1234567890____]       │  │
│  └────────────────────────┘  │
│                              │
│  ⬤ Scan IN    ○ Scan OUT    │
│                              │
│  [      SUBMIT      ]        │
└──────────────────────────────┘
```

**File to Create**: `lib/screens/driver/manual_entry_screen.dart`

**Code Template**:
```dart
class ManualEntryScreen extends StatefulWidget {
  final Session session;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manual Entry')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 14,
              decoration: InputDecoration(
                labelText: 'National ID',
                hintText: '14 digits',
              ),
              onChanged: _validateInput,
            ),
            // Mode toggle
            // Submit button
          ],
        ),
      ),
    );
  }
}
```

---

#### 3. **Passenger List Screen** 👥

**Purpose**: Show all currently scanned-in students

**Requirements**:
- List all students with status IN
- Show National ID
- Show scan time
- One-tap to scan OUT
- Search by ID
- Real-time updates
- Show count (e.g., "25 passengers on board")

**UI Design**:
```
┌──────────────────────────────┐
│  Passengers (25)             │
│  ┌────────────────────────┐  │
│  │ 12345678901234    ✓ IN │  │
│  │ 05:38 PM               │  │
│  │         [SCAN OUT]     │  │
│  ├────────────────────────┤  │
│  │ 98765432109876    ✓ IN │  │
│  │ 05:40 PM               │  │
│  │         [SCAN OUT]     │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

**File to Create**: `lib/screens/driver/passenger_list_screen.dart`

**Database Query**:
```dart
Future<List<Scan>> getCurrentPassengers(int sessionId) async {
  final allScans = await getSessionScans(sessionId);
  final Map<String, Scan> latestScans = {};
  
  for (var scan in allScans) {
    if (!latestScans.containsKey(scan.nationalId) || 
        scan.timestamp.isAfter(latestScans[scan.nationalId]!.timestamp)) {
      latestScans[scan.nationalId] = scan;
    }
  }
  
  return latestScans.values
      .where((scan) => scan.scanType == 'IN')
      .toList();
}
```

---

#### 4. **Session Summary Screen** 📊

**Purpose**: Show trip summary when session ends

**Requirements**:
- Total duration
- Total students scanned IN
- Total students scanned OUT
- Students still on board (IN - OUT)
- List of all scans with times
- Option to export session
- Option to view recordings
- Share summary

**UI Design**:
```
┌──────────────────────────────┐
│  Session Complete ✓          │
│  ┌────────────────────────┐  │
│  │ Duration: 45 minutes   │  │
│  │ Scanned IN:  25        │  │
│  │ Scanned OUT: 25        │  │
│  │ Still on board: 0      │  │
│  └────────────────────────┘  │
│                              │
│  📹 View Recordings          │
│  📄 Export PDF               │
│  📊 Export CSV               │
│  🏠 Return to Dashboard      │
└──────────────────────────────┘
```

**File to Create**: `lib/screens/driver/session_summary_screen.dart`

---

#### 5. **Video Playback System** 🎬

**Purpose**: Allow admin to watch recorded videos

**Requirements**:
- List all recordings by session
- Show front camera and WiFi camera videos
- Video player with controls (play/pause/seek)
- Timestamp display
- Download video option
- Share video option
- Delete video option

**UI Design**:
```
┌──────────────────────────────┐
│  Session 3 - Recordings      │
│  ┌────────────────────────┐  │
│  │ 📹 Front Camera        │  │
│  │ 45:23 | 125 MB         │  │
│  │         [▶ PLAY]       │  │
│  ├────────────────────────┤  │
│  │ 📹 WiFi Camera         │  │
│  │ 45:30 | 340 MB         │  │
│  │         [▶ PLAY]       │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

**Files to Create**:
- `lib/screens/admin/recordings_screen.dart`
- `lib/screens/admin/video_player_screen.dart`

**Packages**:
```yaml
dependencies:
  video_player: ^2.8.1
  chewie: ^1.7.4  # Better video player controls
```

---

### Medium Priority Features

#### 6. **Settings Panel** ⚙️

**Requirements**:
- Change admin password
- Configure recording quality
- Set storage limits
- Clear old data (sessions/videos older than X days)
- Backup database
- Restore database
- App version info
- About section

**File to Create**: `lib/screens/admin/admin_settings_screen.dart`

---

#### 7. **Analytics Dashboard** 📈

**Requirements**:
- Daily/Weekly/Monthly statistics
- Most active drivers
- Peak usage times
- Average trip duration
- Total scans per day
- Charts and graphs

**Packages**:
```yaml
dependencies:
  fl_chart: ^0.68.0
  syncfusion_flutter_charts: ^24.1.41
```

**File to Create**: `lib/screens/admin/analytics_screen.dart`

---

#### 8. **Notifications** 🔔

**Requirements**:
- Low battery warning during session
- Storage space warning
- Session reminder for drivers
- Duplicate scan alerts
- Network connection lost (for WiFi camera)

**Packages**:
```yaml
dependencies:
  flutter_local_notifications: ^16.3.0
```

---

#### 9. **Sounds & Haptics** 🔊

**Requirements**:
- Success beep on valid scan
- Error buzz on invalid scan
- Haptic feedback on scan
- Recording start/stop sounds

**Packages**:
```yaml
dependencies:
  audioplayers: ^5.2.1
  vibration: ^1.8.4
```

**Implementation**:
```dart
// In scanner success
HapticFeedback.mediumImpact();
await audioPlayer.play(AssetSource('sounds/success.mp3'));

// In scanner error
HapticFeedback.heavyImpact();
await audioPlayer.play(AssetSource('sounds/error.mp3'));
```

---

### Low Priority Features

#### 10. **Dark Mode** 🌙

**Implementation**: Already partially set up in `lib/theme/app_theme.dart`

---

#### 11. **Multi-language Support** 🌐

**Languages**: English, Arabic

**Package**:
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

---

#### 12. **Cloud Backup** ☁️

**Purpose**: Upload videos and database to cloud storage

**Options**:
- Firebase Storage
- AWS S3
- Google Drive

---

## 🛠️ **TECHNOLOGY STACK**

### Frontend
```yaml
Framework: Flutter 3.9.2+
Language: Dart 3.0+
UI: Material Design 3
State Management: Provider / StatefulWidget
```

### Backend (Local)
```yaml
Database: SQLite (sqflite ^2.3.3)
File Storage: Local filesystem
Video: FFmpeg / media_kit
```

### Packages (Current)
```yaml
dependencies:
  mobile_scanner: ^5.2.3      # Barcode scanning
  sqflite: ^2.3.3             # Database
  path_provider: ^2.1.4       # File paths
  provider: ^6.1.2            # State management
  intl: ^0.19.0               # Date formatting
  pdf: ^3.11.1                # PDF generation
  csv: ^6.0.0                 # CSV export
  permission_handler: ^11.3.1 # Permissions
```

### Packages (To Add)
```yaml
dependencies:
  camera: ^0.10.5+5           # Front camera
  media_kit: ^1.1.10          # RTSP streaming
  media_kit_video: ^1.2.4     # Video player
  video_player: ^2.8.1        # Video playback
  chewie: ^1.7.4              # Video controls
  audioplayers: ^5.2.1        # Sounds
  vibration: ^1.8.4           # Haptics
  fl_chart: ^0.68.0           # Charts
  flutter_local_notifications: ^16.3.0  # Notifications
```

### Native Code
```
Platform: Android (API 24+)
Languages: Kotlin, Java, C++
NDK: For FFmpeg integration
FFmpeg: Custom compilation for ARM64
```

---

## 📁 **PROJECT STRUCTURE (COMPLETE)**

```
monion_scanner/
├── lib/
│   ├── main.dart                          # ✅ App entry point
│   │
│   ├── models/                            # ✅ Data models
│   │   ├── session.dart                   # ✅ Session model
│   │   ├── scan.dart                      # ✅ Scan model
│   │   ├── driver.dart                    # ✅ Driver model
│   │   └── recording.dart                 # ⏳ Recording model (TO ADD)
│   │
│   ├── screens/                           # Screens
│   │   ├── login_screen.dart             # ✅ Driver/Admin login
│   │   │
│   │   ├── driver/                        # Driver screens
│   │   │   ├── driver_dashboard.dart     # ✅ Main driver screen
│   │   │   ├── scanner_screen.dart       # ✅ Barcode scanner
│   │   │   ├── manual_entry_screen.dart  # ⏳ Manual ID entry (TO ADD)
│   │   │   ├── passenger_list_screen.dart # ⏳ Current passengers (TO ADD)
│   │   │   └── session_summary_screen.dart # ⏳ Session complete (TO ADD)
│   │   │
│   │   └── admin/                         # Admin screens
│   │       ├── admin_dashboard.dart      # ✅ Main admin screen
│   │       ├── session_detail_screen.dart # ✅ Session details
│   │       ├── recordings_screen.dart    # ⏳ Video list (TO ADD)
│   │       ├── video_player_screen.dart  # ⏳ Video playback (TO ADD)
│   │       ├── analytics_screen.dart     # ⏳ Charts/Stats (TO ADD)
│   │       └── admin_settings_screen.dart # ⏳ Settings (TO ADD)
│   │
│   ├── widgets/                           # ✅ Reusable components
│   │   ├── custom_button.dart            # ✅ Buttons
│   │   ├── custom_card.dart              # ✅ Cards
│   │   ├── status_badge.dart             # ✅ Badges
│   │   └── loading_indicator.dart        # ⏳ Loading (TO ADD)
│   │
│   ├── services/                          # Business logic
│   │   ├── database_service.dart         # ✅ SQLite operations
│   │   ├── export_service.dart           # ✅ CSV/PDF export
│   │   ├── camera_service.dart           # ⏳ Front camera (TO ADD)
│   │   ├── rtsp_service.dart             # ⏳ WiFi camera (TO ADD)
│   │   ├── recording_service.dart        # ⏳ Video management (TO ADD)
│   │   └── notification_service.dart     # ⏳ Notifications (TO ADD)
│   │
│   ├── utils/                             # ✅ Helpers
│   │   ├── constants.dart                # ✅ App constants
│   │   └── validators.dart               # ⏳ Validation (TO ADD)
│   │
│   └── theme/                             # ✅ App theming
│       └── app_theme.dart                # ✅ Theme config
│
├── android/                               # Android config
│   ├── app/
│   │   ├── build.gradle.kts              # ✅ Build config
│   │   └── src/main/
│   │       ├── AndroidManifest.xml       # ✅ Permissions
│   │       ├── kotlin/                    # ⏳ Native Kotlin (TO ADD)
│   │       │   └── MainActivity.kt       # ⏳ Platform channels
│   │       └── cpp/                       # ⏳ Native C++ (TO ADD)
│   │           ├── CMakeLists.txt        # ⏳ CMake config
│   │           └── ffmpeg_recorder.cpp   # ⏳ FFmpeg recording
│   │
│   └── gradle/
│
├── assets/
│   ├── images/
│   │   └── vinex_logo.png                # ⏳ Company logo (TO ADD)
│   └── sounds/
│       ├── success.mp3                    # ⏳ Success sound (TO ADD)
│       └── error.mp3                      # ⏳ Error sound (TO ADD)
│
├── pubspec.yaml                           # ✅ Dependencies
└── README.md                              # Project readme

Legend:
✅ = Implemented
⏳ = Pending
```

---

## 🗄️ **DATABASE SCHEMA (COMPLETE)**

### Current Tables

#### 1. sessions
```sql
CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  driver_name TEXT NOT NULL,
  bus_plate TEXT NOT NULL,
  direction TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  total_scans_in INTEGER NOT NULL DEFAULT 0,
  total_scans_out INTEGER NOT NULL DEFAULT 0
);
```

#### 2. scans
```sql
CREATE TABLE scans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  national_id TEXT NOT NULL,
  scan_type TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);
```

#### 3. drivers
```sql
CREATE TABLE drivers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  bus_plate TEXT NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE(name, bus_plate)
);
```

### Tables to Add

#### 4. recordings (NEW)
```sql
CREATE TABLE recordings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  camera_type TEXT NOT NULL,  -- 'FRONT' or 'WIFI'
  file_path TEXT NOT NULL,
  file_size INTEGER,
  duration INTEGER,           -- in seconds
  start_time TEXT NOT NULL,
  end_time TEXT,
  status TEXT DEFAULT 'COMPLETED',
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);
```

#### 5. settings (NEW)
```sql
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

---

## 📐 **FEATURE SPECIFICATIONS (DETAILED)**

### Recording System Specification

#### Camera Types

**1. Front Camera (Phone)**
- **Purpose**: Record driver and front view
- **Start Trigger**: When session starts
- **Stop Trigger**: When session ends
- **Storage**: `/DCIM/Monion/Front/`
- **Naming**: `Session_{sessionId}_Front_{timestamp}.mp4`
- **Quality**: 720p minimum, 1080p if device supports
- **Audio**: Yes
- **Indicator**: Red "REC" badge on screen

**2. WiFi Camera (RTSP)**
- **Purpose**: Record bus interior
- **Camera Model**: Imou WiFi Camera
- **Connection**: RTSP over WiFi hotspot
- **URL Format**: `rtsp://admin:MyCamStream123@192.168.137.75:554/cam/realmonitor?channel=1&subtype=0`
- **Start Trigger**: When session starts
- **Stop Trigger**: When session ends
- **Storage**: `/DCIM/Monion/WiFi/`
- **Naming**: `Session_{sessionId}_WiFi_{timestamp}.mp4`
- **Quality**: 1080p (from camera)
- **Codec**: H.264
- **Reconnection**: Auto-reconnect if WiFi drops

#### Recording Flow

```
1. Driver starts session
   ├─> Initialize front camera
   ├─> Start front camera recording
   ├─> Connect to RTSP stream
   ├─> Start RTSP recording
   └─> Create recording entries in database

2. Session active
   ├─> Monitor recording status
   ├─> Check storage space
   ├─> Handle errors/reconnections
   └─> Update UI indicators

3. Driver ends session
   ├─> Stop front camera recording
   ├─> Stop RTSP recording
   ├─> Save video files
   ├─> Update database with file info
   └─> Show session summary
```

#### Storage Management

**Requirements**:
- Check available space before starting
- Minimum required: 500MB free
- Auto-cleanup of old recordings if space < 1GB
- Keep recordings for 30 days by default
- Admin can configure retention period

**Storage Calculation**:
```
Front Camera: ~60 MB/min (720p)
WiFi Camera: ~120 MB/min (1080p)
45-minute trip:
  - Front: ~2.7 GB
  - WiFi: ~5.4 GB
  - Total: ~8.1 GB per trip

Daily (4 trips): ~32 GB
Weekly: ~160 GB
Monthly: ~640 GB

Recommendation: 128GB+ storage on device
```

---

### Scanner System Specification

#### Barcode Types Supported
```
1D Barcodes:
  - CODE_128 (Primary - National ID cards)
  - CODE_39
  - EAN-13
  - UPC-A

2D Barcodes:
  - QR Code
  - Data Matrix
```

#### Scanning Area
```
Screen Width: 100%
Screen Height: 100%
Scanning Zone: Center 80% x 30%
  - Optimized for faster processing
  - Focuses on center area only
  - Reduces false positives
```

#### Validation Rules
```dart
1. Length Check:
   if (code.length != 14) return false;

2. Numeric Check:
   if (!RegExp(r'^\d+# MONION COMPLETE SYSTEM - MASTER DOCUMENTATION

**Version:** 2.0.0  
**Company:** VINEX  
**Client:** NINU University  
**Project Type:** Mobile Application (Android)  
**Last Updated:** January 18, 2025

---

## 📋 **TABLE OF CONTENTS**

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Current Implementation (Phase 1)](#current-implementation-phase-1)
4. [Pending Features (Phase 2)](#pending-features-phase-2)
5. [Technology Stack](#technology-stack)
6. [Project Structure](#project-structure)
7. [Database Schema](#database-schema)
8. [Feature Specifications](#feature-specifications)
9. [Implementation Roadmap](#implementation-roadmap)
10. [Code Examples](#code-examples)
11. [Testing Requirements](#testing-requirements)
12. [Deployment Guide](#deployment-guide)
13. [Appendices](#appendices)

---

## 🎯 **EXECUTIVE SUMMARY**

### Project Overview

**Monion** is a comprehensive bus security and student verification system designed for NINU University buses operated by VINEX company. The system combines:

- **Real-time video recording** from multiple camera sources
- **Barcode scanning** for student National ID verification
- **Session management** for tracking bus trips
- **Admin dashboard** for data review and reporting
- **Data export** capabilities (CSV/PDF)

### Business Objectives

1. **Safety & Security**: Record all bus trips for accountability
2. **Student Tracking**: Verify and log student boarding/exiting
3. **Compliance**: Maintain detailed audit trails
4. **Efficiency**: Streamline driver and admin workflows
5. **Reporting**: Generate comprehensive trip reports

### Key Stakeholders

- **Drivers**: Use the app to manage trips and scan students
- **Administrators**: Review sessions, access videos, generate reports
- **VINEX Management**: Monitor system performance
- **NINU University**: Ensure student safety and compliance

---

## 🏗️ **SYSTEM ARCHITECTURE**

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    MONION MOBILE APP                        │
│                     (Flutter/Android)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐   │
│  │    Driver     │  │     Admin     │  │   Camera     │   │
│  │    Module     │  │    Module     │  │   Module     │   │
│  └───────────────┘  └───────────────┘  └──────────────┘   │
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐   │
│  │   Scanner     │  │   Database    │  │   Export     │   │
│  │   Module      │  │   Service     │  │   Service    │   │
│  └───────────────┘  └───────────────┘  └──────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
  ┌─────────────┐      ┌──────────┐      ┌────────────────┐
  │ Phone       │      │  SQLite  │      │  File System   │
  │ Camera      │      │ Database │      │ (Videos/Exports│
  └─────────────┘      └──────────┘      └────────────────┘
         │
         ▼
  ┌─────────────┐
  │ WiFi Camera │
  │ (Imou RTSP) │
  └─────────────┘
```

### Data Flow Diagram

```
Driver Login → Start Session → Begin Recording (Both Cameras)
                    ↓
        Student Boards → Scan Barcode → Save to Database
                    ↓
           Trip Continues → Continuous Recording
                    ↓
        Student Exits → Scan OUT → Update Database
                    ↓
         Trip Complete → Stop Recording → Save Videos
                    ↓
         Admin Review → View Sessions → Export Data/Videos
```

### Component Interaction

```mermaid
graph TD
    A[Driver App] -->|Start Session| B[Session Service]
    B -->|Create Session| C[Database]
    B -->|Start Recording| D[Camera Service]
    D -->|Record Front| E[Phone Camera]
    D -->|Record WiFi| F[RTSP Stream]
    A -->|Scan Student| G[Scanner Service]
    G -->|Validate ID| H[Validation]
    H -->|Save Scan| C
    I[Admin App] -->|View Sessions| C
    I -->|Export Data| J[Export Service]
    J -->|Generate CSV/PDF| K[File System]
    I -->|View Videos| F
```

---

## ✅ **CURRENT IMPLEMENTATION (PHASE 1)**

### Implemented Features

#### 1. **Authentication System**
- ✅ Dual login (Driver/Admin)
- ✅ Driver: Name + Bus Plate
- ✅ Admin: Username + Password
- ✅ Persistent credentials
- ✅ Auto-logout on session end

**Files:**
- `lib/screens/login_screen.dart`
- `lib/services/database_service.dart` (driver storage)

#### 2. **Session Management**
- ✅ Start session with direction (To/From University)
- ✅ Automatic timestamp recording
- ✅ Real-time duration tracking
- ✅ End session with confirmation
- ✅ Session status (Active/Completed)

**Files:**
- `lib/models/session.dart`
- `lib/screens/driver/driver_dashboard.dart`
- `lib/services/database_service.dart` (session CRUD)

#### 3. **Barcode Scanner**
- ✅ 1D/2D barcode support
- ✅ Center-area scanning (optimized performance)
- ✅ 14-digit National ID validation
- ✅ IN/OUT mode toggle
- ✅ Duplicate scan prevention
- ✅ Real-time scan statistics
- ✅ Recent scans list (last 10)
- ✅ Flashlight control
- ✅ Success/Error popups
- ✅ Scan overlay with corner markers

**Files:**
- `lib/screens/driver/scanner_screen.dart`
- `lib/services/database_service.dart` (scan storage)

#### 4. **Admin Dashboard**
- ✅ View all sessions
- ✅ Search by driver/bus plate
- ✅ Filter by direction
- ✅ Session statistics overview
- ✅ Pull-to-refresh
- ✅ Session detail view
- ✅ View all scans per session
- ✅ Delete individual scans
- ✅ Filter scans (IN/OUT/All)

**Files:**
- `lib/screens/admin/admin_dashboard.dart`
- `lib/screens/admin/session_detail_screen.dart`

#### 5. **Data Export**
- ✅ CSV export (All sessions)
- ✅ CSV export (Single session with details)
- ✅ PDF export (Professional report)
- ✅ Save to Downloads folder (`/storage/emulated/0/Download/`)
- ✅ Success dialog with file path
- ✅ Export from Admin Dashboard
- ✅ Export from Session Detail

**Files:**
- `lib/services/export_service.dart`

#### 6. **UI/UX**
- ✅ Material Design 3
- ✅ VINEX brand colors (#2B7EF4)
- ✅ Custom widgets (buttons, cards, badges)
- ✅ Loading states
- ✅ Error handling
- ✅ Toast notifications
- ✅ Empty states
- ✅ Portrait mode only

**Files:**
- `lib/theme/app_theme.dart`
- `lib/utils/constants.dart`
- `lib/widgets/*.dart`

#### 7. **Database**
- ✅ SQLite local storage
- ✅ Three tables: sessions, scans, drivers
- ✅ Foreign key relationships
- ✅ Automatic data updates
- ✅ Cascade delete

**Files:**
- `lib/services/database_service.dart`

---

## 🚧 **PENDING FEATURES (PHASE 2)**

### Critical Features (High Priority)

#### 1. **Video Recording System** 🎥

##### Front Camera Recording
**Purpose**: Record from phone's front-facing camera during active session

**Requirements**:
- Auto-start recording when session starts
- Stop when session ends
- Save to `/DCIM/Monion/Front/`
- File naming: `Session_{id}_Front_{timestamp}.mp4`
- Show recording indicator (REC badge)
- Quality: 720p minimum, 1080p preferred
- Include audio

**Implementation**:
```dart
// lib/services/camera_service.dart
class CameraService {
  CameraController? _controller;
  bool _isRecording = false;
  
  Future<void> startRecording(int sessionId) async {
    // Initialize front camera
    // Start recording
    // Update UI with recording status
  }
  
  Future<String?> stopRecording() async {
    // Stop recording
    // Save file
    // Return file path
  }
}
```

**Database Schema Addition**:
```sql
CREATE TABLE recordings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  camera_type TEXT NOT NULL,  -- 'FRONT' or 'WIFI'
  file_path TEXT NOT NULL,
  file_size INTEGER,
  duration INTEGER,
  start_time TEXT NOT NULL,
  end_time TEXT,
  FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

**Packages Needed**:
```yaml
dependencies:
  camera: ^0.10.5+5
```

---

##### WiFi Camera (RTSP) Recording
**Purpose**: Stream and record from Imou WiFi camera mounted on bus

**RTSP Details**:
- URL: `rtsp://admin:MyCamStream123@192.168.137.75:554/cam/realmonitor?channel=1&subtype=0`
- Protocol: RTSP
- Codec: H.264
- Resolution: 1080p
- Network: WiFi Hotspot from phone

**Requirements**:
- Connect to RTSP stream when session starts
- Continuous recording with session segmentation
- Save to `/DCIM/Monion/WiFi/`
- File naming: `Session_{id}_WiFi_{timestamp}.mp4`
- Handle network interruptions
- Auto-reconnect if connection drops
- Show connection status

**Implementation Approach**:

**Option A: FFmpeg Native (Complex but Powerful)**
- Use FFmpeg for RTSP capture and encoding
- Requires NDK and native code
- See `ffmpeg_rtsp_readme.md` for full guide
- Best video quality and control

**Option B: Plugin-based (Simpler)**
```yaml
dependencies:
  media_kit: ^1.1.10
  media_kit_video: ^1.2.4
  flutter_vlc_player: ^7.4.0
```

```dart
// lib/services/rtsp_service.dart
class RTSPService {
  static const String rtspUrl = 'rtsp://admin:MyCamStream123@192.168.137.75:554/...';
  
  Future<void> startStream() async {
    // Connect to RTSP
    // Display preview
  }
  
  Future<void> startRecording(int sessionId) async {
    // Start capturing stream
    // Save to file
  }
  
  Future<void> stopRecording() async {
    // Stop capture
    // Finalize file
  }
}
```

**Network Configuration**:
1. Phone creates WiFi hotspot
2. Camera connects to phone's hotspot
3. Camera IP: `192.168.137.75`
4. App connects to camera via RTSP
5. Recording starts automatically

---

#### 2. **Manual Entry Screen** 📝

**Purpose**: Backup input method when scanner fails

**Requirements**:
- Keyboard input for 14-digit National ID
- Real-time validation as user types
- Show error if not 14 digits
- Show error if not all numbers
- Same IN/OUT logic as scanner
- Same success/error popups

**UI Design**:
```
┌──────────────────────────────┐
│  Manual Entry                │
│  ┌────────────────────────┐  │
│  │ National ID            │  │
│  │ [1234567890____]       │  │
│  └────────────────────────┘  │
│                              │
│  ⬤ Scan IN    ○ Scan OUT    │
│                              │
│  [      SUBMIT      ]        │
└──────────────────────────────┘
```

**File to Create**: `lib/screens/driver/manual_entry_screen.dart`

**Code Template**:
```dart
class ManualEntryScreen extends StatefulWidget {
  final Session session;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manual Entry')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 14,
              decoration: InputDecoration(
                labelText: 'National ID',
                hintText: '14 digits',
              ),
              onChanged: _validateInput,
            ),
            // Mode toggle
            // Submit button
          ],
        ),
      ),
    );
  }
}
```

---

#### 3. **Passenger List Screen** 👥

**Purpose**: Show all currently scanned-in students

**Requirements**:
- List all students with status IN
- Show National ID
- Show scan time
- One-tap to scan OUT
- Search by ID
- Real-time updates
- Show count (e.g., "25 passengers on board")

**UI Design**:
```
┌──────────────────────────────┐
│  Passengers (25)             │
│  ┌────────────────────────┐  │
│  │ 12345678901234    ✓ IN │  │
│  │ 05:38 PM               │  │
│  │         [SCAN OUT]     │  │
│  ├────────────────────────┤  │
│  │ 98765432109876    ✓ IN │  │
│  │ 05:40 PM               │  │
│  │         [SCAN OUT]     │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

**File to Create**: `lib/screens/driver/passenger_list_screen.dart`

**Database Query**:
```dart
Future<List<Scan>> getCurrentPassengers(int sessionId) async {
  final allScans = await getSessionScans(sessionId);
  final Map<String, Scan> latestScans = {};
  
  for (var scan in allScans) {
    if (!latestScans.containsKey(scan.nationalId) || 
        scan.timestamp.isAfter(latestScans[scan.nationalId]!.timestamp)) {
      latestScans[scan.nationalId] = scan;
    }
  }
  
  return latestScans.values
      .where((scan) => scan.scanType == 'IN')
      .toList();
}
```

---

#### 4. **Session Summary Screen** 📊

**Purpose**: Show trip summary when session ends

**Requirements**:
- Total duration
- Total students scanned IN
- Total students scanned OUT
- Students still on board (IN - OUT)
- List of all scans with times
- Option to export session
- Option to view recordings
- Share summary

**UI Design**:
```
┌──────────────────────────────┐
│  Session Complete ✓          │
│  ┌────────────────────────┐  │
│  │ Duration: 45 minutes   │  │
│  │ Scanned IN:  25        │  │
│  │ Scanned OUT: 25        │  │
│  │ Still on board: 0      │  │
│  └────────────────────────┘  │
│                              │
│  📹 View Recordings          │
│  📄 Export PDF               │
│  📊 Export CSV               │
│  🏠 Return to Dashboard      │
└──────────────────────────────┘
```

**File to Create**: `lib/screens/driver/session_summary_screen.dart`

---

#### 5. **Video Playback System** 🎬

**Purpose**: Allow admin to watch recorded videos

**Requirements**:
- List all recordings by session
- Show front camera and WiFi camera videos
- Video player with controls (play/pause/seek)
- Timestamp display
- Download video option
- Share video option
- Delete video option

**UI Design**:
```
┌──────────────────────────────┐
│  Session 3 - Recordings      │
│  ┌────────────────────────┐  │
│  │ 📹 Front Camera        │  │
│  │ 45:23 | 125 MB         │  │
│  │         [▶ PLAY]       │  │
│  ├────────────────────────┤  │
│  │ 📹 WiFi Camera         │  │
│  │ 45:30 | 340 MB         │  │
│  │         [▶ PLAY]       │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

**Files to Create**:
- `lib/screens/admin/recordings_screen.dart`
- `lib/screens/admin/video_player_screen.dart`

**Packages**:
```yaml
dependencies:
  video_player: ^2.8.1
  chewie: ^1.7.4  # Better video player controls
```

---

### Medium Priority Features

#### 6. **Settings Panel** ⚙️

**Requirements**:
- Change admin password
- Configure recording quality
- Set storage limits
- Clear old data (sessions/videos older than X days)
- Backup database
- Restore database
- App version info
- About section

**File to Create**: `lib/screens/admin/admin_settings_screen.dart`

---

#### 7. **Analytics Dashboard** 📈

**Requirements**:
- Daily/Weekly/Monthly statistics
- Most active drivers
- Peak usage times
- Average trip duration
- Total scans per day
- Charts and graphs

**Packages**:
```yaml
dependencies:
  fl_chart: ^0.68.0
  syncfusion_flutter_charts: ^24.1.41
```

**File to Create**: `lib/screens/admin/analytics_screen.dart`

---

#### 8. **Notifications** 🔔

**Requirements**:
- Low battery warning during session
- Storage space warning
- Session reminder for drivers
- Duplicate scan alerts
- Network connection lost (for WiFi camera)

**Packages**:
```yaml
dependencies:
  flutter_local_notifications: ^16.3.0
```

---

#### 9. **Sounds & Haptics** 🔊

**Requirements**:
- Success beep on valid scan
- Error buzz on invalid scan
- Haptic feedback on scan
- Recording start/stop sounds

**Packages**:
```yaml
dependencies:
  audioplayers: ^5.2.1
  vibration: ^1.8.4
```

**Implementation**:
```dart
// In scanner success
HapticFeedback.mediumImpact();
await audioPlayer.play(AssetSource('sounds/success.mp3'));

// In scanner error
HapticFeedback.heavyImpact();
await audioPlayer.play(AssetSource('sounds/error.mp3'));
```

---

### Low Priority Features

#### 10. **Dark Mode** 🌙

**Implementation**: Already partially set up in `lib/theme/app_theme.dart`

---

#### 11. **Multi-language Support** 🌐

**Languages**: English, Arabic

**Package**:
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

---

#### 12. **Cloud Backup** ☁️

**Purpose**: Upload videos and database to cloud storage

**Options**:
- Firebase Storage
- AWS S3
- Google Drive

---

## 🛠️ **TECHNOLOGY STACK**

### Frontend
```yaml
Framework: Flutter 3.9.2+
Language: Dart 3.0+
UI: Material Design 3
State Management: Provider / StatefulWidget
```

### Backend (Local)
```yaml
Database: SQLite (sqflite ^2.3.3)
File Storage: Local filesystem
Video: FFmpeg / media_kit
```

### Packages (Current)
```yaml
dependencies:
  mobile_scanner: ^5.2.3      # Barcode scanning
  sqflite: ^2.3.3             # Database
  path_provider: ^2.1.4       # File paths
  provider: ^6.1.2            # State management
  intl: ^0.19.0               # Date formatting
  pdf: ^3.11.1                # PDF generation
  csv: ^6.0.0                 # CSV export
  permission_handler: ^11.3.1 # Permissions
```

### Packages (To Add)
```yaml
dependencies:
  camera: ^0.10.5+5           # Front camera
  media_kit: ^1.1.10          # RTSP streaming
  media_kit_video: ^1.2.4     # Video player
  video_player: ^2.8.1        # Video playback
  chewie: ^1.7.4              # Video controls
  audioplayers: ^5.2.1        # Sounds
  vibration: ^1.8.4           # Haptics
  fl_chart: ^0.68.0           # Charts
  flutter_local_notifications: ^16.3.0  # Notifications
```

### Native Code
```
Platform: Android (API 24+)
Languages: Kotlin, Java, C++
NDK: For FFmpeg integration
FFmpeg: Custom compilation for ARM64
```

---

## 📁 **PROJECT STRUCTURE (COMPLETE)**

```
monion_scanner/
├── lib/
│   ├── main.dart                          # ✅ App entry point
│   │
│   ├── models/                            # ✅ Data models
│   │   ├── session.dart                   # ✅ Session model
│   │   ├── scan.dart                      # ✅ Scan model
│   │   ├── driver.dart                    # ✅ Driver model
│   │   └── recording.dart                 # ⏳ Recording model (TO ADD)
│   │
│   ├── screens/                           # Screens
│   │   ├── login_screen.dart             # ✅ Driver/Admin login
│   │   │
│   │   ├── driver/                        # Driver screens
│   │   │   ├── driver_dashboard.dart     # ✅ Main driver screen
│   │   │   ├── scanner_screen.dart       # ✅ Barcode scanner
│   │   │   ├── manual_entry_screen.dart  # ⏳ Manual ID entry (TO ADD)
│   │   │   ├── passenger_list_screen.dart # ⏳ Current passengers (TO ADD)
│   │   │   └── session_summary_screen.dart # ⏳ Session complete (TO ADD)
│   │   │
│   │   └── admin/                         # Admin screens
│   │       ├── admin_dashboard.dart      # ✅ Main admin screen
│   │       ├── session_detail_screen.dart # ✅ Session details
│   │       ├── recordings_screen.dart    # ⏳ Video list (TO ADD)
│   │       ├── video_player_screen.dart  # ⏳ Video playback (TO ADD)
│   │       ├── analytics_screen.dart     # ⏳ Charts/Stats (TO ADD)
│   │       └── admin_settings_screen.dart # ⏳ Settings (TO ADD)
│   │
│   ├── widgets/                           # ✅ Reusable components
│   │   ├── custom_button.dart            # ✅ Buttons
│   │   ├── custom_card.dart              # ✅ Cards
│   │   ├── status_badge.dart             # ✅ Badges
│   │   └── loading_indicator.dart        # ⏳ Loading (TO ADD)
│   │
│   ├── services/                          # Business logic
│   │   ├── database_service.dart         # ✅ SQLite operations
│   │   ├── export_service.dart           # ✅ CSV/PDF export
│   │   ├── camera_service.dart           # ⏳ Front camera (TO ADD)
│   │   ├── rtsp_service.dart             # ⏳ WiFi camera (TO ADD)
│   │   ├── recording_service.dart        # ⏳ Video management (TO ADD)
│   │   └── notification_service.dart     # ⏳ Notifications (TO ADD)
│   │
│   ├── utils/                             # ✅ Helpers
│   │   ├── constants.dart                # ✅ App constants
│   │   └── validators.dart               # ⏳ Validation (TO ADD)
│   │
│   └── theme/                             # ✅ App theming
│       └── app_theme.dart                # ✅ Theme config
│
├── android/                               # Android config
│   ├── app/
│   │   ├── build.gradle.kts              # ✅ Build config
│   │   └── src/main/
│   │       ├── AndroidManifest.xml       # ✅ Permissions
│   │       ├── kotlin/                    # ⏳ Native Kotlin (TO ADD)
│   │       │   └── MainActivity.kt       # ⏳ Platform channels
│   │       └── cpp/                       # ⏳ Native C++ (TO ADD)
│   │           ├── CMakeLists.txt        # ⏳ CMake config
│   │           └── ffmpeg_recorder.cpp   # ⏳ FFmpeg recording
│   │
│   └── gradle/
│
├── assets/
│   ├── images/
│   │   └── vinex_logo.png                # ⏳ Company logo (TO ADD)
│   └── sounds/
│       ├── success.mp3                    # ⏳ Success sound (TO ADD)
│       └── error.mp3                      # ⏳ Error sound (TO ADD)
│
├── pubspec.yaml                           # ✅ Dependencies
└── README.md                              # Project readme

Legend:
✅ = Implemented
⏳ = Pending
```

---

## 🗄️ **DATABASE SCHEMA (COMPLETE)**

### Current Tables

#### 1. sessions
```sql
CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  driver_name TEXT NOT NULL,
  bus_plate TEXT NOT NULL,
  direction TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  total_scans_in INTEGER NOT NULL DEFAULT 0,
  total_scans_out INTEGER NOT NULL DEFAULT 0
);
```

#### 2. scans
```sql
CREATE TABLE scans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  national_id TEXT NOT NULL,
  scan_type TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);
```

#### 3. drivers
```sql
CREATE TABLE drivers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  bus_plate TEXT NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE(name, bus_plate)
);
```

### Tables to Add

#### 4. recordings (NEW)
```sql
CREATE TABLE recordings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  camera_type TEXT NOT NULL,  -- 'FRONT' or 'WIFI'
  file_path TEXT NOT NULL,
  file_size INTEGER,
  duration INTEGER,           -- in seconds
  start_time TEXT NOT NULL,
  end_time TEXT,
  status TEXT DEFAULT 'COMPLETED',
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);
```

#### 5. settings (NEW)
```sql
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

---

## 📐 **FEATURE SPECIFICATIONS (DETAILED)**

### Recording System Specification

#### Camera Types

**1. Front Camera (Phone)**
- **Purpose**: Record driver and front view
- **Start Trigger**: When session starts
- **Stop Trigger**: When session ends
- **Storage**: `/DCIM/Monion/Front/`
- **Naming**: `Session_{sessionId}_Front_{timestamp}.mp4`
- **Quality**: 720p minimum, 1080p if device supports
- **Audio**: Yes
- **Indicator**: Red "REC" badge on screen

**2. WiFi Camera (RTSP)**
- **Purpose**: Record bus interior
- **Camera Model**: Imou WiFi Camera
- **Connection**: RTSP over WiFi hotspot
- **URL Format**: `rtsp://admin:MyCamStream123@192.168.137.75:554/cam/realmonitor?channel=1&subtype=0`
- **Start Trigger**: When session starts
- **Stop Trigger**: When session ends
- **Storage**: `/DCIM/Monion/WiFi/`
- **Naming**: `Session_{sessionId}_WiFi_{timestamp}.mp4`
- **Quality**: 1080p (from camera)
- **Codec**: H.264
- **Reconnection**: Auto-reconnect if WiFi drops

#### Recording Flow

```
1. Driver starts session
   ├─> Initialize front camera
   ├─> Start front camera recording
   ├─> Connect to RTSP stream
   ├─> Start RTSP recording
   └─> Create recording entries in database

2. Session active
   ├─> Monitor recording status
   ├─> Check storage space
   ├─> Handle errors/reconnections
   └─> Update UI indicators

3. Driver ends session
   ├─> Stop front camera recording
   ├─> Stop RTSP recording
   ├─> Save video files
   ├─> Update database with file info
   └─> Show session summary
```

#### Storage Management

**Requirements**:
- Check available space before starting
- Minimum required: 500MB free
- Auto-cleanup of old recordings if space < 1GB
- Keep recordings for 30 days by default
- Admin can configure retention period

**Storage Calculation**:
```
Front Camera: ~60 MB/min (720p)
WiFi Camera: ~120 MB/min (1080p)
45-).hasMatch(code)) return false;

3. Duplicate Check (IN mode):
   if (isStudentAlreadyIn(code)) return false;

4. Already Out Check (OUT mode):
   if (!isStudentCurrentlyIn(code)) return false;
```

#### User Feedback
```
Valid Scan:
  ✓ Green success popup
  ✓ Success beep sound
  ✓ Medium haptic feedback
  ✓ Display ID on screen
  ✓ Show IN/OUT badge
  ✓ Auto-dismiss after 2 seconds

Invalid Scan:
  ✗ Red error popup
  ✗ Error buzz sound
  ✗ Heavy haptic feedback
  ✗ Show error message
  ✗ Auto-dismiss after 3 seconds
```

---

### Export System Specification

#### CSV Export Format

**All Sessions CSV**:
```csv
Session ID,Driver Name,Bus Plate,Direction,Start Time,End Time,Duration,Total IN,Total OUT,Status
1,John Doe,ABC-123,To University,2025-01-18 08:30:00,2025-01-18 09:15:00,45m,25,25,Completed
2,Jane Smith,XYZ-789,From University,2025-01-18 14:00:00,N/A,1h 23m,18,15,Active
```

**Single Session CSV**:
```csv
MONION - Session Report
Generated:,2025-01-18 14:30:45

SESSION INFORMATION
Session ID,3
Driver Name,John Doe
Bus Plate,ABC-123
Direction,To University
Start Time,2025-01-18 08:30:00
End Time,2025-01-18 09:15:00
Duration,45m
Total Scans IN,25
Total Scans OUT,25
Status,Completed

DETAILED SCANS
#,National ID,Scan Type,Date,Time
1,12345678901234,IN,2025-01-18,08:35:12
2,98765432109876,IN,2025-01-18,08:36:45
...

SUMMARY
Total Scans,50
Scans IN,25
Scans OUT,25
```

#### PDF Export Format

**Layout**:
```
┌─────────────────────────────────────────┐
│ MONION                                  │
│ by VINEX - NINU University              │
│ (Blue header with white text)           │
└─────────────────────────────────────────┘

Session Report
══════════════════════════════════════════

Session Information
────────────────────────────────────────
Session ID:        3
Driver Name:       John Doe
Bus Plate:         ABC-123
Direction:         To University
Start Time:        2025-01-18 08:30:00
End Time:          2025-01-18 09:15:00
Duration:          45m
Total Scans IN:    25
Total Scans OUT:   25
Status:            Completed

Detailed Scans (50 total)
────────────────────────────────────────
┌───┬────────────────┬──────┬────────────┬──────────┐
│ # │ National ID    │ Type │ Date       │ Time     │
├───┼────────────────┼──────┼────────────┼──────────┤
│ 1 │ 12345678901234 │ IN   │ 2025-01-18 │ 08:35:12 │
│ 2 │ 98765432109876 │ IN   │ 2025-01-18 │ 08:36:45 │
└───┴────────────────┴──────┴────────────┴──────────┘

Summary
────────────────────────────────────────
Total Scans:       50
Scans IN:          25
Scans OUT:         25

────────────────────────────────────────
Generated: 2025-01-18 14:30:45
Monion v1.0.0
```

---

## 🚀 **IMPLEMENTATION ROADMAP**

### Phase 1: Core Features ✅ (COMPLETED)
**Duration**: 2 weeks  
**Status**: DONE

- ✅ Project setup
- ✅ Database implementation
- ✅ Authentication system
- ✅ Session management
- ✅ Barcode scanner
- ✅ Admin dashboard
- ✅ CSV/PDF export
- ✅ Basic UI/UX

---

### Phase 2: Video Recording 🎥 (HIGH PRIORITY)
**Duration**: 2-3 weeks  
**Estimated Effort**: 80 hours

#### Week 1: Front Camera
**Tasks**:
1. Add camera package
2. Create CameraService
3. Implement recording start/stop
4. Add recording indicator UI
5. Save videos to storage
6. Create Recording model
7. Update database schema
8. Test on multiple devices

**Deliverables**:
- Working front camera recording
- Videos saved to `/DCIM/Monion/Front/`
- Database tracking of recordings

#### Week 2-3: WiFi Camera (RTSP)
**Tasks**:
1. Set up RTSP connection
2. Implement FFmpeg native code (or use media_kit)
3. Create RTSPService
4. Handle network errors
5. Auto-reconnection logic
6. Save RTSP recordings
7. Test with actual camera
8. Performance optimization

**Deliverables**:
- RTSP stream connection
- Video recording from WiFi camera
- Network error handling
- Saved recordings

**Decision Point**: FFmpeg (complex) vs media_kit (simpler)
- **FFmpeg**: Better control, requires NDK, native code
- **media_kit**: Easier implementation, good enough quality

**Recommendation**: Start with media_kit, migrate to FFmpeg if needed

---

### Phase 3: Enhanced Driver Features 📱 (MEDIUM PRIORITY)
**Duration**: 1 week  
**Estimated Effort**: 40 hours

#### Tasks:
1. Manual Entry Screen
   - UI layout
   - Keyboard input
   - Validation logic
   - Integration with scanner flow

2. Passenger List Screen
   - Query current passengers
   - UI list with search
   - One-tap scan out
   - Real-time updates

3. Session Summary Screen
   - Calculate statistics
   - UI layout
   - Export integration
   - Share functionality

**Deliverables**:
- 3 new driver screens functional
- Complete driver workflow

---

### Phase 4: Video Playback 🎬 (MEDIUM PRIORITY)
**Duration**: 1 week  
**Estimated Effort**: 40 hours

#### Tasks:
1. Recordings List Screen
   - Query recordings from database
   - Display by session
   - Show file sizes
   - Thumbnail generation

2. Video Player Screen
   - Implement video_player
   - Add controls (play/pause/seek)
   - Timestamp display
   - Download/share options

**Deliverables**:
- Admin can view recordings
- Video player with controls
- Download/share functionality

---

### Phase 5: Polish & Extras ✨ (LOW PRIORITY)
**Duration**: 1-2 weeks  
**Estimated Effort**: 60 hours

#### Tasks:
1. Settings Panel
2. Analytics Dashboard
3. Notifications
4. Sounds & Haptics
5. Dark Mode
6. Multi-language (English/Arabic)
7. Performance optimization
8. Bug fixes

**Deliverables**:
- Polished, production-ready app
- All nice-to-have features

---

### Phase 6: Testing & Deployment 🧪
**Duration**: 1 week  
**Estimated Effort**: 40 hours

#### Tasks:
1. Unit testing
2. Integration testing
3. User acceptance testing
4. Performance testing
5. Bug fixes
6. Build release APK
7. Documentation
8. Training materials

**Deliverables**:
- Tested, stable app
- Release APK
- User documentation

---

## 💻 **CODE EXAMPLES**

### Example 1: Camera Service Implementation

```dart
// lib/services/camera_service.dart

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CameraService {
  CameraController? _controller;
  bool _isRecording = false;
  String? _currentRecordingPath;

  // Initialize front camera
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
    } catch (e) {
      print('Camera initialization error: $e');
      throw Exception('Failed to initialize camera');
    }
  }

  // Start recording
  Future<void> startRecording(int sessionId) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    if (_isRecording) {
      throw Exception('Already recording');
    }

    try {
      // Get storage directory
      final directory = await getExternalStorageDirectory();
      final monionDir = Directory('${directory!.path}/DCIM/Monion/Front');
      
      if (!await monionDir.exists()) {
        await monionDir.create(recursive: true);
      }

      // Create filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${monionDir.path}/Session_${sessionId}_Front_$timestamp.mp4';

      // Start recording
      await _controller!.startVideoRecording();
      _isRecording = true;

      print('Recording started: $_currentRecordingPath');
    } catch (e) {
      print('Recording start error: $e');
      throw Exception('Failed to start recording');
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    if (_controller == null || !_isRecording) {
      return null;
    }

    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Get file info
      final fileSize = await File(file.path).length();
      final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);

      print('Recording stopped: ${file.path} ($fileSizeMB MB)');

      return file.path;
    } catch (e) {
      print('Recording stop error: $e');
      _isRecording = false;
      return null;
    }
  }

  // Get camera controller for preview
  CameraController? get controller => _controller;

  // Check if recording
  bool get isRecording => _isRecording;

  // Dispose
  void dispose() {
    _controller?.dispose();
  }
}
```

**Usage in Driver Dashboard**:
```dart
class _DriverDashboardState extends State<DriverDashboard> {
  final CameraService _cameraService = CameraService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      setState(() {});
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  Future<void> _startSession(String direction) async {
    // Create session in database
    final session = await DatabaseService.instance.createSession(...);

    // Start recording
    try {
      await _cameraService.startRecording(session.id!);
      
      setState(() {
        _activeSession = session;
      });
    } catch (e) {
      _showError('Recording error: $e');
    }
  }

  Future<void> _endSession() async {
    // Stop recording
    final videoPath = await _cameraService.stopRecording();

    // Save recording to database
    if (videoPath != null) {
      await DatabaseService.instance.createRecording(
        sessionId: _activeSession!.id!,
        cameraType: 'FRONT',
        filePath: videoPath,
      );
    }

    // End session
    await DatabaseService.instance.endSession(_activeSession!.id!);

    setState(() {
      _activeSession = null;
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}
```

---

### Example 2: RTSP Service (Using media_kit)

```dart
// lib/services/rtsp_service.dart

import 'package:media_kit/media_kit.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RTSPService {
  static const String rtspUrl = 
      'rtsp://admin:MyCamStream123@192.168.137.75:554/cam/realmonitor?channel=1&subtype=0';
  
  static const platform = MethodChannel('com.example.monion/rtsp');
  
  Player? _player;
  bool _isConnected = false;
  bool _isRecording = false;
  String? _currentRecordingPath;

  // Initialize player
  Future<void> initialize() async {
    _player = Player();
  }

  // Connect to RTSP stream
  Future<void> connect() async {
    if (_player == null) {
      throw Exception('Player not initialized');
    }

    try {
      await _player!.open(Media(rtspUrl));
      _isConnected = true;
      print('RTSP stream connected');
    } catch (e) {
      print('RTSP connection error: $e');
      throw Exception('Failed to connect to camera');
    }
  }

  // Disconnect from stream
  Future<void> disconnect() async {
    if (_player != null) {
      await _player!.pause();
      _isConnected = false;
    }
  }

  // Start recording (using platform channel to FFmpeg)
  Future<void> startRecording(int sessionId) async {
    if (!_isConnected) {
      throw Exception('Not connected to stream');
    }

    try {
      // Get storage directory
      final directory = await getExternalStorageDirectory();
      final monionDir = Directory('${directory!.path}/DCIM/Monion/WiFi');
      
      if (!await monionDir.exists()) {
        await monionDir.create(recursive: true);
      }

      // Create filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${monionDir.path}/Session_${sessionId}_WiFi_$timestamp.mp4';

      // Call native method to start FFmpeg recording
      final result = await platform.invokeMethod('startRecording', {
        'rtsp_url': rtspUrl,
        'output_path': _currentRecordingPath,
      });

      if (result == 0) {
        _isRecording = true;
        print('RTSP recording started: $_currentRecordingPath');
      } else {
        throw Exception('FFmpeg returned error code: $result');
      }
    } catch (e) {
      print('RTSP recording start error: $e');
      throw Exception('Failed to start recording');
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      return null;
    }

    try {
      // Call native method to stop FFmpeg
      await platform.invokeMethod('stopRecording');
      _isRecording = false;

      // Get file info
      if (_currentRecordingPath != null && 
          await File(_currentRecordingPath!).exists()) {
        final fileSize = await File(_currentRecordingPath!).length();
        final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);
        
        print('RTSP recording stopped: $_currentRecordingPath ($fileSizeMB MB)');
        
        return _currentRecordingPath;
      }

      return null;
    } catch (e) {
      print('RTSP recording stop error: $e');
      _isRecording = false;
      return null;
    }
  }

  // Get player for video preview
  Player? get player => _player;

  // Status checks
  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;

  // Dispose
  void dispose() {
    _player?.dispose();
  }
}
```

---

### Example 3: Recording Model

```dart
// lib/models/recording.dart

class Recording {
  final int? id;
  final int sessionId;
  final String cameraType;  // 'FRONT' or 'WIFI'
  final String filePath;
  final int? fileSize;      // in bytes
  final int? duration;      // in seconds
  final DateTime startTime;
  final DateTime? endTime;
  final String status;      // 'ACTIVE', 'COMPLETED', 'FAILED'

  Recording({
    this.id,
    required this.sessionId,
    required this.cameraType,
    required this.filePath,
    this.fileSize,
    this.duration,
    required this.startTime,
    this.endTime,
    this.status = 'ACTIVE',
  });

  // To database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'camera_type': cameraType,
      'file_path': filePath,
      'file_size': fileSize,
      'duration': duration,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
    };
  }

  // From database map
  factory Recording.fromMap(Map<String, dynamic> map) {
    return Recording(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      cameraType: map['camera_type'] as String,
      filePath: map['file_path'] as String,
      fileSize: map['file_size'] as int?,
      duration: map['duration'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null 
          ? DateTime.parse(map['end_time'] as String)
          : null,
      status: map['status'] as String? ?? 'ACTIVE',
    );
  }

  // Get file size in MB
  String get fileSizeMB {
    if (fileSize == null) return 'Unknown';
    return (fileSize! / 1024 / 1024).toStringAsFixed(2);
  }

  // Get formatted duration
  String get formattedDuration {
    if (duration == null) return 'Unknown';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Copy with
  Recording copyWith({
    int? id,
    int? sessionId,
    String? cameraType,
    String? filePath,
    int? fileSize,
    int? duration,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  }) {
    return Recording(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      cameraType: cameraType ?? this.cameraType,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }
}
```

---

### Example 4: Update Database Service for Recordings

```dart
// Add to lib/services/database_service.dart

// Create recordings table
Future _createDB(Database db, int version) async {
  // ... existing tables ...

  // Recordings table
  await db.execute('''
    CREATE TABLE recordings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      camera_type TEXT NOT NULL,
      file_path TEXT NOT NULL,
      file_size INTEGER,
      duration INTEGER,
      start_time TEXT NOT NULL,
      end_time TEXT,
      status TEXT DEFAULT 'COMPLETED',
      FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
    )
  ''');
}

// Create recording
Future<Recording> createRecording(Recording recording) async {
  final db = await database;
  final id = await db.insert('recordings', recording.toMap());
  return recording.copyWith(id: id);
}

// Get recordings for session
Future<List<Recording>> getSessionRecordings(int sessionId) async {
  final db = await database;
  final maps = await db.query(
    'recordings',
    where: 'session_id = ?',
    whereArgs: [sessionId],
    orderBy: 'start_time ASC',
  );

  return maps.map((map) => Recording.fromMap(map)).toList();
}

// Get all recordings
Future<List<Recording>> getAllRecordings() async {
  final db = await database;
  final maps = await db.query(
    'recordings',
    orderBy: 'start_time DESC',
  );

  return maps.map((map) => Recording.fromMap(map)).toList();
}

// Update recording
Future<int> updateRecording(Recording recording) async {
  final db = await database;
  return await db.update(
    'recordings',
    recording.toMap(),
    where: 'id = ?',
    whereArgs: [recording.id],
  );
}

// Delete recording
Future<int> deleteRecording(int id) async {
  final db = await database;
  
  // Get file path before deleting
  final recording = await db.query(
    'recordings',
    where: 'id = ?',
    whereArgs: [id],
  );
  
  if (recording.isNotEmpty) {
    final filePath = recording.first['file_path'] as String;
    final file = File(filePath);
    
    // Delete physical file
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  // Delete database entry
  return await db.delete(
    'recordings',
    where: 'id = ?',
    whereArgs: [id],
  );
}
```

---

## 🧪 **TESTING REQUIREMENTS**

### Unit Tests

**Coverage Target**: 70%+

**Test Files**:
```
test/
├── models/
│   ├── session_test.dart
│   ├── scan_test.dart
│   └── recording_test.dart
├── services/
│   ├── database_service_test.dart
│   ├── export_service_test.dart
│   └── camera_service_test.dart
└── utils/
    └── validators_test.dart
```

**Example Test**:
```dart
// test/models/session_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:monion_scanner/models/session.dart';

void main() {
  group('Session Model', () {
    test('should create session with correct values', () {
      final session = Session(
        driverName: 'Test Driver',
        busPlate: 'ABC-123',
        direction: 'To University',
        startTime: DateTime.now(),
      );

      expect(session.driverName, 'Test Driver');
      expect(session.busPlate, 'ABC-123');
      expect(session.isActive, true);
    });

    test('should calculate duration correctly', () {
      final start = DateTime(2025, 1, 18, 8, 0);
      final end = DateTime(2025, 1, 18, 9, 30);
      
      final session = Session(
        driverName: 'Test Driver',
        busPlate: 'ABC-123',
        direction: 'To University',
        startTime: start,
        endTime: end,
        isActive: false,
      );

      expect(session.duration.inMinutes, 90);
      expect(session.formattedDuration, '1h 30m');
    });

    test('should convert to map correctly', () {
      final session = Session(
        id: 1,
        driverName: 'Test Driver',
        busPlate: 'ABC-123',
        direction: 'To University',
        startTime: DateTime(2025, 1, 18, 8, 0),
        totalScansIn: 10,
      );

      final map = session.toMap();

      expect(map['id'], 1);
      expect(map['driver_name'], 'Test Driver');
      expect(map['total_scans_in'], 10);
    });
  });
}
```

### Integration Tests

**Test Scenarios**:
1. Complete driver workflow
2. Complete admin workflow
3. Recording lifecycle
4. Export functionality
5. Network interruption handling

**Example Integration Test**:
```dart
// integration_test/driver_workflow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:monion_scanner/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Driver Workflow', () {
    testWidgets('Complete session flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Login as driver
      await tester.enterText(
        find.byType(TextField).first,
        'Test Driver',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'ABC-123',
      );
      await tester.tap(find.text('Login as Driver'));
      await tester.pumpAndSettle();

      // Start session
      await tester.tap(find.text('Start New Session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('To University'));
      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      // Verify session started
      expect(find.text('Active Session'), findsOneWidget);

      // Open scanner
      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      // Simulate scan (would need mock)
      // ...

      // End session
      await tester.pageBack();
      await tester.tap(find.text('End Session'));
      await tester.tap(find.text('End Session')); // Confirm
      await tester.pumpAndSettle();

      // Verify session ended
      expect(find.text('No Active Session'), findsOneWidget);
    });
  });
}
```

### Manual Testing Checklist

#### Driver Module
- [ ] Login with valid credentials
- [ ] Login rejected with empty fields
- [ ] Start session (To University)
- [ ] Start session (From University)
- [ ] Recording indicators appear
- [ ] Scanner opens camera
- [ ] Valid scan shows success
- [ ] Invalid scan shows error
- [ ] Duplicate scan prevented
- [ ] Toggle IN/OUT works
- [ ] Flashlight toggles
- [ ] Recent scans update
- [ ] Statistics update
- [ ] End session confirmation
- [ ] Videos saved correctly
- [ ] Return to dashboard

#### Admin Module
- [ ] Login with correct credentials
- [ ] Login rejected with wrong password
- [ ] View all sessions
- [ ] Search by driver works
- [ ] Filter by direction works
- [ ] Pull-to-refresh works
- [ ] Session detail opens
- [ ] View all scans
- [ ] Filter scans works
- [ ] Delete scan works
- [ ] Export CSV (all sessions)
- [ ] Export CSV (single session)
- [ ] Export PDF works
- [ ] Files saved to Downloads
- [ ] View recordings list
- [ ] Play video works
- [ ] Download video works

#### Edge Cases
- [ ] Low storage warning
- [ ] Camera permission denied
- [ ] WiFi connection lost
- [ ] App backgrounded during recording
- [ ] Phone restart during session
- [ ] Database corruption recovery
- [ ] Very long session (>2 hours)
- [ ] 100+ scans in one session

---

## 📦 **DEPLOYMENT GUIDE**

### Build Release APK

#### Step 1: Update Version
**File**: `pubspec.yaml`
```yaml
version: 2.0.0+2  # version+buildNumber
```

#### Step 2: Build APK
```bash
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

#### Step 3: Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

**Output**: `build/app/outputs/bundle/release/app-release.aab`

### Installation

**Method 1: Direct Install**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Method 2: Manual Transfer**
1. Copy APK to phone
2. Enable "Install from Unknown Sources"
3. Open APK file
4. Click Install

### App Signing (for Production)

#### Step 1: Generate Keystore
```bash
keytool -genkey -v -keystore monion-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias monion
```

#### Step 2: Configure Gradle
**File**: `android/key.properties`
```
storePassword=<password>
keyPassword=<password>
keyAlias=monion
storeFile=<path-to-jks>
```

**File**: `android/app/build.gradle.kts`
```kotlin
signingConfigs {
    create("release") {
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        proguar# MONION COMPLETE SYSTEM - MASTER DOCUMENTATION

**Version:** 2.0.0  
**Company:** VINEX  
**Client:** NINU University  
**Project Type:** Mobile Application (Android)  
**Last Updated:** January 18, 2025

---

## 📋 **TABLE OF CONTENTS**

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Current Implementation (Phase 1)](#current-implementation-phase-1)
4. [Pending Features (Phase 2)](#pending-features-phase-2)
5. [Technology Stack](#technology-stack)
6. [Project Structure](#project-structure)
7. [Database Schema](#database-schema)
8. [Feature Specifications](#feature-specifications)
9. [Implementation Roadmap](#implementation-roadmap)
10. [Code Examples](#code-examples)
11. [Testing Requirements](#testing-requirements)
12. [Deployment Guide](#deployment-guide)
13. [Appendices](#appendices)

---

## 🎯 **EXECUTIVE SUMMARY**

### Project Overview

**Monion** is a comprehensive bus security and student verification system designed for NINU University buses operated by VINEX company. The system combines:

- **Real-time video recording** from multiple camera sources
- **Barcode scanning** for student National ID verification
- **Session management** for tracking bus trips
- **Admin dashboard** for data review and reporting
- **Data export** capabilities (CSV/PDF)

### Business Objectives

1. **Safety & Security**: Record all bus trips for accountability
2. **Student Tracking**: Verify and log student boarding/exiting
3. **Compliance**: Maintain detailed audit trails
4. **Efficiency**: Streamline driver and admin workflows
5. **Reporting**: Generate comprehensive trip reports

### Key Stakeholders

- **Drivers**: Use the app to manage trips and scan students
- **Administrators**: Review sessions, access videos, generate reports
- **VINEX Management**: Monitor system performance
- **NINU University**: Ensure student safety and compliance

---

## 🏗️ **SYSTEM ARCHITECTURE**

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    MONION MOBILE APP                        │
│                     (Flutter/Android)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐   │
│  │    Driver     │  │     Admin     │  │   Camera     │   │
│  │    Module     │  │    Module     │  │   Module     │   │
│  └───────────────┘  └───────────────┘  └──────────────┘   │
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐   │
│  │   Scanner     │  │   Database    │  │   Export     │   │
│  │   Module      │  │   Service     │  │   Service    │   │
│  └───────────────┘  └───────────────┘  └──────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
  ┌─────────────┐      ┌──────────┐      ┌────────────────┐
  │ Phone       │      │  SQLite  │      │  File System   │
  │ Camera      │      │ Database │      │ (Videos/Exports│
  └─────────────┘      └──────────┘      └────────────────┘
         │
         ▼
  ┌─────────────┐
  │ WiFi Camera │
  │ (Imou RTSP) │
  └─────────────┘
```

### Data Flow Diagram

```
Driver Login → Start Session → Begin Recording (Both Cameras)
                    ↓
        Student Boards → Scan Barcode → Save to Database
                    ↓
           Trip Continues → Continuous Recording
                    ↓
        Student Exits → Scan OUT → Update Database
                    ↓
         Trip Complete → Stop Recording → Save Videos
                    ↓
         Admin Review → View Sessions → Export Data/Videos
```

### Component Interaction

```mermaid
graph TD
    A[Driver App] -->|Start Session| B[Session Service]
    B -->|Create Session| C[Database]
    B -->|Start Recording| D[Camera Service]
    D -->|Record Front| E[Phone Camera]
    D -->|Record WiFi| F[RTSP Stream]
    A -->|Scan Student| G[Scanner Service]
    G -->|Validate ID| H[Validation]
    H -->|Save Scan| C
    I[Admin App] -->|View Sessions| C
    I -->|Export Data| J[Export Service]
    J -->|Generate CSV/PDF| K[File System]
    I -->|View Videos| F
```

---

## ✅ **CURRENT IMPLEMENTATION (PHASE 1)**

### Implemented Features

#### 1. **Authentication System**
- ✅ Dual login (Driver/Admin)
- ✅ Driver: Name + Bus Plate
- ✅ Admin: Username + Password
- ✅ Persistent credentials
- ✅ Auto-logout on session end

**Files:**
- `lib/screens/login_screen.dart`
- `lib/services/database_service.dart` (driver storage)

#### 2. **Session Management**
- ✅ Start session with direction (To/From University)
- ✅ Automatic timestamp recording
- ✅ Real-time duration tracking
- ✅ End session with confirmation
- ✅ Session status (Active/Completed)

**Files:**
- `lib/models/session.dart`
- `lib/screens/driver/driver_dashboard.dart`
- `lib/services/database_service.dart` (session CRUD)

#### 3. **Barcode Scanner**
- ✅ 1D/2D barcode support
- ✅ Center-area scanning (optimized performance)
- ✅ 14-digit National ID validation
- ✅ IN/OUT mode toggle
- ✅ Duplicate scan prevention
- ✅ Real-time scan statistics
- ✅ Recent scans list (last 10)
- ✅ Flashlight control
- ✅ Success/Error popups
- ✅ Scan overlay with corner markers

**Files:**
- `lib/screens/driver/scanner_screen.dart`
- `lib/services/database_service.dart` (scan storage)

#### 4. **Admin Dashboard**
- ✅ View all sessions
- ✅ Search by driver/bus plate
- ✅ Filter by direction
- ✅ Session statistics overview
- ✅ Pull-to-refresh
- ✅ Session detail view
- ✅ View all scans per session
- ✅ Delete individual scans
- ✅ Filter scans (IN/OUT/All)

**Files:**
- `lib/screens/admin/admin_dashboard.dart`
- `lib/screens/admin/session_detail_screen.dart`

#### 5. **Data Export**
- ✅ CSV export (All sessions)
- ✅ CSV export (Single session with details)
- ✅ PDF export (Professional report)
- ✅ Save to Downloads folder (`/storage/emulated/0/Download/`)
- ✅ Success dialog with file path
- ✅ Export from Admin Dashboard
- ✅ Export from Session Detail

**Files:**
- `lib/services/export_service.dart`

#### 6. **UI/UX**
- ✅ Material Design 3
- ✅ VINEX brand colors (#2B7EF4)
- ✅ Custom widgets (buttons, cards, badges)
- ✅ Loading states
- ✅ Error handling
- ✅ Toast notifications
- ✅ Empty states
- ✅ Portrait mode only

**Files:**
- `lib/theme/app_theme.dart`
- `lib/utils/constants.dart`
- `lib/widgets/*.dart`

#### 7. **Database**
- ✅ SQLite local storage
- ✅ Three tables: sessions, scans, drivers
- ✅ Foreign key relationships
- ✅ Automatic data updates
- ✅ Cascade delete

**Files:**
- `lib/services/database_service.dart`

---

## 🚧 **PENDING FEATURES (PHASE 2)**

### Critical Features (High Priority)

#### 1. **Video Recording System** 🎥

##### Front Camera Recording
**Purpose**: Record from phone's front-facing camera during active session

**Requirements**:
- Auto-start recording when session starts
- Stop when session ends
- Save to `/DCIM/Monion/Front/`
- File naming: `Session_{id}_Front_{timestamp}.mp4`
- Show recording indicator (REC badge)
- Quality: 720p minimum, 1080p preferred
- Include audio

**Implementation**:
```dart
// lib/services/camera_service.dart
class CameraService {
  CameraController? _controller;
  bool _isRecording = false;
  
  Future<void> startRecording(int sessionId) async {
    // Initialize front camera
    // Start recording
    // Update UI with recording status
  }
  
  Future<String?> stopRecording() async {
    // Stop recording
    // Save file
    // Return file path
  }
}
```

**Database Schema Addition**:
```sql
CREATE TABLE recordings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  camera_type TEXT NOT NULL,  -- 'FRONT' or 'WIFI'
  file_path TEXT NOT NULL,
  file_size INTEGER,
  duration INTEGER,
  start_time TEXT NOT NULL,
  end_time TEXT,
  FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

**Packages Needed**:
```yaml
dependencies:
  camera: ^0.10.5+5
```

---

##### WiFi Camera (RTSP) Recording
**Purpose**: Stream and record from Imou WiFi camera mounted on bus

**RTSP Details**:
- URL: `rtsp://admin:MyCamStream123@192.168.137.75:554/cam/realmonitor?channel=1&subtype=0`
- Protocol: RTSP
- Codec: H.264
- Resolution: 1080p
- Network: WiFi Hotspot from phone

**Requirements**:
- Connect to RTSP stream when session starts
- Continuous recording with session segmentation
- Save to `/DCIM/Monion/WiFi/`
- File naming: `Session_{id}_WiFi_{timestamp}.mp4`
- Handle network interruptions
- Auto-reconnect if connection drops
- Show connection status

**Implementation Approach**:

**Option A: FFmpeg Native (Complex but Powerful)**
- Use FFmpeg for RTSP capture and encoding
- Requires NDK and native code
- See `ffmpeg_rtsp_readme.md` for full guide
- Best video quality and control

**Option B: Plugin-based (Simpler)**
```yaml
dependencies:
  media_kit: ^1.1.10
  media_kit_video: ^1.2.4
  flutter_vlc_player: ^7.4.0
```

```dart
// lib/services/rtsp_service.dart
class RTSPService {
  static const String rtspUrl = 'rtsp://admin:MyCamStream123@192.168.137.75:554/...';
  
  Future<void> startStream() async {
    // Connect to RTSP
    // Display preview
  }
  
  Future<void> startRecording(int sessionId) async {
    // Start capturing stream
    // Save to file
  }
  
  Future<void> stopRecording() async {
    // Stop capture
    // Finalize file
  }
}
```

**Network Configuration**:
1. Phone creates WiFi hotspot
2. Camera connects to phone's hotspot
3. Camera IP: `192.168.137.75`
4. App connects to camera via RTSP
5. Recording starts automatically

---

#### 2. **Manual Entry Screen** 📝

**Purpose**: Backup input method when scanner fails

**Requirements**:
- Keyboard input for 14-digit National ID
- Real-time validation as user types
- Show error if not 14 digits
- Show error if not all numbers
- Same IN/OUT logic as scanner
- Same success/error popups

**UI Design**:
```
┌──────────────────────────────┐
│  Manual Entry                │
│  ┌────────────────────────┐  │
│  │ National ID            │  │
│  │ [1234567890____]       │  │
│  └────────────────────────┘  │
│                              │
│  ⬤ Scan IN    ○ Scan OUT    │
│                              │
│  [      SUBMIT      ]        │
└──────────────────────────────┘
```

**File to Create**: `lib/screens/driver/manual_entry_screen.dart`

**Code Template**:
```dart
class ManualEntryScreen extends StatefulWidget {
  final Session session;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manual Entry')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 14,
              decoration: InputDecoration(
                labelText: 'National ID',
                hintText: '14 digits',
              ),
              onChanged: _validateInput,
            ),
            // Mode toggle
            // Submit button
          ],
        ),
      ),
    );
  }
}
```

---

#### 3. **Passenger List Screen** 👥

**Purpose**: Show all currently scanned-in students

**Requirements**:
- List all students with status IN
- Show National ID
- Show scan time
- One-tap to scan OUT
- Search by ID
- Real-time updates
- Show count (e.g., "25 passengers on board")

**UI Design**:
```
┌──────────────────────────────┐
│  Passengers (25)             │
│  ┌────────────────────────┐  │
│  │ 12345678901234    ✓ IN │  │
│  │ 05:38 PM               │  │
│  │         [SCAN OUT]     │  │
│  ├────────────────────────┤  │
│  │ 98765432109876    ✓ IN │  │
│  │ 05:40 PM               │  │
│  │         [SCAN OUT]     │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

**File to Create**: `lib/screens/driver/passenger_list_screen.dart`

**Database Query**:
```dart
Future<List<Scan>> getCurrentPassengers(int sessionId) async {
  final allScans = await getSessionScans(sessionId);
  final Map<String, Scan> latestScans = {};
  
  for (var scan in allScans) {
    if (!latestScans.containsKey(scan.nationalId) || 
        scan.timestamp.isAfter(latestScans[scan.nationalId]!.timestamp)) {
      latestScans[scan.nationalId] = scan;
    }
  }
  
  return latestScans.values
      .where((scan) => scan.scanType == 'IN')
      .toList();
}
```

---

#### 4. **Session Summary Screen** 📊

**Purpose**: Show trip summary when session ends

**Requirements**:
- Total duration
- Total students scanned IN
- Total students scanned OUT
- Students still on board (IN - OUT)
- List of all scans with times
- Option to export session
- Option to view recordings
- Share summary

**UI Design**:
```
┌──────────────────────────────┐
│  Session Complete ✓          │
│  ┌────────────────────────┐  │
│  │ Duration: 45 minutes   │  │
│  │ Scanned IN:  25        │  │
│  │ Scanned OUT: 25        │  │
│  │ Still on board: 0      │  │
│  └────────────────────────┘  │
│                              │
│  📹 View Recordings          │
│  📄 Export PDF               │
│  📊 Export CSV               │
│  🏠 Return to Dashboard      │
└──────────────────────────────┘
```

**File to Create**: `lib/screens/driver/session_summary_screen.dart`

---

#### 5. **Video Playback System** 🎬

**Purpose**: Allow admin to watch recorded videos

**Requirements**:
- List all recordings by session
- Show front camera and WiFi camera videos
- Video player with controls (play/pause/seek)
- Timestamp display
- Download video option
- Share video option
- Delete video option

**UI Design**:
```
┌──────────────────────────────┐
│  Session 3 - Recordings      │
│  ┌────────────────────────┐  │
│  │ 📹 Front Camera        │  │
│  │ 45:23 | 125 MB         │  │
│  │         [▶ PLAY]       │  │
│  ├────────────────────────┤  │
│  │ 📹 WiFi Camera         │  │
│  │ 45:30 | 340 MB         │  │
│  │         [▶ PLAY]       │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

**Files to Create**:
- `lib/screens/admin/recordings_screen.dart`
- `lib/screens/admin/video_player_screen.dart`

**Packages**:
```yaml
dependencies:
  video_player: ^2.8.1
  chewie: ^1.7.4  # Better video player controls
```

---

### Medium Priority Features

#### 6. **Settings Panel** ⚙️

**Requirements**:
- Change admin password
- Configure recording quality
- Set storage limits
- Clear old data (sessions/videos older than X days)
- Backup database
- Restore database
- App version info
- About section

**File to Create**: `lib/screens/admin/admin_settings_screen.dart`

---

#### 7. **Analytics Dashboard** 📈

**Requirements**:
- Daily/Weekly/Monthly statistics
- Most active drivers
- Peak usage times
- Average trip duration
- Total scans per day
- Charts and graphs

**Packages**:
```yaml
dependencies:
  fl_chart: ^0.68.0
  syncfusion_flutter_charts: ^24.1.41
```

**File to Create**: `lib/screens/admin/analytics_screen.dart`

---

#### 8. **Notifications** 🔔

**Requirements**:
- Low battery warning during session
- Storage space warning
- Session reminder for drivers
- Duplicate scan alerts
- Network connection lost (for WiFi camera)

**Packages**:
```yaml
dependencies:
  flutter_local_notifications: ^16.3.0
```

---

#### 9. **Sounds & Haptics** 🔊

**Requirements**:
- Success beep on valid scan
- Error buzz on invalid scan
- Haptic feedback on scan
- Recording start/stop sounds

**Packages**:
```yaml
dependencies:
  audioplayers: ^5.2.1
  vibration: ^1.8.4
```

**Implementation**:
```dart
// In scanner success
HapticFeedback.mediumImpact();
await audioPlayer.play(AssetSource('sounds/success.mp3'));

// In scanner error
HapticFeedback.heavyImpact();
await audioPlayer.play(AssetSource('sounds/error.mp3'));
```

---

### Low Priority Features

#### 10. **Dark Mode** 🌙

**Implementation**: Already partially set up in `lib/theme/app_theme.dart`

---

#### 11. **Multi-language Support** 🌐

**Languages**: English, Arabic

**Package**:
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

---

#### 12. **Cloud Backup** ☁️

**Purpose**: Upload videos and database to cloud storage

**Options**:
- Firebase Storage
- AWS S3
- Google Drive

---

## 🛠️ **TECHNOLOGY STACK**

### Frontend
```yaml
Framework: Flutter 3.9.2+
Language: Dart 3.0+
UI: Material Design 3
State Management: Provider / StatefulWidget
```

### Backend (Local)
```yaml
Database: SQLite (sqflite ^2.3.3)
File Storage: Local filesystem
Video: FFmpeg / media_kit
```

### Packages (Current)
```yaml
dependencies:
  mobile_scanner: ^5.2.3      # Barcode scanning
  sqflite: ^2.3.3             # Database
  path_provider: ^2.1.4       # File paths
  provider: ^6.1.2            # State management
  intl: ^0.19.0               # Date formatting
  pdf: ^3.11.1                # PDF generation
  csv: ^6.0.0                 # CSV export
  permission_handler: ^11.3.1 # Permissions
```

### Packages (To Add)
```yaml
dependencies:
  camera: ^0.10.5+5           # Front camera
  media_kit: ^1.1.10          # RTSP streaming
  media_kit_video: ^1.2.4     # Video player
  video_player: ^2.8.1        # Video playback
  chewie: ^1.7.4              # Video controls
  audioplayers: ^5.2.1        # Sounds
  vibration: ^1.8.4           # Haptics
  fl_chart: ^0.68.0           # Charts
  flutter_local_notifications: ^16.3.0  # Notifications
```

### Native Code
```
Platform: Android (API 24+)
Languages: Kotlin, Java, C++
NDK: For FFmpeg integration
FFmpeg: Custom compilation for ARM64
```

---

## 📁 **PROJECT STRUCTURE (COMPLETE)**

```
monion_scanner/
├── lib/
│   ├── main.dart                          # ✅ App entry point
│   │
│   ├── models/                            # ✅ Data models
│   │   ├── session.dart                   # ✅ Session model
│   │   ├── scan.dart                      # ✅ Scan model
│   │   ├── driver.dart                    # ✅ Driver model
│   │   └── recording.dart                 # ⏳ Recording model (TO ADD)
│   │
│   ├── screens/                           # Screens
│   │   ├── login_screen.dart             # ✅ Driver/Admin login
│   │   │
│   │   ├── driver/                        # Driver screens
│   │   │   ├── driver_dashboard.dart     # ✅ Main driver screen
│   │   │   ├── scanner_screen.dart       # ✅ Barcode scanner
│   │   │   ├── manual_entry_screen.dart  # ⏳ Manual ID entry (TO ADD)
│   │   │   ├── passenger_list_screen.dart # ⏳ Current passengers (TO ADD)
│   │   │   └── session_summary_screen.dart # ⏳ Session complete (TO ADD)
│   │   │
│   │   └── admin/                         # Admin screens
│   │       ├── admin_dashboard.dart      # ✅ Main admin screen
│   │       ├── session_detail_screen.dart # ✅ Session details
│   │       ├── recordings_screen.dart    # ⏳ Video list (TO ADD)
│   │       ├── video_player_screen.dart  # ⏳ Video playback (TO ADD)
│   │       ├── analytics_screen.dart     # ⏳ Charts/Stats (TO ADD)
│   │       └── admin_settings_screen.dart # ⏳ Settings (TO ADD)
│   │
│   ├── widgets/                           # ✅ Reusable components
│   │   ├── custom_button.dart            # ✅ Buttons
│   │   ├── custom_card.dart              # ✅ Cards
│   │   ├── status_badge.dart             # ✅ Badges
│   │   └── loading_indicator.dart        # ⏳ Loading (TO ADD)
│   │
│   ├── services/                          # Business logic
│   │   ├── database_service.dart         # ✅ SQLite operations
│   │   ├── export_service.dart           # ✅ CSV/PDF export
│   │   ├── camera_service.dart           # ⏳ Front camera (TO ADD)
│   │   ├── rtsp_service.dart             # ⏳ WiFi camera (TO ADD)
│   │   ├── recording_service.dart        # ⏳ Video management (TO ADD)
│   │   └── notification_service.dart     # ⏳ Notifications (TO ADD)
│   │
│   ├── utils/                             # ✅ Helpers
│   │   ├── constants.dart                # ✅ App constants
│   │   └── validators.dart               # ⏳ Validation (TO ADD)
│   │
│   └── theme/                             # ✅ App theming
│       └── app_theme.dart                # ✅ Theme config
│
├── android/                               # Android config
│   ├── app/
│   │   ├── build.gradle.kts              # ✅ Build config
│   │   └── src/main/
│   │       ├── AndroidManifest.xml       # ✅ Permissions
│   │       ├── kotlin/                    # ⏳ Native Kotlin (TO ADD)
│   │       │   └── MainActivity.kt       # ⏳ Platform channels
│   │       └── cpp/                       # ⏳ Native C++ (TO ADD)
│   │           ├── CMakeLists.txt        # ⏳ CMake config
│   │           └── ffmpeg_recorder.cpp   # ⏳ FFmpeg recording
│   │
│   └── gradle/
│
├── assets/
│   ├── images/
│   │   └── vinex_logo.png                # ⏳ Company logo (TO ADD)
│   └── sounds/
│       ├── success.mp3                    # ⏳ Success sound (TO ADD)
│       └── error.mp3                      # ⏳ Error sound (TO ADD)
│
├── pubspec.yaml                           # ✅ Dependencies
└── README.md                              # Project readme

Legend:
✅ = Implemented
⏳ = Pending
```

---

## 🗄️ **DATABASE SCHEMA (COMPLETE)**

### Current Tables

#### 1. sessions
```sql
CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  driver_name TEXT NOT NULL,
  bus_plate TEXT NOT NULL,
  direction TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  total_scans_in INTEGER NOT NULL DEFAULT 0,
  total_scans_out INTEGER NOT NULL DEFAULT 0
);
```

#### 2. scans
```sql
CREATE TABLE scans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  national_id TEXT NOT NULL,
  scan_type TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);
```

#### 3. drivers
```sql
CREATE TABLE drivers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  bus_plate TEXT NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE(name, bus_plate)
);
```

### Tables to Add

#### 4. recordings (NEW)
```sql
CREATE TABLE recordings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  camera_type TEXT NOT NULL,  -- 'FRONT' or 'WIFI'
  file_path TEXT NOT NULL,
  file_size INTEGER,
  duration INTEGER,           -- in seconds
  start_time TEXT NOT NULL,
  end_time TEXT,
  status TEXT DEFAULT 'COMPLETED',
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);
```

#### 5. settings (NEW)
```sql
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

---

## 📐 **FEATURE SPECIFICATIONS (DETAILED)**

### Recording System Specification

#### Camera Types

**1. Front Camera (Phone)**
- **Purpose**: Record driver and front view
- **Start Trigger**: When session starts
- **Stop Trigger**: When session ends
- **Storage**: `/DCIM/Monion/Front/`
- **Naming**: `Session_{sessionId}_Front_{timestamp}.mp4`
- **Quality**: 720p minimum, 1080p if device supports
- **Audio**: Yes
- **Indicator**: Red "REC" badge on screen

**2. WiFi Camera (RTSP)**
- **Purpose**: Record bus interior
- **Camera Model**: Imou WiFi Camera
- **Connection**: RTSP over WiFi hotspot
- **URL Format**: `rtsp://admin:MyCamStream123@192.168.137.75:554/cam/realmonitor?channel=1&subtype=0`
- **Start Trigger**: When session starts
- **Stop Trigger**: When session ends
- **Storage**: `/DCIM/Monion/WiFi/`
- **Naming**: `Session_{sessionId}_WiFi_{timestamp}.mp4`
- **Quality**: 1080p (from camera)
- **Codec**: H.264
- **Reconnection**: Auto-reconnect if WiFi drops

#### Recording Flow

```
1. Driver starts session
   ├─> Initialize front camera
   ├─> Start front camera recording
   ├─> Connect to RTSP stream
   ├─> Start RTSP recording
   └─> Create recording entries in database

2. Session active
   ├─> Monitor recording status
   ├─> Check storage space
   ├─> Handle errors/reconnections
   └─> Update UI indicators

3. Driver ends session
   ├─> Stop front camera recording
   ├─> Stop RTSP recording
   ├─> Save video files
   ├─> Update database with file info
   └─> Show session summary
```

#### Storage Management

**Requirements**:
- Check available space before starting
- Minimum required: 500MB free
- Auto-cleanup of old recordings if space < 1GB
- Keep recordings for 30 days by default
- Admin can configure retention period

**Storage Calculation**:
```
Front Camera: ~60 MB/min (720p)
WiFi Camera: ~120 MB/min (1080p)
45-