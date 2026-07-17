import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/stock_in_repository.dart';

class StockInListFilter {
  const StockInListFilter({
    this.search = '',
    this.status = '',
    this.supplierId,
    this.supplierName,
    this.fromDate,
    this.toDate,
  });

  final String search;
  final String status;
  final int? supplierId;
  final String? supplierName;
  final DateTime? fromDate;
  final DateTime? toDate;

  StockInListFilter copyWith({
    String? search,
    String? status,
    int? supplierId,
    String? supplierName,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearSupplier = false,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) => StockInListFilter(
    search: search ?? this.search,
    status: status ?? this.status,
    supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
    supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
    fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
    toDate: clearToDate ? null : (toDate ?? this.toDate),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockInListFilter &&
          other.search == search &&
          other.status == status &&
          other.supplierId == supplierId &&
          other.supplierName == supplierName &&
          other.fromDate == fromDate &&
          other.toDate == toDate);

  @override
  int get hashCode =>
      Object.hash(search, status, supplierId, supplierName, fromDate, toDate);
}

class StockInListFilterNotifier extends StateNotifier<StockInListFilter> {
  StockInListFilterNotifier() : super(const StockInListFilter());

  void setSearch(String value) => state = state.copyWith(search: value);
  void setStatus(String value) => state = state.copyWith(status: value);
  void setSupplier({int? id, String? name}) => state = state.copyWith(
    supplierId: id,
    supplierName: name,
    clearSupplier: id == null,
  );
  void setFromDate(DateTime? value) =>
      state = state.copyWith(fromDate: value, clearFromDate: value == null);
  void setToDate(DateTime? value) =>
      state = state.copyWith(toDate: value, clearToDate: value == null);
  void apply(StockInListFilter filter) => state = filter;
  void clear() => state = const StockInListFilter();
}

final stockInListFilterProvider =
    StateNotifierProvider<StockInListFilterNotifier, StockInListFilter>((ref) {
      return StockInListFilterNotifier();
    });

final stockInListProvider = FutureProvider.autoDispose
    .family<StockInSessionPage, StockInListFilter>((ref, filter) async {
      final repo = ref.watch(stockInRepositoryProvider);
      return repo.listSessions(
        search: filter.search.isEmpty ? null : filter.search,
        status: filter.status.isEmpty ? null : filter.status,
        supplierId: filter.supplierId,
        fromDate: filter.fromDate == null
            ? null
            : '${filter.fromDate!.year.toString().padLeft(4, '0')}-'
                  '${filter.fromDate!.month.toString().padLeft(2, '0')}-'
                  '${filter.fromDate!.day.toString().padLeft(2, '0')}',
        toDate: filter.toDate == null
            ? null
            : '${filter.toDate!.year.toString().padLeft(4, '0')}-'
                  '${filter.toDate!.month.toString().padLeft(2, '0')}-'
                  '${filter.toDate!.day.toString().padLeft(2, '0')}',
        perPage: 25,
      );
    });
