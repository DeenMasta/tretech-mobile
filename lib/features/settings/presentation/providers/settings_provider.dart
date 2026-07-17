import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/printer_settings_model.dart';
import '../../data/repositories/settings_repository.dart';

class SettingsNotifier extends Notifier<PrinterSettingsModel> {
  late final SettingsRepository _repo;

  @override
  PrinterSettingsModel build() {
    _repo = ref.watch(_settingsRepoProvider);
    _load();
    return const PrinterSettingsModel.empty();
  }

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
    NotifierProvider<SettingsNotifier, PrinterSettingsModel>(SettingsNotifier.new);
