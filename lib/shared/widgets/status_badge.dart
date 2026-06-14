import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Status badge widget for inventory/operational states
enum BadgeStatus { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.status = BadgeStatus.neutral,
    this.icon,
    this.dot = true,
  });

  final String label;
  final BadgeStatus status;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.badgePaddingH,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.badgeRadius),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: _dotColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: _dotColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color get _bgColor => switch (status) {
        BadgeStatus.success => AppColors.successContainer,
        BadgeStatus.warning => AppColors.warningContainer,
        BadgeStatus.error => AppColors.errorContainer,
        BadgeStatus.info => AppColors.infoContainer,
        BadgeStatus.neutral => AppColors.surfaceElevated,
      };

  Color get _borderColor => switch (status) {
        BadgeStatus.success => AppColors.success.withValues(alpha: 0.3),
        BadgeStatus.warning => AppColors.warning.withValues(alpha: 0.3),
        BadgeStatus.error => AppColors.error.withValues(alpha: 0.3),
        BadgeStatus.info => AppColors.info.withValues(alpha: 0.3),
        BadgeStatus.neutral => AppColors.border,
      };

  Color get _dotColor => switch (status) {
        BadgeStatus.success => AppColors.success,
        BadgeStatus.warning => AppColors.warning,
        BadgeStatus.error => AppColors.error,
        BadgeStatus.info => AppColors.info,
        BadgeStatus.neutral => AppColors.textMuted,
      };
}
