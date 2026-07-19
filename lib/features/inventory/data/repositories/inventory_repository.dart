import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../models/inventory_movement_model.dart';
import '../models/inventory_product_availability_model.dart';
import '../models/inventory_set_availability_model.dart';
import '../models/inventory_summary_model.dart';
import '../models/inventory_unit_model.dart';

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  final List<T> items;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
}

class InventoryRepository {
  InventoryRepository(this._dio);

  final Dio _dio;

  AppException _wrap(Object error) =>
      error is AppException ? error : const UnknownException();

  Map<String, dynamic> _unwrapData(Map<String, dynamic> body) {
    if (body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body;
  }

  PaginatedResult<T> _parsePage<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final list = (body['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
    final pagination =
        (body['pagination'] as Map<String, dynamic>?) ?? const {};

    return PaginatedResult<T>(
      items: list,
      total: (pagination['total'] as num?)?.toInt() ?? list.length,
      perPage: (pagination['per_page'] as num?)?.toInt() ?? 15,
      currentPage: (pagination['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (pagination['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  Future<InventorySummaryModel> getSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventorySummary,
      );
      final data = _unwrapData(response.data ?? const {});
      return InventorySummaryModel.fromJson(data);
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<PaginatedResult<InventoryProductAvailabilityModel>> listProducts({
    String? search,
    String? status,
    String? fromDate,
    String? toDate,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.masterDataProducts,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'search': (search ?? '').trim().isEmpty ? null : search,
          'status': (status ?? '').isEmpty || status == 'all' ? null : status,
          'from_date': fromDate,
          'to_date': toDate,
          'include_availability': true,
        },
      );
      return _parsePage(
        response.data ?? const {},
        InventoryProductAvailabilityModel.fromJson,
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<PaginatedResult<InventorySetAvailabilityModel>> listInstrumentSets({
    String? search,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.masterDataInstrumentSets,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'search': (search ?? '').trim().isEmpty ? null : search,
          'status': (status ?? '').isEmpty || status == 'all' ? null : status,
          'include_availability': true,
        },
      );
      return _parsePage(
        response.data ?? const {},
        InventorySetAvailabilityModel.fromJson,
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<PaginatedResult<InventoryUnitModel>> listInventoryUnits({
    String? search,
    String? status,
    int? supplierId,
    int? productId,
    int? instrumentSetId,
    String? expiryFrom,
    String? expiryTo,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryUnits,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'search': (search ?? '').trim().isEmpty ? null : search,
          'status': (status ?? '').isEmpty || status == 'all' ? null : status,
          'supplier_id': supplierId,
          'product_id': productId,
          'instrument_set_id': instrumentSetId,
          'expiry_from': expiryFrom,
          'expiry_to': expiryTo,
        },
      );
      return _parsePage(response.data ?? const {}, InventoryUnitModel.fromJson);
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<PaginatedResult<InventoryUnitModel>> listExpiringSoon({
    int days = 30,
    String? search,
    String? status,
    int? supplierId,
    int? productId,
    int? instrumentSetId,
    String? expiryFrom,
    String? expiryTo,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryExpiringSoon,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'days': days,
          'search': (search ?? '').trim().isEmpty ? null : search,
          'status': (status ?? '').isEmpty || status == 'all' ? null : status,
          'supplier_id': supplierId,
          'product_id': productId,
          'instrument_set_id': instrumentSetId,
          'expiry_from': expiryFrom,
          'expiry_to': expiryTo,
        },
      );
      return _parsePage(response.data ?? const {}, InventoryUnitModel.fromJson);
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<InventoryUnitModel> getInventoryUnit(int lotId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryUnitById(lotId),
      );
      return InventoryUnitModel.fromJson(
        _unwrapData(response.data ?? const {}),
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<InventoryUnitModel> lookupByLot(String lotNumber) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryLookupByLot(
          Uri.encodeComponent(lotNumber.trim()),
        ),
      );
      return InventoryUnitModel.fromJson(
        _unwrapData(response.data ?? const {}),
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<List<InventoryUnitModel>> lookupByRef(String refNum) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryLookupByRef(Uri.encodeComponent(refNum.trim())),
      );
      final body = response.data ?? const {};
      final list = (body['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InventoryUnitModel.fromJson)
          .toList();
      return list;
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<PaginatedResult<InventoryMovementModel>> listLotMovements(
    int lotId, {
    String? movementType,
    String? fromDate,
    String? toDate,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryUnitMovements(lotId),
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'movement_type': (movementType ?? '').isEmpty ? null : movementType,
          'from_date': fromDate,
          'to_date': toDate,
        },
      );
      return _parsePage(
        response.data ?? const {},
        InventoryMovementModel.fromJson,
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<PaginatedResult<InventoryMovementModel>> listLedger({
    int? lotId,
    String? lotNumber,
    String? movementType,
    String? fromDate,
    String? toDate,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryLedger,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'lot_id': lotId,
          'lot_number': (lotNumber ?? '').trim().isEmpty ? null : lotNumber,
          'movement_type': (movementType ?? '').isEmpty ? null : movementType,
          'from_date': fromDate,
          'to_date': toDate,
        },
      );
      return _parsePage(
        response.data ?? const {},
        InventoryMovementModel.fromJson,
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(dioProvider));
});
