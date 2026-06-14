import 'package:flutter/material.dart';

/// Tretech design system — color palette
/// Dark charcoal enterprise theme with emerald green accents
abstract final class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1C1F26);
  static const Color surfaceElevated = Color(0xFF252A33);
  static const Color surfaceHighest = Color(0xFF2D3341);

  // ── Sidebar ───────────────────────────────────────────────────
  static const Color sidebarBg = Color(0xFF13161D);
  static const Color sidebarItemHover = Color(0xFF1E2330);
  static const Color sidebarItemActive = Color(0xFF1A3A2F);

  // ── Primary — Emerald Green ───────────────────────────────────
  static const Color primary = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryContainer = Color(0xFF0D2B22);

  // ── Accent — Electric Teal ────────────────────────────────────
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentContainer = Color(0xFF0B2D34);

  // ── Status ───────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFF0F2A1A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFF2D2209);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFF2D1111);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFF111D3D);

  // ── Typography ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF3F4758);

  // ── Borders & Dividers ───────────────────────────────────────
  static const Color border = Color(0xFF1E2736);
  static const Color borderFocus = Color(0xFF10B981);
  static const Color divider = Color(0xFF1A2030);

  // ── Card Gradients ───────────────────────────────────────────
  static const LinearGradient cardGradientGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2B22), Color(0xFF1C1F26)],
  );

  static const LinearGradient cardGradientBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111D3D), Color(0xFF1C1F26)],
  );

  static const LinearGradient cardGradientOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D1E09), Color(0xFF1C1F26)],
  );

  static const LinearGradient cardGradientRed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D1111), Color(0xFF1C1F26)],
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF13161D), Color(0xFF0F1117)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F1117), Color(0xFF111520)],
  );
}
