// lib/screens/admin/session_detail_screen.dart
// Purpose: Detailed view of a single session with all scans

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/status_badge.dart';
import '../../services/database_service.dart';
import '../../models/session.dart';
import '../../models/scan.dart';
import '../../services/export_service.dart';

class SessionDetailScreen extends StatefulWidget {
  final Session session;

  const SessionDetailScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  List<Scan> _scans = [];
  bool _isLoading = false;
  String _filterType = 'All';

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() => _isLoading = true);

    final scans = await DatabaseService.instance.getSessionScans(widget.session.id!);

    setState(() {
      _scans = scans;
      _isLoading = false;
    });
  }

  List<Scan> get _filteredScans {
    if (_filterType == 'All') return _scans;
    return _scans.where((scan) => scan.scanType == _filterType).toList();
  }

  Future<void> _confirmDeleteScan(Scan scan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan?'),
        content: Text('Delete scan for ID ${scan.nationalId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.instance.deleteScan(scan.id!, widget.session.id!);
      _loadScans();
      _showMessage('Scan deleted');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Export session as CSV
  Future<void> _exportSessionCSV() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final filePath = await ExportService.exportSessionToCSV(widget.session);

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (filePath != null) {
        _showExportSuccessDialog(filePath, 'CSV');
      } else {
        _showMessage('Export failed. Please check permissions.');
      }
    }
  }

  // Export session as PDF
  Future<void> _exportSessionPDF() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final filePath = await ExportService.exportSessionToPDF(widget.session);

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (filePath != null) {
        _showExportSuccessDialog(filePath, 'PDF');
      } else {
        _showMessage('Export failed. Please check permissions.');
      }
    }
  }

  // Show export success dialog
  void _showExportSuccessDialog(String filePath, String fileType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Export Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$fileType file saved to:',
              style: AppTextStyles.bodyBold,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: Text(
                filePath,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(
                  Icons.folder,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Check your Downloads folder',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        actions: [
          // Export button
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: (value) {
              if (value == 'csv') {
                _exportSessionCSV();
              } else if (value == 'pdf') {
                _exportSessionPDF();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session info header
                  Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.all(AppConstants.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.session.driverName,
                                    style: AppTextStyles.h2,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.session.busPlate,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            if (widget.session.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),
                        
                        // Session details
                        _buildInfoRow('Direction', widget.session.direction, Icons.route),
                        const SizedBox(height: AppSpacing.sm),
                        _buildInfoRow(
                          'Started',
                          DateFormat('MMM dd, yyyy - HH:mm').format(widget.session.startTime),
                          Icons.access_time,
                        ),
                        if (widget.session.endTime != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _buildInfoRow(
                            'Ended',
                            DateFormat('MMM dd, yyyy - HH:mm').format(widget.session.endTime!),
                            Icons.access_time,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        _buildInfoRow(
                          'Duration',
                          widget.session.formattedDuration,
                          Icons.timer,
                        ),
                      ],
                    ),
                  ),

                  // Stats cards
                  Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.all(AppConstants.screenPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Scanned IN',
                            '${widget.session.totalScansIn}',
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildStatCard(
                            'Scanned OUT',
                            '${widget.session.totalScansOut}',
                            AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter chips
                  Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.screenPadding,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Text('Filter:', style: AppTextStyles.bodyBold),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip('All'),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip('IN'),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip('OUT'),
                      ],
                    ),
                  ),

                  // Scans list
                  Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.all(AppConstants.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Scans (${_filteredScans.length})',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        if (_filteredScans.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xxl),
                              child: Text(
                                'No scans found',
                                style: AppTextStyles.caption,
                              ),
                            ),
                          )
                        else
                          ..._filteredScans.map((scan) => _buildScanItem(scan)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.grey),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.caption),
        const Spacer(),
        Text(value, style: AppTextStyles.bodyBold),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filterType = label;
        });
      },
      selectedColor: AppColors.primary.withAlpha(51),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.greyDark,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildScanItem(Scan scan) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.nationalId,
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm:ss').format(scan.timestamp),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          StatusBadge(status: scan.scanType),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: () => _confirmDeleteScan(scan),
            tooltip: 'Delete scan',
          ),
        ],
      ),
    );
  }
}