import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outlined, ghost, danger }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      AppButtonSize.sm => AppDimensions.buttonHeightSm,
      AppButtonSize.md => AppDimensions.buttonHeight,
      AppButtonSize.lg => AppDimensions.buttonHeightLg,
    };

    final textStyle = switch (size) {
      AppButtonSize.sm => AppTextStyles.labelMedium.copyWith(
          fontWeight: FontWeight.w600, color: _labelColor),
      AppButtonSize.md => AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w600, color: _labelColor),
      AppButtonSize.lg => AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600, color: _labelColor),
    };

    final iconSize = switch (size) {
      AppButtonSize.sm => AppDimensions.iconSm,
      AppButtonSize.md => AppDimensions.iconMd,
      AppButtonSize.lg => AppDimensions.iconLg,
    };

    final Widget child = isLoading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _labelColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize, color: _labelColor),
                const SizedBox(width: AppDimensions.spaceSm),
              ],
              Text(label, style: textStyle),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppDimensions.spaceSm),
                Icon(trailingIcon, size: iconSize, color: _labelColor),
              ],
            ],
          );

    final button = SizedBox(
      height: height,
      child: _buildButton(child),
    );

    if (!isFullWidth) {
      return IntrinsicWidth(child: button);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return IntrinsicWidth(child: button);
        }
        return SizedBox(width: double.infinity, child: button);
      },
    );
  }

  Widget _buildButton(Widget child) {
    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
            ),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => ElevatedButton(

          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceElevated,
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
              side: BorderSide(color: AppColors.border),

            ),
          ),
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
            ),
          ),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
            ),
          ),
          child: child,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
            ),
          ),
          child: child,
        ),
    };
  }

  Color get _labelColor => switch (variant) {
        AppButtonVariant.primary => AppColors.onPrimary,

        AppButtonVariant.secondary => AppColors.textPrimary,
        AppButtonVariant.outlined => AppColors.primary,
        AppButtonVariant.ghost => AppColors.textSecondary,
        AppButtonVariant.danger => Colors.white,
      };
}
