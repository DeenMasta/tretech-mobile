import '../../data/models/auth_models.dart';

/// Auth repository contract
abstract interface class AuthRepository {
  /// Login with email + password → store token + return user
  Future<UserModel> login(LoginRequest request);

  /// Logout from current device (revoke Sanctum token)
  Future<void> logout();

  /// Fetch authenticated user profile from /api/auth/me
  Future<UserModel> getMe();

  /// Check if a valid token exists in secure storage
  Future<bool> isAuthenticated();
}
