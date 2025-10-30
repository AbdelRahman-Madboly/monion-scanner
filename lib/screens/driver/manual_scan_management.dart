// lib/screens/driver/manual_scan_management.dart
// Purpose: Manage all scanned students - OVERFLOW FIXED

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/session.dart';
import '../../models/scan.dart';

class ManualScanManagement extends StatefulWidget {
  final Session session;

  const ManualScanManagement({super.key, required this.session});

  @override
  State<ManualScanManagement> createState() => _ManualScanManagementState();
}

class _ManualScanManagementState extends State<ManualScanManagement> {
  List<Scan> _allScans = [];
  List<Scan> _filteredScans = [];
  Set<String> _selectedIds = {};
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterMode = 'All';
  bool _selectAllMode = false;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() => _isLoading = true);
    final scans = await DatabaseService.instance.getSessionScans(widget.session.id!);
    setState(() {
      _allScans = scans;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    var filtered = _allScans;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((scan) => scan.nationalId.contains(_searchQuery)).toList();
    }

    if (_filterMode == 'IN') {
      filtered = filtered.where((scan) => scan.isScannedIn).toList();
    } else if (_filterMode == 'OUT') {
      filtered = filtered.where((scan) => scan.isScannedOut).toList();
    }

    setState(() => _filteredScans = filtered);
  }

  void _toggleSelection(String nationalId) {
    setState(() {
      if (_selectedIds.contains(nationalId)) {
        _selectedIds.remove(nationalId);
      } else {
        _selectedIds.add(nationalId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAllMode) {
        _selectedIds.clear();
        _selectAllMode = false;
      } else {
        _selectedIds = _filteredScans
            .where((scan) => scan.isScannedIn)
            .map((scan) => scan.nationalId)
            .toSet();
        _selectAllMode = true;
      }
    });
  }

  Future<void> _markSelectedAsOut() async {
    if (_selectedIds.isEmpty) {
      _showMessage('No students selected', isError: true);
      return;
    }

    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Scanned OUT'),
        content: Text(
          'Mark $count student(s) as scanned OUT?\n\n'
          'This will record the current time as their scan out time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await DatabaseService.instance.markMultipleAsOut(
          widget.session.id!,
          _selectedIds.toList(),
        );
        final markedCount = _selectedIds.length;
        setState(() {
          _selectedIds.clear();
          _selectAllMode = false;
        });
        _showMessage('$markedCount student(s) marked as OUT');
        await _loadScans();
      } catch (e) {
        _showMessage('Error: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showManualEntryDialog() {
    final TextEditingController idController = TextEditingController();
    String selectedMode = 'IN';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Manual ID Entry',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: idController,
                    keyboardType: TextInputType.number,
                    maxLength: 14,
                    decoration: const InputDecoration(
                      labelText: 'National ID',
                      hintText: '14 digits',
                      prefixIcon: Icon(Icons.badge),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Scan Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedMode = 'IN'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'IN',
                                groupValue: selectedMode,
                                onChanged: (value) => setDialogState(() => selectedMode = value!),
                              ),
                              const Text('IN', overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedMode = 'OUT'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'OUT',
                                groupValue: selectedMode,
                                onChanged: (value) => setDialogState(() => selectedMode = value!),
                              ),
                              const Text('OUT', overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final id = idController.text.trim();

                            if (id.length != 14) {
                              _showMessage('ID must be 14 digits', isError: true);
                              return;
                            }

                            if (!RegExp(r'^\d+$').hasMatch(id)) {
                              _showMessage('ID must contain only numbers', isError: true);
                              return;
                            }

                            Navigator.of(context).pop();
                            await _processManualEntry(id, selectedMode);
                          },
                          child: const Text('Add'),
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
  }

  Future<void> _processManualEntry(String nationalId, String scanMode) async {
    setState(() => _isLoading = true);

    try {
      final scan = Scan(
        sessionId: widget.session.id!,
        nationalId: nationalId,
        scanType: scanMode,
        scanInTime: DateTime.now(),
        scanOutTime: scanMode == 'OUT' ? DateTime.now() : null,
      );

      await DatabaseService.instance.createOrUpdateScan(scan);
      _showMessage('Student added: $nationalId ($scanMode)');
      await _loadScans();
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStudentState(Scan scan) async {
    if (scan.isScannedOut) {
      _showMessage('Student already scanned OUT', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DatabaseService.instance.markStudentAsOut(
        widget.session.id!,
        scan.nationalId,
      );
      _showMessage('${scan.nationalId} marked as OUT');
      await _loadScans();
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFf44336) : const Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannedInCount = _allScans.where((s) => s.isScannedIn).length;
    final scannedOutCount = _allScans.where((s) => s.isScannedOut).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Scans'),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_selectedIds.length}'),
                child: const Icon(Icons.check_circle),
              ),
              onPressed: _markSelectedAsOut,
              tooltip: 'Mark Selected as OUT',
            ),
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: _showManualEntryDialog,
            tooltip: 'Manual Entry',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats header
                Container(
                  color: const Color(0xFF2196F3),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildHeaderStatCard(
                          'Scanned IN',
                          scannedInCount.toString(),
                          Icons.login,
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeaderStatCard(
                          'Scanned OUT',
                          scannedOutCount.toString(),
                          Icons.logout,
                          const Color(0xFFf44336),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeaderStatCard(
                          'Total',
                          _allScans.length.toString(),
                          Icons.people,
                          Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search and filter bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by ID...',
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('IN'),
                            const SizedBox(width: 8),
                            _buildFilterChip('OUT'),
                            const SizedBox(width: 16),
                            if (scannedInCount > 0)
                              TextButton.icon(
                                onPressed: _toggleSelectAll,
                                icon: Icon(
                                  _selectAllMode
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 18,
                                ),
                                label: const Text('Select All'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Scans list
                Expanded(
                  child: _filteredScans.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No students found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredScans.length,
                          itemBuilder: (context, index) {
                            final scan = _filteredScans[index];
                            final isSelected = _selectedIds.contains(scan.nationalId);
                            return _buildScanCard(scan, isSelected);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String mode) {
    final isSelected = _filterMode == mode;
    return FilterChip(
      label: Text(mode, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterMode = mode;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildScanCard(Scan scan, bool isSelected) {
    final inTime = DateFormat('HH:mm:ss').format(scan.scanInTime);
    final outTime = scan.scanOutTime != null
        ? DateFormat('HH:mm:ss').format(scan.scanOutTime!)
        : '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        dense: true,
        leading: Checkbox(
          value: isSelected,
          onChanged: (scan.isScannedOut)
              ? null
              : (_) => _toggleSelection(scan.nationalId),
        ),
        title: Text(
          scan.nationalId,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('IN: $inTime', style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 12),
              Text('OUT: $outTime', style: const TextStyle(fontSize: 11)),
              if (scan.duration != null) ...[
                const SizedBox(width: 12),
                Text(scan.formattedDuration, style: const TextStyle(fontSize: 11)),
              ],
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scan.isScannedIn
                ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                : const Color(0xFFf44336).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            scan.scanType,
            style: TextStyle(
              color: scan.isScannedIn
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFf44336),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        onTap: scan.isScannedIn
            ? () => _toggleStudentState(scan)
            : null,
      ),
    );
  }
}