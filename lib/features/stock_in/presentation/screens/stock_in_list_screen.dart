import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/stock_in_session_model.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/stock_in_repository.dart';
import '../providers/stock_in_list_provider.dart';
import '../widgets/stock_in_status_badge.dart';
import '../widgets/supplier_search_sheet.dart';

class StockInListScreen extends ConsumerStatefulWidget {
  const StockInListScreen({super.key});

  @override
  ConsumerState<StockInListScreen> createState() => _StockInListScreenState();
}

class _StockInListScreenState extends ConsumerState<StockInListScreen> {
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
    ref
        .read(stockInListFilterProvider.notifier)
        .setSearch(_searchCtl.text.trim());
  }

  Future<void> _openFilters(StockInListFilter filter) async {
    final result = await showModalBottomSheet<StockInListFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => _StockInFilterSheet(
        initialFilter: filter,
        repository: ref.read(stockInMasterDataRepositoryProvider),
      ),
    );
    if (result == null) return;
    ref.read(stockInListFilterProvider.notifier).apply(result);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(stockInListFilterProvider);
    final pageAsync = ref.watch(stockInListProvider(filter));

    if (_searchCtl.text != filter.search) {
      _searchCtl.value = TextEditingValue(
        text: filter.search,
        selection: TextSelection.collapsed(offset: filter.search.length),
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
        title: Text('Stock In', style: AppTextStyles.titleMedium),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.sidebarBg,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceLg,
              AppDimensions.spaceMd,
              AppDimensions.spaceLg,
              AppDimensions.spaceSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock In',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  'Receive new inventory, manage stock-in sessions, and track incoming shipments.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppButton(
                  label: 'Create session',
                  icon: Icons.add_rounded,
                  isFullWidth: false,
                  onPressed: () => context.push(RouteNames.stockInCreate),
                ),
              ],
            ),
          ),
          _buildToolbar(filter),
          Expanded(
            child: pageAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(stockInListProvider(filter)),
              ),
              data: (page) => _buildListBody(page, filter),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(StockInListFilter filter) {
    final hasExtraFilters =
        filter.supplierId != null ||
        filter.fromDate != null ||
        filter.toDate != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceLg,
        AppDimensions.spaceMd,
        AppDimensions.spaceLg,
        AppDimensions.spaceSm,
      ),
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _searchCtl,
                  hint: 'Search by session no. or DO number',
                  prefixIcon: Icons.search_rounded,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _applySearch(),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              InkWell(
                onTap: () => _openFilters(filter),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasExtraFilters
                        ? AppColors.primaryContainer
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: hasExtraFilters
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : AppColors.border,
                    ),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: hasExtraFilters
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusChip('All', '', filter.status),
                const SizedBox(width: AppDimensions.spaceSm),
                _statusChip('Draft', 'draft', filter.status),
                const SizedBox(width: AppDimensions.spaceSm),
                _statusChip('Finalized', 'finalized', filter.status),
              ],
            ),
          ),
          if (hasExtraFilters) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            Wrap(
              spacing: AppDimensions.spaceSm,
              runSpacing: AppDimensions.spaceSm,
              children: [
                if (filter.supplierId != null)
                  _filterPill(
                    filter.supplierName?.trim().isNotEmpty == true
                        ? filter.supplierName!
                        : 'Supplier filtered',
                  ),
                if (filter.fromDate != null)
                  _filterPill(
                    'From ${DateFormatter.toDisplay(filter.fromDate!)}',
                  ),
                if (filter.toDate != null)
                  _filterPill('To ${DateFormatter.toDisplay(filter.toDate!)}'),
                InkWell(
                  onTap: () =>
                      ref.read(stockInListFilterProvider.notifier).clear(),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceSm,
                      vertical: 6,
                    ),
                    child: Text(
                      'Clear filters',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value, String selected) {
    final isActive = selected == value;
    return InkWell(
      onTap: () =>
          ref.read(stockInListFilterProvider.notifier).setStatus(value),
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _filterPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }

  Widget _buildListBody(StockInSessionPage page, StockInListFilter filter) {
    if (page.items.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(stockInListProvider(filter)),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceLg,
          AppDimensions.spaceMd,
          AppDimensions.spaceLg,
          AppDimensions.space5xl,
        ),
        itemCount: page.items.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppDimensions.spaceSm),
        itemBuilder: (_, index) => _buildSessionCard(page.items[index]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space3xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 36,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            Text('No stock-in sessions', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              'Create a new session to start receiving incoming stock.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.spaceXxl),
            AppButton(
              label: 'Create session',
              icon: Icons.add_rounded,
              isFullWidth: false,
              onPressed: () => context.push(RouteNames.stockInCreate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(StockInSessionModel session) {
    return InkWell(
      onTap: () => context.push(RouteNames.stockInDetailPath(session.id)),
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.sessionNo,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StockInStatusBadge(status: session.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'DO: ${session.doNumber}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    session.supplierName,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  session.picUserName,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.toDisplayDateTime(session.stockInAt),
                  style: AppTextStyles.bodySmall,
                ),
                const Spacer(),
                Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.itemsCount ?? session.items?.length ?? 0} items',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StockInFilterSheet extends StatefulWidget {
  const _StockInFilterSheet({
    required this.initialFilter,
    required this.repository,
  });

  final StockInListFilter initialFilter;
  final StockInMasterDataRepository repository;

  @override
  State<_StockInFilterSheet> createState() => _StockInFilterSheetState();
}

class _StockInFilterSheetState extends State<_StockInFilterSheet> {
  SupplierModel? _supplier;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _loadingSupplier = false;

  @override
  void initState() {
    super.initState();
    _supplier = widget.initialFilter.supplierId == null
        ? null
        : SupplierModel(
            id: widget.initialFilter.supplierId!,
            supplierName:
                widget.initialFilter.supplierName ?? 'Selected supplier',
          );
    _fromDate = widget.initialFilter.fromDate;
    _toDate = widget.initialFilter.toDate;
  }

  Future<void> _pickSupplier() async {
    setState(() => _loadingSupplier = true);
    final selected = await SupplierSearchSheet.show(
      context,
      repository: widget.repository,
      title: 'Filter by supplier',
    );
    if (!mounted) return;
    setState(() {
      _loadingSupplier = false;
      if (selected != null) {
        _supplier = selected;
      }
    });
  }

  Future<void> _pickDate({required bool from}) async {
    final initialDate = from
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? _fromDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (from) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Text('More filters', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppDimensions.spaceLg),
              _FilterPicker(
                label: 'Supplier',
                value: _supplier?.supplierName,
                hint: 'Tap to choose supplier',
                icon: Icons.local_shipping_outlined,
                loading: _loadingSupplier,
                onTap: _pickSupplier,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _FilterPicker(
                      label: 'From date',
                      value: _fromDate == null
                          ? null
                          : DateFormatter.toDisplay(_fromDate!),
                      hint: 'Select date',
                      icon: Icons.event_outlined,
                      onTap: () => _pickDate(from: true),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: _FilterPicker(
                      label: 'To date',
                      value: _toDate == null
                          ? null
                          : DateFormatter.toDisplay(_toDate!),
                      hint: 'Select date',
                      icon: Icons.event_outlined,
                      onTap: () => _pickDate(from: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              AppButton(
                label: 'Apply filters',
                onPressed: () {
                  Navigator.pop(
                    context,
                    widget.initialFilter.copyWith(
                      supplierId:
                          _supplier?.id ?? widget.initialFilter.supplierId,
                      supplierName:
                          _supplier?.supplierName ??
                          widget.initialFilter.supplierName,
                      clearSupplier: _supplier == null,
                      fromDate: _fromDate,
                      toDate: _toDate,
                      clearFromDate: _fromDate == null,
                      clearToDate: _toDate == null,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              AppButton(
                label: 'Reset',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.pop(
                  context,
                  widget.initialFilter.copyWith(
                    clearSupplier: true,
                    clearFromDate: true,
                    clearToDate: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPicker extends StatelessWidget {
  const _FilterPicker({
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.value,
    this.loading = false,
  });

  final String label;
  final String hint;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18),
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search_rounded, size: 18),
              filled: true,
              fillColor: AppColors.surfaceElevated,
            ),
            child: Text(
              hasValue ? value! : hint,
              style: hasValue
                  ? AppTextStyles.bodyMedium
                  : AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
