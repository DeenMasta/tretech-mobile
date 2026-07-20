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
import '../../../../shared/widgets/module_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/disposal_providers.dart';
import '../widgets/disposal_widgets.dart';

class DisposalScreen extends ConsumerStatefulWidget {
  const DisposalScreen({super.key});
  @override
  ConsumerState<DisposalScreen> createState() => _DisposalScreenState();
}

class _DisposalScreenState extends ConsumerState<DisposalScreen> {
  DisposalListQuery _query = const DisposalListQuery();
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

  void _apply(DisposalListQuery value) => setState(() => _query = value);

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(currentUserProvider)?.permissions ?? const [];
    if (!permissions.contains('disposals.view')) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: ModuleAppBar(
          title: 'Disposals',
          onBack: () => context.go(RouteNames.dashboard),
        ),
        body: const Center(
          child: Text('You do not have permission to view disposals.'),
        ),
      );
    }
    final data = ref.watch(disposalListProvider(_query));
    if (_search.text != _query.search) _search.text = _query.search;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Disposals',
        onBack: () => context.go(RouteNames.dashboard),
      ),
      floatingActionButton: permissions.contains('disposals.create')
          ? FloatingActionButton.extended(
              heroTag: 'disposal-create',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              onPressed: () => context.push(RouteNames.disposalCreate),
              icon: const Icon(Icons.add_rounded, color: Color(0xFF09090B)),
              label: Text(
                'Create disposal',
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
                  'Disposals',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  'Create draft disposals, record affected lots, and complete inventory movements.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _toolbar(),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(disposalListProvider(_query)),
              ),
              data: (page) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(disposalListProvider(_query)),
                child: page.items.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              'No disposals found.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.spaceLg,
                          AppDimensions.spaceMd,
                          AppDimensions.spaceLg,
                          96,
                        ),
                        itemCount: page.items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppDimensions.spaceSm),
                        itemBuilder: (_, index) => DisposalListTile(
                          disposal: page.items[index],
                          onTap: () => context.push(
                            RouteNames.disposalDetailPath(
                              page.items[index].id,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<DisposalListQuery>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => _DisposalFilterSheet(initialQuery: _query),
    );
    if (result == null) return;
    _apply(result);
  }

  Widget _toolbar() {
    final hasExtraFilters = _query.fromDate != null || _query.toDate != null;
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
                  hint: 'Search disposal number',
                  prefixIcon: Icons.search_rounded,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) =>
                      _apply(_query.copyWith(search: _search.text.trim(), page: 1)),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              InkWell(
                onTap: _openFilters,
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
                _statusChip('All', 'all', _query.status ?? 'all'),
                const SizedBox(width: AppDimensions.spaceSm),
                _statusChip('Draft', 'draft', _query.status ?? 'all'),
                const SizedBox(width: AppDimensions.spaceSm),
                _statusChip('Completed', 'completed', _query.status ?? 'all'),
              ],
            ),
          ),
          if (hasExtraFilters) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            Wrap(
              spacing: AppDimensions.spaceSm,
              runSpacing: AppDimensions.spaceSm,
              children: [
                if (_query.fromDate != null)
                  _filterPill('From ${_query.fromDate}'),
                if (_query.toDate != null)
                  _filterPill('To ${_query.toDate}'),
                InkWell(
                  onTap: () => _apply(_query.copyWith(clearFrom: true, clearTo: true, page: 1)),
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
      onTap: () => _apply(_query.copyWith(status: value, page: 1)),
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

}

class _DisposalFilterSheet extends StatefulWidget {
  const _DisposalFilterSheet({required this.initialQuery});
  final DisposalListQuery initialQuery;

  @override
  State<_DisposalFilterSheet> createState() => _DisposalFilterSheetState();
}

class _DisposalFilterSheetState extends State<_DisposalFilterSheet> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialQuery.fromDate != null
        ? DateTime.tryParse(widget.initialQuery.fromDate!)
        : null;
    _toDate = widget.initialQuery.toDate != null
        ? DateTime.tryParse(widget.initialQuery.toDate!)
        : null;
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
                    widget.initialQuery.copyWith(
                      fromDate: _fromDate != null ? DateFormatter.toApi(_fromDate!) : null,
                      toDate: _toDate != null ? DateFormatter.toApi(_toDate!) : null,
                      clearFrom: _fromDate == null,
                      clearTo: _toDate == null,
                      page: 1,
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
                  widget.initialQuery.copyWith(
                    clearFrom: true,
                    clearTo: true,
                    page: 1,
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
  });

  final String label;
  final String hint;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

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
              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
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
