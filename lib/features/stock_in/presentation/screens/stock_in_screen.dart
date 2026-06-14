import 'package:flutter/material.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

class StockInScreen extends StatelessWidget {
  const StockInScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Stock In',
        icon: Icons.inventory_2_rounded,
        description: 'Record incoming stock, scan barcodes, and process received items from suppliers.',
      );
}
