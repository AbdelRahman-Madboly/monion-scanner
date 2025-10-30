// lib/screens/admin/video_player_screen.dart
// Purpose: Full-screen video player with controls
// STATUS: PHASE 2 - NOT USED YET (Recording disabled)
// TODO: Uncomment and add packages (video_player, chewie) in Phase 2

/*
============================================================================
PHASE 2 - FULL VIDEO PLAYER CODE (COMMENTED OUT)
============================================================================
Uncomment this section when ready to implement recording in Phase 2

Required packages in pubspec.yaml:
  video_player: ^2.8.1
  chewie: ^1.7.4

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';
import '../../utils/constants.dart';
import '../../models/recording.dart';
import 'package:intl/intl.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Recording recording;

  const VideoPlayerScreen({
    super.key,
    required this.recording,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.recording.filePath);
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video file not found';
        });
        return;
      }

      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: AppColors.greyLight,
          bufferedColor: AppColors.grey,
        ),
      );

      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${widget.recording.cameraType} Camera'),
      ),
      body: _hasError
          ? _buildErrorState()
          : !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : const CircularProgressIndicator(),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 80),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Unknown error',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

============================================================================
END OF PHASE 2 CODE
============================================================================
*/

// CURRENT PHASE 1 - SIMPLE PLACEHOLDER
import 'package:flutter/material.dart';
import '../../models/recording.dart';
import '../../utils/constants.dart';

class VideoPlayerScreen extends StatelessWidget {
  final Recording recording;

  const VideoPlayerScreen({
    super.key,
    required this.recording,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Video Player'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_outline,
                size: 100,
                color: AppColors.white,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Video Player',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: const Text(
                  'PHASE 2 - Coming Soon',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Video playback will be available\nwhen recording is implemented',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.greyLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.videocam, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Recording Details',
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Camera:', recording.cameraType),
                    _buildInfoRow('Duration:', recording.formattedDuration),
                    _buildInfoRow('Size:', '${recording.fileSizeMB} MB'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.greyLight,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}