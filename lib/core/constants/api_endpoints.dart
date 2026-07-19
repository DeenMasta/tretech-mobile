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
  static const String inventoryExpiringSoon =
      '$_base/inventory-units/expiring-soon';
  static const String inventoryLedger = '$_base/inventory-ledger';
  static String inventoryUnitById(int id) => '$inventoryUnits/$id';
  static String inventoryUnitMovements(int id) =>
      '$inventoryUnits/$id/movements';
  static String inventoryLookupByLot(String lotNumber) =>
      '$inventoryUnits/lookup/by-lot/$lotNumber';
  static String inventoryLookupByRef(String refNum) =>
      '$inventoryUnits/lookup/by-ref/$refNum';
  static String inventorySetsByProduct(int productId) =>
      '$inventoryUnits/lookup/sets-by-product/$productId';
  static const String holdingArea = '$_base/holding-area';

  // ── Stock In ──────────────────────────────────────────────────
  static const String stockInSessions = '$_base/stock-in-sessions';
  static String stockInSessionById(int id) => '$stockInSessions/$id';
  static String stockInSessionItems(int id) => '$stockInSessions/$id/items';
  static String stockInSessionItem(int sessionId, int itemId) =>
      '$stockInSessions/$sessionId/items/$itemId';
  static String stockInSessionItemCorrection(int sessionId, int itemId) =>
      '${stockInSessionItem(sessionId, itemId)}/correct';
  static String stockInSessionReview(int id) => '$stockInSessions/$id/review';
  static String stockInSessionFinalize(int id) =>
      '$stockInSessions/$id/finalize';
  static String stockInSessionPrint(int id) => '$stockInSessions/$id/print';

  // ── Master Data (used by stock-in flow) ───────────────────────
  static const String masterDataSuppliers = '$_base/master-data/suppliers';
  static const String masterDataProducts = '$_base/master-data/products';
  static const String masterDataInstrumentSets =
      '$_base/master-data/instrument-sets';
  static const String masterDataUsers = '$_base/master-data/users';
  static const String masterDataClients = '$_base/master-data/clients';

  // ── QR Labels & Print Jobs ────────────────────────────────────
  static String qrLabelByLot(int lotId) => '$_base/qr-labels/$lotId';
  static String qrLabelPreview(int lotId) => '$_base/qr-labels/$lotId/preview';
  static const String printJobs = '$_base/print-jobs';
  static String printJobById(int id) => '$printJobs/$id';
  static String printJobMarkPrinted(int id) => '$printJobs/$id/mark-printed';
  static String printJobMarkFailed(int id) => '$printJobs/$id/mark-failed';
  static const String printJobReprint = '$printJobs/reprint';

  // ── Returns ───────────────────────────────────────────────────────────────
  static const String returnSessions = '$_base/return-sessions';
  static String returnSessionById(int id) => '$returnSessions/$id';
  static String returnSessionScan(int id) => '$returnSessions/$id/scan';
  static String returnSessionItem(int sessionId, int itemId) =>
      '$returnSessions/$sessionId/items/$itemId';
  static String returnSessionPrint(int id) => '$returnSessions/$id/print';
  static String returnSessionComplete(int id) => '$returnSessions/$id/complete';
  static String returnSessionReopen(int id) => '$returnSessions/$id/reopen';

  // ── Consignments ──────────────────────────────────────────────
  static const String consignments = '$_base/consignments';

  // ── Disposals ─────────────────────────────────────────────────
  static const String disposals = '$_base/disposals';
  static String disposalById(int id) => '$disposals/$id';
  static String disposalItems(int id) => '${disposalById(id)}/items';
  static String disposalItem(int disposalId, int itemId) =>
      '${disposalItems(disposalId)}/$itemId';
  static String disposalComplete(int id) => '${disposalById(id)}/complete';

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
