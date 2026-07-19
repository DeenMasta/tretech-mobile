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
import '../../data/models/return_session_model.dart';
import '../providers/returns_list_provider.dart';
import '../widgets/return_status_badge.dart';

class ReturnsListScreen extends ConsumerStatefulWidget {
  const ReturnsListScreen({super.key});

  @override
  ConsumerState<ReturnsListScreen> createState() => _ReturnsListScreenState();
}

class _ReturnsListScreenState extends ConsumerState<ReturnsListScreen> {
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
        .read(returnListFilterProvider.notifier)
        .setSearch(_searchCtl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(returnListFilterProvider);
    final pageAsync = ref.watch(returnListProvider(filter));

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
        title: Text('Returns', style: AppTextStyles.titleMedium),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'returns-create-fab',
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF09090B),
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Color(0xFF09090B)),
        label: Text(
          'Create session',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF09090B),
          ),
        ),
        onPressed: () => context.push(RouteNames.returnsCreate),
      ),
      body: Column(
        children: [
          // ── Hero header ──────────────────────────────────────────────────
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
                  'Returns',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  'Process returned items, manage return sessions, and update inventory.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Toolbar ───────────────────────────────────────────────────────
          _buildToolbar(filter),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: pageAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(returnListProvider(filter)),
              ),
              data: (page) => _buildListBody(page, filter),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(ReturnListFilter filter) {
    return Container(
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
          AppTextField(
            controller: _searchCtl,
            hint: 'Search by session no. or consignment',
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
                _statusChip('In Progress', 'in_progress', filter.status),
                const SizedBox(width: AppDimensions.spaceSm),
                _statusChip('Completed', 'completed', filter.status),
                const SizedBox(width: AppDimensions.spaceSm),
                _statusChip('Reconciled', 'reconciled', filter.status),
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
          ref.read(returnListFilterProvider.notifier).setStatus(value),
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

  Widget _buildListBody(ReturnSessionPage page, ReturnListFilter filter) {
    if (page.items.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(returnListProvider(filter)),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceLg,
          AppDimensions.spaceMd,
          AppDimensions.spaceLg,
          AppDimensions.space5xl,
        ),
        itemCount: page.items.length + 1,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppDimensions.spaceSm),
        itemBuilder: (_, index) {
          if (index < page.items.length) {
            return _buildSessionCard(page.items[index]);
          }
          if (page.lastPage <= 1) return const SizedBox.shrink();
          return _buildPagination(page, filter);
        },
      ),
    );
  }

  Widget _buildPagination(ReturnSessionPage page, ReturnListFilter filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Previous',
              variant: AppButtonVariant.secondary,
              onPressed: page.currentPage > 1
                  ? () => ref
                        .read(returnListFilterProvider.notifier)
                        .loadPage(page.currentPage - 1)
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMd,
            ),
            child: Text(
              'Page ${page.currentPage} of ${page.lastPage}',
              style: AppTextStyles.labelMedium,
            ),
          ),
          Expanded(
            child: AppButton(
              label: 'Next',
              variant: AppButtonVariant.secondary,
              onPressed: page.currentPage < page.lastPage
                  ? () => ref
                        .read(returnListFilterProvider.notifier)
                        .loadPage(page.currentPage + 1)
                  : null,
            ),
          ),
        ],
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
                Icons.assignment_return_rounded,
                size: 36,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            Text('No return sessions', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              'Create a return session from a confirmed consignment.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(ReturnSessionModel session) {
    return InkWell(
      onTap: () => context.push(RouteNames.returnsDetailPath(session.id)),
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
                    session.returnSessionNo,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ReturnStatusBadge(status: session.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              session.consignment?.consignmentNo ?? '—',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    session.picUserName,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.itemsCount ?? session.items?.length ?? 0} lots',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            if (session.startedAt != null) ...[
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
                    DateFormatter.toDisplay(session.startedAt!),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
