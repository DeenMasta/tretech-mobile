import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Tretech Material 3 theme — monochrome zinc system with light + dark.
///
/// Matches the Tretech web app design tokens. Both variants are built from
/// the same [_build] routine so they stay structurally identical and only
/// differ by [brightness] (which drives [AppColors]).
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // Keep AppColors resolving against the brightness we are building.
    AppColors.brightness = brightness;
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.accentContainer,
      onSecondaryContainer: AppColors.textPrimary,
      error: AppColors.error,
      onError: const Color(0xFFFFFFFF),
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      scrim: const Color(0x99000000),
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: _appBar(isDark),
      cardTheme: _card(),
      inputDecorationTheme: _input(),
      elevatedButtonTheme: _elevatedButton(),
      outlinedButtonTheme: _outlinedButton(),
      textButtonTheme: _textButton(),
      chipTheme: _chip(),
      dividerTheme: _divider(),
      listTileTheme: _listTile(),
      bottomNavigationBarTheme: _bottomNav(),
      drawerTheme: _drawer(),
      dialogTheme: _dialog(),
      bottomSheetTheme: _bottomSheet(),
      snackBarTheme: _snackBar(),
      switchTheme: _switch(),
      checkboxTheme: _checkbox(),
      progressIndicatorTheme: _progress(),
      floatingActionButtonTheme: _fab(),
      tabBarTheme: _tabBar(),
      dataTableTheme: _dataTable(),
      iconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size: AppDimensions.iconLg,
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────
  static AppBarTheme _appBar(bool isDark) => AppBarTheme(
    backgroundColor: AppColors.sidebarBg,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    ),
    titleTextStyle: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    iconTheme: IconThemeData(
      color: AppColors.textSecondary,
      size: AppDimensions.iconLg,
    ),
  );

  // ── Card ─────────────────────────────────────────────────
  static CardThemeData _card() => CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      side: BorderSide(color: AppColors.border, width: 1),
    ),
    margin: EdgeInsets.zero,
  );

  // ── Input ────────────────────────────────────────────────
  static InputDecorationTheme _input() => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceElevated,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.inputPaddingH,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
      borderSide: BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
      borderSide: BorderSide(color: AppColors.error, width: 1.5),
    ),
    hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
    labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
    prefixIconColor: AppColors.textMuted,
    suffixIconColor: AppColors.textMuted,
  );

  // ── Elevated Button ───────────────────────────────────────
  static ElevatedButtonThemeData _elevatedButton() => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
  );

  // ── Outlined Button ───────────────────────────────────────
  static OutlinedButtonThemeData _outlinedButton() => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: BorderSide(color: AppColors.border),
      minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
      ),
      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  // ── Text Button ───────────────────────────────────────────
  static TextButtonThemeData _textButton() => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  );

  // ── Chip ─────────────────────────────────────────────────
  static ChipThemeData _chip() => ChipThemeData(
    backgroundColor: AppColors.surfaceElevated,
    selectedColor: AppColors.primaryContainer,
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    side: BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
    ),
  );

  // ── Divider ───────────────────────────────────────────────
  static DividerThemeData _divider() =>
      DividerThemeData(color: AppColors.divider, thickness: 1, space: 1);

  // ── List Tile ─────────────────────────────────────────────
  static ListTileThemeData _listTile() => ListTileThemeData(
    tileColor: Colors.transparent,
    selectedTileColor: AppColors.sidebarItemActive,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.spaceLg,
      vertical: AppDimensions.spaceXs,
    ),
    iconColor: AppColors.textSecondary,
    textColor: AppColors.textSecondary,
    selectedColor: AppColors.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.sidebarItemRadius),
    ),
  );

  // ── Bottom Navigation Bar ─────────────────────────────────
  static BottomNavigationBarThemeData _bottomNav() =>
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.sidebarBg,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      );

  // ── Navigation Drawer ─────────────────────────────────────
  static DrawerThemeData _drawer() => DrawerThemeData(
    backgroundColor: AppColors.sidebarBg,
    elevation: 0,
    width: AppDimensions.sidebarWidth,
  );

  // ── Dialog ────────────────────────────────────────────────
  static DialogThemeData _dialog() => DialogThemeData(
    backgroundColor: AppColors.surfaceElevated,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      side: BorderSide(color: AppColors.border),
    ),
    titleTextStyle: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    contentTextStyle: GoogleFonts.inter(
      fontSize: 14,
      color: AppColors.textSecondary,
    ),
  );

  // ── Bottom Sheet ──────────────────────────────────────────
  static BottomSheetThemeData _bottomSheet() => BottomSheetThemeData(
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusXxl),
      ),
    ),
    dragHandleColor: AppColors.textMuted,
    // Sheets render their own handle; the Material handle would duplicate it.
    showDragHandle: false,
  );

  // ── Snack Bar ─────────────────────────────────────────────
  static SnackBarThemeData _snackBar() => SnackBarThemeData(
    backgroundColor: AppColors.surfaceHighest,
    contentTextStyle: GoogleFonts.inter(
      fontSize: 14,
      color: AppColors.textPrimary,
    ),
    actionTextColor: AppColors.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
    ),
    behavior: SnackBarBehavior.floating,
  );

  // ── Switch ────────────────────────────────────────────────
  static SwitchThemeData _switch() => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.primary
          : AppColors.textMuted,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.primaryContainer
          : AppColors.surfaceHighest,
    ),
  );

  // ── Checkbox ─────────────────────────────────────────────
  static CheckboxThemeData _checkbox() => CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.primary
          : Colors.transparent,
    ),
    checkColor: WidgetStateProperty.all(AppColors.onPrimary),
    side: BorderSide(color: AppColors.border, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
    ),
  );

  // ── Progress Indicator ────────────────────────────────────
  static ProgressIndicatorThemeData _progress() => ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.primaryContainer,
    circularTrackColor: AppColors.primaryContainer,
  );

  // ── Floating Action Button ────────────────────────────────
  static FloatingActionButtonThemeData _fab() => FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    ),
  );

  // ── Tab Bar ───────────────────────────────────────────────
  static TabBarThemeData _tabBar() => TabBarThemeData(
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.textMuted,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    unselectedLabelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  );

  // ── Data Table ───────────────────────────────────────────
  static DataTableThemeData _dataTable() => DataTableThemeData(
    headingRowColor: WidgetStateProperty.all(AppColors.surfaceElevated),
    dataRowColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.hovered)
          ? AppColors.sidebarItemHover
          : Colors.transparent,
    ),
    headingTextStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
    dataTextStyle: GoogleFonts.inter(
      fontSize: 14,
      color: AppColors.textPrimary,
    ),
    dividerThickness: 1,
    decoration: BoxDecoration(color: AppColors.surface),
  );
}
