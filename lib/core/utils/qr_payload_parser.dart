import 'dart:convert';

/// Extracts the lot number from current and legacy stock-in QR-label payloads.
///
/// A non-QR value is returned unchanged so callers can also use normal text
/// searches (product name, reference number, or lot number).
abstract final class QrPayloadParser {
  static String lotNumberOrRaw(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return value;

    try {
      final json = jsonDecode(value);
      if (json is Map) {
        final lot = json['lot_number']?.toString().trim();
        if (lot?.isNotEmpty == true) return lot!;
      }
    } catch (_) {
      // Continue with compact and legacy QR-label payload formats.
    }

    final match = RegExp(
      r'(?:^|;)LOT[=:]([^;]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (match?.group(1)?.trim().isNotEmpty == true) {
      return match!.group(1)!.trim();
    }

    // Legacy labels can start with the lot number followed by metadata.
    var parsed = value.split(';').first.trim();
    if (parsed.contains('MFG=')) parsed = parsed.split('MFG=').first.trim();
    if (parsed.contains('EXP=')) parsed = parsed.split('EXP=').first.trim();
    return parsed;
  }
}
