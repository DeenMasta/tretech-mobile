import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../data/repositories/dashboard_repository_impl.dart';

/// Fetches the dashboard summary for the given quick-range key.
///
/// - `'7d'`  → last 7 days
/// - `'30d'` → last 30 days
/// - `'all'` → no date filter (all available data)
///
/// Uses [FutureProvider.autoDispose.family] so each unique range param gets its
/// own cache slot, and the cache is released when the screen unmounts.
final dashboardSummaryProvider = FutureProvider.autoDispose
    .family<DashboardSummary, String>((ref, range) async {
  final repo = ref.watch(dashboardRepositoryProvider);

  DateTime? dateFrom;
  if (range == '7d') {
    dateFrom = DateTime.now().subtract(const Duration(days: 7));
  } else if (range == '30d') {
    dateFrom = DateTime.now().subtract(const Duration(days: 30));
  }

  return repo.getSummary(dateFrom: dateFrom);
});
