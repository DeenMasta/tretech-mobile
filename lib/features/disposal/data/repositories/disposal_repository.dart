import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../models/disposal_models.dart';

class DisposalRepository {
  DisposalRepository(this._dio);
  final Dio _dio;

  AppException _wrap(Object error) =>
      error is AppException ? error : const UnknownException();
  Map<String, dynamic> _data(Map<String, dynamic> body) =>
      body['data'] is Map<String, dynamic>
      ? body['data'] as Map<String, dynamic>
      : body;
  String? _text(String? value) =>
      value?.trim().isEmpty ?? true ? null : value!.trim();

  Future<DisposalPage> list({
    String search = '',
    String status = 'all',
    String? fromDate,
    String? toDate,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.disposals,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'search': _text(search),
          'status': status == 'all' || status.isEmpty ? null : status,
          'from_date': fromDate,
          'to_date': toDate,
        },
      );
      final body = response.data ?? const {};
      final pagination =
          body['pagination'] as Map<String, dynamic>? ?? const {};
      final items = (body['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DisposalModel.fromJson)
          .toList();
      return DisposalPage(
        items: items,
        total: (pagination['total'] as num?)?.toInt() ?? items.length,
        perPage: (pagination['per_page'] as num?)?.toInt() ?? perPage,
        currentPage: (pagination['current_page'] as num?)?.toInt() ?? page,
        lastPage: (pagination['last_page'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<DisposalModel> get(int id) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.disposalById(id),
      );
      return DisposalModel.fromJson(_data(r.data ?? const {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<List<DisposalItemModel>> items(int id) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.disposalItems(id),
      );
      return (r.data?['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DisposalItemModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<DisposalModel> create({
    required String disposedAt,
    required int picUserId,
    String? remarks,
  }) => _save(ApiEndpoints.disposals, {
    'disposed_at': disposedAt,
    'pic_user_id': picUserId,
    'remarks': _text(remarks),
  });

  Future<DisposalModel> update(
    int id, {
    required String disposedAt,
    required int picUserId,
    String? remarks,
  }) async {
    try {
      final r = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.disposalById(id),
        data: {
          'disposed_at': disposedAt,
          'pic_user_id': picUserId,
          'remarks': _text(remarks),
        },
      );
      return DisposalModel.fromJson(_data(r.data ?? const {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<DisposalModel> _save(String path, Map<String, dynamic> data) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(path, data: data);
      return DisposalModel.fromJson(_data(r.data ?? const {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<void> addItem(
    int disposalId, {
    required int lotId,
    required int quantity,
    required String category,
    required String reasonText,
    String? remarks,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.disposalItems(disposalId),
        data: {
          'lot_id': lotId,
          'quantity': quantity,
          'disposal_category': category,
          'reason_text': reasonText.trim(),
          'remarks': _text(remarks),
        },
      );
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<void> deleteItem(int disposalId, int itemId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.disposalItem(disposalId, itemId));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<DisposalModel> complete(int id) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.disposalComplete(id),
      );
      return DisposalModel.fromJson(_data(r.data ?? const {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }
}

final disposalRepositoryProvider = Provider<DisposalRepository>(
  (ref) => DisposalRepository(ref.watch(dioProvider)),
);
