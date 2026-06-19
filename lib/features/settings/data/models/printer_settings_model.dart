/// Holds the saved Bluetooth printer configuration.
class PrinterSettingsModel {
  const PrinterSettingsModel({
    required this.printerName,
    required this.macAddress,
  });

  /// No printer configured.
  const PrinterSettingsModel.empty()
      : printerName = '',
        macAddress = '';

  final String printerName;
  final String macAddress;

  bool get isConfigured => macAddress.isNotEmpty;

  PrinterSettingsModel copyWith({String? printerName, String? macAddress}) {
    return PrinterSettingsModel(
      printerName: printerName ?? this.printerName,
      macAddress: macAddress ?? this.macAddress,
    );
  }

  @override
  String toString() =>
      'PrinterSettingsModel(name: $printerName, mac: $macAddress)';
}
