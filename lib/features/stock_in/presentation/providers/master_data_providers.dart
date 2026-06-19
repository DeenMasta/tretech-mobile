import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/instrument_set_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_in_session_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/repositories/master_data_repository.dart';

/// Active suppliers — refreshed on demand from the create-session screen.
final suppliersProvider = FutureProvider.autoDispose<List<SupplierModel>>((
  ref,
) async {
  final repo = ref.watch(stockInMasterDataRepositoryProvider);
  return repo.listSuppliers(perPage: 100);
});

/// Active products — used both by the scan screen for ref-num lookup
/// and by an in-app product picker.
final productsProvider = FutureProvider.autoDispose<List<ProductModel>>((
  ref,
) async {
  final repo = ref.watch(stockInMasterDataRepositoryProvider);
  return repo.listProducts(perPage: 100);
});

final instrumentSetsProvider =
    FutureProvider.autoDispose<List<InstrumentSetModel>>((ref) async {
      final repo = ref.watch(stockInMasterDataRepositoryProvider);
      return repo.listInstrumentSets(perPage: 100);
    });

/// Users available as PIC. May fail with 403 for non-admin users —
/// in that case the create-session screen falls back to current user.
final picUsersProvider = FutureProvider.autoDispose<List<StockInUserBrief>>((
  ref,
) async {
  final repo = ref.watch(stockInMasterDataRepositoryProvider);
  try {
    return await repo.listUsers(perPage: 100);
  } catch (_) {
    return const <StockInUserBrief>[];
  }
});
