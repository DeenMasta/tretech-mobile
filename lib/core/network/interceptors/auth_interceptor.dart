import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_session_provider.dart';
import '../../storage/secure_storage.dart';

/// Intercepts every request and attaches the Bearer token from SecureStorage.
/// On 401 responses, clears the stored token (token refresh is handled
/// separately by the AuthService / auth state notifier).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;

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
    final hadAuthHeader =
        err.requestOptions.headers['Authorization']?.toString().isNotEmpty ??
        false;

    if (err.response?.statusCode == 401 && hadAuthHeader) {
      // Clear stale token — router guard will redirect to login
      await SecureStorage.clearAll();
      _ref.read(authSessionProvider.notifier).markExpired();
    }
    return handler.next(err);
  }
}
