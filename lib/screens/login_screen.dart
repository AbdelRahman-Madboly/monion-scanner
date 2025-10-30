// lib/screens/login_screen.dart
// Purpose: Login screen with Driver and Admin tabs

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../services/database_service.dart';
import '../models/driver.dart';
import 'driver/driver_dashboard.dart';
import 'admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Driver form controllers
  final _driverNameController = TextEditingController();
  final _busPlateController = TextEditingController();

  // Admin form controllers
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  // Loading states
  bool _isDriverLoading = false;
  bool _isAdminLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _driverNameController.dispose();
    _busPlateController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  // Handle driver login
  Future<void> _handleDriverLogin() async {
    final name = _driverNameController.text.trim();
    final busPlate = _busPlateController.text.trim().toUpperCase();

    if (name.isEmpty || busPlate.isEmpty) {
      _showError('Please enter both name and bus plate');
      return;
    }

    setState(() => _isDriverLoading = true);

    try {
      // Create/get driver from database
      final driver = Driver(name: name, busPlate: busPlate);
      await DatabaseService.instance.createDriver(driver);

      // Navigate to driver dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DriverDashboard(
              driverName: name,
              busPlate: busPlate,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isDriverLoading = false);
      }
    }
  }

  // Handle admin login
  Future<void> _handleAdminLogin() async {
    final username = _adminUsernameController.text.trim();
    final password = _adminPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Please enter both username and password');
      return;
    }

    setState(() => _isAdminLoading = true);

    // Simple credential check
    await Future.delayed(const Duration(seconds: 1));

    if (username == AppConstants.adminUsername &&
        password == AppConstants.adminPassword) {
      // Navigate to admin dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AdminDashboard(),
          ),
        );
      }
    } else {
      _showError('Invalid credentials');
    }

    if (mounted) {
      setState(() => _isAdminLoading = false);
    }
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // VINEX Logo - Using Asset Image
                Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/vinex_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if image not found
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'VINEX',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // App name
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Company name
                Text(
                  'by ${AppConstants.companyName}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    labelColor: AppColors.white,
                    unselectedLabelColor: AppColors.greyDark,
                    tabs: const [
                      Tab(text: 'Driver'),
                      Tab(text: 'Admin'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Tab views
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDriverForm(),
                      _buildAdminForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Driver login form
  Widget _buildDriverForm() {
    return Column(
      children: [
        TextField(
          controller: _driverNameController,
          decoration: const InputDecoration(
            labelText: 'Driver Name',
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person),
          ),
          textCapitalization: TextCapitalization.words,
          enabled: !_isDriverLoading,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _busPlateController,
          decoration: const InputDecoration(
            labelText: 'Bus Plate Number',
            hintText: 'e.g., ABC-1234',
            prefixIcon: Icon(Icons.directions_bus),
          ),
          textCapitalization: TextCapitalization.characters,
          enabled: !_isDriverLoading,
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomButton(
          text: 'Login as Driver',
          onPressed: _handleDriverLogin,
          isLoading: _isDriverLoading,
          icon: Icons.login,
        ),
      ],
    );
  }

  // Admin login form
  Widget _buildAdminForm() {
    return Column(
      children: [
        TextField(
          controller: _adminUsernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Enter admin username',
            prefixIcon: Icon(Icons.admin_panel_settings),
          ),
          enabled: !_isAdminLoading,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _adminPasswordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter password',
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
          enabled: !_isAdminLoading,
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomButton(
          text: 'Login as Admin',
          onPressed: _handleAdminLogin,
          isLoading: _isAdminLoading,
          icon: Icons.login,
        ),
      ],
    );
  }
}
