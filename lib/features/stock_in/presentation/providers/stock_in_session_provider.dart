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
    this.manufacturingDate,
    this.expiryDate,
    this.quantity = 1,
    this.lotEntryMode = LotEntryMode.scan,
    this.expiryEntryMode = LotEntryMode.scan,
    this.missingLotFlag = false,
    this.generateLotNumber = false,
    this.entryOverrideReason,
    this.sourceBarcode,
    this.remarks,
  });

  final ProductModel? product;
  final String? scannedLotNumber;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;
  final int quantity;
  final LotEntryMode lotEntryMode;
  final LotEntryMode expiryEntryMode;
  final bool missingLotFlag;
  final bool generateLotNumber;
  final String? entryOverrideReason;
  final String? sourceBarcode;
  final String? remarks;

  bool get hasProduct => product != null;
  bool get requiresLot => product?.requiresLot ?? true;
  bool get hasLot =>
      (scannedLotNumber?.isNotEmpty ?? false) ||
      missingLotFlag ||
      generateLotNumber;
  bool get lotSatisfied => !requiresLot || hasLot;
  bool get hasExpiry => expiryDate != null;

  bool get readyToSubmit => hasProduct && lotSatisfied;

  bool get requiresOverrideReason =>
      missingLotFlag ||
      lotEntryMode == LotEntryMode.manual ||
      expiryEntryMode == LotEntryMode.manual;

  ItemDraft copyWith({
    ProductModel? product,
    String? scannedLotNumber,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    int? quantity,
    LotEntryMode? lotEntryMode,
    LotEntryMode? expiryEntryMode,
    bool? missingLotFlag,
    bool? generateLotNumber,
    String? entryOverrideReason,
    String? sourceBarcode,
    String? remarks,
    bool clearProduct = false,
    bool clearLot = false,
    bool clearExpiry = false,
  }) {
    return ItemDraft(
      product: clearProduct ? null : (product ?? this.product),
      scannedLotNumber: clearLot
          ? null
          : (scannedLotNumber ?? this.scannedLotNumber),
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      quantity: quantity ?? this.quantity,
      lotEntryMode: lotEntryMode ?? this.lotEntryMode,
      expiryEntryMode: expiryEntryMode ?? this.expiryEntryMode,
      missingLotFlag: missingLotFlag ?? this.missingLotFlag,
      generateLotNumber: generateLotNumber ?? this.generateLotNumber,
      entryOverrideReason: entryOverrideReason ?? this.entryOverrideReason,
      sourceBarcode: sourceBarcode ?? this.sourceBarcode,
      remarks: remarks ?? this.remarks,
    );
  }
}

class StockInSessionController extends Notifier<StockInSessionState> {
  StockInSessionController(this._sessionId);
  final int _sessionId;
  bool _initialLoadStarted = false;

  @override
  StockInSessionState build() {
    if (!_initialLoadStarted) {
      _initialLoadStarted = true;
      Future<void>.microtask(_load);
    }
    return const StockInSessionState(isLoading: true);
  }

  StockInRepository get _repo => ref.read(stockInRepositoryProvider);

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repo.getSession(_sessionId);
      final items = session.items ?? await _repo.listItems(_sessionId);
      state = state.copyWith(session: session, items: items, isLoading: false);
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
            error: 'Lot number "$lot" already exists in this session.',
          );
          return false;
        }
      }

      final created = await _repo.addItem(
        session.id,
        entryKind: StockInEntryKind.product,
        productId: draft.product!.id,
        scannedLotNumber: draft.missingLotFlag || draft.generateLotNumber
            ? null
            : (draft.scannedLotNumber?.trim().isEmpty ?? true
                  ? null
                  : draft.scannedLotNumber!.trim()),
        manufacturingDate: draft.manufacturingDate,
        expiryDate: draft.expiryDate,
        quantity: draft.quantity,
        lotEntryMode: draft.lotEntryMode,
        expiryEntryMode: draft.expiryEntryMode,
        missingLotFlag: draft.missingLotFlag,
        generateLotNumber: draft.generateLotNumber,
        sourceBarcode: draft.sourceBarcode,
        entryOverrideReason: draft.entryOverrideReason,
        remarks: draft.remarks,
      );

      state = state.copyWith(items: [...state.items, created], isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> addSetItem({
    required int instrumentSetId,
    required List<StockInComponentLotDecision> componentLots,
    int quantity = 1,
    String? remarks,
  }) async {
    final session = state.session;
    if (session == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final created = await _repo.addItem(
        session.id,
        entryKind: StockInEntryKind.set,
        instrumentSetId: instrumentSetId,
        componentLots: componentLots,
        quantity: quantity,
        remarks: remarks,
      );
      state = state.copyWith(items: [...state.items, created], isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateItem(
    int itemId, {
    required int productId,
    String? scannedLotNumber,
    bool clearLot = false,
    DateTime? expiryDate,
    DateTime? manufacturingDate,
    int? quantity,
    bool clearExpiry = false,
    LotEntryMode lotEntryMode = LotEntryMode.scan,
    LotEntryMode expiryEntryMode = LotEntryMode.scan,
    bool missingLotFlag = false,
    bool generateLotNumber = false,
    String? entryOverrideReason,
    String? remarks,
  }) async {
    final session = state.session;
    if (session == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repo.updateItem(
        session.id,
        itemId,
        productId: productId,
        scannedLotNumber: scannedLotNumber,
        clearLot: clearLot,
        expiryDate: expiryDate,
        manufacturingDate: manufacturingDate,
        quantity: quantity,
        clearExpiry: clearExpiry,
        lotEntryMode: lotEntryMode,
        expiryEntryMode: expiryEntryMode,
        missingLotFlag: missingLotFlag,
        generateLotNumber: generateLotNumber,
        entryOverrideReason: entryOverrideReason,
        remarks: remarks,
      );
      state = state.copyWith(
        items: state.items.map((i) => i.id == itemId ? updated : i).toList(),
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateSetItem(
    int itemId, {
    required List<StockInComponentLotDecision> componentLots,
    int? quantity,
    String? remarks,
  }) async {
    final session = state.session;
    if (session == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repo.updateItem(
        session.id,
        itemId,
        componentLots: componentLots,
        quantity: quantity,
        remarks: remarks,
      );
      state = state.copyWith(
        items: state.items.map((i) => i.id == itemId ? updated : i).toList(),
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

  Future<bool> correctItem(
    int itemId, {
    String? lotNumber,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    required String adminReason,
  }) async {
    final session = state.session;
    if (session == null) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final corrected = await _repo.correctItem(
        session.id,
        itemId,
        lotNumber: lotNumber,
        manufacturingDate: manufacturingDate,
        expiryDate: expiryDate,
        adminReason: adminReason,
      );
      state = state.copyWith(
        items: state.items
            .map((item) => item.id == itemId ? corrected : item)
            .toList(),
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
final stockInSessionControllerProvider = NotifierProvider.autoDispose
    .family<StockInSessionController, StockInSessionState, int>(
      StockInSessionController.new,
    );

/// Local-only draft notifier for the in-progress item being scanned.
class ItemDraftNotifier extends Notifier<ItemDraft> {
  @override
  ItemDraft build() {
    return const ItemDraft();
  }

  void setProduct(ProductModel product) => state = ItemDraft(product: product);

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
    state = state.copyWith(expiryDate: date, expiryEntryMode: mode);
  }

  void clearExpiry() => state = state.copyWith(clearExpiry: true);

  void setOverrideReason(String? reason) =>
      state = state.copyWith(entryOverrideReason: reason);

  void setSourceBarcode(String? value) =>
      state = state.copyWith(sourceBarcode: value);

  void setRemarks(String? value) => state = state.copyWith(remarks: value);

  void reset() => state = const ItemDraft();
}

final itemDraftProvider =
    NotifierProvider.autoDispose<ItemDraftNotifier, ItemDraft>(
      ItemDraftNotifier.new,
    );
