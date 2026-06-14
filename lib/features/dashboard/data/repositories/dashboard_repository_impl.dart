import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_summary_model.dart';

/// Concrete implementation that calls GET /api/v1/dashboard/summary.
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<DashboardSummary> getSummary({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (dateFrom != null) {
        // API expects YYYY-MM-DD strings
        params['date_from'] =
            '${dateFrom.year.toString().padLeft(4, '0')}-'
            '${dateFrom.month.toString().padLeft(2, '0')}-'
            '${dateFrom.day.toString().padLeft(2, '0')}';
      }
      if (dateTo != null) {
        params['date_to'] =
            '${dateTo.year.toString().padLeft(4, '0')}-'
            '${dateTo.month.toString().padLeft(2, '0')}-'
            '${dateTo.day.toString().padLeft(2, '0')}';
      }

      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.dashboardSummary,
        queryParameters: params.isEmpty ? null : params,
      );

      final body = response.data!;
      // Unwrap standard envelope: { success, data, ... }
      final payload =
          body.containsKey('data') && body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : body;

      return DashboardSummary.fromJson(payload);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : const UnknownException();
    }
  }
}

/// Riverpod provider for [DashboardRepository].
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dioProvider));
});
