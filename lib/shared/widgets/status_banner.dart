import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    required this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String message;
  final IconData icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? AppColors.info;
    final bg = backgroundColor ?? AppColors.infoContainer;
    final bd = borderColor ?? fg.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: bd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
