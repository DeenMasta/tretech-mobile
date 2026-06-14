import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../models/lot_model.dart';
import '../models/stock_in_item_model.dart';
import '../models/stock_in_session_model.dart';

/// Result of a paginated session list call.
class StockInSessionPage {
  const StockInSessionPage({
    required this.items,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  final List<StockInSessionModel> items;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
}

/// Result of finalizing a session: returns the session and any created lots.
class StockInFinalizeResult {
  const StockInFinalizeResult({
    required this.session,
    required this.createdLots,
  });

  final StockInSessionModel session;
  final List<LotModel> createdLots;
}

/// Repository for stock-in sessions and their items.
class StockInRepository {
  StockInRepository(this._dio);
  final Dio _dio;

  AppException _wrap(Object error) =>
      error is AppException ? error : const UnknownException();

  Map<String, dynamic> _unwrap(Map<String, dynamic> body) {
    if (body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body;
  }

  // ── Sessions ────────────────────────────────────────────────
  Future<StockInSessionPage> listSessions({
    String? search,
    String? status,
    int? supplierId,
    String? fromDate,
    String? toDate,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (supplierId != null) params['supplier_id'] = supplierId;
      if (fromDate != null) params['from_date'] = fromDate;
      if (toDate != null) params['to_date'] = toDate;

      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.stockInSessions,
        queryParameters: params,
      );
      final body = response.data ?? const {};
      final list = (body['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StockInSessionModel.fromJson)
          .toList();

      final pagination = (body['pagination'] as Map<String, dynamic>?) ?? {};
      return StockInSessionPage(
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

  Future<StockInSessionModel> getSession(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.stockInSessionById(id),
      );
      return StockInSessionModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<StockInSessionModel> reviewSession(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.stockInSessionReview(id),
      );
      return StockInSessionModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<StockInSessionModel> createSession({
    required int supplierId,
    required String doNumber,
    required DateTime stockInAt,
    required int picUserId,
    String? remarks,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.stockInSessions,
        data: {
          'supplier_id': supplierId,
          'do_number': doNumber,
          'stock_in_at': stockInAt.toUtc().toIso8601String(),
          'pic_user_id': picUserId,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        },
      );
      return StockInSessionModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<StockInSessionModel> updateSession(
    int id, {
    int? supplierId,
    String? doNumber,
    DateTime? stockInAt,
    int? picUserId,
    String? remarks,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (supplierId != null) payload['supplier_id'] = supplierId;
      if (doNumber != null) payload['do_number'] = doNumber;
      if (stockInAt != null) {
        payload['stock_in_at'] = stockInAt.toUtc().toIso8601String();
      }
      if (picUserId != null) payload['pic_user_id'] = picUserId;
      if (remarks != null) payload['remarks'] = remarks;

      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.stockInSessionById(id),
        data: payload,
      );
      return StockInSessionModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<StockInFinalizeResult> finalizeSession(int id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.stockInSessionFinalize(id),
      );
      final body = _unwrap(response.data ?? {});
      final sessionJson =
          body['session'] as Map<String, dynamic>? ?? const {};
      final lotsJson = (body['created_lots'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      return StockInFinalizeResult(
        session: StockInSessionModel.fromJson(sessionJson),
        createdLots: lotsJson.map(LotModel.fromJson).toList(),
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  // ── Items ───────────────────────────────────────────────────
  Future<List<StockInItemModel>> listItems(int sessionId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.stockInSessionItems(sessionId),
      );
      final list = (response.data?['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      return list.map(StockInItemModel.fromJson).toList();
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<StockInItemModel> addItem(
    int sessionId, {
    required int productId,
    required String supplierBatchCode,
    String? scannedLotNumber,
    DateTime? expiryDate,
    LotEntryMode lotEntryMode = LotEntryMode.scan,
    LotEntryMode expiryEntryMode = LotEntryMode.scan,
    bool missingLotFlag = false,
    String? sourceBarcode,
    String? entryOverrideReason,
    String? remarks,
  }) async {
    try {
      final payload = <String, dynamic>{
        'product_id': productId,
        'supplier_batch_code': supplierBatchCode,
        'lot_entry_mode': lotEntryMode.apiValue,
        'expiry_entry_mode': expiryEntryMode.apiValue,
        'missing_lot_flag': missingLotFlag,
      };
      if (scannedLotNumber != null && scannedLotNumber.isNotEmpty) {
        payload['scanned_lot_number'] = scannedLotNumber;
      }
      if (expiryDate != null) {
        payload['expiry_date'] =
            '${expiryDate.year.toString().padLeft(4, '0')}-'
            '${expiryDate.month.toString().padLeft(2, '0')}-'
            '${expiryDate.day.toString().padLeft(2, '0')}';
      }
      if (sourceBarcode != null && sourceBarcode.isNotEmpty) {
        payload['source_barcode'] = sourceBarcode;
      }
      if (entryOverrideReason != null && entryOverrideReason.isNotEmpty) {
        payload['entry_override_reason'] = entryOverrideReason;
      }
      if (remarks != null && remarks.isNotEmpty) {
        payload['remarks'] = remarks;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.stockInSessionItems(sessionId),
        data: payload,
      );
      return StockInItemModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<void> deleteItem(int sessionId, int itemId) async {
    try {
      await _dio.delete<void>(
        ApiEndpoints.stockInSessionItem(sessionId, itemId),
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }
}

/// Riverpod provider.
final stockInRepositoryProvider = Provider<StockInRepository>((ref) {
  return StockInRepository(ref.watch(dioProvider));
});
