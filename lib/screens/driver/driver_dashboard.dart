// lib/screens/driver/driver_dashboard.dart
// Purpose: Main dashboard for drivers with full recording support

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:monion_scanner/screens/driver/camera_view_screen.dart';
import 'package:monion_scanner/screens/driver/camera_recording_screen.dart';
import 'package:monion_scanner/screens/driver/manual_scan_management.dart';
import '../../services/database_service.dart';
import '../../services/camera_service.dart';
import '../../services/rtsp_service.dart';
import '../../services/recording_service.dart';
import '../../models/session.dart';
import 'scanner_screen.dart';
import '../login_screen.dart';

class DriverDashboard extends StatefulWidget {
  final String driverName;
  final String busPlate;

  const DriverDashboard({
    super.key,
    required this.driverName,
    required this.busPlate,
  });

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  Session? _activeSession;
  bool _isLoading = false;

  final CameraService _cameraService = CameraService();
  final RtspService _rtspService = RtspService();
  late final RecordingService _recordingService;
  
  bool _cameraInitialized = false;
  bool _rtspInitialized = false;
  
  // Recording state
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
  _recordingService = RecordingService(DatabaseService.instance, _rtspService);
    _checkActiveSession();
    _initializeServices();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _cameraService.dispose();
    _rtspService.dispose();
    _recordingService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      _cameraInitialized = await _cameraService.initializeFrontCamera();
      _rtspInitialized = await _rtspService.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Service initialization error: $e');
    }
  }

  Future<void> _checkActiveSession() async {
    setState(() => _isLoading = true);
    final session = await DatabaseService.instance.getActiveSession();
    if (mounted) {
      setState(() {
        _activeSession = session;
        _isLoading = false;
      });
      
      // If there's an active session, start recording timer
      if (_activeSession != null && _recordingService.isRtspRecording) {
        _startRecordingTimer();
      }
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = _recordingService.rtspRecordingDuration ?? Duration.zero;
        });
      }
    });
  }

  Future<void> _showStartSessionDialog() async {
    String selectedDirection = 'To University';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start New Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Select direction:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: const Text('To University', overflow: TextOverflow.ellipsis),
                    value: 'To University',
                    groupValue: selectedDirection,
                    onChanged: (value) => setDialogState(() => selectedDirection = value ?? 'To University'),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    title: const Text('From University', overflow: TextOverflow.ellipsis),
                    value: 'From University',
                    groupValue: selectedDirection,
                    onChanged: (value) => setDialogState(() => selectedDirection = value ?? 'To University'),
                    dense: true,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildCameraStatus('Front Camera', _cameraInitialized),
                  const SizedBox(height: 8),
                  _buildCameraStatus('WiFi Camera', _rtspInitialized),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf44336).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFf44336)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record, color: Color(0xFFf44336), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'WiFi camera will start recording',
                            style: TextStyle(fontSize: 11, color: Color(0xFFf44336)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Start'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      await _startSession(selectedDirection);
    }
  }

  Widget _buildCameraStatus(String label, bool isReady) {
    return Row(
      children: [
        Icon(
          isReady ? Icons.check_circle : Icons.error,
          color: isReady ? const Color(0xFF4CAF50) : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isReady ? Colors.black : Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          isReady ? 'Ready' : 'Not Ready',
          style: TextStyle(
            fontSize: 11,
            color: isReady ? const Color(0xFF4CAF50) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _startSession(String direction) async {
    setState(() => _isLoading = true);

    try {
      final newSession = Session(
        driverName: widget.driverName,
        busPlate: widget.busPlate,
        direction: direction,
        startTime: DateTime.now(),
        isActive: true,
      );

      final createdSession = await DatabaseService.instance.createSession(newSession);

      // Connect RTSP stream
      if (_rtspInitialized) {
        try {
          final connected = await _rtspService.connect();
          if (connected) {
            // Start RTSP recording
            final recordingPath = await _recordingService.startRtspRecording(createdSession.id!);
            if (recordingPath != null) {
              // Start actual recording with FFmpeg (if available)
              await _rtspService.startRecording(recordingPath);
              _startRecordingTimer();
              _showSuccess('WiFi camera recording started');
            } else {
              _showWarning('WiFi camera recording unavailable');
            }
          } else {
            _showWarning('WiFi camera not connected');
          }
        } catch (e) {
          debugPrint('RTSP recording error: $e');
          _showWarning('WiFi camera error: $e');
        }
      }

      if (mounted) {
        setState(() {
          _activeSession = createdSession;
          _isLoading = false;
        });

        _showSuccess('Session started!');

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _navigateToScanner();
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to start session: $e');
    }
  }

  Future<void> _startManualFrontRecording() async {
    try {
      if (_activeSession == null) {
        _showError('No active session');
        return;
      }

      if (!_cameraInitialized || _cameraService.controller == null) {
        _showError('Camera not ready');
        return;
      }

      // Navigate to camera preview screen to initialize surface
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraRecordingScreen(
            cameraService: _cameraService,
            onStartRecording: () async {
              final started = await _recordingService.startFrontRecording(
                _activeSession!.id!,
                _cameraService.controller!,
              );
              return started != null;
            },
          ),
        ),
      );

      if (result == true && mounted) {
        _showSuccess('Front camera recording started!');
        setState(() {});
      }
    } catch (e) {
      _showError('Recording error: $e');
    }
  }

  Future<void> _stopManualFrontRecording() async {
    try {
      if (_activeSession == null) {
        _showError('No active session');
        return;
      }

      if (_cameraService.controller != null) {
        await _recordingService.stopFrontRecording(
          _activeSession!.id!,
          _cameraService.controller!,
        );
        _showSuccess('Front camera recording saved!');
        setState(() {});
      }
    } catch (e) {
      _showError('Error stopping recording: $e');
    }
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: Text(
          _recordingService.isFrontRecording
              ? 'This will:\n'
                '• Stop front camera recording\n'
                '• Stop WiFi camera recording\n'
                '• End the session\n\n'
                'Make sure all passengers have been scanned out.'
              : 'This will:\n'
                '• Stop WiFi camera recording\n'
                '• End the session\n\n'
                'Make sure all passengers have been scanned out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFf44336)),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirm == true && _activeSession != null) {
      setState(() => _isLoading = true);

      try {
        // Stop front camera recording if active
        if (_recordingService.isFrontRecording && _cameraService.controller != null) {
          await _recordingService.stopFrontRecording(
            _activeSession!.id!,
            _cameraService.controller!,
          );
          _showSuccess('Front camera recording saved');
        }

        // Stop RTSP recording
        if (_recordingService.isRtspRecording) {
          await _rtspService.stopRecording();
          await _recordingService.stopRtspRecording(_activeSession!.id!);
          _showSuccess('WiFi camera recording saved');
        }

        // Disconnect RTSP stream
        if (_rtspService.isConnected) {
          await _rtspService.disconnect();
        }

        // End session in database
        await DatabaseService.instance.endSession(_activeSession!.id!);

        // Stop recording timer
        _recordingTimer?.cancel();

        if (mounted) {
          setState(() {
            _activeSession = null;
            _isLoading = false;
            _recordingDuration = Duration.zero;
          });

          _showSuccess('Session ended successfully!');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Error ending session: $e');
      }
    }
  }

  Future<void> _navigateToScanner() async {
    if (_activeSession != null) {
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScannerScreen(session: _activeSession!),
          ),
        );

        _checkActiveSession();
      }
    }
  }

  Future<void> _navigateToManageScans() async {
    if (_activeSession != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManualScanManagement(session: _activeSession!),
        ),
      );
      _checkActiveSession();
    }
  }

  Future<void> _logout() async {
    if (_activeSession != null) {
      _showError('Please end the active session before logging out');
      return;
    }

    // Stop front camera recording if active
    if (_recordingService.isFrontRecording && _cameraService.controller != null) {
      try {
        await _recordingService.stopFrontRecording(
          _activeSession?.id ?? 0,
          _cameraService.controller!,
        );
        _showSuccess('Front camera recording saved');
      } catch (e) {
        debugPrint('Error stopping front recording on logout: $e');
      }
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: const Color(0xFFf44336)),
      );
    }
  }

  void _showWarning(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: const Color(0xFFFFC107)),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: const Color(0xFF4CAF50)),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannedInCount = _activeSession?.totalScansIn ?? 0;
    final scannedOutCount = _activeSession?.totalScansOut ?? 0;
    final isRecording = _recordingService.isRtspRecording || _recordingService.isFrontRecording;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          // Recording indicator
          if (isRecording)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf44336),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF2196F3),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.driverName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Bus: ${widget.busPlate}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isRecording)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFf44336).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fiber_manual_record,
                                color: Color(0xFFf44336),
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_activeSession != null) ...[
                    const Text('Active Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.circle, color: Color(0xFF4CAF50), size: 6),
                                      SizedBox(width: 4),
                                      Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Text(
                                    _activeSession!.direction,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            _buildStatRow('Started', _formatTime(_activeSession!.startTime), Icons.access_time),
                            const SizedBox(height: 8),
                            _buildStatRow('Duration', _activeSession!.formattedDuration, Icons.timer),
                            const SizedBox(height: 8),
                            _buildStatRow('Scans IN', '$scannedInCount', Icons.login),
                            const SizedBox(height: 8),
                            _buildStatRow('Scans OUT', '$scannedOutCount', Icons.logout),
                            if (_recordingService.isRtspRecording) ...[
                              const SizedBox(height: 8),
                              _buildStatRow(
                                'Recording',
                                _formatDuration(_recordingDuration),
                                Icons.fiber_manual_record,
                                color: const Color(0xFFf44336),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildGridActionButton(
                            icon: Icons.qr_code_scanner,
                            label: 'Scan',
                            color: const Color(0xFF2196F3),
                            onPressed: _navigateToScanner,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGridActionButton(
                            icon: Icons.list_alt,
                            label: 'Manage',
                            color: const Color(0xFF9C27B0),
                            onPressed: _navigateToManageScans,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGridActionButton(
                            icon: Icons.videocam,
                            label: 'Camera',
                            color: const Color(0xFF4CAF50),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => const CameraViewScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGridActionButton(
                            icon: _recordingService.isFrontRecording
                                ? Icons.stop_circle
                                : Icons.fiber_manual_record,
                            label: _recordingService.isFrontRecording
                                ? 'Stop Recording'
                                : 'Start Recording',
                            color: _recordingService.isFrontRecording
                                ? const Color(0xFFf44336)
                                : const Color(0xFFFF9800),
                            onPressed: _recordingService.isFrontRecording
                                ? _stopManualFrontRecording
                                : _startManualFrontRecording,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGridActionButton(
                            icon: Icons.stop_circle,
                            label: 'End Session',
                            color: const Color(0xFFf44336),
                            onPressed: _endSession,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Column(
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.qr_code_scanner,
                            size: 40,
                            color: const Color(0xFF2196F3).withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No Active Session',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Start a new session to begin scanning',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: double.infinity,
                                  maxWidth: double.infinity,
                                  minHeight: 50,
                                  maxHeight: 50,
                                ),
                                child: ElevatedButton(
                                  onPressed: _showStartSessionDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.play_arrow, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Start Session',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: double.infinity,
                                  maxWidth: double.infinity,
                                  minHeight: 50,
                                  maxHeight: 50,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (ctx) => const CameraViewScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.videocam, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'View Camera',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 11, color: color ?? Colors.grey)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildGridActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}