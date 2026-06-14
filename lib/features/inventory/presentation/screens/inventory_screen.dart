import 'package:flutter/material.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Inventory',
        icon: Icons.warehouse_rounded,
        description: 'Full inventory view with search, filters, stock levels, and item details.',
      );
}
