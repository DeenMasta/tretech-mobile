import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';

/// Intercepts every request and attaches the Bearer token from SecureStorage.
/// On 401 responses, clears the stored token (token refresh is handled
/// separately by the AuthService / auth state notifier).
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authHeader = await SecureStorage.getAuthHeader();
    if (authHeader != null) {
      options.headers['Authorization'] = authHeader;
    }
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Clear stale token — router guard will redirect to login
      await SecureStorage.clearAll();
    }
    return handler.next(err);
  }
}