// lib/screens/admin/admin_dashboard.dart
// Purpose: Admin panel to view all sessions and export data

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monion_scanner/screens/admin/recording_view.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../services/database_service.dart';
import '../../models/session.dart';
import 'session_detail_screen.dart';
import '../login_screen.dart';
import '../../services/export_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Session> _sessions = [];
  List<Session> _filteredSessions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterDirection = 'All';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);

    final sessions = await DatabaseService.instance.getAllSessions();

    setState(() {
      _sessions = sessions;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    var filtered = _sessions;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((session) {
        return session.driverName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            session.busPlate.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by direction
    if (_filterDirection != 'All') {
      filtered = filtered
          .where((session) => session.direction == _filterDirection)
          .toList();
    }

    setState(() {
      _filteredSessions = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onFilterChanged(String? filter) {
    if (filter != null) {
      setState(() {
        _filterDirection = filter;
        _applyFilters();
      });
    }
  }

  void _navigateToSessionDetail(Session session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDetailScreen(session: session),
      ),
    ).then((_) => _loadSessions());
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showExportOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Data',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.primary),
              title: const Text('Export as CSV'),
              subtitle: const Text('Excel-compatible format'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('CSV export feature - Coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
              title: const Text('Export as PDF'),
              subtitle: const Text('Formatted report'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('PDF export feature - Coming soon!');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const RecordingView()));
          },
          child: Icon(
            Icons.video_call_outlined,
            size: 32,
          ),
        ),
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportOptions,
            tooltip: 'Export Data',
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
          : Column(
              children: [
                // Search and filter bar
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by driver or bus plate...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: AppSpacing.sm),
                            _buildFilterChip(AppConstants.sessionToUniversity),
                            const SizedBox(width: AppSpacing.sm),
                            _buildFilterChip(
                                AppConstants.sessionFromUniversity),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats summary
                Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Sessions',
                          '${_sessions.length}',
                          Icons.list_alt,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildStatCard(
                          'Active Now',
                          '${_sessions.where((s) => s.isActive).length}',
                          Icons.radio_button_checked,
                          AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildStatCard(
                          'Completed',
                          '${_sessions.where((s) => !s.isActive).length}',
                          Icons.check_circle,
                          AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sessions list
                Expanded(
                  child: _filteredSessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 80,
                                color: AppColors.grey.withAlpha(128),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No sessions yet'
                                    : 'No sessions found',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSessions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: _filteredSessions.length,
                            itemBuilder: (context, index) {
                              final session = _filteredSessions[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: SessionCard(
                                  driverName: session.driverName,
                                  busPlate: session.busPlate,
                                  direction: session.direction,
                                  time: _formatSessionTime(session),
                                  scansIn: session.totalScansIn,
                                  scansOut: session.totalScansOut,
                                  isActive: session.isActive,
                                  onTap: () =>
                                      _navigateToSessionDetail(session),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterDirection == label;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(label),
      selectedColor: AppColors.primary.withAlpha(51),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.greyDark,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatSessionTime(Session session) {
    final date = DateFormat('MMM dd, yyyy').format(session.startTime);
    final time = DateFormat('HH:mm').format(session.startTime);

    if (session.isActive) {
      return '$date at $time (Active)';
    } else {
      return '$date at $time';
    }
  }
}
