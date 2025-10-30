// lib/utils/constants.dart
// Purpose: App-wide constants (colors, text styles, values)

import 'package:flutter/material.dart';

// VINEX Brand Colors
class AppColors {
  // Primary color - VINEX Blue
  static const Color primary = Color(0xFF2B7EF4);
  static const Color primaryDark = Color(0xFF1E5BB8);
  static const Color primaryLight = Color(0xFF5C9BF7);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFFE5E7EB);
  static const Color greyDark = Color(0xFF374151);
  
  // Background
  static const Color background = Color(0xFFF9FAFB);
  static const Color cardBackground = Color(0xFFFFFFFF);
}

// Text Styles
class AppTextStyles {
  // Headlines
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );
  
  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.greyDark,
  );
  
  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );
  
  // Small text
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.grey,
  );
  
  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}

// App Constants
class AppConstants {
  // App info
  static const String appName = 'Monion';
  static const String companyName = 'VINEX';
  static const String universityName = 'NINU University';
  static const String version = '1.0.0';
  
  // National ID validation
  static const int nationalIdLength = 14;
  
  // Session types
  static const String sessionToUniversity = 'To University';
  static const String sessionFromUniversity = 'From University';
  
  // Scan modes
  static const String scanModeIn = 'IN';
  static const String scanModeOut = 'OUT';
  
  // Admin credentials (CHANGE THESE IN PRODUCTION!)
  static const String adminUsername = 'admin';
  static const String adminPassword = 'admin123';
  
  // UI Constants
  static const double borderRadius = 12.0;
  static const double buttonHeight = 56.0;
  static const double cardPadding = 16.0;
  static const double screenPadding = 20.0;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Scanner settings
  static const double scanAreaWidth = 0.8; // 80% of screen width
  static const double scanAreaHeight = 0.3; // 30% of screen height
}

// Helper class for spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}