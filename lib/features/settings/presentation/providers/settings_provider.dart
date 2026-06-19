import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/printer_settings_model.dart';
import '../../data/repositories/settings_repository.dart';

class SettingsNotifier extends StateNotifier<PrinterSettingsModel> {
  SettingsNotifier(this._repo) : super(const PrinterSettingsModel.empty()) {
    _load();
  }

  final SettingsRepository _repo;

  Future<void> _load() async {
    state = await _repo.load();
  }

  Future<void> savePrinter({
    required String printerName,
    required String macAddress,
  }) async {
    final updated = PrinterSettingsModel(
      printerName: printerName,
      macAddress: macAddress,
    );
    await _repo.save(updated);
    state = updated;
  }

  Future<void> clearPrinter() async {
    await _repo.clear();
    state = const PrinterSettingsModel.empty();
  }
}

final _settingsRepoProvider = Provider<SettingsRepository>(
  (_) => SettingsRepository(),
);

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, PrinterSettingsModel>((ref) {
  return SettingsNotifier(ref.watch(_settingsRepoProvider));
});
