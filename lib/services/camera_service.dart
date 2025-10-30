// lib/services/camera_service.dart
// Purpose: Manages front camera (phone camera) operations and recording

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  String? _error;
  bool _isRecording = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isRecording => _isRecording;
  List<CameraDescription> get cameras => _cameras;

  /// Initialize front camera
  Future<bool> initializeFrontCamera() async {
    try {
      _error = null;
      
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        _error = 'No cameras found on this device';
        notifyListeners();
        return false;
      }

      // Find front camera
      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      // Initialize controller with video recording enabled
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: true, // Enable audio for video recording
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();
      
      print('✅ Front camera initialized successfully');
      return true;
    } catch (e) {
      _error = 'Failed to initialize camera: $e';
      _isInitialized = false;
      notifyListeners();
      print('❌ Camera initialization error: $e');
      return false;
    }
  }

  /// Start video recording
  Future<bool> startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('❌ Camera not initialized');
      return false;
    }

    if (_isRecording) {
      print('⚠️ Already recording');
      return false;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      notifyListeners();
      print('✅ Video recording started');
      return true;
    } catch (e) {
      print('❌ Error starting video recording: $e');
      _error = 'Failed to start recording: $e';
      notifyListeners();
      return false;
    }
  }

  /// Stop video recording and return the file path
  Future<String?> stopVideoRecording() async {
    if (_controller == null || !_isRecording) {
      print('⚠️ Not currently recording');
      return null;
    }

    try {
      final xFile = await _controller!.stopVideoRecording();
      _isRecording = false;
      notifyListeners();
      print('✅ Video recording stopped: ${xFile.path}');
      return xFile.path;
    } catch (e) {
      print('❌ Error stopping video recording: $e');
      _error = 'Failed to stop recording: $e';
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  /// Check if camera is recording
  bool get isCurrentlyRecording => _isRecording && _controller != null;

  /// Pause video recording (if supported)
  Future<void> pauseVideoRecording() async {
    if (_controller == null || !_isRecording) return;
    
    try {
      await _controller!.pauseVideoRecording();
      print('⏸️ Video recording paused');
    } catch (e) {
      print('❌ Error pausing recording: $e');
    }
  }

  /// Resume video recording (if supported)
  Future<void> resumeVideoRecording() async {
    if (_controller == null || !_isRecording) return;
    
    try {
      await _controller!.resumeVideoRecording();
      print('▶️ Video recording resumed');
    } catch (e) {
      print('❌ Error resuming recording: $e');
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_cameras.length < 2) {
      print('⚠️ Only one camera available');
      return;
    }

    try {
      final currentLensDirection = _controller!.description.lensDirection;
      final newCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection != currentLensDirection,
      );

      await dispose();
      
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();
      
      print('✅ Camera switched successfully');
    } catch (e) {
      print('❌ Error switching camera: $e');
      _error = 'Failed to switch camera: $e';
      notifyListeners();
    }
  }

  /// Take a picture (if needed for Phase 3)
  Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final xFile = await _controller!.takePicture();
      print('✅ Picture taken: ${xFile.path}');
      return xFile.path;
    } catch (e) {
      print('❌ Error taking picture: $e');
      return null;
    }
  }

  /// Dispose camera resources
  @override
  Future<void> dispose() async {
    if (_isRecording) {
      try {
        await stopVideoRecording();
      } catch (e) {
        print('❌ Error stopping recording during dispose: $e');
      }
    }
    
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isRecording = false;
    super.dispose();
    print('🗑️ Camera service disposed');
  }

  /// Reinitialize camera (useful for error recovery)
  Future<bool> reinitialize() async {
    await dispose();
    return await initializeFrontCamera();
  }
}