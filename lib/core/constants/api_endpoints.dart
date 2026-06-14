/// All Laravel API endpoint paths.
/// Base URL is injected via --dart-define=API_BASE_URL=...
/// or falls back to the staging URL.
abstract final class ApiEndpoints {
  // ── Base ──────────────────────────────────────────────────────
  static const String _base = '/api';

  // ── Auth (Laravel Sanctum) ───────────────────────────────────
  static const String login = '$_base/auth/login';
  static const String logout = '$_base/auth/logout';
  static const String me = '$_base/auth/me';
  static const String refreshToken = '$_base/auth/refresh';

  // ── Dashboard ─────────────────────────────────────────────────
  static const String dashboardKpi = '$_base/dashboard/kpi';
  static const String dashboardAlerts = '$_base/dashboard/alerts';

  // ── Stock In ──────────────────────────────────────────────────
  static const String stockIn = '$_base/stock-in';
  static const String stockInCreate = '$_base/stock-in/create';
  static const String stockInDetail = '$_base/stock-in/{id}';

  // ── Inventory ─────────────────────────────────────────────────
  static const String inventory = '$_base/inventory';
  static const String inventoryDetail = '$_base/inventory/{id}';
  static const String inventorySearch = '$_base/inventory/search';

  // ── QR Printing ───────────────────────────────────────────────
  static const String qrPrint = '$_base/qr/print';
  static const String qrBatchPrint = '$_base/qr/batch-print';

  // ── Consignment ───────────────────────────────────────────────
  static const String consignment = '$_base/consignment';
  static const String consignmentCreate = '$_base/consignment/create';
  static const String consignmentDetail = '$_base/consignment/{id}';

  // ── Returns ───────────────────────────────────────────────────
  static const String returns = '$_base/returns';
  static const String returnsCreate = '$_base/returns/create';
  static const String returnsDetail = '$_base/returns/{id}';

  // ── Disposal ─────────────────────────────────────────────────
  static const String disposal = '$_base/disposal';
  static const String disposalCreate = '$_base/disposal/create';
  static const String disposalDetail = '$_base/disposal/{id}';

  // ── Helpers ───────────────────────────────────────────────────
  /// Replace a path parameter, e.g. [stockInDetail] with id
  static String withId(String path, dynamic id) =>
      path.replaceFirst('{id}', id.toString());
}
