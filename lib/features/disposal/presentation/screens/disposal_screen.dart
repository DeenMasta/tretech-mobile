import 'package:flutter/material.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

class DisposalScreen extends StatelessWidget {
  const DisposalScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Disposal',
        icon: Icons.delete_sweep_rounded,
        description: 'Record and manage disposal of expired, damaged, or obsolete inventory items.',
      );
}
