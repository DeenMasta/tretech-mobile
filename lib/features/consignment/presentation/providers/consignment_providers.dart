import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/consignment_models.dart';
import '../../data/repositories/consignment_repository.dart';

class ConsignmentFilter {
  const ConsignmentFilter({
    this.search = '',
    this.page = 1,
    this.status = '',
    this.clientId,
    this.clientName,
    this.fromDate,
    this.toDate,
  });
  final String search;
  final int page;
  final String status;
  final int? clientId;
  final String? clientName;
  final DateTime? fromDate;
  final DateTime? toDate;
  ConsignmentFilter copyWith({
    String? search,
    int? page,
    String? status,
    int? clientId,
    String? clientName,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearClient = false,
    bool clearFrom = false,
    bool clearTo = false,
    bool resetPage = false,
  }) => ConsignmentFilter(
    search: search ?? this.search,
    page: resetPage ? 1 : page ?? this.page,
    status: status ?? this.status,
    clientId: clearClient ? null : clientId ?? this.clientId,
    clientName: clearClient ? null : clientName ?? this.clientName,
    fromDate: clearFrom ? null : fromDate ?? this.fromDate,
    toDate: clearTo ? null : toDate ?? this.toDate,
  );
  @override
  bool operator ==(Object other) =>
      other is ConsignmentFilter &&
      other.search == search &&
      other.page == page &&
      other.status == status &&
      other.clientId == clientId &&
      other.fromDate == fromDate &&
      other.toDate == toDate;
  @override
  int get hashCode =>
      Object.hash(page, search, status, clientId, fromDate, toDate);
}

class ConsignmentFilterNotifier extends StateNotifier<ConsignmentFilter> {
  ConsignmentFilterNotifier() : super(const ConsignmentFilter());
  void apply(ConsignmentFilter value) => state = value;
  void clear() => state = const ConsignmentFilter();
}

final consignmentFilterProvider =
    StateNotifierProvider<ConsignmentFilterNotifier, ConsignmentFilter>(
      (ref) => ConsignmentFilterNotifier(),
    );
String _date(DateTime? value) => value == null
    ? ''
    : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
final consignmentListProvider = FutureProvider.autoDispose
    .family<ConsignmentPage, ConsignmentFilter>(
      (ref, filter) => ref
          .watch(consignmentRepositoryProvider)
          .list(
            page: filter.page,
            search: filter.search,
            status: filter.status,
            clientId: filter.clientId,
            fromDate: _date(filter.fromDate).isEmpty
                ? null
                : _date(filter.fromDate),
            toDate: _date(filter.toDate).isEmpty ? null : _date(filter.toDate),
          ),
    );
final consignmentDetailProvider = FutureProvider.autoDispose
    .family<ConsignmentModel, int>(
      (ref, id) => ref.watch(consignmentRepositoryProvider).get(id),
    );
final consignmentItemsProvider = FutureProvider.autoDispose
    .family<List<ConsignmentItem>, int>(
      (ref, id) => ref.watch(consignmentRepositoryProvider).items(id),
    );
final consignmentClientsProvider =
    FutureProvider.autoDispose<List<ClientBrief>>(
      (ref) => ref.watch(consignmentRepositoryProvider).clients(),
    );
final consignmentLotsProvider =
    FutureProvider.autoDispose<List<ConsignmentLot>>(
      (ref) => ref.watch(consignmentRepositoryProvider).lots(),
    );
final consignmentSetsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(consignmentRepositoryProvider).instrumentSets(),
);
