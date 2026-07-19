import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/module_app_bar.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_status_badge.dart';

class InventoryDetailScreen extends ConsumerWidget {
  const InventoryDetailScreen({
    super.key,
    required this.lotId,
  });

  final int lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotAsync = ref.watch(inventoryUnitDetailProvider(lotId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Lot Detail',
        onBack: () => context.go(RouteNames.inventoryAllLots),
      ),
      body: lotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(inventoryUnitDetailProvider(lotId)),
        ),
        data: (lot) {
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lot.lotNumber,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceXs),
                        Text(
                          lot.product?.productName ?? 'Inventory lot',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InventoryStatusBadge(status: lot.status),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              FilledButton.icon(
                onPressed: () =>
                    context.push(RouteNames.inventoryMovementsPath(lot.id)),
                icon: const Icon(Icons.history_rounded),
                label: const Text('View Movements'),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              ContentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lot Context', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _item('Manufacturing Date', lot.manufacturingDate == null
                        ? '-'
                        : DateFormatter.toDisplay(lot.manufacturingDate!)),
                    _item('Expiry Date', lot.expiryDate == null
                        ? '-'
                        : DateFormatter.toDisplay(lot.expiryDate!)),
                    _item('Received At', lot.receivedAt == null
                        ? '-'
                        : DateFormatter.toDisplayDateTime(lot.receivedAt!)),
                    _item('Quantity Available', '${lot.quantityAvailable ?? lot.quantity ?? 0}'),
                    _item('Current Location Type', lot.currentLocationType ?? '-'),
                    _item('Movement Count', '${lot.lotMovementsCount ?? 0}'),
                    _item('Generated Lot', lot.isSystemGeneratedLot ? 'Yes' : 'No'),
                    _item('Remarks', (lot.remarks ?? '').trim().isEmpty ? '-' : lot.remarks!.trim()),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              ContentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product & Supplier', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _item('Product Name', lot.product?.productName ?? '-'),
                    _item('Reference', lot.product?.refNum ?? '-'),
                    _item('Product Type', lot.product?.productType ?? '-'),
                    _item('UOM', lot.product?.uom ?? '-'),
                    _item('Supplier', lot.supplier?.supplierName ?? '-'),
                    _item('Instrument Set', lot.instrumentSet?.setName ?? '-'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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
}
