import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_session_provider.dart';
import '../../../../core/storage/auth_preferences.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.rememberMe = false,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool rememberMe;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? rememberMe,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref, this._repository) : super(const AuthState());

  final Ref _ref;
  final AuthRepository _repository;

  static const _unsupportedRoleMessage =
      'This mobile app supports Admin and Logistic Staff accounts only.';

  Future<void> setRememberMe(bool value) async {
    await AuthPreferences.setRememberMe(value);
    state = state.copyWith(rememberMe: value);
  }

  Future<void> acknowledgeSessionExpired() async {
    _ref.read(authSessionProvider.notifier).clear();
    state = AuthState(
      status: AuthStatus.unauthenticated,
      rememberMe: state.rememberMe,
    );
  }

  Future<void> checkAuthStatus() async {
    final rememberMe = await AuthPreferences.getRememberMe();
    state = state.copyWith(
      status: AuthStatus.loading,
      error: null,
      rememberMe: rememberMe,
    );

    try {
      final isAuth = await _repository.isAuthenticated();

      if (!rememberMe) {
        if (isAuth) {
          await SecureStorage.clearAll();
        }

        _ref.read(authSessionProvider.notifier).clear();
        state = AuthState(
          status: AuthStatus.unauthenticated,
          rememberMe: rememberMe,
        );
        return;
      }

      if (isAuth) {
        final user = await _repository.getMe();
        if (!user.hasSupportedMobileRole) {
          await SecureStorage.clearAll();
          state = AuthState(
            status: AuthStatus.error,
            error: _unsupportedRoleMessage,
            rememberMe: rememberMe,
          );
          return;
        }

        _ref.read(authSessionProvider.notifier).clear();
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          rememberMe: rememberMe,
        );
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          rememberMe: rememberMe,
        );
      }
    } catch (_) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        rememberMe: rememberMe,
      );
    }
  }

  Future<void> login(String email, String password) async {
    final rememberMe = state.rememberMe;
    state = state.copyWith(status: AuthStatus.loading, error: null);
    _ref.read(authSessionProvider.notifier).clear();

    try {
      final request = LoginRequest(email: email, password: password);
      final user = await _repository.login(request);

      if (!user.hasSupportedMobileRole) {
        await SecureStorage.clearAll();
        state = AuthState(
          status: AuthStatus.error,
          error: _unsupportedRoleMessage,
          rememberMe: rememberMe,
        );
        return;
      }

      await AuthPreferences.setRememberMe(rememberMe);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        rememberMe: rememberMe,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: e.toString(),
        rememberMe: rememberMe,
      );
    }
  }

  Future<void> logout() async {
    final rememberMe = state.rememberMe;
    state = state.copyWith(status: AuthStatus.loading, error: null);
    _ref.read(authSessionProvider.notifier).clear();

    try {
      await _repository.logout();
    } finally {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        rememberMe: rememberMe,
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref, ref.watch(authRepositoryProvider));
});final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
