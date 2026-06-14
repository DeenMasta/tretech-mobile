import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSessionState {
  const AuthSessionState({this.isExpired = false});

  final bool isExpired;

  AuthSessionState copyWith({bool? isExpired}) {
    return AuthSessionState(isExpired: isExpired ?? this.isExpired);
  }
}

class AuthSessionNotifier extends StateNotifier<AuthSessionState> {
  AuthSessionNotifier() : super(const AuthSessionState());

  void markExpired() {
    state = state.copyWith(isExpired: true);
  }

  void clear() {
    if (!state.isExpired) return;
    state = state.copyWith(isExpired: false);
  }
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSessionState>((ref) {
      return AuthSessionNotifier();
    });
