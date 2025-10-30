// lib/screens/admin/recordings_screen.dart
// Purpose: List all video recordings from database with export functionality

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../services/database_service.dart';
import '../../models/recording.dart';
import '../../models/session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  List<Recording> _allRecordings = [];
  Map<int, Session> _sessionsMap = {};
  bool _isLoading = false;
  String _filterType = 'All';

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);

    try {
      // Load all recordings
      final recordings = await DatabaseService.instance.getAllRecordings();
      
      // Load all sessions to map session IDs to session data
      final sessions = await DatabaseService.instance.getAllSessions();
      final sessionsMap = <int, Session>{};
      for (var session in sessions) {
        if (session.id != null) {
          sessionsMap[session.id!] = session;
        }
      }

      setState(() {
        _allRecordings = recordings;
        _sessionsMap = sessionsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error loading recordings: $e');
    }
  }

  List<Recording> get _filteredRecordings {
    if (_filterType == 'All') return _allRecordings;
    return _allRecordings.where((r) => r.cameraType == _filterType).toList();
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Request storage permissions
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
      
      // For Android 13+
      if (Platform.isAndroid) {
        await Permission.videos.request();
        await Permission.photos.request();
      }
      
      return true; // Continue anyway, app directory doesn't need special permission
    }
    return true;
  }

  Future<void> _exportRecording(Recording recording) async {
    try {
      // Request permissions
      await _requestStoragePermission();

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get source file
      final sourceFile = File(recording.filePath);
      if (!await sourceFile.exists()) {
        if (!mounted) return;
        Navigator.pop(context);
        _showMessage('Video file not found');
        return;
      }

      // Use Download/Monion folder (same as CSV/PDF exports)
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download/Monion');
      } else {
        final appDir = await getExternalStorageDirectory();
        downloadsDir = Directory('${appDir?.path}/Download/Monion');
      }

      // Create Monion folder if it doesn't exist
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Create filename
      final session = _sessionsMap[recording.sessionId];
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(recording.startTime);
      final filename = '${recording.cameraType}_${session?.driverName ?? 'Unknown'}_$timestamp.mp4';
      final destPath = '${downloadsDir.path}/$filename';

      // Copy file
      await sourceFile.copy(destPath);

      if (!mounted) return;
      Navigator.pop(context);
      _showExportSuccessDialog(destPath);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showMessage('Export failed: $e');
    }
  }

  Future<void> _exportAllRecordings() async {
    if (_filteredRecordings.isEmpty) {
      _showMessage('No recordings to export');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export All Recordings'),
        content: Text('Export ${_filteredRecordings.length} recording(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Request permissions
      await _requestStoragePermission();

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      int successCount = 0;
      
      // Use Download/Monion folder (same as CSV/PDF exports)
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download/Monion');
      } else {
        final appDir = await getExternalStorageDirectory();
        downloadsDir = Directory('${appDir?.path}/Download/Monion');
      }

      // Create Monion folder if it doesn't exist
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      for (var recording in _filteredRecordings) {
        try {
          final sourceFile = File(recording.filePath);
          if (!await sourceFile.exists()) continue;

          final session = _sessionsMap[recording.sessionId];
          final timestamp = DateFormat('yyyyMMdd_HHmmss').format(recording.startTime);
          final filename = '${recording.cameraType}_${session?.driverName ?? 'Unknown'}_$timestamp.mp4';
          final destPath = '${downloadsDir.path}/$filename';

          await sourceFile.copy(destPath);
          successCount++;
        } catch (e) {
          print('Failed to export recording ${recording.id}: $e');
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      _showMessage('Exported $successCount recording(s) successfully to:\nInternal storage/Download/Monion/');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showMessage('Export failed: $e');
    }
  }

  void _showExportSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Export Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Video saved to:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Internal storage/Download/Monion/',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filePath.split('/').last,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.folder, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Same folder as CSV/PDF exports',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
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
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteRecording(Recording recording) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: Text('Delete this ${recording.cameraType} recording?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && recording.id != null) {
      try {
        await DatabaseService.instance.deleteRecording(recording.id!);
        
        // Also delete file
        final file = File(recording.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        _showMessage('Recording deleted');
        _loadRecordings();
      } catch (e) {
        _showMessage('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Recordings'),
        actions: [
          if (_filteredRecordings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportAllRecordings,
              tooltip: 'Export All',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('WIFI'),
                      const SizedBox(width: 8),
                      _buildFilterChip('FRONT'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Recordings list
                Expanded(
                  child: _filteredRecordings.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecordings.length,
                          itemBuilder: (context, index) {
                            final recording = _filteredRecordings[index];
                            return _buildRecordingCard(recording);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filterType = label;
        });
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Recordings Found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recordings will appear here after sessions',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(Recording recording) {
    final session = _sessionsMap[recording.sessionId];
    final fileExists = File(recording.filePath).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: recording.cameraType == 'WIFI' 
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: recording.cameraType == 'WIFI' 
                          ? Colors.blue
                          : Colors.green,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        recording.cameraType == 'WIFI' 
                            ? Icons.wifi
                            : Icons.camera_front,
                        size: 16,
                        color: recording.cameraType == 'WIFI' 
                            ? Colors.blue
                            : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recording.cameraType,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: recording.cameraType == 'WIFI' 
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  fileExists ? Icons.check_circle : Icons.error,
                  color: fileExists ? Colors.green : Colors.red,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (session != null) ...[
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(session.driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  const Icon(Icons.directions_bus, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(session.busPlate),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(DateFormat('MMM dd, yyyy HH:mm').format(recording.startTime)),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Duration: ${recording.formattedDuration}'),
                const SizedBox(width: 24),
                const Icon(Icons.storage, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Size: ${recording.fileSizeMB} MB'),
              ],
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: fileExists ? () => _exportRecording(recording) : null,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _deleteRecording(recording),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}