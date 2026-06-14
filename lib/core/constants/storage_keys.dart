/// Keys for flutter_secure_storage, Hive, and SharedPreferences
abstract final class StorageKeys {
  // ── Secure Storage (tokens) ───────────────────────────────────
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenType = 'token_type';

  // ── Hive — User ───────────────────────────────────────────────
  static const String currentUser = 'current_user';

  // ── SharedPreferences — Settings ──────────────────────────────
  static const String onboardingComplete = 'onboarding_complete';
  static const String selectedPrinterId = 'selected_printer_id';
  static const String selectedPrinterName = 'selected_printer_name';
  static const String locale = 'locale';
  static const String theme = 'theme';
  static const String lastSyncedAt = 'last_synced_at';
  static const String rememberMe = 'remember_me';
}
