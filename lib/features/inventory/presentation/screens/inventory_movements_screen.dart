import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/module_app_bar.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_movement_tile.dart';

class InventoryMovementsScreen extends ConsumerStatefulWidget {
  const InventoryMovementsScreen({super.key, required this.lotId});

  final int lotId;

  @override
  ConsumerState<InventoryMovementsScreen> createState() =>
      _InventoryMovementsScreenState();
}

class _InventoryMovementsScreenState
    extends ConsumerState<InventoryMovementsScreen> {
  InventoryMovementsQuery _query = const InventoryMovementsQuery();

  @override
  Widget build(BuildContext context) {
    final movementAsync = ref.watch(
      inventoryMovementsProvider((lotId: widget.lotId, query: _query)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModuleAppBar(title: 'Lot Movements'),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: movementAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(
                  inventoryMovementsProvider((
                    lotId: widget.lotId,
                    query: _query,
                  )),
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return Center(
                    child: Text(
                      'No movements found.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.spaceLg),
                  itemCount: page.items.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDimensions.spaceSm),
                  itemBuilder: (_, index) {
                    if (index == page.items.length) {
                      return _pagination(page.currentPage, page.lastPage);
                    }
                    return InventoryMovementTile(movement: page.items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceSm,
            children: [
              _chip('All', ''),
              _chip('Stock In', 'stock_in'),
              _chip('Consigned', 'consigned'),
              _chip('Returned', 'returned'),
              _chip('Used', 'used'),
              _chip('Returned to Supplier', 'returned_to_supplier'),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (picked == null) return;
                    setState(() {
                      _query = _query.copyWith(
                        fromDate: DateFormatter.toApi(picked),
                        page: 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.event_rounded),
                  label: Text(_query.fromDate ?? 'From Date'),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (picked == null) return;
                    setState(() {
                      _query = _query.copyWith(
                        toDate: DateFormatter.toApi(picked),
                        page: 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.event_available_rounded),
                  label: Text(_query.toDate ?? 'To Date'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _query.movementType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _query = _query.copyWith(movementType: value, page: 1);
        });
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
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
