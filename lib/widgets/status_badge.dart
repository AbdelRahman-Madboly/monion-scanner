// lib/widgets/status_badge.dart
// Purpose: Colored badge to show IN/OUT status

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StatusBadge extends StatelessWidget {
  final String status; // 'IN' or 'OUT'
  final bool isActive; // Is this session/status currently active?

  const StatusBadge({
    super.key,
    required this.status,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on status
    Color backgroundColor;
    Color textColor;

    if (status == 'IN') {
      backgroundColor = isActive 
          ? AppColors.success.withOpacity(0.1)
          : AppColors.grey.withOpacity(0.1);
      textColor = isActive ? AppColors.success : AppColors.grey;
    } else if (status == 'OUT') {
      backgroundColor = isActive
          ? AppColors.error.withOpacity(0.1)
          : AppColors.grey.withOpacity(0.1);
      textColor = isActive ? AppColors.error : AppColors.grey;
    } else {
      // Default/Active badge
      backgroundColor = AppColors.primary.withOpacity(0.1);
      textColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// Large status badge (for emphasis)
class LargeStatusBadge extends StatelessWidget {
  final String status;
  final IconData? icon;

  const LargeStatusBadge({
    super.key,
    required this.status,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (status == 'IN' || status == 'ACTIVE') {
      backgroundColor = AppColors.success;
      textColor = AppColors.white;
    } else if (status == 'OUT' || status == 'ENDED') {
      backgroundColor = AppColors.error;
      textColor = AppColors.white;
    } else {
      backgroundColor = AppColors.primary;
      textColor = AppColors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}