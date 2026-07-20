import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/disposal_models.dart';

class DisposalStatusBadge extends StatelessWidget {
  const DisposalStatusBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => StatusBadge(
    label: status == 'completed' ? 'Completed' : 'Draft',
    status: status == 'completed' ? BadgeStatus.success : BadgeStatus.warning,
  );
}

class DisposalListTile extends StatelessWidget {
  const DisposalListTile({super.key, required this.disposal, this.onTap});
  final DisposalModel disposal;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
    child: ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  disposal.disposalNo,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DisposalStatusBadge(status: disposal.status),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'Disposal date: ${disposal.disposedAt == null ? '-' : DateFormatter.toDisplay(disposal.disposedAt!)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${disposal.itemsCount ?? disposal.items.length} lot(s) · PIC: ${disposal.picUser?.fullName ?? '-'}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}

class DisposalItemTile extends StatelessWidget {
  const DisposalItemTile({super.key, required this.item});
  final DisposalItemModel item;
  @override
  Widget build(BuildContext context) => ContentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.lot?.lotNumber ?? 'Lot #${item.lotId}',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'Qty ${item.quantity}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(item.lot?.productName ?? '-', style: AppTextStyles.bodySmall),
        if (item.lot?.refNum?.isNotEmpty == true)
          Text(
            item.lot!.refNum!,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        const Divider(height: 20),
        Text(
          'Category: ${_title(item.disposalCategory)}',
          style: AppTextStyles.labelMedium,
        ),
        const SizedBox(height: 3),
        Text('Reason: ${item.reasonText}', style: AppTextStyles.bodySmall),
        if (item.remarks?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 3),
          Text(
            'Remarks: ${item.remarks}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );

  String _title(String value) => value
      .split('_')
      .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');
}

class DisposalInfoRow extends StatelessWidget {
  const DisposalInfoRow({super.key, required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
