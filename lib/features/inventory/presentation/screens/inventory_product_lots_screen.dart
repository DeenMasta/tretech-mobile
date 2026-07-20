import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/module_app_bar.dart';
import '../../data/models/inventory_product_availability_model.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_unit_tile.dart';

class InventoryProductLotsScreen extends ConsumerStatefulWidget {
  const InventoryProductLotsScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<InventoryProductLotsScreen> createState() =>
      _InventoryProductLotsScreenState();
}

class _InventoryProductLotsScreenState
    extends ConsumerState<InventoryProductLotsScreen> {
  late InventoryUnitsQuery _query;

  @override
  void initState() {
    super.initState();
    _query = InventoryUnitsQuery(
      productId: widget.productId,
      status: 'available',
    );
  }

  @override
  Widget build(BuildContext context) {
    final lotsAsync = ref.watch(inventoryUnitsProvider(_query));
    final productAsync = ref.watch(inventoryProductProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Product Lots',
        onBack: () => context.go(RouteNames.inventory),
      ),
      body: lotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(inventoryUnitsProvider(_query)),
        ),
        data: (page) {
          final productName = productAsync.value?.productName ?? 'Product';
          final productRef = productAsync.value?.refNum ?? '-';

          if (page.items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppDimensions.spaceLg),
              children: [
                Text(
                  productName,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  'Reference: $productRef',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXl),
                Center(
                  child: Text(
                    'No lots available for this product.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            itemBuilder: (_, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceXs),
                      Text(
                        'Reference: $productRef',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (index == page.items.length + 1) {
                return _pagination(page.currentPage, page.lastPage);
              }
              final lot = page.items[index - 1];
              return InventoryUnitTile(
                unit: lot,
                onTap: () =>
                    context.push(RouteNames.inventoryDetailPath(lot.id)),
              );
            },
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDimensions.spaceSm),
            itemCount: page.items.length + 2,
          );
        },
      ),
    );
  }

  Widget _pagination(int current, int last) {
    return Column(
      children: [
        Row(
          children: [
            Text('Rows', style: AppTextStyles.labelSmall),
            const SizedBox(width: AppDimensions.spaceSm),
            DropdownButton<int>(
              value: _query.perPage,
              items: const [10, 20, 50, 100]
                  .map(
                    (value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _query = _query.copyWith(perPage: value, page: 1);
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: current <= 1
                    ? null
                    : () {
                        setState(() {
                          _query = _query.copyWith(page: current - 1);
                        });
                      },
                child: const Text('Previous'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMd,
              ),
              child: Text(
                'Page $current / $last',
                style: AppTextStyles.labelMedium,
              ),
            ),
            Expanded(
              child: OutlinedButton(
                onPressed: current >= last
                    ? null
                    : () {
                        setState(() {
                          _query = _query.copyWith(page: current + 1);
                        });
                      },
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
