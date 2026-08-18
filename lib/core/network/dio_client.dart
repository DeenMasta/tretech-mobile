import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Configured Dio instance with:
/// - Staging base URL for debug/profile and production for release builds
/// - Optional `API_BASE_URL` override for local or integration environments
/// - Timeouts from AppConstants
/// - AuthInterceptor (Bearer token)
/// - ErrorInterceptor (typed exceptions)
/// - PrettyDioLogger (debug only)
class DioClient {
  DioClient._(Ref ref) : _dio = _createDio(ref);

  final Dio _dio;

  Dio get dio => _dio;

  static Dio _createDio(Ref ref) {
    const isReleaseBuild = bool.fromEnvironment('dart.vm.product');
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: isReleaseBuild
          ? 'https://tretech-be.mysztechnology.com'
          : 'https://tretech-staging-be.mysztechnology.com',
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(ref),
      ErrorInterceptor(),
      // Only enable logger in debug mode
      if (const bool.fromEnvironment('dart.vm.product') == false)
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
        ),
    ]);

    return dio;
  }
}

/// Singleton Dio provider
final dioClientProvider = Provider<DioClient>((ref) => DioClient._(ref));

/// Direct Dio instance provider (used by Retrofit-generated clients)
final dioProvider = Provider<Dio>((ref) => ref.watch(dioClientProvider).dio);
