import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

class MoreFiltersSheet extends StatelessWidget {
  const MoreFiltersSheet({
    super.key,
    required this.child,
    required this.onApply,
    required this.onReset,
  });

  final Widget child;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Text('More filters', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppDimensions.spaceLg),
              child,
              const SizedBox(height: AppDimensions.spaceLg),
              AppButton(label: 'Apply filters', onPressed: onApply),
              const SizedBox(height: AppDimensions.spaceSm),
              AppButton(
                label: 'Reset',
                variant: AppButtonVariant.ghost,
                onPressed: onReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterPicker extends StatelessWidget {
  const FilterPicker({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.value,
    this.loading = false,
  });

  final String label;
  final String hint;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18),
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search_rounded, size: 18),
              filled: true,
              fillColor: AppColors.surfaceElevated,
            ),
            child: Text(
              hasValue ? value! : hint,
              style: hasValue
                  ? AppTextStyles.bodyMedium
                  : AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
