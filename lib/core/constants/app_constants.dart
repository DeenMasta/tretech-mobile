/// Application-wide constants
abstract final class AppConstants {
  // ── App Info ─────────────────────────────────────────────────
  static const String appName = 'Tretech';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  // ── API ───────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Pagination ────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int defaultPage = 1;

  // ── Hive Boxes ───────────────────────────────────────────────
  static const String hiveBoxUser = 'user_box';
  static const String hiveBoxInventory = 'inventory_box';
  static const String hiveBoxSettings = 'settings_box';

  // ── Date Formats ─────────────────────────────────────────────
  static const String dateFormatDisplay = 'dd MMM yyyy';
  static const String dateTimeFormatDisplay = 'dd MMM yyyy, HH:mm';
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String dateTimeFormatApi = "yyyy-MM-dd'T'HH:mm:ss'Z'";

  // ── Bluetooth ─────────────────────────────────────────────────
  static const int btPrinterPaperWidth = 58; // mm (58mm thermal roll)
  static const String btPrinterDefaultName = 'Tretech Printer';
}
