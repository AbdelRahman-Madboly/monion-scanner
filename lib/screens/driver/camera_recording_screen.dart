// lib/screens/driver/camera_recording_screen.dart
// Purpose: Camera preview screen for starting recording

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../services/camera_service.dart';
import 'dart:async';

class CameraRecordingScreen extends StatefulWidget {
  final CameraService cameraService;
  final Future<bool> Function() onStartRecording;

  const CameraRecordingScreen({
    super.key,
    required this.cameraService,
    required this.onStartRecording,
  });

  @override
  State<CameraRecordingScreen> createState() => _CameraRecordingScreenState();
}

class _CameraRecordingScreenState extends State<CameraRecordingScreen> {
  bool _isStarting = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // Wait for camera to be fully ready
    _waitForCameraReady();
  }

  Future<void> _waitForCameraReady() async {
    // Wait for camera preview to be fully initialized
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted && widget.cameraService.controller != null) {
      setState(() => _isReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera'),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Start Recording'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Camera Preview (CRITICAL - this creates the surface)
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),

          // Overlay info
          if (!_isReady)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Preparing camera surface...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Start Recording Button
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (_isReady && !_isStarting)
                  ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.fiber_manual_record, size: 32),
                    label: const Text(
                      'Start Recording',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (_isStarting)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Starting recording...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (!_isReady)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Please wait for camera to be ready...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    if (!_isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not ready yet, please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    try {
      print('🎬 CameraRecordingScreen: Starting recording...');
      print('📱 Camera ready: $_isReady');
      print('📷 Controller initialized: ${widget.cameraService.controller?.value.isInitialized}');
      
      // Extra wait to ensure surface is stable
      await Future.delayed(const Duration(milliseconds: 500));

      final success = await widget.onStartRecording();

      if (mounted) {
        if (success) {
          print('✅ CameraRecordingScreen: Recording started successfully');
          Navigator.pop(context, true);
        } else {
          print('❌ CameraRecordingScreen: Recording failed');
          setState(() => _isStarting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start recording'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ CameraRecordingScreen: Exception: $e');
      if (mounted) {
        setState(() => _isStarting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}