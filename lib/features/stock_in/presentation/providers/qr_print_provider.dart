import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/services/bluetooth_print_service.dart';
import '../../data/models/stock_in_item_model.dart';
import '../../data/repositories/qr_print_repository.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Tracks the state of a batch print operation.
class QrPrintJobState {
  const QrPrintJobState({
    this.isPrinting = false,
    this.printed = 0,
    this.total = 0,
    this.errors = const [],
    this.isDone = false,
  });

  final bool isPrinting;
  final int printed;
  final int total;
  final List<String> errors;
  final bool isDone;

  bool get hasErrors => errors.isNotEmpty;

  QrPrintJobState copyWith({
    bool? isPrinting,
    int? printed,
    int? total,
    List<String>? errors,
    bool? isDone,
  }) {
    return QrPrintJobState(
      isPrinting: isPrinting ?? this.isPrinting,
      printed: printed ?? this.printed,
      total: total ?? this.total,
      errors: errors ?? this.errors,
      isDone: isDone ?? this.isDone,
    );
  }
}

/// Drives a batch "print selected lots" workflow:
/// 1. For each selected lot: POST /print-jobs to get TSPL.
/// 2. Send TSPL via Bluetooth.
/// 3. PATCH /print-jobs/{id}/mark-printed or mark-failed.
class QrPrintNotifier extends StateNotifier<QrPrintJobState> {
  QrPrintNotifier(this._ref) : super(const QrPrintJobState());

  final Ref _ref;

  QrPrintRepository get _repo => _ref.read(qrPrintRepositoryProvider);
  BluetoothPrintService get _bt => _ref.read(bluetoothPrintServiceProvider);

  /// Prints only the provided [items] (those with a valid lotId).
  /// [macAddress] — the Bluetooth MAC to print to.
  Future<void> printSelected(
    List<StockInItemModel> items,
    String macAddress,
  ) async {
    // Only items that have a resolved lotId (non-holding, product entries).
    final printable =
        items.where((i) => i.lotId != null && !i.missingLotFlag).toList();

    if (printable.isEmpty) {
      state = const QrPrintJobState(isDone: true, errors: [
        'No printable lots found. Ensure items have resolved lot numbers.',
      ]);
      return;
    }

    state = QrPrintJobState(
      isPrinting: true,
      total: printable.length,
      printed: 0,
    );

    final errors = <String>[];

    // Connect to printer once for the whole batch
    final connected = await _bt.connect(macAddress);
    if (!connected) {
      state = state.copyWith(
        isPrinting: false,
        isDone: true,
        errors: ['Could not connect to printer $macAddress.'],
      );
      return;
    }

    try {
      for (final item in printable) {
        final lotId = item.lotId!;
        final label = item.productLabel;
        try {
          // Create print job and get TSPL from backend.
          final job = await _repo.createPrintJob(
            lotId: lotId,
            printerName: _ref.read(settingsProvider).printerName,
            deviceId: macAddress,
          );

          var tspl = job.tsplPayload;
          if (tspl == null || tspl.isEmpty) {
            errors.add('$label: No TSPL payload returned from server.');
            await _repo.markFailed(job.id, errorMessage: 'Empty TSPL payload');
            state = state.copyWith(printed: state.printed + 1);
            continue;
          }

          // HOTFIX: Rewrite only legacy JSON-based QR payloads before printing.
          try {
            // Fix legacy JSON inner quotes in old backend payloads.
            tspl = tspl.replaceFirstMapped(RegExp(r'QRCODE(.*?),"(\{.*?\})"'), (match) {
              final prefix = match.group(1);
              final jsonStr = match.group(2);
              if (jsonStr != null) {
                // If it contains escaped quotes, unescape them first just in case
                final cleanJson = jsonStr.replaceAll(r'\"', '"');
                final data = jsonDecode(cleanJson) as Map<String, dynamic>;
                final ref = data['product_ref'] ?? data['set_code'] ?? '';
                final lot = data['lot_number'] ?? '';
                final mfg = data['manufacturing_date'] ?? data['batch_code'] ?? '-';
                final exp = data['expiry_date'] ?? '-';
                final newPayload = 'V=1;REF=$ref;LOT=$lot;MFG=$mfg;EXP=$exp';
                return 'QRCODE$prefix,"$newPayload"';
              }
              return match.group(0)!;
            });
          } catch (_) {
            // Ignore if JSON parsing fails, just send the original payload
          }

          // Send to printer using the existing connection.
          final result = await _bt.writeTspl(tspl!);
          if (result.success) {
            await _repo.markPrinted(job.id);
            // Brief delay to allow printer buffer to process before sending the next
            await Future<void>.delayed(const Duration(milliseconds: 200));
          } else {
            errors.add('$label: ${result.error ?? 'Print failed'}');
            await _repo.markFailed(job.id, errorMessage: result.error);
          }
        } catch (e) {
          errors.add('$label: $e');
        }

        state = state.copyWith(printed: state.printed + 1, errors: errors);
      }
    } finally {
      // Disconnect when batch is done
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _bt.disconnect();
    }

    state = state.copyWith(isPrinting: false, isDone: true, errors: errors);
  }

  void reset() => state = const QrPrintJobState();
}

final qrPrintNotifierProvider =
    StateNotifierProvider.autoDispose<QrPrintNotifier, QrPrintJobState>((ref) {
  return QrPrintNotifier(ref);
});
