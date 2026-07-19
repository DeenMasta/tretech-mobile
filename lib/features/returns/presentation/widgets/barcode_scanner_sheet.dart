import 'package:flutter/material.dart';
import '../../../stock_in/presentation/widgets/barcode_scanner_sheet.dart';

/// Thin adapter so the returns module can use the shared BarcodeScannerSheet
/// and get back a plain String (the lot number / QR payload).
abstract final class ReturnBarcodeScannerSheet {
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String helperText,
  }) async {
    final result = await BarcodeScannerSheet.show(
      context,
      title: title,
      helperText: helperText,
    );
    return result?.value;
  }
}
