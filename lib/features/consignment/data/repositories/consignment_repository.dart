import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../../../stock_in/data/models/instrument_set_model.dart';
import '../models/consignment_models.dart';

class ConsignmentRepository {
  ConsignmentRepository(this._dio);
  final Dio _dio;
  AppException _wrap(Object error) =>
      error is AppException ? error : const UnknownException();
  Map<String, dynamic> _data(Map<String, dynamic> body) =>
      body['data'] is Map<String, dynamic>
      ? body['data'] as Map<String, dynamic>
      : body;
  Future<ConsignmentPage> list({
    String? search,
    String? status,
    int? clientId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.consignments,
        queryParameters: {
          'per_page': 25,
          if (search?.isNotEmpty == true) 'search': search,
          if (status?.isNotEmpty == true) 'status': status,
          if (clientId != null) 'client_id': clientId,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
      );
      final body = response.data ?? {};
      final list = (body['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ConsignmentModel.fromJson)
          .toList();
      final pagination = body['pagination'] as Map<String, dynamic>? ?? {};
      return ConsignmentPage(
        items: list,
        total: (pagination['total'] as num?)?.toInt() ?? list.length,
        lastPage: (pagination['last_page'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<ConsignmentModel> get(int id) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.consignments}/$id',
      );
      return ConsignmentModel.fromJson(_data(r.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<List<ConsignmentItem>> items(int id) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.consignments}/$id/items',
      );
      return (r.data?['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ConsignmentItem.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<ConsignmentModel> create({
    required int clientId,
    required DateTime date,
    required int picUserId,
    String? remarks,
  }) => _save(ApiEndpoints.consignments, {
    'client_id': clientId,
    'consignment_at': _date(date),
    'pic_user_id': picUserId,
    'remarks': _nullable(remarks),
  });
  Future<ConsignmentModel> update(
    int id, {
    required int clientId,
    required DateTime date,
    required int picUserId,
    String? remarks,
  }) async {
    try {
      final r = await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.consignments}/$id',
        data: {
          'client_id': clientId,
          'consignment_at': _date(date),
          'pic_user_id': picUserId,
          'remarks': _nullable(remarks),
        },
      );
      return ConsignmentModel.fromJson(_data(r.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<ConsignmentModel> _save(String path, Map<String, dynamic> data) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(path, data: data);
      return ConsignmentModel.fromJson(_data(r.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<void> addItem(
    int id, {
    required bool isSet,
    int? lotId,
    int? setId,
    required int proposedQuantity,
    required int quantity,
    String? remarks,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.consignments}/$id/items',
        data: {
          'entry_kind': isSet ? 'set' : 'lot',
          if (isSet) 'instrument_set_id': setId else 'lot_id': lotId,
          'proposed_quantity': proposedQuantity,
          'quantity': quantity,
          'remarks': _nullable(remarks),
        },
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<void> deleteItem(int id, int itemId) async {
    try {
      await _dio.delete<void>('${ApiEndpoints.consignments}/$id/items/$itemId');
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<void> confirm(int id) async {
    try {
      await _dio.post<void>('${ApiEndpoints.consignments}/$id/confirm');
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<ConsignmentModel> postConfirmEdit(
    int id,
    String reason,
    String? remarks,
  ) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
        '${ApiEndpoints.consignments}/$id/post-confirm-edit',
        data: {'reason': reason, 'remarks': _nullable(remarks)},
      );
      return ConsignmentModel.fromJson(_data(r.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<List<ClientBrief>> clients({String? search}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.masterDataClients,
        queryParameters: {
          'per_page': 100,
          'is_active': 1,
          if (search?.isNotEmpty == true) 'search': search,
        },
      );
      return (r.data?['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ClientBrief.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<List<ConsignmentLot>> lots({String? search}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryUnits,
        queryParameters: {
          'per_page': 100,
          'status': 'available',
          if (search?.isNotEmpty == true) 'search': search,
        },
      );
      return (r.data?['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ConsignmentLot.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<List<InstrumentSetModel>> instrumentSets() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.masterDataInstrumentSets,
        queryParameters: {'per_page': 100, 'is_active': 1},
      );
      return (r.data?['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InstrumentSetModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<List<int>> print(
    int id, {
    String surgeon = '',
    String dateCase = '',
    String caseName = '',
  }) async {
    try {
      final r = await _dio.get<List<int>>(
        '${ApiEndpoints.consignments}/$id/print',
        queryParameters: {
          'surgeon': surgeon,
          'date_case': dateCase,
          'case': caseName,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return r.data ?? const [];
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String? _nullable(String? s) => s?.trim().isEmpty ?? true ? null : s!.trim();
}

final consignmentRepositoryProvider = Provider<ConsignmentRepository>(
  (ref) => ConsignmentRepository(ref.watch(dioProvider)),
);
