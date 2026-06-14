import 'package:flutter/material.dart';

/// Tretech design system — color palette.
///
/// Mirrors the Tretech web app (shadcn / zinc neutral system) with full
/// light + dark support. All values are exposed as runtime getters that
/// resolve against [AppColors.brightness], so existing `AppColors.x`
/// call sites keep working while the whole app re-themes on mode change.
///
/// The active brightness is kept in sync with the rendered [ThemeData]
/// by the root widget (see `main.dart`) before each frame builds.
abstract final class AppColors {
  /// Active brightness driving every color getter below.
  static Brightness brightness = Brightness.dark;

  static bool get _isDark => brightness == Brightness.dark;

  /// Picks the right value for the active brightness.
  static Color _pick(Color light, Color dark) => _isDark ? dark : light;

  // ── Backgrounds ──────────────────────────────────────────────
  // light: --background #fff / --card #f4f4f5
  // dark:  --background #09090b / --card #18181b
  static Color get background => _pick(const Color(0xFFFFFFFF), const Color(0xFF09090B));
  static Color get surface => _pick(const Color(0xFFF4F4F5), const Color(0xFF18181B));
  static Color get surfaceElevated => _pick(const Color(0xFFFFFFFF), const Color(0xFF27272A));
  static Color get surfaceHighest => _pick(const Color(0xFFE4E4E7), const Color(0xFF3F3F46));

  // ── Sidebar ───────────────────────────────────────────────────
  // light: --sidebar #fafafa  dark: #09090b
  static Color get sidebarBg => _pick(const Color(0xFFFAFAFA), const Color(0xFF09090B));
  static Color get sidebarItemHover => _pick(const Color(0xFFF4F4F5), const Color(0xFF18181B));
  static Color get sidebarItemActive => _pick(const Color(0xFFE4E4E7), const Color(0xFF27272A));

  // ── Primary — monochrome (near-black in light, near-white in dark) ──
  // light: --primary #18181b / --primary-foreground #fafafa
  // dark:  --primary #fafafa / --primary-foreground #09090b
  static Color get primary => _pick(const Color(0xFF18181B), const Color(0xFFFAFAFA));
  static Color get onPrimary => _pick(const Color(0xFFFAFAFA), const Color(0xFF09090B));
  static Color get primaryLight => _pick(const Color(0xFF3F3F46), const Color(0xFFE4E4E7));
  static Color get primaryDark => _pick(const Color(0xFF09090B), const Color(0xFFFFFFFF));
  static Color get primaryContainer => _pick(const Color(0xFFE4E4E7), const Color(0xFF27272A));

  // ── Accent — secondary/muted zinc surface ─────────────────────
  static Color get accent => _pick(const Color(0xFF18181B), const Color(0xFFFAFAFA));
  static Color get accentContainer => _pick(const Color(0xFFF4F4F5), const Color(0xFF27272A));

  // ── Status ───────────────────────────────────────────────────
  static Color get success => _pick(const Color(0xFF16A34A), const Color(0xFF22C55E));
  static Color get successContainer => _pick(const Color(0xFFDCFCE7), const Color(0xFF0F2A1A));
  static Color get warning => _pick(const Color(0xFFD97706), const Color(0xFFF59E0B));
  static Color get warningContainer => _pick(const Color(0xFFFEF3C7), const Color(0xFF2D2209));
  // destructive — light: hsl(0 84% 60%) / dark: hsl(0 63% 31%)
  static Color get error => _pick(const Color(0xFFEF4444), const Color(0xFFEF4444));
  static Color get errorContainer => _pick(const Color(0xFFFEE2E2), const Color(0xFF3F1D1D));
  static Color get info => _pick(const Color(0xFF2563EB), const Color(0xFF3B82F6));
  static Color get infoContainer => _pick(const Color(0xFFDBEAFE), const Color(0xFF111D3D));

  // ── Typography ───────────────────────────────────────────────
  // light: --foreground #09090b / muted-foreground #71717a (zinc-500)
  // dark:  --foreground #fafafa / muted-foreground #a1a1aa (zinc-400)
  static Color get textPrimary => _pick(const Color(0xFF09090B), const Color(0xFFFAFAFA));
  static Color get textSecondary => _pick(const Color(0xFF52525B), const Color(0xFFA1A1AA));
  static Color get textMuted => _pick(const Color(0xFF71717A), const Color(0xFF71717A));
  static Color get textDisabled => _pick(const Color(0xFFA1A1AA), const Color(0xFF52525B));

  // ── Borders & Dividers ───────────────────────────────────────
  // --border / --input: light #e4e4e7  dark #27272a
  static Color get border => _pick(const Color(0xFFE4E4E7), const Color(0xFF27272A));
  static Color get borderFocus => _pick(const Color(0xFF18181B), const Color(0xFFFAFAFA));
  static Color get divider => _pick(const Color(0xFFE4E4E7), const Color(0xFF27272A));

  // ── Card / surface gradients (neutral, monochrome) ───────────
  static LinearGradient get _neutralCard => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [surfaceElevated, surface],
      );

  static LinearGradient get cardGradientGreen => _neutralCard;
  static LinearGradient get cardGradientBlue => _neutralCard;
  static LinearGradient get cardGradientOrange => _neutralCard;
  static LinearGradient get cardGradientRed => _neutralCard;

  static LinearGradient get sidebarGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [sidebarBg, background],
      );

  static LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [background, surface],
      );
}
