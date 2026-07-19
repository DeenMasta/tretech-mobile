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
import '../../../../shared/widgets/more_filters_sheet.dart';
import '../../../../shared/widgets/module_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/consignment_models.dart';
import '../providers/consignment_providers.dart';
import '../widgets/consignment_widgets.dart';
import '../widgets/client_search_sheet.dart';

class ConsignmentScreen extends ConsumerStatefulWidget {
  const ConsignmentScreen({super.key});
  @override
  ConsumerState<ConsignmentScreen> createState() => _ConsignmentScreenState();
}

class _ConsignmentScreenState extends ConsumerState<ConsignmentScreen> {
  late final TextEditingController _search;
  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(consignmentFilterProvider);
    final page = ref.watch(consignmentListProvider(filter));
    final permissions = ref.watch(currentUserProvider)?.permissions ?? const [];
    if (_search.text != filter.search) _search.text = filter.search;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Consignments',
        onBack: () => context.go(RouteNames.dashboard),
      ),
      floatingActionButton: permissions.contains('consignments.create')
          ? FloatingActionButton.extended(
              heroTag: 'consignment-create',
              onPressed: () => context.push(RouteNames.consignmentCreate),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              icon: const Icon(Icons.add_rounded, color: Color(0xFF09090B)),
              label: Text(
                'Create consignment',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF09090B),
                ),
              ),
            )
          : null,
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
                  'Consignments',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage consigned inventory, track items sent to clients, and handle returns.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _toolbar(filter),
          Expanded(
            child: page.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(consignmentListProvider(filter)),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(consignmentListProvider(filter));
                },
                child: _list(data, filter),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(ConsignmentFilter filter) {
    final hasExtraFilters =
        filter.clientId != null ||
        filter.fromDate != null ||
        filter.toDate != null;

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
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _search,
                  hint: 'Search by consignment number',
                  prefixIcon: Icons.search_rounded,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) =>
                      _apply(filter.copyWith(search: _search.text.trim())),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              InkWell(
                onTap: () => _filters(filter),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasExtraFilters
                        ? AppColors.primaryContainer
                        : AppColors.surfaceElevated,
                    border: Border.all(
                      color: hasExtraFilters
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
                _statusChip('Confirmed', 'confirmed', filter.status),
              ],
            ),
          ),
          if (hasExtraFilters) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            Wrap(
              spacing: AppDimensions.spaceSm,
              runSpacing: AppDimensions.spaceSm,
              children: [
                if (filter.clientId != null)
                  _filterPill(
                    filter.clientName?.trim().isNotEmpty == true
                        ? filter.clientName!
                        : 'Client filtered',
                  ),
                if (filter.fromDate != null)
                  _filterPill('From ${displayDate(filter.fromDate)}'),
                if (filter.toDate != null)
                  _filterPill('To ${displayDate(filter.toDate)}'),
                InkWell(
                  onTap: () =>
                      ref.read(consignmentFilterProvider.notifier).clear(),
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
      onTap: () => _apply(
        ref
            .read(consignmentFilterProvider)
            .copyWith(status: value, resetPage: true),
      ),
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

  Widget _filterPill(String label) => Container(
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
  void _apply(ConsignmentFilter value) {
    final current = ref.read(consignmentFilterProvider);
    final filtersChanged =
        current.search != value.search ||
        current.status != value.status ||
        current.clientId != value.clientId ||
        current.fromDate != value.fromDate ||
        current.toDate != value.toDate;
    ref
        .read(consignmentFilterProvider.notifier)
        .apply(filtersChanged ? value.copyWith(page: 1) : value);
  }

  Future<void> _filters(ConsignmentFilter current) async {
    final clients = await ref.read(consignmentClientsProvider.future);
    if (!mounted) return;
    final result = await showModalBottomSheet<ConsignmentFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (context) => _FilterSheet(filter: current, clients: clients),
    );
    if (result != null) _apply(result);
  }

  Widget _list(ConsignmentPage page, ConsignmentFilter filter) {
    final rows = page.items;
    if (rows.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              'No consignments found\nAdjust filters or create the first consignment.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceLg,
        AppDimensions.spaceMd,
        AppDimensions.spaceLg,
        96,
      ),
      itemCount: rows.length + (page.lastPage > 1 ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
      itemBuilder: (_, i) {
        if (i == rows.length) {
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: page.currentPage > 1
                      ? () =>
                            _apply(filter.copyWith(page: page.currentPage - 1))
                      : null,
                  child: const Text('Previous'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Page ${page.currentPage} of ${page.lastPage}'),
              ),
              Expanded(
                child: OutlinedButton(
                  onPressed: page.currentPage < page.lastPage
                      ? () =>
                            _apply(filter.copyWith(page: page.currentPage + 1))
                      : null,
                  child: const Text('Next'),
                ),
              ),
            ],
          );
        }
        final item = rows[i];
        return InkWell(
          onTap: () => context.push(RouteNames.consignmentDetailPath(item.id)),
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: ContentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.number,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ConsignmentStatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.client?.name ?? '-', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _meta(
                      Icons.calendar_today_outlined,
                      displayDate(item.consignmentAt),
                    ),
                    _meta(Icons.person_outline, item.picName ?? '-'),
                    _meta(
                      Icons.inventory_2_outlined,
                      '${item.itemsCount ?? 0} lots',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
      ),
    ],
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filter, required this.clients});
  final ConsignmentFilter filter;
  final List<ClientBrief> clients;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _status;
  late ClientBrief? _client;
  late DateTime? _from, _to;
  @override
  void initState() {
    super.initState();
    _status = widget.filter.status;
    _client = widget.clients
        .where((c) => c.id == widget.filter.clientId)
        .firstOrNull;
    _from = widget.filter.fromDate;
    _to = widget.filter.toDate;
  }

  @override
  Widget build(BuildContext context) => MoreFiltersSheet(
    onApply: () => Navigator.pop(
      context,
      ConsignmentFilter(
        search: widget.filter.search,
        status: _status,
        clientId: _client?.id,
        clientName: _client?.name,
        fromDate: _from,
        toDate: _to,
      ),
    ),
    onReset: () => Navigator.pop(
      context,
      ConsignmentFilter(search: widget.filter.search, status: _status),
    ),
    child: Column(
      children: [
        FilterPicker(
          label: 'Client',
          value: _client?.name,
          hint: 'Tap to choose client',
          icon: Icons.business_outlined,
          onTap: () async {
            final client = await ClientSearchSheet.show(
              context,
              clients: widget.clients,
            );
            if (client != null) setState(() => _client = client);
          },
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Row(
          children: [
            Expanded(
              child: FilterPicker(
                label: 'From date',
                value: _from == null ? null : displayDate(_from),
                hint: 'Select date',
                icon: Icons.event_outlined,
                onTap: () => _pickDate(from: true),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: FilterPicker(
                label: 'To date',
                value: _to == null ? null : displayDate(_to),
                hint: 'Select date',
                icon: Icons.event_outlined,
                onTap: () => _pickDate(from: false),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _pickDate({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from
          ? (_from ?? DateTime.now())
          : (_to ?? _from ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }
}
