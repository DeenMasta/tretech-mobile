import 'package:flutter/material.dart';
import 'stock_in_list_screen.dart';

export 'stock_in_list_screen.dart';

/// Backwards-compatible alias for the routing layer.
/// The real implementation lives in [StockInListScreen].
class StockInScreen extends StatelessWidget {
  const StockInScreen({super.key});

  @override
  Widget build(BuildContext context) => const StockInListScreen();
}
