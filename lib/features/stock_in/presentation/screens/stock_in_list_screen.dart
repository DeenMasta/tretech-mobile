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
import '../../data/models/stock_in_session_model.dart';
import '../../data/repositories/stock_in_repository.dart';
import '../providers/stock_in_list_provider.dart';
import '../widgets/stock_in_status_badge.dart';

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

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(stockInListFilterProvider);
    final pageAsync = ref.watch(stockInListProvider(filter));

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
          _buildToolbar(filter),
          Expanded(
            child: pageAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(stockInListProvider(filter)),
              ),
              data: (page) => _buildListBody(page, filter),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.stockInCreate),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New session'),
      ),
    );
  }

  Widget _buildToolbar(StockInListFilter filter) {
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
          AppTextField(
            controller: _searchCtl,
            hint: 'Search by session no. or DO number',
            prefixIcon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _applySearch(),
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
                _statusChip('Confirmed', 'confirmed', filter.status),
                const SizedBox(width: AppDimensions.spaceSm),
                _statusChip('Cancelled', 'cancelled', filter.status),
              ],
            ),
          ),
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
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDimensions.spaceSm),
        itemBuilder: (_, i) => _buildSessionCard(page.items[i]),
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
              'Create a new session to start scanning incoming stock.',
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
      onTap: () => context.push('/stock-in/${session.id}/scan'),
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
                Icon(Icons.local_shipping_outlined,
                    size: 14, color: AppColors.textMuted),
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
                Icon(Icons.person_outline,
                    size: 14, color: AppColors.textMuted),
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
                Icon(Icons.event_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.toDisplayDateTime(session.stockInAt),
                  style: AppTextStyles.bodySmall,
                ),
                const Spacer(),
                Icon(Icons.inventory_2_outlined,
                    size: 14, color: AppColors.textMuted),
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
