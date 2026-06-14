import '../../data/models/dashboard_summary_model.dart';

/// Domain contract for dashboard data access.
abstract class DashboardRepository {
  /// Fetch the live dashboard summary.
  ///
  /// [dateFrom] / [dateTo] map to the `date_from` / `date_to` query params
  /// accepted by `GET /api/v1/dashboard/summary`.
  Future<DashboardSummary> getSummary({
    DateTime? dateFrom,
    DateTime? dateTo,
  });
}
