import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/module_app_bar.dart';
import '../../../stock_in/data/models/supplier_model.dart';
import '../../../stock_in/data/repositories/master_data_repository.dart';
import '../../../stock_in/presentation/widgets/product_search_sheet.dart';
import '../../../stock_in/presentation/widgets/supplier_search_sheet.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_unit_tile.dart';

class InventoryAllLotsScreen extends ConsumerStatefulWidget {
  const InventoryAllLotsScreen({super.key});

  @override
  ConsumerState<InventoryAllLotsScreen> createState() =>
      _InventoryAllLotsScreenState();
}

class _InventoryAllLotsScreenState
    extends ConsumerState<InventoryAllLotsScreen> {
  InventoryUnitsQuery _query = const InventoryUnitsQuery();
  late final TextEditingController _searchCtl;

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _applySearch() {
    setState(() {
      _query = _query.copyWith(search: _searchCtl.text.trim(), page: 1);
    });
  }

  Future<void> _pickSupplier() async {
    final repo = ref.read(stockInMasterDataRepositoryProvider);
    final SupplierModel? supplier = await SupplierSearchSheet.show(
      context,
      repository: repo,
      title: 'Filter by supplier',
    );
    if (supplier == null) return;

    setState(() {
      _query = _query.copyWith(
        supplierId: supplier.id,
        supplierName: supplier.supplierName,
        page: 1,
      );
    });
  }

  Future<void> _pickProduct() async {
    final product = await ProductSearchSheet.show(context);
    if (product == null) return;

    setState(() {
      _query = _query.copyWith(
        productId: product.id,
        productName: '${product.refNum} - ${product.productName}',
        page: 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lotsAsync = ref.watch(inventoryUnitsProvider(_query));
    if (_searchCtl.text != _query.search) {
      _searchCtl.value = TextEditingValue(
        text: _query.search,
        selection: TextSelection.collapsed(offset: _query.search.length),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'All Lots',
        onBack: () => context.go(RouteNames.inventory),
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: lotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(inventoryUnitsProvider(_query)),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return Center(
                    child: Text(
                      'No lots found for current filters.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(inventoryUnitsProvider(_query));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.spaceLg),
                    itemBuilder: (_, index) {
                      if (index == page.items.length) {
                        return _buildPagination(
                          page.currentPage,
                          page.lastPage,
                        );
                      }
                      final lot = page.items[index];
                      return InventoryUnitTile(
                        unit: lot,
                        onTap: () => context.push(
                          RouteNames.inventoryDetailPath(lot.id),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimensions.spaceSm),
                    itemCount: page.items.length + 1,
                  ),
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
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceLg,
        AppDimensions.spaceMd,
        AppDimensions.spaceLg,
        AppDimensions.spaceMd,
      ),
      child: Column(
        children: [
          AppTextField(
            controller: _searchCtl,
            hint: 'Search lot number or product name',
            textInputAction: TextInputAction.search,
            prefixIcon: Icons.search_rounded,
            onSubmitted: (_) => _applySearch(),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('All', 'all'),
                const SizedBox(width: AppDimensions.spaceSm),
                _chip('Available', 'available'),
                const SizedBox(width: AppDimensions.spaceSm),
                _chip('Holding', 'holding'),
                const SizedBox(width: AppDimensions.spaceSm),
                _chip('Supplied', 'supplied'),
                const SizedBox(width: AppDimensions.spaceSm),
                _chip('Used', 'used'),
                const SizedBox(width: AppDimensions.spaceSm),
                _chip('Disposed', 'disposed'),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickSupplier,
                icon: const Icon(Icons.business_rounded),
                label: Text(_query.supplierName ?? 'Supplier'),
              ),
              TextButton.icon(
                onPressed: _pickProduct,
                icon: const Icon(Icons.category_rounded),
                label: Text(_query.productName ?? 'Product'),
              ),
              if (_query.supplierId != null || _query.productId != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _query = _query.copyWith(
                        clearSupplier: true,
                        clearProduct: true,
                        page: 1,
                      );
                    });
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
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
                        expiryFrom: DateFormatter.toApi(picked),
                        page: 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(_query.expiryFrom ?? 'Expiry From'),
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
                        expiryTo: DateFormatter.toApi(picked),
                        page: 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.event_available_rounded),
                  label: Text(_query.expiryTo ?? 'Expiry To'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _query.status == value;
    return InkWell(
      onTap: () {
        setState(() {
          _query = _query.copyWith(status: value, page: 1);
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

  Widget _buildPagination(int current, int last) {
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
