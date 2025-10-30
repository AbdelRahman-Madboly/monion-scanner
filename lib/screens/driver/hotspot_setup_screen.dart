// lib/screens/driver/hotspot_setup_screen.dart
// Purpose: Setup hotspot and connect IMOU Ranger Pro camera

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';
import '../../services/hotspot_manager.dart';

class HotspotSetupScreen extends StatefulWidget {
  const HotspotSetupScreen({super.key});

  @override
  State<HotspotSetupScreen> createState() => _HotspotSetupScreenState();
}

class _HotspotSetupScreenState extends State<HotspotSetupScreen> {
  final HotspotManager _hotspotManager = HotspotManager();
  
  bool _isHotspotSupported = false;
  bool _isHotspotEnabled = false;
  bool _isLoading = true;
  bool _isProcessing = false;
  int _connectedDevices = 0;
  String _ssid = HotspotManager.defaultSSID;
  String _password = HotspotManager.defaultPassword;
  
  // IMOU Ranger Pro default settings
  final String _cameraDefaultIP = '192.168.90.66'; // Your camera's actual IP
  final String _rtspPort = '554';
  final String _cameraUsername = 'admin';
  final String _cameraPassword = 'admin';

  @override
  void initState() {
    super.initState();
    _checkHotspotStatus();
  }

  Future<void> _checkHotspotStatus() async {
    setState(() => _isLoading = true);
    
    final isSupported = await _hotspotManager.isHotspotSupported();
    final isEnabled = await _hotspotManager.isHotspotEnabled();
    
    if (isEnabled) {
      final config = await _hotspotManager.getHotspotConfig();
      final devicesCount = await _hotspotManager.getConnectedDevicesCount();
      
      if (config != null) {
        _ssid = config['ssid']!;
        _password = config['password']!;
      }
      _connectedDevices = devicesCount;
    }
    
    setState(() {
      _isHotspotSupported = isSupported;
      _isHotspotEnabled = isEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleHotspot() async {
    setState(() => _isProcessing = true);
    
    try {
      if (_isHotspotEnabled) {
        final success = await _hotspotManager.disableHotspot();
        if (success) {
          _showMessage('Hotspot disabled', isError: false);
          setState(() => _isHotspotEnabled = false);
        } else {
          _showMessage('Failed to disable hotspot', isError: true);
        }
      } else {
        final success = await _hotspotManager.enableHotspot(
          ssid: _ssid,
          password: _password,
        );
        if (success) {
          _showMessage('Hotspot enabled: $_ssid', isError: false);
          setState(() => _isHotspotEnabled = true);
          _startDeviceCheck();
        } else {
          _showMessage('Failed to enable hotspot', isError: true);
        }
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _startDeviceCheck() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isHotspotEnabled) {
        _updateConnectedDevices();
        _startDeviceCheck();
      }
    });
  }

  Future<void> _updateConnectedDevices() async {
    final count = await _hotspotManager.getConnectedDevicesCount();
    if (mounted) {
      setState(() => _connectedDevices = count);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showMessage('$label copied to clipboard', isError: false);
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  String get _rtspUrl {
    return 'rtsp://$_cameraUsername:$_cameraPassword@$_cameraDefaultIP:$_rtspPort/cam/realmonitor?channel=1&subtype=0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Hotspot Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkHotspotStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isHotspotSupported
              ? _buildNotSupportedView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildHotspotControls(),
                      if (_isHotspotEnabled) ...[
                        const SizedBox(height: 16),
                        _buildConnectionInfo(),
                        const SizedBox(height: 16),
                        _buildCameraInstructions(),
                        const SizedBox(height: 16),
                        _buildRTSPInfo(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildNotSupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: AppColors.warning,
            ),
            const SizedBox(height: 24),
            const Text(
              'Hotspot Not Supported',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your device does not support WiFi hotspot functionality.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (_isHotspotEnabled ? AppColors.success : AppColors.grey)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isHotspotEnabled ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                color: _isHotspotEnabled ? AppColors.success : AppColors.grey,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isHotspotEnabled ? 'Hotspot Active' : 'Hotspot Inactive',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isHotspotEnabled
                        ? '$_connectedDevices device(s) connected'
                        : 'Enable to connect camera',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotspotControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hotspot Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Network Name (SSID)', _ssid, Icons.wifi),
            const SizedBox(height: 12),
            _buildInfoRow('Password', _password, Icons.lock, canCopy: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _toggleHotspot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isHotspotEnabled
                      ? AppColors.error
                      : AppColors.success,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isHotspotEnabled
                                ? Icons.stop
                                : Icons.play_arrow,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isHotspotEnabled
                                ? 'Stop Hotspot'
                                : 'Start Hotspot',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInfo() {
    return Card(
      color: AppColors.success.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                const Text(
                  'Hotspot Ready',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your phone is now broadcasting a WiFi network. Connect your IMOU Ranger Pro camera to this network.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.videocam, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Camera Connection Steps',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStep(1, 'Open IMOU Life app'),
            _buildStep(2, 'Go to camera Settings → Network Settings'),
            _buildStep(3, 'Connect camera to WiFi: "$_ssid"'),
            _buildStep(4, 'Enter password: "$_password"'),
            _buildStep(5, 'Wait for camera LED to turn solid'),
            _buildStep(6, 'Camera will get IP: $_cameraDefaultIP'),
          ],
        ),
      ),
    );
  }

  Widget _buildRTSPInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings_input_antenna, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'RTSP Stream URL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Use this URL in the camera stream:',
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _rtspUrl,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyToClipboard(_rtspUrl, 'RTSP URL'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {bool canCopy = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (canCopy)
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => _copyToClipboard(value, label),
          ),
      ],
    );
  }
}