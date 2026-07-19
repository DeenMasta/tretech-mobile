import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_badge.dart';

/// Maps a stock-in session status to a [StatusBadge].
class StockInStatusBadge extends StatelessWidget {
  const StockInStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final (label, color, background) = switch (lower) {
      'draft' => ('Draft', AppColors.warning, AppColors.warningContainer),
      'confirmed' => (
        'Finalized',
        AppColors.success,
        AppColors.successContainer,
      ),
      'finalized' => (
        'Finalized',
        AppColors.success,
        AppColors.successContainer,
      ),
      'cancelled' => ('Cancelled', AppColors.error, AppColors.errorContainer),
      _ => (
        status.isEmpty ? 'Unknown' : status,
        AppColors.textMuted,
        AppColors.surfaceElevated,
      ),
    };

    return AppBadge(
      label: label.toUpperCase(),
      variant: AppBadgeVariant.secondary,
      backgroundColor: background,
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      borderRadius: BorderRadius.circular(6),
      textStyle: const TextStyle(letterSpacing: .35),
    );
  }
}
