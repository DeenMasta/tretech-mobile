import 'package:shared_preferences/shared_preferences.dart';
import '../models/printer_settings_model.dart';

/// Persists [PrinterSettingsModel] to [SharedPreferences].
class SettingsRepository {
  static const _keyPrinterName = 'printer_name';
  static const _keyMacAddress = 'printer_mac';

  Future<PrinterSettingsModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyPrinterName) ?? '';
    final mac = prefs.getString(_keyMacAddress) ?? '';
    return PrinterSettingsModel(printerName: name, macAddress: mac);
  }

  Future<void> save(PrinterSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrinterName, settings.printerName);
    await prefs.setString(_keyMacAddress, settings.macAddress);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrinterName);
    await prefs.remove(_keyMacAddress);
  }
}
