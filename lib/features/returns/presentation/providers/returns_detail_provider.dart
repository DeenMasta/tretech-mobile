import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/return_session_model.dart';
import '../../data/repositories/returns_repository.dart';
import 'returns_list_provider.dart';

// ── Detail state ──────────────────────────────────────────────────────────────

class ReturnDetailState {
  const ReturnDetailState({
    this.session,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final ReturnSessionModel? session;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  ReturnDetailState copyWith({
    ReturnSessionModel? session,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      ReturnDetailState(
        session: session ?? this.session,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Detail notifier ───────────────────────────────────────────────────────────
// Mirrors StockInSessionController: receives sessionId via constructor,
// and uses Notifier<T> so `ref` is available as a built-in property.

class ReturnDetailNotifier extends Notifier<ReturnDetailState> {
  ReturnDetailNotifier(this._sessionId);
  final int _sessionId;
  bool _initialLoadStarted = false;

  @override
  ReturnDetailState build() {
    if (!_initialLoadStarted) {
      _initialLoadStarted = true;
      Future<void>.microtask(_load);
    }
    return const ReturnDetailState(isLoading: true);
  }

  ReturnsRepository get _repo => ref.read(returnsRepositoryProvider);

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repo.get(_sessionId);
      state = state.copyWith(session: session, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<bool> deleteItem(int itemId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.deleteItem(_sessionId, itemId);
      await _load();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> complete() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repo.complete(_sessionId);
      state = state.copyWith(session: updated, isSaving: false);
      // Invalidate the filter provider so the list screen re-fetches
      ref.invalidate(returnListFilterProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> reopen(String reason) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repo.reopen(_sessionId, reason);
      state = state.copyWith(session: updated, isSaving: false);
      ref.invalidate(returnListFilterProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final returnDetailProvider = NotifierProvider.autoDispose
    .family<ReturnDetailNotifier, ReturnDetailState, int>(
  ReturnDetailNotifier.new,
);
