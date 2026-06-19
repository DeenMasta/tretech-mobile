import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Represents a paired Bluetooth device available for printing.
class BluetoothDevice {
  const BluetoothDevice({required this.name, required this.macAddress});
  final String name;
  final String macAddress;
}

/// Result of a single print operation.
class PrintResult {
  const PrintResult({required this.success, this.error});
  final bool success;
  final String? error;
}

/// Wraps [PrintBluetoothThermal] for sending TSPL commands to a BT printer.
class BluetoothPrintService {
  /// Returns all paired Bluetooth devices on this device.
  Future<List<BluetoothDevice>> listPairedDevices() async {
    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices
          .map((d) => BluetoothDevice(name: d.name, macAddress: d.macAdress))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Connects to a paired Bluetooth device.
  Future<bool> connect(String macAddress) async {
    try {
      return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    } catch (_) {
      return false;
    }
  }

  /// Disconnects from the current Bluetooth device.
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
  }

  /// Sends TSPL bytes to the connected printer.
  Future<PrintResult> writeTspl(String tsplPayload) async {
    try {
      // Split the payload into individual TSPL command lines.
      // The backend joins with \r\n, but if it arrives as one flat string we
      // must re-split carefully — the regex only matches keyword tokens that
      // appear at the start (^) or after whitespace OUTSIDE quoted strings.
      final List<String> lines = _splitTsplLines(tsplPayload);

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        // Convert Uint8List to standard List<int> to avoid Android plugin cast exception
        final bytes = latin1.encode('$line\r\n').toList();
        final ok = await PrintBluetoothThermal.writeBytes(bytes);
        if (!ok) {
          return const PrintResult(
            success: false,
            error: 'Print command was not accepted by printer.',
          );
        }
        // Small delay to allow the printer's receive buffer to process
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      return const PrintResult(success: true);
    } catch (e) {
      return PrintResult(success: false, error: e.toString());
    }
  }

  /// Splits a TSPL payload string into individual command lines.
  ///
  /// If the payload already contains newlines (e.g. \r\n from the backend's
  /// implode), we split on those directly.  Otherwise we walk character-by-
  /// character and insert a split before each TSPL keyword that appears
  /// outside of double-quoted strings.
  List<String> _splitTsplLines(String payload) {
    // The backend uses implode("\r\n", ...) so this is the happy path.
    if (payload.contains('\n')) {
      return payload
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
    }

    // Flat-string fallback: split before top-level TSPL keywords.
    // We walk through and track whether we are inside a " ... " block so
    // that we never split on keywords that appear inside a quoted argument.
    const keywords = [
      'SIZE', 'GAP', 'DIRECTION', 'CLS', 'QRCODE',
      'TEXT', 'PRINT', 'BARCODE', 'BITMAP', 'BOX', 'LINE',
    ];

    final result = <String>[];
    final buf = StringBuffer();
    bool inQuote = false;

    for (int i = 0; i < payload.length; i++) {
      final ch = payload[i];

      if (ch == '"') {
        inQuote = !inQuote;
        buf.write(ch);
        continue;
      }

      if (!inQuote && (ch == ' ' || ch == '\t' || ch == '\r')) {
        // Look ahead to see if the next token is a top-level TSPL keyword.
        final remaining = payload.substring(i + 1);
        bool foundKeyword = false;
        for (final kw in keywords) {
          if (remaining.startsWith(kw) &&
              (remaining.length == kw.length ||
               !RegExp(r'[A-Za-z0-9_]').hasMatch(remaining[kw.length]))) {
            final line = buf.toString().trim();
            if (line.isNotEmpty) result.add(line);
            buf.clear();
            foundKeyword = true;
            break;
          }
        }
        if (!foundKeyword) buf.write(ch);
        continue;
      }

      buf.write(ch);
    }

    final last = buf.toString().trim();
    if (last.isNotEmpty) result.add(last);
    return result;
  }

  /// Connects to [macAddress], prints [tsplPayload], and disconnects.
  Future<PrintResult> printTspl(
    String macAddress,
    String tsplPayload,
  ) async {
    final connected = await connect(macAddress);
    if (!connected) {
      return const PrintResult(
        success: false,
        error: 'Could not connect to printer.',
      );
    }

    final result = await writeTspl(tsplPayload);

    // Short delay to ensure printer receives buffer before disconnect
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await disconnect();

    return result;
  }
}

final bluetoothPrintServiceProvider = Provider<BluetoothPrintService>(
  (_) => BluetoothPrintService(),
);
