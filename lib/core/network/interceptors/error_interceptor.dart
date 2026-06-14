import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../exceptions/api_exception.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Converts Dio errors into typed [AppException] subclasses.
/// Thrown exceptions are caught by repository layers.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.e(
      '[API Error] ${err.requestOptions.method} ${err.requestOptions.path}',
      error: err.message,
    );

    final appEx = _mapDioError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appEx,
        type: err.type,
        response: err.response,
      ),
    );
  }

  AppException _mapDioError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return _mapStatusCode(err.response);

      default:
        return const UnknownException();
    }
  }

  AppException _mapStatusCode(Response<dynamic>? response) {
    if (response == null) return const UnknownException();

    final status = response.statusCode ?? 0;
    final responseData = response.data as Map<String, dynamic>?;

    switch (status) {
      case 401:
        return const UnauthorizedException();
      case 403:
        return const ForbiddenException();
      case 404:
        return const NotFoundException();
      case 422:
        final message =
            responseData?['message'] as String? ?? 'Validation failed.';
        final rawErrors =
            responseData?['errors'] as Map<String, dynamic>? ?? {};
        final errors = rawErrors.map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>).map((e) => e.toString()).toList(),
          ),
        );
        return ValidationException(message: message, errors: errors);
      default:
        if (status >= 500) return ServerException.withCode(status);
        final fallbackMsg =
            responseData?['message'] as String? ?? 'Request failed.';
        return UnknownException(fallbackMsg);
    }
  }
}
