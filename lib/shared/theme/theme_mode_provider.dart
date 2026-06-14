import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';

/// Persists and exposes the app's [ThemeMode], mirroring the Tretech web app
/// (which stores the choice under `tretech-theme-mode`).
///
/// Defaults to [ThemeMode.dark] to match the previous app behavior. The value
/// is stored in the already-open Hive settings box so it survives restarts.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_load());

  static const String _storageKey = 'tretech-theme-mode';

  static Box<dynamic> get _box =>
      Hive.box<dynamic>(AppConstants.hiveBoxSettings);

  static ThemeMode _load() {
    final saved = _box.get(_storageKey) as String?;
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> _persist(ThemeMode mode) async {
    await _box.put(_storageKey, mode.name);
  }

  /// Sets an explicit theme mode.
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _persist(mode);
  }

  /// Toggles between light and dark (matches the web app toggle).
  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
