// lib/services/export_service.dart
// Purpose: Handle CSV and PDF export of session data

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/session.dart';
import '../models/scan.dart';
import '../utils/constants.dart';
import 'database_service.dart';

class ExportService {
  // Request storage permission
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), storage permission works differently
      // For now, we'll use the Downloads directory which doesn't need special permission
      return true;
    }
    
    // Request storage permission for older Android versions
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    
    return status.isGranted;
  }

  // Get Downloads directory
  static Future<Directory> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Use the standard Android Downloads directory
      // This works on all Android versions and is accessible via file manager
      final directory = Directory('/storage/emulated/0/Download');
      
      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          // If we can't create in Download, fallback to app directory
          final externalDir = await getExternalStorageDirectory();
          return externalDir!;
        }
      }
      
      return directory;
    } else {
      // For iOS, use app documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  // ==================== CSV EXPORT ====================

  // Export single session to CSV
  static Future<String?> exportSessionToCSV(Session session) async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get all scans for this session
      final scans = await DatabaseService.instance.getSessionScans(session.id!);

      // Prepare CSV data
      List<List<dynamic>> rows = [];

      // Header section
      rows.add(['MONION - Session Report']);
      rows.add(['Generated:', DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())]);
      rows.add([]);

      // Session info section
      rows.add(['SESSION INFORMATION']);
      rows.add(['Session ID', session.id]);
      rows.add(['Driver Name', session.driverName]);
      rows.add(['Bus Plate', session.busPlate]);
      rows.add(['Direction', session.direction]);
      rows.add(['Start Time', DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime)]);
      rows.add([
        'End Time',
        session.endTime != null 
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!)
            : 'Active'
      ]);
      rows.add(['Duration', session.formattedDuration]);
      rows.add(['Total Scans IN', session.totalScansIn]);
      rows.add(['Total Scans OUT', session.totalScansOut]);
      rows.add(['Status', session.isActive ? 'Active' : 'Completed']);
      rows.add([]);

      // Scans section
      rows.add(['DETAILED SCANS']);
      rows.add(['#', 'National ID', 'Scan Type', 'Date', 'Time']);

      for (int i = 0; i < scans.length; i++) {
        final scan = scans[i];
        rows.add([
          i + 1,
          scan.nationalId,
          scan.scanType,
          DateFormat('yyyy-MM-dd').format(scan.timestamp),
          DateFormat('HH:mm:ss').format(scan.timestamp),
        ]);
      }

      // Summary section
      rows.add([]);
      rows.add(['SUMMARY']);
      rows.add(['Total Scans', scans.length]);
      rows.add(['Scans IN', scans.where((s) => s.scanType == 'IN').length]);
      rows.add(['Scans OUT', scans.where((s) => s.scanType == 'OUT').length]);

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Get Downloads directory
      final directory = await getDownloadsDirectory();

      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'Monion_Session_${session.id}_$timestamp.csv';
      final filePath = '${directory.path}/$filename';

      // Write file
      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      print('Error exporting CSV: $e');
      return null;
    }
  }

  // Export all sessions to CSV
  static Future<String?> exportAllSessionsToCSV() async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get all sessions
      final sessions = await DatabaseService.instance.getAllSessions();

      if (sessions.isEmpty) {
        throw Exception('No sessions to export');
      }

      // Prepare CSV data
      List<List<dynamic>> rows = [];

      // Header
      rows.add(['MONION - All Sessions Report']);
      rows.add(['Generated:', DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())]);
      rows.add([]);

      // Data header
      rows.add([
        'Session ID',
        'Driver Name',
        'Bus Plate',
        'Direction',
        'Start Time',
        'End Time',
        'Duration',
        'Total IN',
        'Total OUT',
        'Status',
      ]);

      // Sessions data
      for (var session in sessions) {
        rows.add([
          session.id,
          session.driverName,
          session.busPlate,
          session.direction,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime),
          session.endTime != null 
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!)
              : 'N/A',
          session.formattedDuration,
          session.totalScansIn,
          session.totalScansOut,
          session.isActive ? 'Active' : 'Completed',
        ]);
      }

      // Summary
      rows.add([]);
      rows.add(['SUMMARY']);
      rows.add(['Total Sessions', sessions.length]);
      rows.add(['Active Sessions', sessions.where((s) => s.isActive).length]);
      rows.add(['Completed Sessions', sessions.where((s) => !s.isActive).length]);

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Get Downloads directory
      final directory = await getDownloadsDirectory();

      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'Monion_All_Sessions_$timestamp.csv';
      final filePath = '${directory.path}/$filename';

      // Write file
      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      print('Error exporting all sessions CSV: $e');
      return null;
    }
  }

  // ==================== PDF EXPORT ====================

  // Export single session to PDF
  static Future<String?> exportSessionToPDF(Session session) async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get all scans for this session
      final scans = await DatabaseService.instance.getSessionScans(session.id!);

      // Create PDF document
      final pdf = pw.Document();

      // Add pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#2B7EF4'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MONION',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'by ${AppConstants.companyName} - ${AppConstants.universityName}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Title
              pw.Text(
                'Session Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 20),

              // Session Information
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfInfoRow('Session ID:', '${session.id}'),
                    _buildPdfInfoRow('Driver Name:', session.driverName),
                    _buildPdfInfoRow('Bus Plate:', session.busPlate),
                    _buildPdfInfoRow('Direction:', session.direction),
                    _buildPdfInfoRow(
                      'Start Time:',
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime),
                    ),
                    _buildPdfInfoRow(
                      'End Time:',
                      session.endTime != null
                          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!)
                          : 'Active',
                    ),
                    _buildPdfInfoRow('Duration:', session.formattedDuration),
                    _buildPdfInfoRow('Total Scans IN:', '${session.totalScansIn}'),
                    _buildPdfInfoRow('Total Scans OUT:', '${session.totalScansOut}'),
                    _buildPdfInfoRow(
                      'Status:',
                      session.isActive ? 'Active' : 'Completed',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Scans Table
              pw.Text(
                'Detailed Scans (${scans.length} total)',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 15),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#2B7EF4').flatten(),
                    ),
                    children: [
                      _buildTableCell('#', isHeader: true),
                      _buildTableCell('National ID', isHeader: true),
                      _buildTableCell('Type', isHeader: true),
                      _buildTableCell('Date', isHeader: true),
                      _buildTableCell('Time', isHeader: true),
                    ],
                  ),
                  // Table rows
                  ...scans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final scan = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildTableCell('${index + 1}'),
                        _buildTableCell(scan.nationalId),
                        _buildTableCell(
                          scan.scanType,
                          textColor: scan.scanType == 'IN'
                              ? PdfColor.fromHex('#10B981')
                              : PdfColor.fromHex('#EF4444'),
                        ),
                        _buildTableCell(
                          DateFormat('yyyy-MM-dd').format(scan.timestamp),
                        ),
                        _buildTableCell(
                          DateFormat('HH:mm:ss').format(scan.timestamp),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 30),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPdfInfoRow('Total Scans:', '${scans.length}'),
                    _buildPdfInfoRow(
                      'Scans IN:',
                      '${scans.where((s) => s.scanType == 'IN').length}',
                    ),
                    _buildPdfInfoRow(
                      'Scans OUT:',
                      '${scans.where((s) => s.scanType == 'OUT').length}',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.Text(
                    'Monion v${AppConstants.version}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      // Get Downloads directory
      final directory = await getDownloadsDirectory();

      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'Monion_Session_${session.id}_$timestamp.pdf';
      final filePath = '${directory.path}/$filename';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      print('Error exporting PDF: $e');
      return null;
    }
  }

  // Helper: Build PDF info row
  static pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  // Helper: Build PDF table cell
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
          color: textColor,
        ),
      ),
    );
  }
}