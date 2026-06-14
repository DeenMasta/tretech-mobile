import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_in_item_model.dart';
import '../../data/models/stock_in_session_model.dart';
import '../../data/repositories/stock_in_repository.dart';

/// Holds the active session being scanned, plus its items list.
class StockInSessionState {
  const StockInSessionState({
    this.session,
    this.items = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.finalizeResult,
  });

  final StockInSessionModel? session;
  final List<StockInItemModel> items;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final StockInFinalizeResult? finalizeResult;

  StockInSessionState copyWith({
    StockInSessionModel? session,
    List<StockInItemModel>? items,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    StockInFinalizeResult? finalizeResult,
  }) {
    return StockInSessionState(
      session: session ?? this.session,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      finalizeResult: finalizeResult ?? this.finalizeResult,
    );
  }
}

/// Holds the in-progress item the user is currently scanning. The user
/// fills it in step by step (product → lot → expiry → batch) before
/// submitting it to the API as a stock-in item.
class ItemDraft {
  const ItemDraft({
    this.product,
    this.scannedLotNumber,
    this.expiryDate,
    this.supplierBatchCode = '',
    this.lotEntryMode = LotEntryMode.scan,
    this.expiryEntryMode = LotEntryMode.scan,
    this.missingLotFlag = false,
    this.entryOverrideReason,
    this.sourceBarcode,
  });

  final ProductModel? product;
  final String? scannedLotNumber;
  final DateTime? expiryDate;
  final String supplierBatchCode;
  final LotEntryMode lotEntryMode;
  final LotEntryMode expiryEntryMode;
  final bool missingLotFlag;
  final String? entryOverrideReason;
  final String? sourceBarcode;

  bool get hasProduct => product != null;
  bool get hasLot => (scannedLotNumber?.isNotEmpty ?? false) || missingLotFlag;
  bool get hasExpiry => expiryDate != null;
  bool get hasBatch => supplierBatchCode.trim().isNotEmpty;

  bool get readyToSubmit => hasProduct && hasLot && hasBatch;

  bool get requiresOverrideReason =>
      missingLotFlag ||
      lotEntryMode == LotEntryMode.manual ||
      expiryEntryMode == LotEntryMode.manual;

  ItemDraft copyWith({
    ProductModel? product,
    String? scannedLotNumber,
    DateTime? expiryDate,
    String? supplierBatchCode,
    LotEntryMode? lotEntryMode,
    LotEntryMode? expiryEntryMode,
    bool? missingLotFlag,
    String? entryOverrideReason,
    String? sourceBarcode,
    bool clearProduct = false,
    bool clearLot = false,
    bool clearExpiry = false,
  }) {
    return ItemDraft(
      product: clearProduct ? null : (product ?? this.product),
      scannedLotNumber:
          clearLot ? null : (scannedLotNumber ?? this.scannedLotNumber),
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      supplierBatchCode: supplierBatchCode ?? this.supplierBatchCode,
      lotEntryMode: lotEntryMode ?? this.lotEntryMode,
      expiryEntryMode: expiryEntryMode ?? this.expiryEntryMode,
      missingLotFlag: missingLotFlag ?? this.missingLotFlag,
      entryOverrideReason: entryOverrideReason ?? this.entryOverrideReason,
      sourceBarcode: sourceBarcode ?? this.sourceBarcode,
    );
  }
}

class StockInSessionController
    extends StateNotifier<StockInSessionState> {
  StockInSessionController(this._ref, this._sessionId)
      : super(const StockInSessionState()) {
    _load();
  }

  final Ref _ref;
  final int _sessionId;

  StockInRepository get _repo => _ref.read(stockInRepositoryProvider);

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repo.getSession(_sessionId);
      final items = session.items ?? await _repo.listItems(_sessionId);
      state = state.copyWith(
        session: session,
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  /// Adds a scanned item to the session via the API.
  /// Throws on duplicate lot numbers (server-enforced unique constraint).
  Future<bool> addItem(ItemDraft draft) async {
    final session = state.session;
    if (session == null || draft.product == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      // Client-side duplicate check before hitting the network.
      final lot = draft.scannedLotNumber?.trim() ?? '';
      if (lot.isNotEmpty) {
        final dup = state.items.any(
          (i) =>
              (i.scannedLotNumber ?? i.lot?.lotNumber ?? '').toLowerCase() ==
              lot.toLowerCase(),
        );
        if (dup) {
          state = state.copyWith(
            isSaving: false,
            error:
                'Lot number "$lot" already exists in this session.',
          );
          return false;
        }
      }

      final created = await _repo.addItem(
        session.id,
        productId: draft.product!.id,
        supplierBatchCode: draft.supplierBatchCode.trim(),
        scannedLotNumber: draft.missingLotFlag
            ? null
            : (draft.scannedLotNumber?.trim().isEmpty ?? true
                ? null
                : draft.scannedLotNumber!.trim()),
        expiryDate: draft.expiryDate,
        lotEntryMode: draft.lotEntryMode,
        expiryEntryMode: draft.expiryEntryMode,
        missingLotFlag: draft.missingLotFlag,
        sourceBarcode: draft.sourceBarcode,
        entryOverrideReason: draft.entryOverrideReason,
      );

      state = state.copyWith(
        items: [...state.items, created],
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> removeItem(int itemId) async {
    final session = state.session;
    if (session == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.deleteItem(session.id, itemId);
      state = state.copyWith(
        items: state.items.where((i) => i.id != itemId).toList(),
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> finalize() async {
    final session = state.session;
    if (session == null) return false;
    if (state.items.isEmpty) {
      state = state.copyWith(
        error: 'Add at least one item before finalizing the session.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final result = await _repo.finalizeSession(session.id);
      state = state.copyWith(
        isSaving: false,
        session: result.session,
        finalizeResult: result,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

/// Per-session controller. Use `.family(sessionId)`.
final stockInSessionControllerProvider = StateNotifierProvider.autoDispose
    .family<StockInSessionController, StockInSessionState, int>(
        (ref, sessionId) {
  return StockInSessionController(ref, sessionId);
});

/// Local-only draft notifier for the in-progress item being scanned.
class ItemDraftNotifier extends StateNotifier<ItemDraft> {
  ItemDraftNotifier() : super(const ItemDraft());

  void setProduct(ProductModel product) =>
      state = state.copyWith(product: product);

  void setLot({
    required String lotNumber,
    LotEntryMode mode = LotEntryMode.scan,
  }) {
    state = state.copyWith(
      scannedLotNumber: lotNumber,
      lotEntryMode: mode,
      missingLotFlag: false,
      clearLot: false,
    );
  }

  void setMissingLot(bool value) {
    state = state.copyWith(
      missingLotFlag: value,
      clearLot: value,
      lotEntryMode: value ? LotEntryMode.manual : state.lotEntryMode,
    );
  }

  void setExpiry({
    required DateTime date,
    LotEntryMode mode = LotEntryMode.scan,
  }) {
    state =
        state.copyWith(expiryDate: date, expiryEntryMode: mode);
  }

  void clearExpiry() => state = state.copyWith(clearExpiry: true);

  void setBatch(String value) =>
      state = state.copyWith(supplierBatchCode: value);

  void setOverrideReason(String? reason) =>
      state = state.copyWith(entryOverrideReason: reason);

  void setSourceBarcode(String? value) =>
      state = state.copyWith(sourceBarcode: value);

  void reset() => state = const ItemDraft();
}

final itemDraftProvider =
    StateNotifierProvider.autoDispose<ItemDraftNotifier, ItemDraft>(
  (ref) => ItemDraftNotifier(),
);
