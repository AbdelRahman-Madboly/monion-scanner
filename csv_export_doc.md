# CSV Export Feature Implementation Guide

## 📋 Project Context

**App Name:** Monion Scanner  
**Current Version:** 1.0.0  
**Purpose:** Bus security and student verification app for NINU University by VINEX company

---

## 🎯 Feature Goal

Implement CSV export functionality that allows admins to export session data to CSV files saved in the device's **Downloads folder**.

---

## 📦 Required Packages

Add these to `pubspec.yaml` (already included):

```yaml
dependencies:
  csv: ^6.0.0                    # For CSV file generation
  path_provider: ^2.1.4          # For finding Downloads directory
  permission_handler: ^11.3.1    # For storage permissions
```

---

## 🔐 Required Permissions

### Android Permissions

**File:** `android/app/src/main/AndroidManifest.xml`

Add these permissions:

```xml
<!-- Storage permissions for saving files -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32" />
    
<!-- For Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />

<!-- Manage external storage for saving to Downloads -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" 
    tools:ignore="ScopedStorage" />
```

---

## 🏗️ Implementation Structure

### File to Create:

```
lib/services/export_service.dart
```

### File to Update:

```
lib/screens/admin/admin_dashboard.dart
```

---

## 💻 Complete Code Implementation

### Step 1: Create Export Service

**File:** `lib/services/export_service.dart`

```dart
// lib/services/export_service.dart
// Purpose: Handle CSV export of session data

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../models/scan.dart';
import 'database_service.dart';

class ExportService {
  // Request storage permission
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
      if (await Permission.photos.isGranted ||
          await Permission.videos.isGranted ||
          await Permission.audio.isGranted) {
        return true;
      }

      // Request permissions
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }

      // Fallback to storage permission for older Android versions
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true; // iOS doesn't need permission for app documents
  }

  // Export single session to CSV
  static Future<String?> exportSessionToCSV(Session session) async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get all scans for this session
      final scans = await DatabaseService.instance.getSessionScans(session.id!);

      // Prepare CSV data
      List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        'Session ID',
        'Driver Name',
        'Bus Plate',
        'Direction',
        'Session Start',
        'Session End',
        'Duration',
        'Total Scans IN',
        'Total Scans OUT',
      ]);

      // Session info row
      rows.add([
        session.id,
        session.driverName,
        session.busPlate,
        session.direction,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime),
        session.endTime != null 
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!)
            : 'Active',
        session.formattedDuration,
        session.totalScansIn,
        session.totalScansOut,
      ]);

      // Empty row for separation
      rows.add([]);

      // Scans header
      rows.add([
        'Scan ID',
        'National ID',
        'Scan Type',
        'Timestamp',
      ]);

      // Scans data
      for (var scan in scans) {
        rows.add([
          scan.id,
          scan.nationalId,
          scan.scanType,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(scan.timestamp),
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Get Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'Session_${session.id}_$timestamp.csv';
      final filePath = '${directory!.path}/$filename';

      // Write file
      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      print('Error exporting CSV: $e');
      return null;
    }
  }

  // Export all sessions to CSV
  static Future<String?> exportAllSessionsToCSV() async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get all sessions
      final sessions = await DatabaseService.instance.getAllSessions();

      if (sessions.isEmpty) {
        throw Exception('No sessions to export');
      }

      // Prepare CSV data
      List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        'Session ID',
        'Driver Name',
        'Bus Plate',
        'Direction',
        'Start Time',
        'End Time',
        'Duration',
        'Total IN',
        'Total OUT',
        'Status',
      ]);

      // Sessions data
      for (var session in sessions) {
        rows.add([
          session.id,
          session.driverName,
          session.busPlate,
          session.direction,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime),
          session.endTime != null 
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!)
              : 'N/A',
          session.formattedDuration,
          session.totalScansIn,
          session.totalScansOut,
          session.isActive ? 'Active' : 'Completed',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Get Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'All_Sessions_$timestamp.csv';
      final filePath = '${directory!.path}/$filename';

      // Write file
      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      print('Error exporting all sessions CSV: $e');
      return null;
    }
  }

  // Export detailed session with all scans to CSV
  static Future<String?> exportDetailedSessionToCSV(Session session) async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get all scans for this session
      final scans = await DatabaseService.instance.getSessionScans(session.id!);

      // Prepare CSV data with detailed scan information
      List<List<dynamic>> rows = [];

      // Title
      rows.add(['MONION - Session Detailed Report']);
      rows.add([]);

      // Session Information Section
      rows.add(['SESSION INFORMATION']);
      rows.add(['Session ID:', session.id]);
      rows.add(['Driver Name:', session.driverName]);
      rows.add(['Bus Plate:', session.busPlate]);
      rows.add(['Direction:', session.direction]);
      rows.add(['Start Time:', DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime)]);
      rows.add([
        'End Time:',
        session.endTime != null 
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!)
            : 'Active'
      ]);
      rows.add(['Duration:', session.formattedDuration]);
      rows.add(['Total Scans IN:', session.totalScansIn]);
      rows.add(['Total Scans OUT:', session.totalScansOut]);
      rows.add(['Status:', session.isActive ? 'Active' : 'Completed']);
      rows.add([]);

      // Scans Section
      rows.add(['DETAILED SCANS']);
      rows.add(['#', 'National ID', 'Scan Type', 'Date', 'Time']);

      for (int i = 0; i < scans.length; i++) {
        final scan = scans[i];
        rows.add([
          i + 1,
          scan.nationalId,
          scan.scanType,
          DateFormat('yyyy-MM-dd').format(scan.timestamp),
          DateFormat('HH:mm:ss').format(scan.timestamp),
        ]);
      }

      // Summary Section
      rows.add([]);
      rows.add(['SUMMARY']);
      rows.add(['Total Scans:', scans.length]);
      rows.add(['Scans IN:', scans.where((s) => s.scanType == 'IN').length]);
      rows.add(['Scans OUT:', scans.where((s) => s.scanType == 'OUT').length]);
      rows.add([]);
      rows.add(['Generated:', DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())]);
      rows.add(['Generated by:', 'VINEX Monion System']);

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Get Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Create filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'Session_${session.id}_Detailed_$timestamp.csv';
      final filePath = '${directory!.path}/$filename';

      // Write file
      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      print('Error exporting detailed CSV: $e');
      return null;
    }
  }
}
```

---

### Step 2: Update Admin Dashboard

**File:** `lib/screens/admin/admin_dashboard.dart`

Update the `_showExportOptions()` method:

```dart
Future<void> _showExportOptions() async {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Export Data',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Export All Sessions
          ListTile(
            leading: const Icon(Icons.table_chart, color: AppColors.primary),
            title: const Text('Export All Sessions (CSV)'),
            subtitle: const Text('All sessions summary'),
            onTap: () async {
              Navigator.pop(context);
              await _exportAllSessions();
            },
          ),
          
          // Export Selected Session
          if (_filteredSessions.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.description, color: AppColors.success),
              title: const Text('Export Latest Session (CSV)'),
              subtitle: const Text('Detailed with all scans'),
              onTap: () async {
                Navigator.pop(context);
                await _exportLatestSession();
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _exportAllSessions() async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  final filePath = await ExportService.exportAllSessionsToCSV();

  if (mounted) {
    Navigator.pop(context); // Close loading

    if (filePath != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CSV file saved to:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filePath,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You can find it in your Downloads folder.',
                style: TextStyle(color: AppColors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showMessage('Export failed. Please check permissions.');
    }
  }
}

Future<void> _exportLatestSession() async {
  if (_filteredSessions.isEmpty) return;

  final session = _filteredSessions.first;

  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  final filePath = await ExportService.exportDetailedSessionToCSV(session);

  if (mounted) {
    Navigator.pop(context); // Close loading

    if (filePath != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detailed CSV file saved to:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filePath,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You can find it in your Downloads folder.',
                style: TextStyle(color: AppColors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showMessage('Export failed. Please check permissions.');
    }
  }
}
```

Add import at the top of admin_dashboard.dart:

```dart
import '../../services/export_service.dart';
```

---

## 🧪 Testing Steps

1. **Build and run the app:**
   ```bash
   flutter run
   ```

2. **Login as admin:**
   - Username: `admin`
   - Password: `admin123`

3. **Create test sessions:**
   - Logout and login as driver
   - Create sessions and scan some barcodes
   - Go back to admin panel

4. **Test export:**
   - Tap download icon in admin dashboard
   - Select "Export All Sessions (CSV)"
   - Grant storage permission when prompted
   - Check Downloads folder for CSV file

5. **Verify CSV file:**
   - Open with Excel, Google Sheets, or text editor
   - Check all data is present and formatted correctly

---

## 📱 Expected Output

### All Sessions CSV Format:

```
Session ID,Driver Name,Bus Plate,Direction,Start Time,End Time,Duration,Total IN,Total OUT,Status
1,John Doe,ABC-123,To University,2025-01-15 08:30:00,2025-01-15 09:15:00,45m,25,25,Completed
2,Jane Smith,XYZ-789,From University,2025-01-15 14:00:00,N/A,1h 23m,18,15,Active
```

### Detailed Session CSV Format:

```
MONION - Session Detailed Report

SESSION INFORMATION
Session ID:,1
Driver Name:,John Doe
Bus Plate:,ABC-123
Direction:,To University
...

DETAILED SCANS
#,National ID,Scan Type,Date,Time
1,12345678901234,IN,2025-01-15,08:35:12
2,98765432109876,IN,2025-01-15,08:36:45
...
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Permission Denied

**Solution:**
- Go to phone Settings > Apps > Monion > Permissions
- Enable "Files and media" or "Storage"
- For Android 13+: Enable "Photos and videos", "Music and audio"

### Issue 2: File not found in Downloads

**Solution:**
- File might be in `/storage/emulated/0/Android/data/com.example.monion_scanner/files/`
- Use a file manager app to locate the file
- Update code to use MediaStore for Android 10+ (more complex but better)

### Issue 3: CSV opens incorrectly in Excel

**Solution:**
- Open Excel first
- Go to File > Open > Browse
- Select "All Files (*.*)"
- Choose your CSV file
- Use "Text Import Wizard" to set delimiters

---

## 🚀 Future Enhancements

1. **Share functionality:** Allow sharing CSV via email/WhatsApp
2. **Date range filter:** Export only sessions from specific dates
3. **Custom columns:** Let admin choose which columns to export
4. **Compressed export:** Create ZIP files for large datasets
5. **Cloud backup:** Auto-upload to Google Drive or Dropbox

---

## 📞 Support

If you encounter issues:
1. Check Android version (should be 5.0+)
2. Verify storage permissions are granted
3. Try exporting to external storage directory instead
4. Check logcat for detailed error messages

---

## ✅ Completion Checklist

- [ ] Created `lib/services/export_service.dart`
- [ ] Updated `lib/screens/admin/admin_dashboard.dart`
- [ ] Added storage permissions to AndroidManifest.xml
- [ ] Tested on physical Android device
- [ ] Verified CSV file is in Downloads folder
- [ ] Opened CSV in Excel/Google Sheets successfully
- [ ] Tested with multiple sessions
- [ ] Tested permission handling

---

**This documentation is ready to use in a new chat to implement CSV export functionality!** 📊