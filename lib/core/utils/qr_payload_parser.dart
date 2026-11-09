import 'dart:convert';

/// Extracts the lot number from current and legacy stock-in QR-label payloads.
///
/// A non-QR value is returned unchanged so callers can also use normal text
/// searches (product name, reference number, or lot number).
abstract final class QrPayloadParser {
  /// Extracts the immutable identity fields from a stock-in QR payload.
  ///
  /// A manually entered lot number remains supported with a null reference.
  static ({String lotNumber, String? refNum}) lotAndRefOrRaw(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return (lotNumber: value, refNum: null);

    try {
      final json = jsonDecode(value);
      if (json is Map) {
        final lot = json['lot_number']?.toString().trim();
        if (lot?.isNotEmpty == true) {
          final ref = json['ref_num']?.toString().trim() ??
              json['reference']?.toString().trim();
          return (lotNumber: lot!, refNum: ref?.isNotEmpty == true ? ref : null);
        }
      }
    } catch (_) {
      // Continue with compact and legacy QR-label payload formats.
    }

    final lotMatch = RegExp(
      r'(?:^|;)LOT[=:]([^;]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (lotMatch?.group(1)?.trim().isNotEmpty == true) {
      final ref = RegExp(
        r'(?:^|;)REF[=:]([^;]+)',
        caseSensitive: false,
      ).firstMatch(value)?.group(1)?.trim();
      return (lotNumber: lotMatch!.group(1)!.trim(), refNum: ref?.isNotEmpty == true ? ref : null);
    }

    // Legacy labels can start with the lot number followed by metadata.
    var parsed = value.split(';').first.trim();
    if (parsed.contains('MFG=')) parsed = parsed.split('MFG=').first.trim();
    if (parsed.contains('EXP=')) parsed = parsed.split('EXP=').first.trim();
    return (lotNumber: parsed, refNum: null);
  }

  static String lotNumberOrRaw(String rawValue) {
    return lotAndRefOrRaw(rawValue).lotNumber;
  }

  static String refNumberOrRaw(String rawValue) {
    final parsed = lotAndRefOrRaw(rawValue);
    return parsed.refNum ?? rawValue.trim();
  }
}
