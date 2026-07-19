import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../data/models/inventory_product_availability_model.dart';
import '../../data/models/inventory_set_availability_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../providers/inventory_providers.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  InventoryHomeQuery _query = const InventoryHomeQuery();
  late final TextEditingController _searchCtl;
  String _activeTab = 'product';

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

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(inventoryProductsProvider(_query));
    final setsAsync = ref.watch(inventorySetsProvider(_query));

    if (_searchCtl.text != _query.search) {
      _searchCtl.value = TextEditingValue(
        text: _query.search,
        selection: TextSelection.collapsed(offset: _query.search.length),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => context.go(RouteNames.dashboard),
        ),
        title: Text('Inventory', style: AppTextStyles.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        children: [
          Text(
            'Inventory',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'Monitor stock levels, available lots, and movement insights.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          ContentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _searchCtl,
                  hint: _activeTab == 'product'
                      ? 'Search product name or ref number'
                      : 'Search set name or code',
                  textInputAction: TextInputAction.search,
                  prefixIcon: Icons.search_rounded,
                  onSubmitted: (_) => _applySearch(),
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _statusChip('All', 'all'),
                      const SizedBox(width: AppDimensions.spaceSm),
                      _statusChip('Active', 'active'),
                      const SizedBox(width: AppDimensions.spaceSm),
                      _statusChip('Inactive', 'inactive'),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'product',
                            label: Text('Products'),
                            icon: Icon(Icons.inventory_2_outlined),
                          ),
                          ButtonSegment<String>(
                            value: 'set',
                            label: Text('Instrument Sets'),
                            icon: Icon(Icons.widgets_outlined),
                          ),
                        ],
                        selected: <String>{_activeTab},
                        onSelectionChanged: (values) {
                          setState(() {
                            _activeTab = values.first;
                            _query = _query.copyWith(page: 1);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push(RouteNames.inventoryExpiringSoon),
                  icon: const Icon(Icons.event_busy_rounded),
                  label: const Text('Expiring Soon'),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(RouteNames.inventoryLedger),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Ledger'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(RouteNames.inventoryLookup),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Lookup by Lot / Ref'),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(RouteNames.inventoryAllLots),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('View All Lots'),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          if (_activeTab == 'product')
            _buildProducts(productsAsync)
          else
            _buildSets(setsAsync),
        ],
      ),
    );
  }

  Widget _buildProducts(
    AsyncValue<PaginatedResult<InventoryProductAvailabilityModel>>
    productsAsync,
  ) {
    return productsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceLg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(inventoryProductsProvider(_query)),
      ),
      data: (page) {
        if (page.items.isEmpty) {
          return Center(
            child: Text(
              'No products found.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ContentCard(
          child: Column(
            children: [
              ...page.items.map<Widget>((item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item.productName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(item.refNum, style: AppTextStyles.labelSmall),
                  trailing: Text(
                    '${item.availableLotsCount ?? 0} lots',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => context.push(
                    RouteNames.inventoryProductLotsPath(item.id),
                  ),
                );
              }),
              const SizedBox(height: AppDimensions.spaceSm),
              _pagination(page.currentPage, page.lastPage),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSets(
    AsyncValue<PaginatedResult<InventorySetAvailabilityModel>> setsAsync,
  ) {
    return setsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceLg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(inventorySetsProvider(_query)),
      ),
      data: (page) {
        if (page.items.isEmpty) {
          return Center(
            child: Text(
              'No instrument sets found.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ContentCard(
          child: Column(
            children: [
              ...page.items.map<Widget>((item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item.setName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item.setCode?.trim().isNotEmpty == true
                        ? item.setCode!
                        : 'No set code',
                    style: AppTextStyles.labelSmall,
                  ),
                  trailing: Text(
                    '${item.availableSetsCount ?? 0} sets',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppDimensions.spaceSm),
              _pagination(page.currentPage, page.lastPage),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(String label, String value) {
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

  Widget _pagination(int current, int last) {
    return Row(
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
    );
  }
}
