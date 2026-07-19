import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../data/models/inventory_unit_model.dart';
import 'inventory_status_badge.dart';

class InventoryUnitTile extends StatelessWidget {
  const InventoryUnitTile({super.key, required this.unit, this.onTap});

  final InventoryUnitModel unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.lotNumber,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceXxs),
                      Text(
                        unit.product?.productName ?? '-',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        unit.product?.refNum ?? '-',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                InventoryStatusBadge(status: unit.status),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Wrap(
              spacing: AppDimensions.spaceLg,
              runSpacing: AppDimensions.spaceXs,
              children: [
                _meta('Supplier', unit.supplier?.supplierName ?? '-'),
                _meta(
                  'Expiry',
                  unit.expiryDate == null
                      ? '-'
                      : DateFormatter.toDisplay(unit.expiryDate!),
                ),
                _meta('Qty', '${unit.quantityAvailable ?? unit.quantity ?? 0}'),
              ],
            ),
          ],
        ),
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
