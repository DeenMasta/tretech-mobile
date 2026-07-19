import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../models/instrument_set_model.dart';
import '../models/product_model.dart';
import '../models/supplier_model.dart';
import '../models/stock_in_session_model.dart';

/// Repository for master data lookups used by the stock-in flow:
/// suppliers, products, and PIC users.
class StockInMasterDataRepository {
  StockInMasterDataRepository(this._dio);
  final Dio _dio;

  AppException _wrap(Object error) =>
      error is AppException ? error : const UnknownException();

  Future<List<SupplierModel>> listSuppliers({
    String? search,
    int perPage = 50,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.masterDataSuppliers,
        queryParameters: {
          'per_page': perPage,
          'is_active': 1,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final list = (response.data?['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      return list.map(SupplierModel.fromJson).toList();
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<List<ProductModel>> listProducts({
    String? search,
    int perPage = 50,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.masterDataProducts,
        queryParameters: {
          'per_page': perPage,
          'is_active': 1,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final list = (response.data?['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      return list.map(ProductModel.fromJson).toList();
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<List<InstrumentSetModel>> listInstrumentSets({
    String? search,
    int perPage = 50,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.masterDataInstrumentSets,
        queryParameters: {
          'per_page': perPage,
          'is_active': 1,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final list = (response.data?['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      return list.map(InstrumentSetModel.fromJson).toList();
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<InstrumentSetModel> getInstrumentSet(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.masterDataInstrumentSets}/$id',
      );
      final body = response.data ?? const <String, dynamic>{};
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      return InstrumentSetModel.fromJson(data);
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  /// Looks up a product by its ref_num (used when scanning the product code).
  /// Returns null when the search yields no results.
  Future<ProductModel?> findProductByRef(String refNum) async {
    final results = await listProducts(search: refNum, perPage: 5);
    for (final p in results) {
      if (p.refNum.toUpperCase() == refNum.toUpperCase()) {
        return p;
      }
    }
    return results.isEmpty ? null : results.first;
  }

  /// Lists active users that can be assigned as PIC for a stock-in session.
  /// The endpoint requires the `system.manage_users` permission, so for users
  /// without that permission this is allowed to fail gracefully — the screen
  /// falls back to using the currently logged-in user.
  Future<List<StockInUserBrief>> listUsers({
    String? search,
    int perPage = 50,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.masterDataUsers,
        queryParameters: {
          'per_page': perPage,
          'is_active': 1,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final list = (response.data?['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      return list
          .map(
            (json) => StockInUserBrief(
              id: (json['id'] as num).toInt(),
              fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }
}

final stockInMasterDataRepositoryProvider =
    Provider<StockInMasterDataRepository>((ref) {
      return StockInMasterDataRepository(ref.watch(dioProvider));
    });
