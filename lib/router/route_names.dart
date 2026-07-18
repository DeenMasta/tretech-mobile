/// Named route constants — single source of truth for all navigation paths
abstract final class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String sessionExpired = '/session-expired';
  static const String dashboard = '/dashboard';
  static const String stockIn = '/stock-in';
  static const String stockInCreate = '/stock-in/create';
  static const String stockInDetail = '/stock-in/:id';
  static String stockInDetailPath(int id) => '/stock-in/$id';
  static const String stockInEdit = '/stock-in/:id/edit';
  static String stockInEditPath(int id) => '/stock-in/$id/edit';
  static const String stockInItemAdd = '/stock-in/:id/items/add';
  static String stockInItemAddPath(int id) => '/stock-in/$id/items/add';
  static const String stockInItemEdit = '/stock-in/:id/items/:itemId/edit';
  static String stockInItemEditPath(int id, int itemId) =>
      '/stock-in/$id/items/$itemId/edit';
  static const String stockInScan = '/stock-in/:id/scan';
  static const String stockInReview = '/stock-in/:id/review';
  static const String stockInFinalized = '/stock-in/:id/finalized';
  static String stockInFinalizedPath(int id) => '/stock-in/$id/finalized';
  static const String stockInConfirmation = '/stock-in/:id/confirmation';
  static String stockInConfirmationPath(int id) => '/stock-in/$id/confirmation';
  static const String consignment = '/consignment';
  static const String consignmentCreate = '/consignment/create';
  static const String returns = '/returns';
  static const String returnsCreate = '/returns/create';
  static const String disposal = '/disposal';
  static const String disposalCreate = '/disposal/create';
  static const String inventory = '/inventory';
  static const String inventoryDetail = '/inventory/:id';
  static const String profile = '/profile';
  static const String settings = '/settings';
}
