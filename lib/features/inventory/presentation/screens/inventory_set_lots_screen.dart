import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/module_app_bar.dart';
import '../../data/models/inventory_set_availability_model.dart';
import '../../data/models/inventory_unit_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_unit_tile.dart';

class InventorySetLotsScreen extends ConsumerStatefulWidget {
  const InventorySetLotsScreen({super.key, required this.setId});

  final int setId;

  @override
  ConsumerState<InventorySetLotsScreen> createState() =>
      _InventorySetLotsScreenState();
}

class _InventorySetLotsScreenState
    extends ConsumerState<InventorySetLotsScreen> {
  late InventoryUnitsQuery _query;

  @override
  void initState() {
    super.initState();
    _query = InventoryUnitsQuery(
      instrumentSetId: widget.setId,
      status: 'available',
    );
  }

  @override
  Widget build(BuildContext context) {
    final lotsAsync = ref.watch(inventoryUnitsProvider(_query));
    final setAsync = ref.watch(inventoryInstrumentSetProvider(widget.setId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: ModuleAppBar(
          title: 'Instrument Set Details',
          onBack: () => context.go(RouteNames.inventory),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lots'),
              Tab(text: 'Components'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLotsTab(lotsAsync, setAsync),
            _buildComponentsTab(setAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildLotsTab(
    AsyncValue<PaginatedResult<InventoryUnitModel>> lotsAsync,
    AsyncValue<InventorySetAvailabilityModel> setAsync,
  ) {
    return lotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(inventoryUnitsProvider(_query)),
      ),
      data: (page) {
        final setName = setAsync.value?.setName ?? 'Instrument Set';

        if (page.items.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: [
              Text(
                setName,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXs),
              Text(
                'Set lots available',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXl),
              Center(
                child: Text(
                  'No lots available for this instrument set.',
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
                        setName,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceXs),
                      Text(
                        'Set lots available',
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
      );
  }

  Widget _buildComponentsTab(AsyncValue<InventorySetAvailabilityModel> setAsync) {
    return setAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(inventoryInstrumentSetProvider(widget.setId)),
      ),
      data: (model) {
        final items = model.items ?? [];
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No components configured for this instrument set.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          itemBuilder: (_, index) {
            final item = items[index];
            final product = item.product;
            if (product == null) {
              return ListTile(
                title: Text('Unknown Product (ID: ${item.productId})'),
                trailing: Text('Req: ${item.quantity}'),
              );
            }
            return ListTile(
              onTap: () => context.push(
                RouteNames.inventoryProductLotsPath(product.id),
              ),
              contentPadding: const EdgeInsets.all(AppDimensions.spaceLg),
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                side: BorderSide(color: AppColors.border),
              ),
              title: Text(
                product.productName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(product.refNum, style: AppTextStyles.labelSmall),
              trailing: Text(
                'Required: ${item.quantity}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDimensions.spaceSm),
          itemCount: items.length,
        );
      },
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
