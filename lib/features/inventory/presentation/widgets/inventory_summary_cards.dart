import 'package:flutter/material.dart';

import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/widgets/kpi_card.dart';
import '../../data/models/inventory_summary_model.dart';

class InventorySummaryCards extends StatelessWidget {
  const InventorySummaryCards({super.key, required this.summary});

  final InventorySummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppDimensions.spaceMd,
      mainAxisSpacing: AppDimensions.spaceMd,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        KpiCard(
          title: 'Total Lots',
          value: '${summary.total}',
          subtitle: 'All inventory units',
          icon: Icons.inventory_2_rounded,
        ),
        KpiCard(
          title: 'Available',
          value: '${summary.available}',
          subtitle: 'Ready for use',
          icon: Icons.check_circle_outline_rounded,
        ),
        KpiCard(
          title: 'Holding',
          value: '${summary.holding}',
          subtitle: 'Pending assignment',
          icon: Icons.archive_outlined,
        ),
        KpiCard(
          title: 'Supplied',
          value: '${summary.supplied}',
          subtitle: 'Moved to clients',
          icon: Icons.local_shipping_outlined,
        ),
        KpiCard(
          title: 'Used',
          value: '${summary.used}',
          subtitle: 'Consumed',
          icon: Icons.science_outlined,
        ),
        KpiCard(
          title: 'Disposed',
          value: '${summary.disposed}',
          subtitle: 'Removed stock',
          icon: Icons.delete_sweep_outlined,
        ),
      ],
    );
  }
}
