import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/models/consignment_models.dart';
import '../../data/repositories/consignment_repository.dart';
import '../providers/consignment_providers.dart';
import '../widgets/consignment_widgets.dart';

class ConsignmentFormScreen extends ConsumerStatefulWidget {
  const ConsignmentFormScreen({super.key, this.consignmentId});
  final int? consignmentId;
  @override
  ConsumerState<ConsignmentFormScreen> createState() =>
      _ConsignmentFormScreenState();
}

class _ConsignmentFormScreenState extends ConsumerState<ConsignmentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _remarks = TextEditingController();
  final _surgeon = TextEditingController();
  final _caseDate = TextEditingController();
  final _caseName = TextEditingController();
  ClientBrief? _client;
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _loaded = false;
  bool _showClientError = false;
  int? _existingPicId;
  @override
  void dispose() {
    _remarks.dispose();
    _surgeon.dispose();
    _caseDate.dispose();
    _caseName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.consignmentId != null;
    final detail = isEdit
        ? ref.watch(consignmentDetailProvider(widget.consignmentId!))
        : null;
    if (detail?.hasValue == true && !_loaded) {
      final c = detail!.value!;
      _client = c.client;
      _date = c.consignmentAt;
      _existingPicId = c.picUserId;
      _remarks.text = c.remarks ?? '';
      _surgeon.text = c.surgeonName ?? '';
      _caseDate.text = _apiDate(c.caseDate);
      _caseName.text = c.caseName ?? '';
      _loaded = true;
    }
    if (detail?.isLoading == true && !_loaded) return _loading();
    if (detail?.hasError == true) {
      return Scaffold(body: AppErrorWidget(message: detail!.error.toString()));
    }
    final user = ref.watch(currentUserProvider);
    final title = isEdit ? 'Edit consignment' : 'Create consignment';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text(title, style: AppTextStyles.titleMedium),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spaceLg,
            AppDimensions.spaceMd,
            AppDimensions.spaceLg,
            AppDimensions.spaceLg,
          ),
          decoration: BoxDecoration(
            color: AppColors.sidebarBg,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              AppButton(
                label: 'Back',
                variant: AppButtonVariant.ghost,
                isFullWidth: false,
                onPressed: _saving ? null : () => context.pop(),
              ),
              const Spacer(),
              AppButton(
                label: isEdit ? 'Save changes' : 'Create consignment',
                isLoading: _saving,
                isFullWidth: false,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: [
              _headerForm(user?.name ?? user?.email ?? '-', isEdit: isEdit),
              const SizedBox(height: AppDimensions.space5xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loading() => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Consignment')),
    body: const Center(child: CircularProgressIndicator()),
  );
  Widget _headerForm(String userName, {required bool isEdit}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        isEdit
            ? 'Update the draft consignment header before items are confirmed.'
            : 'Capture the consignment header before items are added.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppDimensions.spaceSm),
      Text(
        isEdit
            ? 'The draft remains editable until it is confirmed.'
            : 'After save, the draft consignment opens so you can add lots or instrument sets.',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      ),
      const SizedBox(height: AppDimensions.spaceLg),
      ContentCard(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Consignment session'),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              'Match the web draft-consignment flow before item capture starts.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            _ClientPickerField(
              value: _client?.name,
              onTap: _chooseClient,
              errorText: _showClientError ? 'Client is required.' : null,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            _ReadOnlyField(
              label: 'Consignment date',
              value: displayDate(_date),
              helperText: isEdit
                  ? 'Captured when the draft was created'
                  : 'Automatically set when the draft is created',
              icon: Icons.event_outlined,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            _ReadOnlyField(
              label: 'PIC user',
              value: userName,
              helperText: isEdit
                  ? 'Assigned when the draft was created'
                  : 'Automatically assigned to your account',
              icon: Icons.person_outline,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppDimensions.spaceLg),
      ContentCard(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Surgery details'),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              'Optional context for the surgical case.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            AppTextField(
              controller: _surgeon,
              label: 'Surgeon',
              hint: 'e.g. Dr. John Doe',
              maxLength: 255,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            _CaseDatePickerField(
              value: DateTime.tryParse(_caseDate.text),
              enabled: !_saving,
              onTap: _pickCaseDate,
              onClear: () => setState(_caseDate.clear),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              controller: _caseName,
              label: 'Case',
              hint: 'e.g. Total Knee Replacement',
              maxLength: 255,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppDimensions.spaceLg),
      ContentCard(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Notes'),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              'Optional context for downstream review.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            AppTextField(
              controller: _remarks,
              label: 'Remarks',
              hint: 'Enter any consignment notes',
              maxLines: 4,
              maxLength: 1000,
            ),
          ],
        ),
      ),
    ],
  );
  Future<void> _chooseClient() async {
    final clients = await ref.read(consignmentClientsProvider.future);
    if (!mounted) return;
    final picked = await showSearchPickerSheet(
      context,
      title: 'Choose client',
      items: clients,
      label: (ClientBrief c) => c.name,
      searchHint: 'Search clients',
    );
    if (picked != null) {
      setState(() {
        _client = picked;
        _showClientError = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(consignmentRepositoryProvider);
    final current = ref.read(currentUserProvider);
    if (_client == null) {
      setState(() => _showClientError = true);
      _error('Client is required.');
      return;
    }
    if (current == null) {
      _error('Current user is unavailable.');
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = widget.consignmentId == null
          ? await repo.create(
              clientId: _client!.id,
              date: _date,
              picUserId: current.id,
              surgeonName: _surgeon.text,
              caseDate: _caseDate.text,
              caseName: _caseName.text,
              remarks: _remarks.text,
            )
          : await repo.update(
              widget.consignmentId!,
              clientId: _client!.id,
              date: _date,
              picUserId: _existingPicId ?? current.id,
              surgeonName: _surgeon.text,
              caseDate: _caseDate.text,
              caseName: _caseName.text,
              remarks: _remarks.text,
            );
      if (mounted) {
        ref.invalidate(consignmentListProvider);
        ref.invalidate(consignmentDetailProvider(saved.id));
        context.go(RouteNames.consignmentDetailPath(saved.id));
      }
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_caseDate.text) ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      helpText: 'Select case date',
    );
    if (picked != null && mounted) {
      setState(() => _caseDate.text = _apiDate(picked));
    }
  }

  void _error(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String _apiDate(DateTime? value) => value == null
      ? ''
      : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _CaseDatePickerField extends StatelessWidget {
  const _CaseDatePickerField({
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: AppDimensions.spaceMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date case',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXxs),
                Text(
                  value == null ? 'Tap to pick case date' : displayDate(value),
                  style: value == null
                      ? AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        )
                      : AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          if (value != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              color: AppColors.textMuted,
              onPressed: enabled ? onClear : null,
            ),
        ],
      ),
    ),
  );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.helperText,
    required this.icon,
  });

  final String label;
  final String value;
  final String helperText;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
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
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
          vertical: AppDimensions.spaceMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppDimensions.spaceMd),
            Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        helperText,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
      ),
    ],
  );
}

class _ClientPickerField extends StatelessWidget {
  const _ClientPickerField({required this.onTap, this.value, this.errorText});

  final String? value;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value?.trim().isNotEmpty == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMd,
              vertical: AppDimensions.spaceMd,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: errorText == null ? AppColors.border : AppColors.error,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppDimensions.spaceMd),
                Expanded(
                  child: Text(
                    hasValue ? value! : 'Choose client',
                    style: hasValue
                        ? AppTextStyles.bodyMedium
                        : AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                  ),
                ),
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          errorText ?? 'Search active clients',
          style: AppTextStyles.labelSmall.copyWith(
            color: errorText == null ? AppColors.textMuted : AppColors.error,
          ),
        ),
      ],
    );
  }
}
