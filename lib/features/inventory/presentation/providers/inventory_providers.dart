import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/inventory_movement_model.dart';
import '../../data/models/inventory_product_availability_model.dart';
import '../../data/models/inventory_set_availability_model.dart';
import '../../data/models/inventory_summary_model.dart';
import '../../data/models/inventory_unit_model.dart';
import '../../data/repositories/inventory_repository.dart';

class InventoryHomeQuery {
  const InventoryHomeQuery({
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

  InventoryHomeQuery copyWith({
    String? search,
    String? status,
    String? fromDate,
    String? toDate,
    int? page,
    int? perPage,
  }) {
    return InventoryHomeQuery(
      search: search ?? this.search,
      status: status ?? this.status,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryHomeQuery &&
        other.search == search &&
        other.status == status &&
        other.fromDate == fromDate &&
        other.toDate == toDate &&
        other.page == page &&
        other.perPage == perPage;
  }

  @override
  int get hashCode =>
      Object.hash(search, status, fromDate, toDate, page, perPage);
}

class InventoryUnitsQuery {
  const InventoryUnitsQuery({
    this.page = 1,
    this.perPage = 10,
    this.status = 'all',
    this.supplierId,
    this.supplierName,
    this.productId,
    this.productName,
    this.instrumentSetId,
    this.instrumentSetName,
    this.search = '',
    this.expiryFrom,
    this.expiryTo,
  });

  final int page;
  final int perPage;
  final String status;
  final int? supplierId;
  final String? supplierName;
  final int? productId;
  final String? productName;
  final int? instrumentSetId;
  final String? instrumentSetName;
  final String search;
  final String? expiryFrom;
  final String? expiryTo;

  InventoryUnitsQuery copyWith({
    int? page,
    int? perPage,
    String? status,
    int? supplierId,
    String? supplierName,
    int? productId,
    String? productName,
    int? instrumentSetId,
    String? instrumentSetName,
    String? search,
    String? expiryFrom,
    String? expiryTo,
    bool clearSupplier = false,
    bool clearProduct = false,
    bool clearInstrumentSet = false,
    bool clearExpiryFrom = false,
    bool clearExpiryTo = false,
  }) {
    return InventoryUnitsQuery(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      status: status ?? this.status,
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
      productId: clearProduct ? null : (productId ?? this.productId),
      productName: clearProduct ? null : (productName ?? this.productName),
      instrumentSetId: clearInstrumentSet
          ? null
          : (instrumentSetId ?? this.instrumentSetId),
      instrumentSetName: clearInstrumentSet
          ? null
          : (instrumentSetName ?? this.instrumentSetName),
      search: search ?? this.search,
      expiryFrom: clearExpiryFrom ? null : (expiryFrom ?? this.expiryFrom),
      expiryTo: clearExpiryTo ? null : (expiryTo ?? this.expiryTo),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryUnitsQuery &&
        other.page == page &&
        other.perPage == perPage &&
        other.status == status &&
        other.supplierId == supplierId &&
        other.productId == productId &&
        other.instrumentSetId == instrumentSetId &&
        other.search == search &&
        other.expiryFrom == expiryFrom &&
        other.expiryTo == expiryTo;
  }

  @override
  int get hashCode => Object.hash(
    page,
    perPage,
    status,
    supplierId,
    productId,
    instrumentSetId,
    search,
    expiryFrom,
    expiryTo,
  );
}

class InventoryMovementsQuery {
  const InventoryMovementsQuery({
    this.page = 1,
    this.perPage = 10,
    this.movementType = '',
    this.fromDate,
    this.toDate,
  });

  final int page;
  final int perPage;
  final String movementType;
  final String? fromDate;
  final String? toDate;

  InventoryMovementsQuery copyWith({
    int? page,
    int? perPage,
    String? movementType,
    String? fromDate,
    String? toDate,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) {
    return InventoryMovementsQuery(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      movementType: movementType ?? this.movementType,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryMovementsQuery &&
        other.page == page &&
        other.perPage == perPage &&
        other.movementType == movementType &&
        other.fromDate == fromDate &&
        other.toDate == toDate;
  }

  @override
  int get hashCode =>
      Object.hash(page, perPage, movementType, fromDate, toDate);
}

class InventoryExpiringSoonQuery extends InventoryUnitsQuery {
  const InventoryExpiringSoonQuery({
    this.days = 30,
    super.page = 1,
    super.perPage = 10,
    super.status = 'all',
    super.supplierId,
    super.supplierName,
    super.productId,
    super.productName,
    super.instrumentSetId,
    super.instrumentSetName,
    super.search = '',
    super.expiryFrom,
    super.expiryTo,
  });

  final int days;

  @override
  InventoryExpiringSoonQuery copyWith({
    int? days,
    int? page,
    int? perPage,
    String? status,
    int? supplierId,
    String? supplierName,
    int? productId,
    String? productName,
    int? instrumentSetId,
    String? instrumentSetName,
    String? search,
    String? expiryFrom,
    String? expiryTo,
    bool clearSupplier = false,
    bool clearProduct = false,
    bool clearInstrumentSet = false,
    bool clearExpiryFrom = false,
    bool clearExpiryTo = false,
  }) {
    return InventoryExpiringSoonQuery(
      days: days ?? this.days,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      status: status ?? this.status,
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
      productId: clearProduct ? null : (productId ?? this.productId),
      productName: clearProduct ? null : (productName ?? this.productName),
      instrumentSetId: clearInstrumentSet
          ? null
          : (instrumentSetId ?? this.instrumentSetId),
      instrumentSetName: clearInstrumentSet
          ? null
          : (instrumentSetName ?? this.instrumentSetName),
      search: search ?? this.search,
      expiryFrom: clearExpiryFrom ? null : (expiryFrom ?? this.expiryFrom),
      expiryTo: clearExpiryTo ? null : (expiryTo ?? this.expiryTo),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryExpiringSoonQuery &&
        super == other &&
        other.days == days;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, days);
}

final inventorySummaryProvider =
    FutureProvider.autoDispose<InventorySummaryModel>((ref) async {
      return ref.watch(inventoryRepositoryProvider).getSummary();
    });

final inventoryProductsProvider = FutureProvider.autoDispose
    .family<
      PaginatedResult<InventoryProductAvailabilityModel>,
      InventoryHomeQuery
    >((ref, query) async {
      return ref
          .watch(inventoryRepositoryProvider)
          .listProducts(
            search: query.search,
            status: query.status,
            fromDate: query.fromDate,
            toDate: query.toDate,
            page: query.page,
            perPage: query.perPage,
          );
    });

final inventorySetsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<InventorySetAvailabilityModel>, InventoryHomeQuery>(
      (ref, query) async {
        return ref
            .watch(inventoryRepositoryProvider)
            .listInstrumentSets(
              search: query.search,
              status: query.status,
              page: query.page,
              perPage: query.perPage,
            );
      },
    );

final inventoryUnitsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<InventoryUnitModel>, InventoryUnitsQuery>((
      ref,
      query,
    ) async {
      return ref
          .watch(inventoryRepositoryProvider)
          .listInventoryUnits(
            search: query.search,
            status: query.status,
            supplierId: query.supplierId,
            productId: query.productId,
            instrumentSetId: query.instrumentSetId,
            expiryFrom: query.expiryFrom,
            expiryTo: query.expiryTo,
            page: query.page,
            perPage: query.perPage,
          );
    });

final inventoryUnitDetailProvider = FutureProvider.autoDispose
    .family<InventoryUnitModel, int>((ref, lotId) async {
      return ref.watch(inventoryRepositoryProvider).getInventoryUnit(lotId);
    });

final inventoryLookupByLotProvider = FutureProvider.autoDispose
    .family<InventoryUnitModel, String>((ref, lotNumber) async {
      return ref.watch(inventoryRepositoryProvider).lookupByLot(lotNumber);
    });

final inventoryLookupByRefProvider = FutureProvider.autoDispose
    .family<List<InventoryUnitModel>, String>((ref, refNum) async {
      return ref.watch(inventoryRepositoryProvider).lookupByRef(refNum);
    });

final inventoryMovementsProvider = FutureProvider.autoDispose
    .family<
      PaginatedResult<InventoryMovementModel>,
      ({int lotId, InventoryMovementsQuery query})
    >((ref, args) async {
      return ref
          .watch(inventoryRepositoryProvider)
          .listLotMovements(
            args.lotId,
            movementType: args.query.movementType,
            fromDate: args.query.fromDate,
            toDate: args.query.toDate,
            page: args.query.page,
            perPage: args.query.perPage,
          );
    });

final inventoryLedgerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<InventoryMovementModel>, InventoryMovementsQuery>((
      ref,
      query,
    ) async {
      return ref
          .watch(inventoryRepositoryProvider)
          .listLedger(
            movementType: query.movementType,
            fromDate: query.fromDate,
            toDate: query.toDate,
            page: query.page,
            perPage: query.perPage,
          );
    });

final inventoryExpiringSoonProvider = FutureProvider.autoDispose
    .family<PaginatedResult<InventoryUnitModel>, InventoryExpiringSoonQuery>((
      ref,
      query,
    ) async {
      return ref
          .watch(inventoryRepositoryProvider)
          .listExpiringSoon(
            days: query.days,
            search: query.search,
            status: query.status,
            supplierId: query.supplierId,
            productId: query.productId,
            instrumentSetId: query.instrumentSetId,
            expiryFrom: query.expiryFrom,
            expiryTo: query.expiryTo,
            page: query.page,
            perPage: query.perPage,
          );
    });
