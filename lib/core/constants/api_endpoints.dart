/// All Laravel API endpoint paths.
/// Base URL is injected via --dart-define=API_BASE_URL=...
/// or falls back to the default URL.
abstract final class ApiEndpoints {
  // ── Base ──────────────────────────────────────────────────────
  static const String _base = '/api/v1';

  // ── Dashboard ─────────────────────────────────────────────────
  static const String dashboardSummary = '$_base/dashboard/summary';

  // ── Auth ──────────────────────────────────────────────────────
  static const String login = '$_base/auth/login';
  static const String logout = '$_base/auth/logout';
  static const String me = '$_base/auth/me';
  static const String permissions = '$_base/auth/permissions';

  // ── Inventory / Ledger ───────────────────────────────────────
  static const String inventoryUnits = '$_base/inventory-units';
  static const String inventorySummary = '$_base/inventory-units/summary';
  static const String inventoryExpiringSoon = '$_base/inventory-units/expiring-soon';
  static const String inventoryLedger = '$_base/inventory-ledger';
  static const String holdingArea = '$_base/holding-area';

  // ── Stock In ──────────────────────────────────────────────────
  static const String stockInSessions = '$_base/stock-in-sessions';

  // ── Returns ───────────────────────────────────────────────────
  static const String returnSessions = '$_base/return-sessions';

  // ── Consignments ──────────────────────────────────────────────
  static const String consignments = '$_base/consignments';

  // ── Disposals ─────────────────────────────────────────────────
  static const String disposals = '$_base/disposals';

  // ── Supplier Returns ──────────────────────────────────────────
  static const String supplierReturns = '$_base/supplier-returns';

  // ── Reconciliations ───────────────────────────────────────────
  static const String reconciliations = '$_base/reconciliations';

  // ── Helpers ───────────────────────────────────────────────────
  /// Replace a path parameter, e.g. /inventory-units/{id} with actual id
  static String withId(String path, dynamic id) =>
      path.replaceFirst('{id}', id.toString());

  /// Replace a lot number, e.g. /inventory-units/lookup/by-lot/{lotNumber}
  static String withLot(String path, String lotNumber) =>
      path.replaceFirst('{lotNumber}', lotNumber);

  /// Replace a reference number, e.g. /inventory-units/lookup/by-ref/{refNum}
  static String withRef(String path, String refNum) =>
      path.replaceFirst('{refNum}', refNum);
}
