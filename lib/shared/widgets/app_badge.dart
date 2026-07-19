import 'package:flutter/material.dart';

/// Compact status or metadata label shared across operational modules.
enum AppBadgeVariant { primary, secondary, destructive, outline, ghost, link }

enum AppBadgeIconPosition { start, end }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.primary,
    this.icon,
    this.iconPosition = AppBadgeIconPosition.start,
    this.isLoading = false,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.semanticLabel,
  });

  final String label;
  final AppBadgeVariant variant;
  final Widget? icon;
  final AppBadgeIconPosition iconPosition;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final TextStyle? textStyle;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(Theme.of(context).colorScheme);
    final foreground = foregroundColor ?? style.foreground;
    final effectiveIcon = isLoading
        ? SizedBox.square(
            dimension: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: foreground,
            ),
          )
        : icon;
    Widget iconWidget() => IconTheme(
      data: IconThemeData(size: 14, color: foreground),
      child: effectiveIcon!,
    );

    final badge = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minHeight: 22, minWidth: 22),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? style.background,
        borderRadius: borderRadius ?? BorderRadius.circular(999),
        border: style.hasBorder || borderColor != null
            ? Border.all(color: borderColor ?? style.border)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (effectiveIcon != null &&
              iconPosition == AppBadgeIconPosition.start) ...[
            iconWidget(),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    decoration: variant == AppBadgeVariant.link
                        ? TextDecoration.underline
                        : null,
                    decorationColor: foreground,
                  )
                  .merge(textStyle),
            ),
          ),
          if (effectiveIcon != null &&
              iconPosition == AppBadgeIconPosition.end) ...[
            const SizedBox(width: 5),
            iconWidget(),
          ],
        ],
      ),
    );
    return Semantics(
      label: semanticLabel ?? label,
      button: onTap != null,
      child: onTap == null
          ? badge
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : onTap,
                borderRadius: BorderRadius.circular(999),
                child: badge,
              ),
            ),
    );
  }

  _AppBadgeStyle _resolveStyle(ColorScheme colors) => switch (variant) {
    AppBadgeVariant.primary => _AppBadgeStyle(
      colors.primary,
      colors.onPrimary,
      colors.primary,
    ),
    AppBadgeVariant.secondary => _AppBadgeStyle(
      colors.secondaryContainer,
      colors.onSecondaryContainer,
      colors.secondaryContainer,
    ),
    AppBadgeVariant.destructive => _AppBadgeStyle(
      colors.error,
      colors.onError,
      colors.error,
    ),
    AppBadgeVariant.outline => _AppBadgeStyle(
      Colors.transparent,
      colors.onSurface,
      colors.outline,
      hasBorder: true,
    ),
    AppBadgeVariant.ghost => _AppBadgeStyle(
      Colors.transparent,
      colors.onSurfaceVariant,
      Colors.transparent,
    ),
    AppBadgeVariant.link => _AppBadgeStyle(
      Colors.transparent,
      colors.primary,
      Colors.transparent,
    ),
  };
}

class _AppBadgeStyle {
  const _AppBadgeStyle(
    this.background,
    this.foreground,
    this.border, {
    this.hasBorder = false,
  });
  final Color background;
  final Color foreground;
  final Color border;
  final bool hasBorder;
}
