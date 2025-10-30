// lib/screens/driver/camera_view_screen.dart
// Purpose: Live preview of both cameras in split-screen mode
// NOTE: Preview only - No recording (Phase 1)

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_card.dart';

class CameraViewScreen extends StatefulWidget {
  const CameraViewScreen({
    super.key,
  });

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  late final player = Player();
  late final controller = VideoController(player);
  // FIXED: Updated to correct IP and password
  final String rtspUrl =
      'rtsp://admin:MyCamStream123@192.168.90.66:554/cam/realmonitor?channel=1&subtype=0';
  
  bool _isLoading = true;
  bool _cameraInitialized = false;
  bool _rtspInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  Future<void> _initializeStreams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Initialize phone camera
    await _initCamera();
    
    // Initialize RTSP stream
    await _initRTSP();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _initCamera() async {
    try {
      final available = await availableCameras();
      cameras = available;
      
      if (cameras != null && cameras!.isNotEmpty) {
        // Find front camera (prefer front, fallback to any available)
        final frontCamera = cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras!.first,
        );
        
        cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _cameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Camera initialization error: $e');
      setState(() {
        _errorMessage = 'Failed to initialize phone camera';
      });
    }
  }

  Future<void> _initRTSP() async {
    try {
      print('🔌 Attempting RTSP connection to: $rtspUrl');
      await player.open(Media(rtspUrl));
      
      if (mounted) {
        setState(() {
          _rtspInitialized = true;
        });
        print('✅ RTSP stream initialized successfully');
      }
    } catch (e) {
      print('❌ RTSP initialization error: $e');
      setState(() {
        _errorMessage = 'Failed to connect to WiFi camera: $e';
      });
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Streams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeStreams,
            tooltip: 'Refresh Streams',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildSplitScreenView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Connecting to cameras...',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Camera IP: 192.168.90.66',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Connection Error',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _initializeStreams,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitScreenView() {
    return Column(
      children: [
        // Connection status bar
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _buildStatusIndicator('WiFi Camera', _rtspInitialized, Icons.wifi),
              const SizedBox(width: AppSpacing.lg),
              _buildStatusIndicator('Phone Camera', _cameraInitialized, Icons.videocam),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Preview Mode',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Top half - WiFi Camera (RTSP)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.greyLight,
                  width: 2,
                ),
              ),
            ),
            child: Stack(
              children: [
                // RTSP Stream
                if (_rtspInitialized)
                  Center(
                    child: Video(
                      controller: controller,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  _buildCameraPlaceholder('WiFi Camera', Icons.wifi_off, AppColors.primary),
                
                // Label overlay
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: _buildCameraLabel(
                    'WiFi Camera',
                    _rtspInitialized,
                    Icons.wifi,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom half - Phone Camera
        Expanded(
          child: Stack(
            children: [
              // Phone Camera Preview
              if (_cameraInitialized && cameraController != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: cameraController!.value.aspectRatio,
                    child: CameraPreview(cameraController!),
                  ),
                )
              else
                _buildCameraPlaceholder('Phone Camera', Icons.videocam_off, AppColors.success),
              
              // Label overlay
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: _buildCameraLabel(
                  'Phone Camera',
                  _cameraInitialized,
                  Icons.videocam,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.success : AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(
          icon,
          color: AppColors.white,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraLabel(String label, bool isActive, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: isActive ? accentColor : AppColors.grey,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? accentColor : AppColors.grey,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.greyDark : AppColors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? accentColor : AppColors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder(String label, IconData icon, Color accentColor) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: CustomCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                style: AppTextStyles.h3.copyWith(color: AppColors.greyDark),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Not Available',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warning),
                ),
                child: const Text(
                  'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}