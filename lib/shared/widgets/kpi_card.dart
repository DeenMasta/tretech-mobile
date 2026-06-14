import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// KPI card for the dashboard — displays a metric with trend indicator
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.trend,
    this.trendLabel,
    this.gradient,
    this.accentColor,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final double? trend; // positive = up, negative = down, null = neutral
  final String? trendLabel;
  final LinearGradient? gradient;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    final cardGradient = gradient ?? AppColors.cardGradientGreen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.cardPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.kpiLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: AppDimensions.iconMd,
                        color: color,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMd),

              // Value
              Text(value, style: AppTextStyles.kpiValue),

              // Subtitle
              if (subtitle != null) ...[
                const SizedBox(height: AppDimensions.spaceXs),
                Text(subtitle!, style: AppTextStyles.bodySmall),
              ],

              // Trend
              if (trend != null) ...[
                const SizedBox(height: AppDimensions.spaceMd),
                Row(
                  children: [
                    Icon(
                      trend! >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: trend! >= 0 ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendLabel ??
                          '${trend! >= 0 ? '+' : ''}${trend!.toStringAsFixed(1)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: trend! >= 0 ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'vs last month',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
