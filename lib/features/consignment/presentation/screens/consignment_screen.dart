import 'package:flutter/material.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

class ConsignmentScreen extends StatelessWidget {
  const ConsignmentScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Consignment',
        icon: Icons.local_shipping_rounded,
        description: 'Manage outgoing shipments and consignment records for distributors.',
      );
}
