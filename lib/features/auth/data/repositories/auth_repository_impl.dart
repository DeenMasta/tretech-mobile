import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_models.dart';

/// Concrete implementation of [AuthRepository].
/// Communicates with the Laravel Sanctum auth endpoints.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);
  final Dio _dio;

  AppException _invalidAuthResponse(Object error) {
    return InvalidResponseException(
      error is FormatException
          ? 'Unable to sign in because the server response is missing required account data.'
          : 'Unable to sign in because the server returned an invalid response.',
    );
  }

  @override
  Future<UserModel> login(LoginRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      final responseData = response.data!;
      final payload =
          responseData.containsKey('data') && responseData['data'] is Map
          ? responseData['data'] as Map<String, dynamic>
          : responseData;

      // The backend returns permissions beside user, while the mobile user
      // model owns the permissions list.
      if (payload.containsKey('permissions') && payload.containsKey('user')) {
        final userObj = payload['user'];
        if (userObj is Map<String, dynamic>) {
          userObj['permissions'] = payload['permissions'];
        }
      }

      final authResponse = AuthResponse.fromJson(payload);

      await SecureStorage.setAccessToken(authResponse.token);
      await SecureStorage.setTokenType(authResponse.tokenType);

      return authResponse.user;
    } on FormatException catch (e) {
      throw _invalidAuthResponse(e);
    } on TypeError catch (e) {
      throw _invalidAuthResponse(e);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : const UnknownException();
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiEndpoints.logout);
    } finally {
      // Always clear local tokens even if request fails
      await SecureStorage.clearAll();
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      final payload =
          response.data!.containsKey('data') && response.data!['data'] is Map
          ? response.data!['data'] as Map<String, dynamic>
          : response.data!;

      if (payload.containsKey('permissions') && payload.containsKey('user')) {
        final userObj = payload['user'];
        if (userObj is Map<String, dynamic>) {
          userObj['permissions'] = payload['permissions'];
        }
      }

      return UserModel.fromJson(payload['user'] as Map<String, dynamic>);
    } on FormatException catch (e) {
      throw _invalidAuthResponse(e);
    } on TypeError catch (e) {
      throw _invalidAuthResponse(e);
      } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : const UnknownException();
    }
  }

  @override
  Future<bool> isAuthenticated() => SecureStorage.hasValidToken();
}

/// Riverpod provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepositoryImpl(dio);
});
