import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../models/return_session_model.dart';

class ReturnsRepository {
  ReturnsRepository(this._dio);
  final Dio _dio;

  AppException _wrap(Object error) =>
      error is AppException ? error : const UnknownException();

  Map<String, dynamic> _unwrap(Map<String, dynamic> body) =>
      body['data'] is Map<String, dynamic>
      ? body['data'] as Map<String, dynamic>
      : body;

  // ── List ────────────────────────────────────────────────────

  Future<ReturnSessionPage> list({
    String? search,
    String? status,
    int? consignmentId,
    String? fromDate,
    String? toDate,
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'per_page': perPage};
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }
      if (consignmentId != null) {
        params['consignment_id'] = consignmentId;
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        params['from_date'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        params['to_date'] = toDate;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.returnSessions,
        queryParameters: params,
      );
      final body = response.data ?? {};
      final list = (body['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ReturnSessionModel.fromJson)
          .toList();
      final pagination = (body['pagination'] as Map<String, dynamic>?) ?? {};
      return ReturnSessionPage(
        items: list,
        total: (pagination['total'] as num?)?.toInt() ?? list.length,
        perPage: (pagination['per_page'] as num?)?.toInt() ?? perPage,
        currentPage: (pagination['current_page'] as num?)?.toInt() ?? page,
        lastPage: (pagination['last_page'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  // ── Get detail ───────────────────────────────────────────────

  Future<ReturnSessionModel> get(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.returnSessionById(id),
      );
      return ReturnSessionModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  // ── Create ───────────────────────────────────────────────────

  Future<ReturnSessionModel> create({
    required int consignmentId,
    required int picUserId,
    String? remarks,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.returnSessions,
        data: {
          'consignment_id': consignmentId,
          'pic_user_id': picUserId,
          if (remarks != null && remarks.trim().isNotEmpty)
            'remarks': remarks.trim(),
        },
      );
      return ReturnSessionModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  // ── Scan item ────────────────────────────────────────────────

  Future<ReturnSessionItem> scanItem(
    int sessionId, {
    int? lotId,
    String? lotNumber,
    int? productId,
    int? instrumentSetId,
    int quantity = 1,
    int usedQuantity = 0,
    int damagedQuantity = 0,
    int missingQuantity = 0,
    String? sourceQrPayload,
    String? remarks,
    List<Map<String, dynamic>>? instrumentResults,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (lotId != null) {
        payload['lot_id'] = lotId;
      }
      if (lotNumber != null && lotNumber.trim().isNotEmpty) {
        payload['lot_number'] = lotNumber.trim();
      }
      if (productId != null) {
        payload['product_id'] = productId;
      }
      if (instrumentSetId != null) {
        payload['instrument_set_id'] = instrumentSetId;
      }
      payload['quantity'] = quantity;
      if (usedQuantity > 0) {
        payload['used_quantity'] = usedQuantity;
      }
      if (damagedQuantity > 0) {
        payload['damaged_quantity'] = damagedQuantity;
      }
      if (missingQuantity > 0) {
        payload['missing_quantity'] = missingQuantity;
      }
      if (sourceQrPayload != null && sourceQrPayload.trim().isNotEmpty) {
        payload['source_qr_payload'] = sourceQrPayload.trim();
      }
      if (remarks != null && remarks.trim().isNotEmpty) {
        payload['remarks'] = remarks.trim();
      }
      if (instrumentResults != null && instrumentResults.isNotEmpty) {
        payload['instrument_results'] = instrumentResults;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.returnSessionScan(sessionId),
        data: payload,
      );
      return ReturnSessionItem.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  // ── Delete item ──────────────────────────────────────────────

  Future<void> deleteItem(int sessionId, int itemId) async {
    try {
      await _dio.delete<void>(
        ApiEndpoints.returnSessionItem(sessionId, itemId),
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<void> updateItemRemarks(
    int sessionId,
    int itemId,
    String? remarks,
  ) async {
    try {
      await _dio.patch<void>(
        ApiEndpoints.returnSessionItem(sessionId, itemId),
        data: {'remarks': _nullableRemarks(remarks)},
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<void> updateReconciliationItemRemarks(
    int reconciliationId,
    int itemId,
    String? remarks,
  ) async {
    try {
      await _dio.patch<void>(
        '${ApiEndpoints.reconciliations}/$reconciliationId/items/$itemId',
        data: {'remarks': _nullableRemarks(remarks)},
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<void> updateReconciliationComponentRemarks(
    int reconciliationId,
    int itemId,
    int componentId,
    String? remarks,
  ) async {
    try {
      await _dio.patch<void>(
        '${ApiEndpoints.reconciliations}/$reconciliationId/items/$itemId/components/$componentId',
        data: {'remarks': _nullableRemarks(remarks)},
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  // ── Complete session ─────────────────────────────────────────

  /// Downloads the usage/invoice PDF generated after a return is completed.
  Future<List<int>> print(int sessionId) async {
    try {
      final response = await _dio.get<List<int>>(
        ApiEndpoints.returnSessionPrint(sessionId),
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<ReturnSessionModel> complete(int sessionId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.returnSessionComplete(sessionId),
      );
      return ReturnSessionModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  // ── Reopen session ───────────────────────────────────────────

  Future<ReturnSessionModel> reopen(int sessionId, String reason) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.returnSessionReopen(sessionId),
        data: {'reopen_reason': reason.trim()},
      );
      return ReturnSessionModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  String? _nullableRemarks(String? remarks) {
    final value = remarks?.trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

/// Riverpod provider
final returnsRepositoryProvider = Provider<ReturnsRepository>((ref) {
  return ReturnsRepository(ref.watch(dioProvider));
});
