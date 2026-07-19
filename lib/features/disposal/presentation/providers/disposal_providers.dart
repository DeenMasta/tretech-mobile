import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/disposal_models.dart';
import '../../data/repositories/disposal_repository.dart';

class DisposalListQuery {
  const DisposalListQuery({
    this.search = '',
    this.status = 'all',
    this.fromDate,
    this.toDate,
    this.page = 1,
    this.perPage = 15,
  });
  final String search;
  final String status;
  final String? fromDate;
  final String? toDate;
  final int page;
  final int perPage;
  DisposalListQuery copyWith({
    String? search,
    String? status,
    String? fromDate,
    String? toDate,
    int? page,
    int? perPage,
    bool clearFrom = false,
    bool clearTo = false,
  }) => DisposalListQuery(
    search: search ?? this.search,
    status: status ?? this.status,
    fromDate: clearFrom ? null : fromDate ?? this.fromDate,
    toDate: clearTo ? null : toDate ?? this.toDate,
    page: page ?? this.page,
    perPage: perPage ?? this.perPage,
  );
  @override
  bool operator ==(Object other) =>
      other is DisposalListQuery &&
      other.search == search &&
      other.status == status &&
      other.fromDate == fromDate &&
      other.toDate == toDate &&
      other.page == page &&
      other.perPage == perPage;
  @override
  int get hashCode =>
      Object.hash(search, status, fromDate, toDate, page, perPage);
}

final disposalListProvider = FutureProvider.autoDispose
    .family<DisposalPage, DisposalListQuery>(
      (ref, query) => ref
          .watch(disposalRepositoryProvider)
          .list(
            search: query.search,
            status: query.status,
            fromDate: query.fromDate,
            toDate: query.toDate,
            page: query.page,
            perPage: query.perPage,
          ),
    );
final disposalDetailProvider = FutureProvider.autoDispose
    .family<DisposalModel, int>(
      (ref, id) => ref.watch(disposalRepositoryProvider).get(id),
    );
final disposalItemsProvider = FutureProvider.autoDispose
    .family<List<DisposalItemModel>, int>(
      (ref, id) => ref.watch(disposalRepositoryProvider).items(id),
    );
