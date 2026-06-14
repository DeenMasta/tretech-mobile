import 'package:flutter/material.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

class QrPrintingScreen extends StatelessWidget {
  const QrPrintingScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'QR Printing',
        icon: Icons.qr_code_2_rounded,
        description: 'Generate and print QR labels via Bluetooth thermal printer. Supports batch printing.',
      );
}
