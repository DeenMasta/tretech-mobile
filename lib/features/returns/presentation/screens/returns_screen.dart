import 'package:flutter/material.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Returns',
        icon: Icons.assignment_return_rounded,
        description: 'Process customer returns, inspect items, and update inventory status accordingly.',
      );
}
