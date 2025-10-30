// lib/screens/driver/scanner_screen.dart
// Purpose: Fast barcode scanner with IN/OUT state management - OVERFLOW FIXED

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/session.dart';
import '../../models/scan.dart';

class ScannerScreen extends StatefulWidget {
  final Session session;

  const ScannerScreen({
    super.key,
    required this.session,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _scannerController;
  String _scanMode = 'IN';
  List<Scan> _recentScans = [];
  bool _isProcessing = false;
  Session? _currentSession;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _initializeScanner();
    _loadRecentScans();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  Future<void> _loadRecentScans() async {
    final scans = await DatabaseService.instance.getSessionScans(widget.session.id!);
    final updatedSession = await DatabaseService.instance.getSession(widget.session.id!);

    if (mounted) {
      setState(() {
        _recentScans = scans;
        if (updatedSession != null) {
          _currentSession = updatedSession;
        }
      });
    }
  }

  void _toggleScanMode() {
    setState(() {
      _scanMode = _scanMode == 'IN' ? 'OUT' : 'IN';
    });
  }

  void _toggleTorch() {
    _scannerController?.toggleTorch();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    await _scannerController?.stop();
    await _processBarcode(code);
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processBarcode(String code) async {
    if (code.length != 14) {
      _showInvalidDialog(code, 'Invalid National ID - Must be 14 digits');
      return;
    }

    if (!RegExp(r'^\d+$').hasMatch(code)) {
      _showInvalidDialog(code, 'Invalid National ID - Must contain only numbers');
      return;
    }

    final isCurrentlyIn = await DatabaseService.instance.isStudentScannedIn(
      widget.session.id!,
      code,
    );

    if (_scanMode == 'IN' && isCurrentlyIn) {
      _showAlreadyScannedDialog(code, 'Student is already scanned IN');
      return;
    }

    if (_scanMode == 'OUT' && !isCurrentlyIn) {
      _showAlreadyScannedDialog(code, 'Student is not scanned IN yet');
      return;
    }

    final scan = Scan(
      sessionId: widget.session.id!,
      nationalId: code,
      scanType: _scanMode,
      scanInTime: DateTime.now(),
      scanOutTime: _scanMode == 'OUT' ? DateTime.now() : null,
    );

    try {
      await DatabaseService.instance.createOrUpdateScan(scan);
      await _loadRecentScans();
      _showSuccessDialog(code);
    } catch (e) {
      _showInvalidDialog(code, 'Failed to save scan: $e');
    }
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan Successful!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _scanMode == 'IN'
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                        : const Color(0xFFf44336).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID: $code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _scanMode == 'IN'
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFf44336),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _scanMode == 'IN'
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                        : const Color(0xFFf44336).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _scanMode,
                    style: TextStyle(
                      color: _scanMode == 'IN'
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFf44336),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _scannerController?.start();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Continue Scanning',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInvalidDialog(String code, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFf44336).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error,
                    color: Color(0xFFf44336),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Invalid Barcode',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf44336).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFf44336),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _scannerController?.start();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf44336),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlreadyScannedDialog(String code, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Color(0xFFFFC107),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Already Scanned',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID: $code',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFC107),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _scannerController?.start();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner - ${_currentSession?.direction ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _toggleTorch,
            tooltip: 'Toggle Flashlight',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetected,
                ),
                CustomPaint(
                  painter: ScannerOverlayPainter(),
                  child: Container(),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Scan Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _scanMode == 'IN'
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                                : const Color(0xFFf44336).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _scanMode == 'IN'
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFf44336),
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _toggleScanMode,
                              borderRadius: BorderRadius.circular(8),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _scanMode == 'IN' ? Icons.login : Icons.logout,
                                      color: _scanMode == 'IN'
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFf44336),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _scanMode,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _scanMode == 'IN'
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFf44336),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Scanned IN',
                          '${_currentSession?.totalScansIn ?? 0}',
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Scanned OUT',
                          '${_currentSession?.totalScansOut ?? 0}',
                          const Color(0xFFf44336),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Recent Scans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Expanded(
                    child: _recentScans.isEmpty
                        ? const Center(child: Text('No scans yet', style: TextStyle(fontSize: 12)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _recentScans.length > 10 ? 10 : _recentScans.length,
                            itemBuilder: (context, index) {
                              final scan = _recentScans[index];
                              return _buildRecentScanItem(scan);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRecentScanItem(Scan scan) {
    final time = DateFormat('HH:mm').format(scan.timestamp);
    final isIn = scan.scanType == 'IN';

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isIn ? const Color(0xFF4CAF50) : const Color(0xFFf44336),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isIn
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                  : const Color(0xFFf44336).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              scan.scanType,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isIn ? const Color(0xFF4CAF50) : const Color(0xFFf44336),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            scan.nationalId.substring(0, 8),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanWidth = size.width * 0.8;
    final scanHeight = size.height * 0.5;
    final left = (size.width - scanWidth) / 2;
    final top = (size.height - scanHeight) / 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, scanHeight), paint);
    canvas.drawRect(Rect.fromLTWH(left + scanWidth, top, left, scanHeight), paint);
    canvas.drawRect(Rect.fromLTWH(0, top + scanHeight, size.width, top), paint);

    final borderPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanWidth, scanHeight),
        const Radius.circular(12),
      ),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    const cornerLength = 30.0;

    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);
    canvas.drawLine(Offset(left + scanWidth - cornerLength, top), Offset(left + scanWidth, top), cornerPaint);
    canvas.drawLine(Offset(left + scanWidth, top), Offset(left + scanWidth, top + cornerLength), cornerPaint);
    canvas.drawLine(Offset(left, top + scanHeight - cornerLength), Offset(left, top + scanHeight), cornerPaint);
    canvas.drawLine(Offset(left, top + scanHeight), Offset(left + cornerLength, top + scanHeight), cornerPaint);
    canvas.drawLine(Offset(left + scanWidth, top + scanHeight - cornerLength), Offset(left + scanWidth, top + scanHeight), cornerPaint);
    canvas.drawLine(Offset(left + scanWidth - cornerLength, top + scanHeight), Offset(left + scanWidth, top + scanHeight), cornerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}