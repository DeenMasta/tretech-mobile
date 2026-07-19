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
    final data = ref.watch(disposalListProvider(_query));
    if (_search.text != _query.search) _search.text = _query.search;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Disposals',
        onBack: () => context.go(RouteNames.dashboard),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'disposal-create',
        onPressed: () => context.push(RouteNames.disposalCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create disposal'),
      ),
      body: Column(
        children: [
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
                        itemCount: page.items.length + 1,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppDimensions.spaceSm),
                        itemBuilder: (_, index) => index == page.items.length
                            ? _pagination(page.currentPage, page.lastPage)
                            : DisposalListTile(
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

  Widget _toolbar() => Container(
    color: AppColors.sidebarBg,
    padding: const EdgeInsets.all(AppDimensions.spaceLg),
    child: Column(
      children: [
        AppTextField(
          controller: _search,
          hint: 'Search disposal number',
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) =>
              _apply(_query.copyWith(search: _search.text.trim(), page: 1)),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('All', 'all'),
              const SizedBox(width: AppDimensions.spaceSm),
              _chip('Draft', 'draft'),
              const SizedBox(width: AppDimensions.spaceSm),
              _chip('Completed', 'completed'),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: const Icon(Icons.event_outlined),
                label: Text(_query.fromDate ?? 'From date'),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: const Icon(Icons.event_available_outlined),
                label: Text(_query.toDate ?? 'To date'),
              ),
            ),
          ],
        ),
        if (_query.fromDate != null || _query.toDate != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _apply(
                _query.copyWith(clearFrom: true, clearTo: true, page: 1),
              ),
              child: const Text('Clear dates'),
            ),
          ),
      ],
    ),
  );
  Widget _chip(String label, String value) => ChoiceChip(
    label: Text(label),
    selected: _query.status == value,
    onSelected: (_) => _apply(_query.copyWith(status: value, page: 1)),
  );
  Future<void> _pickDate(bool from) async {
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null)
      _apply(
        _query.copyWith(
          fromDate: from ? DateFormatter.toApi(value) : null,
          toDate: from ? null : DateFormatter.toApi(value),
          page: 1,
        ),
      );
  }

  Widget _pagination(int current, int last) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: current <= 1
              ? null
              : () => _apply(_query.copyWith(page: current - 1)),
          child: const Text('Previous'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
        child: Text('Page $current / $last'),
      ),
      Expanded(
        child: OutlinedButton(
          onPressed: current >= last
              ? null
              : () => _apply(_query.copyWith(page: current + 1)),
          child: const Text('Next'),
        ),
      ),
    ],
  );
}
