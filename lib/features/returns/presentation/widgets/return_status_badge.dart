import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/app_dimensions.dart';

/// Consistent status badge for return sessions — uses AppBadge colour semantics:
/// lifecycle state only, neutral for metadata (same as StockInStatusBadge).
class ReturnStatusBadge extends StatelessWidget {
  const ReturnStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: bg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (String, Color, Color) _resolve(String s) => switch (s) {
    'in_progress' => ('In Progress', AppColors.warning, AppColors.warning),
    'completed' => ('Completed', AppColors.success, AppColors.success),
    'reconciled' => ('Reconciled', AppColors.primary, AppColors.primary),
    _ => ('Unknown', AppColors.textMuted, AppColors.textMuted),
  };
}
