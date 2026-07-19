import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../data/models/inventory_movement_model.dart';
import 'inventory_status_badge.dart';

class InventoryMovementTile extends StatelessWidget {
  const InventoryMovementTile({super.key, required this.movement});

  final InventoryMovementModel movement;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  movement.lot?.lotNumber ?? 'Lot #${movement.lotId}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InventoryStatusBadge(status: movement.movementType),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            movement.performedAt == null
                ? '-'
                : DateFormatter.toDisplayDateTime(movement.performedAt!),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Wrap(
            spacing: AppDimensions.spaceLg,
            runSpacing: AppDimensions.spaceXs,
            children: [
              _meta('From', movement.fromStatus ?? '-'),
              _meta('To', movement.toStatus ?? '-'),
              _meta('By', movement.performedByUser?.fullName ?? '-'),
            ],
          ),
          if ((movement.remarks ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceSm),
            Text(
              movement.remarks!.trim(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _meta(String label, String value) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.labelSmall,
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
