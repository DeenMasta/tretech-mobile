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

  @override
  Future<UserModel> login(LoginRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(
        response.data!,
      );

      // Persist tokens
      await SecureStorage.setAccessToken(authResponse.token);
      await SecureStorage.setTokenType(authResponse.tokenType);

      return authResponse.user;
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
      return UserModel.fromJson(
        response.data!['user'] as Map<String, dynamic>,
      );
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
