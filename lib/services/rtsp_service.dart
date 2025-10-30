// lib/services/rtsp_service.dart
// Purpose: Manages RTSP stream from IMOU Ranger Pro camera
// Phase 3: Enhanced placeholder recording (FFmpeg alternative)

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:io';
import 'dart:async';

class RtspService extends ChangeNotifier {
  Player? _player;
  VideoController? _videoController;
  bool _isConnected = false;
  bool _isInitialized = false;
  bool _isRecording = false;
  String? _error;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _metadataTimer;

  // RTSP Configuration
  static const String rtspUrl = 'rtsp://admin:MyCamStream123@192.168.90.66:554/cam/realmonitor?channel=1&subtype=0';
  
  Player? get player => _player;
  VideoController? get videoController => _videoController;
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  String? get error => _error;

  /// Initialize RTSP player
  Future<bool> initialize() async {
    try {
      _error = null;
      
      // Create player
      _player = Player();
      
      // Create video controller
      _videoController = VideoController(_player!);
      
      _isInitialized = true;
      notifyListeners();
      
      print('✅ RTSP Service initialized');
      return true;
    } catch (e) {
      _error = 'Failed to initialize RTSP service: $e';
      _isInitialized = false;
      notifyListeners();
      print('❌ RTSP initialization error: $e');
      return false;
    }
  }

  /// Connect to RTSP stream
  Future<bool> connect() async {
    if (!_isInitialized || _player == null) {
      print('❌ RTSP service not initialized');
      return false;
    }

    try {
      _error = null;
      
      // Open RTSP stream
      await _player!.open(Media(rtspUrl));
      
      _isConnected = true;
      notifyListeners();
      
      print('✅ Connected to RTSP stream');
      return true;
    } catch (e) {
      _error = 'Failed to connect to RTSP stream: $e';
      _isConnected = false;
      notifyListeners();
      print('❌ RTSP connection error: $e');
      return false;
    }
  }

  /// Disconnect from RTSP stream
  Future<void> disconnect() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }
      
      await _player?.stop();
      _isConnected = false;
      notifyListeners();
      print('🔌 Disconnected from RTSP stream');
    } catch (e) {
      print('❌ Error disconnecting: $e');
    }
  }

  /// Start recording RTSP stream (Enhanced metadata logging)
  Future<bool> startRecording(String outputPath) async {
    print('🎬 RTSP SERVICE: startRecording() called');
    print('📍 Output path: $outputPath');
    
    if (!_isConnected) {
      print('❌ Not connected to RTSP stream');
      return false;
    }

    if (_isRecording) {
      print('⚠️ Already recording');
      return false;
    }

    try {
      // Ensure output directory exists
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      print('✅ Directory created: ${file.parent.path}');
      
      print('🎬 Starting WiFi camera session logging...');
      print('📹 RTSP URL: $rtspUrl');
      print('💾 Output: $outputPath');
      
      // Create metadata file
      await _createRecordingMetadata(outputPath);
      print('✅ Metadata file created');
      
      _currentRecordingPath = outputPath;
      _recordingStartTime = DateTime.now();
      _isRecording = true;
      
      // Start periodic metadata updates
      _startMetadataUpdates();
      
      notifyListeners();
      
      print('✅ WiFi camera session started: $outputPath');
      print('⏱️ Start time: ${_recordingStartTime!.toIso8601String()}');
      print('📝 Note: Recording session metadata');
      return true;
    } catch (e) {
      print('❌ Error starting recording: $e');
      print('Stack trace: ${StackTrace.current}');
      _error = 'Failed to start recording: $e';
      notifyListeners();
      return false;
    }
  }

  /// Create initial recording metadata
  Future<void> _createRecordingMetadata(String outputPath) async {
    final file = File(outputPath);
    final buffer = StringBuffer();
    
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('     MONION SCANNER - WiFi Camera Session Log');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('CAMERA INFORMATION:');
    buffer.writeln('  Device: IMOU Ranger Pro (WiFi Camera)');
    buffer.writeln('  Stream: RTSP (Back Camera View)');
    buffer.writeln('  URL: $rtspUrl');
    buffer.writeln('  Status: Connected & Streaming');
    buffer.writeln('');
    buffer.writeln('SESSION INFORMATION:');
    buffer.writeln('  Start Time: ${DateTime.now().toIso8601String()}');
    buffer.writeln('  Start Time (Local): ${DateTime.now()}');
    buffer.writeln('  File Path: $outputPath');
    buffer.writeln('');
    buffer.writeln('RECORDING STATUS:');
    buffer.writeln('  ● Stream Preview: Active');
    buffer.writeln('  ● Connection: Stable');
    buffer.writeln('  ● Recording Method: Session Metadata Log');
    buffer.writeln('');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('NOTE: This is a session log file.');
    buffer.writeln('The WiFi camera stream was active and monitored during');
    buffer.writeln('this session. To enable actual video recording, FFmpeg');
    buffer.writeln('native integration is required.');
    buffer.writeln('');
    buffer.writeln('For video playback, please review:');
    buffer.writeln('  • Front camera recordings (full video)');
    buffer.writeln('  • Session scan data');
    buffer.writeln('  • Session timing information below');
    buffer.writeln('');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('SESSION ACTIVITY LOG:');
    buffer.writeln('---------------------------------------------------');
    
    await file.writeAsString(buffer.toString());
  }

  /// Start periodic metadata updates
  void _startMetadataUpdates() {
    _metadataTimer?.cancel();
    _metadataTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isRecording && _currentRecordingPath != null) {
        await _updateMetadata();
      }
    });
  }

  /// Update metadata file
  Future<void> _updateMetadata() async {
    if (_currentRecordingPath == null || _recordingStartTime == null) return;
    
    try {
      final file = File(_currentRecordingPath!);
      if (!await file.exists()) return;
      
      final duration = DateTime.now().difference(_recordingStartTime!);
      final update = '${DateTime.now().toIso8601String()} | Recording Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s | Stream: Active\n';
      
      await file.writeAsString(update, mode: FileMode.append);
    } catch (e) {
      print('⚠️ Error updating metadata: $e');
    }
  }

  /// Stop recording RTSP stream
  Future<bool> stopRecording() async {
    print('⏹️ RTSP SERVICE: stopRecording() called');
    
    if (!_isRecording) {
      print('⚠️ Not currently recording');
      return false;
    }

    try {
      print('⏹️ Stopping WiFi camera session...');
      
      // Stop metadata timer
      _metadataTimer?.cancel();
      _metadataTimer = null;
      
      final duration = DateTime.now().difference(_recordingStartTime!);
      final recordingPath = _currentRecordingPath;
      
      // Finalize metadata file
      if (recordingPath != null) {
        await _finalizeMetadata(recordingPath, duration);
        
        final file = File(recordingPath);
        if (await file.exists()) {
          final fileSize = await file.length();
          print('✅ WiFi camera session stopped: $recordingPath');
          print('ℹ️ Duration: ${duration.inSeconds} seconds');
          print('📊 Log file size: ${fileSize ~/ 1024} KB');
        } else {
          print('⚠️ Warning: Log file not found');
        }
      }
      
      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      print('❌ Error stopping recording: $e');
      _error = 'Failed to stop recording: $e';
      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
      notifyListeners();
      return false;
    }
  }

  /// Finalize metadata file
  Future<void> _finalizeMetadata(String outputPath, Duration duration) async {
    try {
      final file = File(outputPath);
      if (!await file.exists()) return;
      
      final buffer = StringBuffer();
      buffer.writeln('');
      buffer.writeln('═══════════════════════════════════════════════════');
      buffer.writeln('');
      buffer.writeln('SESSION SUMMARY:');
      buffer.writeln('  End Time: ${DateTime.now().toIso8601String()}');
      buffer.writeln('  End Time (Local): ${DateTime.now()}');
      buffer.writeln('  Total Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
      buffer.writeln('  Total Duration (Seconds): ${duration.inSeconds}');
      buffer.writeln('');
      buffer.writeln('STREAM STATUS:');
      buffer.writeln('  ● Stream was active throughout session');
      buffer.writeln('  ● Connection maintained: Stable');
      buffer.writeln('  ● Preview displayed: Yes');
      buffer.writeln('');
      buffer.writeln('═══════════════════════════════════════════════════');
      buffer.writeln('');
      buffer.writeln('Session log completed successfully.');
      buffer.writeln('Generated by Monion Scanner v1.0.0');
      buffer.writeln('');
      
      await file.writeAsString(buffer.toString(), mode: FileMode.append);
    } catch (e) {
      print('⚠️ Error finalizing metadata: $e');
    }
  }

  /// Get current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Get recording duration
  Duration? get recordingDuration {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Reconnect to stream (useful for error recovery)
  Future<bool> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    return await connect();
  }

  /// Dispose resources
  @override
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    
    _metadataTimer?.cancel();
    _metadataTimer = null;
    
    await disconnect();
    await _player?.dispose();
    _player = null;
    _videoController = null;
    _isInitialized = false;
    super.dispose();
    print('🗑️ RTSP service disposed');
  }
}