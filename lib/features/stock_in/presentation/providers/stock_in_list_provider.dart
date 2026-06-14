import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/stock_in_repository.dart';

class StockInListFilter {
  const StockInListFilter({
    this.search = '',
    this.status = '',
  });

  final String search;
  final String status;

  StockInListFilter copyWith({String? search, String? status}) =>
      StockInListFilter(
        search: search ?? this.search,
        status: status ?? this.status,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockInListFilter &&
          other.search == search &&
          other.status == status);

  @override
  int get hashCode => Object.hash(search, status);
}

class StockInListFilterNotifier extends StateNotifier<StockInListFilter> {
  StockInListFilterNotifier() : super(const StockInListFilter());

  void setSearch(String value) => state = state.copyWith(search: value);
  void setStatus(String value) => state = state.copyWith(status: value);
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
    perPage: 25,
  );
});
