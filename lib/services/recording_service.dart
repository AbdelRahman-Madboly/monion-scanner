import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import '../models/recording.dart';
import 'database_service.dart';
import 'rtsp_service.dart';

/// Central service to manage video recordings from both cameras
class RecordingService {
  final DatabaseService _databaseService;
  final RtspService? _rtspService;
  
  // Recording state
  String? _currentRtspRecordingPath;
  String? _currentFrontRecordingPath;
  DateTime? _rtspRecordingStartTime;
  DateTime? _frontRecordingStartTime;

  RecordingService(this._databaseService, [this._rtspService]);

  /// Get the recordings directory
  Future<Directory> getRecordingsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/recordings');
    
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    
    return recordingsDir;
  }

  /// Generate filename for recording
  String generateFilename(String cameraType, int sessionId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${cameraType}_${sessionId}_$timestamp.mp4';
  }

  /// Start RTSP recording
  Future<String?> startRtspRecording(int sessionId) async {
    print('🔵 RECORDING SERVICE: startRtspRecording() called');
    print('🔵 Session ID: $sessionId');
    print('🔵 RTSP Service available: ${_rtspService != null}');
    print('🔵 RTSP Service connected: ${_rtspService?.isConnected ?? false}');
    
    try {
      final recordingsDir = await getRecordingsDirectory();
      final filename = generateFilename('WIFI', sessionId);
      final filePath = '${recordingsDir.path}/$filename';
      
      print('🔵 Generated file path: $filePath');
      
      // CRITICAL: Actually call the RTSP service to start recording
      if (_rtspService != null && _rtspService!.isConnected) {
        print('🔵 Calling rtsp_service.startRecording()...');
        final started = await _rtspService!.startRecording(filePath);
        print('🔵 RTSP service returned: $started');
        
        if (!started) {
          print('❌ RTSP service failed to start recording');
          return null;
        }
      } else {
        print('⚠️ RTSP service not available or not connected');
        return null;
      }
      
      _currentRtspRecordingPath = filePath;
      _rtspRecordingStartTime = DateTime.now();
      
      print('✅ RTSP Recording path registered: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Error starting RTSP recording: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Stop RTSP recording and save to database
  Future<Recording?> stopRtspRecording(int sessionId) async {
    print('🔵 RECORDING SERVICE: stopRtspRecording() called');
    
    if (_currentRtspRecordingPath == null || _rtspRecordingStartTime == null) {
      print('⚠️ No active RTSP recording to stop');
      return null;
    }

    try {
      // CRITICAL: Actually call the RTSP service to stop recording
      if (_rtspService != null && _rtspService!.isRecording) {
        print('🔵 Calling rtsp_service.stopRecording()...');
        await _rtspService!.stopRecording();
      }
      
      final file = File(_currentRtspRecordingPath!);
      final duration = DateTime.now().difference(_rtspRecordingStartTime!);
      
      // Get file size
      final fileSize = await file.exists() ? await file.length() : 0;
      
      print('📊 RTSP file exists: ${await file.exists()}');
      print('📊 RTSP file size: $fileSize bytes (${fileSize ~/ 1024} KB)');
      
      // Create recording model
      final recording = Recording(
        sessionId: sessionId,
        cameraType: 'WIFI',
        filePath: _currentRtspRecordingPath!,
        fileSize: fileSize,
        duration: duration.inSeconds,
        startTime: _rtspRecordingStartTime!,
        endTime: DateTime.now(),
        status: 'COMPLETED',
      );

      // Save to database
      final recordingId = await _databaseService.insertRecording(recording);
      print('✅ RTSP Recording saved to DB: ID $recordingId, Duration: ${duration.inSeconds}s, Size: ${fileSize ~/ 1024}KB');

      // Reset state
      _currentRtspRecordingPath = null;
      _rtspRecordingStartTime = null;

      return recording.copyWith(id: recordingId);
    } catch (e) {
      print('❌ Error stopping RTSP recording: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Start front camera recording
  Future<String?> startFrontRecording(int sessionId, CameraController controller) async {
    try {
      // Validate controller
      if (!controller.value.isInitialized) {
        print('❌ Camera controller not initialized');
        throw Exception('Camera not initialized');
      }

      // Check if already recording
      if (controller.value.isRecordingVideo) {
        print('⚠️ Camera is already recording');
        throw Exception('Already recording');
      }

      final recordingsDir = await getRecordingsDirectory();
      final filename = generateFilename('FRONT', sessionId);
      final filePath = '${recordingsDir.path}/$filename';
      
      print('🎬 Starting front camera recording...');
      print('📱 Controller initialized: ${controller.value.isInitialized}');
      print('📷 Preview size: ${controller.value.previewSize}');
      
      // Start recording with camera controller
      await controller.startVideoRecording();
      
      _currentFrontRecordingPath = filePath;
      _frontRecordingStartTime = DateTime.now();
      
      print('✅ Front Camera Recording started: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Error starting front camera recording: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Stop front camera recording and save to database
  Future<Recording?> stopFrontRecording(int sessionId, CameraController controller) async {
    if (_currentFrontRecordingPath == null || _frontRecordingStartTime == null) {
      print('⚠️ No active front camera recording to stop');
      return null;
    }

    try {
      // Validate controller
      if (!controller.value.isInitialized) {
        print('❌ Camera controller not initialized');
        throw Exception('Camera not initialized');
      }

      // Check if recording
      if (!controller.value.isRecordingVideo) {
        print('⚠️ Camera is not recording');
        throw Exception('Not recording');
      }

      print('⏹️ Stopping front camera recording...');
      
      // Stop recording and get the file
      final xFile = await controller.stopVideoRecording();
      final duration = DateTime.now().difference(_frontRecordingStartTime!);
      
      print('✅ Recording stopped, file at: ${xFile.path}');
      
      // Move file to our recordings directory
      final recordingsDir = await getRecordingsDirectory();
      final filename = _currentFrontRecordingPath!.split('/').last;
      final finalPath = '${recordingsDir.path}/$filename';
      
      final originalFile = File(xFile.path);
      
      // Check if original file exists
      if (!await originalFile.exists()) {
        print('❌ Original recording file not found: ${xFile.path}');
        throw Exception('Recording file not found');
      }
      
      print('📁 Copying to: $finalPath');
      await originalFile.copy(finalPath);
      
      print('🗑️ Deleting original: ${xFile.path}');
      await originalFile.delete();
      
      final file = File(finalPath);
      final fileSize = await file.length();
      
      print('📊 Final file size: ${fileSize ~/ 1024} KB');
      
      // Create recording model
      final recording = Recording(
        sessionId: sessionId,
        cameraType: 'FRONT',
        filePath: finalPath,
        fileSize: fileSize,
        duration: duration.inSeconds,
        startTime: _frontRecordingStartTime!,
        endTime: DateTime.now(),
        status: 'COMPLETED',
      );

      // Save to database
      final recordingId = await _databaseService.insertRecording(recording);
      print('✅ Front Camera Recording saved: ID $recordingId, Duration: ${duration.inSeconds}s, Size: ${fileSize ~/ 1024}KB');

      // Reset state
      _currentFrontRecordingPath = null;
      _frontRecordingStartTime = null;

      return recording.copyWith(id: recordingId);
    } catch (e) {
      print('❌ Error stopping front camera recording: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Reset state even on error
      _currentFrontRecordingPath = null;
      _frontRecordingStartTime = null;
      
      rethrow;
    }
  }

  /// Check if RTSP is currently recording
  bool get isRtspRecording => _currentRtspRecordingPath != null;

  /// Check if front camera is currently recording
  bool get isFrontRecording => _currentFrontRecordingPath != null;

  /// Get current RTSP recording duration
  Duration? get rtspRecordingDuration {
    if (_rtspRecordingStartTime == null) return null;
    return DateTime.now().difference(_rtspRecordingStartTime!);
  }

  /// Get current front recording duration
  Duration? get frontRecordingDuration {
    if (_frontRecordingStartTime == null) return null;
    return DateTime.now().difference(_frontRecordingStartTime!);
  }

  /// Clean up resources
  void dispose() {
    _currentRtspRecordingPath = null;
    _currentFrontRecordingPath = null;
    _rtspRecordingStartTime = null;
    _frontRecordingStartTime = null;
  }
}