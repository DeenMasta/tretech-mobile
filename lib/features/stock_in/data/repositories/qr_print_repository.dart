import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../models/print_job_model.dart';
import '../models/qr_label_model.dart';

/// Repository for QR labels and printing jobs related to stock-in lots.
class QrPrintRepository {
  QrPrintRepository(this._dio);
  final Dio _dio;

  AppException _wrap(Object error) =>
      error is AppException ? error : const UnknownException();

  Map<String, dynamic> _unwrap(Map<String, dynamic> body) {
    if (body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body;
  }

  Future<QrLabelModel> getOrCreateLabel(int lotId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.qrLabelByLot(lotId),
      );
      return QrLabelModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<QrLabelModel> previewLabel(int lotId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.qrLabelPreview(lotId),
      );
      return QrLabelModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<PrintJobModel> createPrintJob({
    required int lotId,
    String? printerName,
    String? deviceId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.printJobs,
        data: {
          'lot_id': lotId,
          if (printerName != null && printerName.isNotEmpty)
            'printer_name': printerName,
          if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
        },
      );
      return PrintJobModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<PrintJobModel> markPrinted(int jobId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.printJobMarkPrinted(jobId),
      );
      return PrintJobModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<PrintJobModel> markFailed(int jobId, {String? errorMessage}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.printJobMarkFailed(jobId),
        data: {
          if (errorMessage != null && errorMessage.isNotEmpty)
            'error_message': errorMessage,
        },
      );
      return PrintJobModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }

  Future<PrintJobModel> reprint({
    required int lotId,
    required String reason,
    String? printerName,
    String? deviceId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.printJobReprint,
        data: {
          'lot_id': lotId,
          'reprint_reason': reason,
          if (printerName != null && printerName.isNotEmpty)
            'printer_name': printerName,
          if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
        },
      );
      return PrintJobModel.fromJson(_unwrap(response.data ?? {}));
    } on DioException catch (e) {
      throw _wrap(e.error ?? const UnknownException());
    }
  }
}

final qrPrintRepositoryProvider = Provider<QrPrintRepository>((ref) {
  return QrPrintRepository(ref.watch(dioProvider));
});
