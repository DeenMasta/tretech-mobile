import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/return_session_model.dart';
import '../../data/repositories/returns_repository.dart';

// ── Filter ───────────────────────────────────────────────────────────────────

class ReturnListFilter {
  const ReturnListFilter({
    this.search = '',
    this.status = '',
    this.consignmentId,
    this.consignmentLabel,
    this.fromDate,
    this.toDate,
    this.page = 1,
  });

  final String search;
  final String status;
  final int? consignmentId;
  final String? consignmentLabel;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int page;

  ReturnListFilter copyWith({
    String? search,
    String? status,
    int? consignmentId,
    String? consignmentLabel,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearConsignment = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    int? page,
  }) =>
      ReturnListFilter(
        search: search ?? this.search,
        status: status ?? this.status,
        consignmentId:
            clearConsignment ? null : (consignmentId ?? this.consignmentId),
        consignmentLabel:
            clearConsignment ? null : (consignmentLabel ?? this.consignmentLabel),
        fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
        toDate: clearToDate ? null : (toDate ?? this.toDate),
        page: page ?? 1,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReturnListFilter &&
          other.search == search &&
          other.status == status &&
          other.consignmentId == consignmentId &&
          other.fromDate == fromDate &&
          other.toDate == toDate &&
          other.page == page);

  @override
  int get hashCode =>
      Object.hash(search, status, consignmentId, fromDate, toDate, page);
}

// ── Filter Notifier ───────────────────────────────────────────────────────────

class ReturnListFilterNotifier extends StateNotifier<ReturnListFilter> {
  ReturnListFilterNotifier() : super(const ReturnListFilter());

  void setSearch(String value) => state = state.copyWith(search: value);
  void setStatus(String value) => state = state.copyWith(status: value);
  void loadPage(int p) => state = state.copyWith(page: p);
  void apply(ReturnListFilter filter) => state = filter;
  void clear() => state = const ReturnListFilter();
}

final returnListFilterProvider =
    StateNotifierProvider<ReturnListFilterNotifier, ReturnListFilter>(
      (ref) => ReturnListFilterNotifier(),
    );

// ── List provider ─────────────────────────────────────────────────────────────

String _date(DateTime? d) => d == null
    ? ''
    : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final returnListProvider = FutureProvider.autoDispose
    .family<ReturnSessionPage, ReturnListFilter>((ref, filter) async {
  final repo = ref.watch(returnsRepositoryProvider);
  return repo.list(
    search: filter.search.isEmpty ? null : filter.search,
    status: filter.status.isEmpty ? null : filter.status,
    consignmentId: filter.consignmentId,
    fromDate: _date(filter.fromDate).isEmpty ? null : _date(filter.fromDate),
    toDate: _date(filter.toDate).isEmpty ? null : _date(filter.toDate),
    page: filter.page,
    perPage: 25,
  );
});
