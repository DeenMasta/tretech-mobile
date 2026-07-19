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
import '../../../../shared/widgets/module_app_bar.dart';
import '../../data/models/consignment_models.dart';
import '../../data/repositories/consignment_repository.dart';
import '../providers/consignment_providers.dart';
import '../widgets/consignment_widgets.dart';

class ConsignmentFormScreen extends ConsumerStatefulWidget {
  const ConsignmentFormScreen({
    super.key,
    this.consignmentId,
    this.postConfirmEdit = false,
  });
  final int? consignmentId;
  final bool postConfirmEdit;
  @override
  ConsumerState<ConsignmentFormScreen> createState() =>
      _ConsignmentFormScreenState();
}

class _ConsignmentFormScreenState extends ConsumerState<ConsignmentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _remarks = TextEditingController();
  final _reason = TextEditingController();
  ClientBrief? _client;
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _loaded = false;
  @override
  void dispose() {
    _remarks.dispose();
    _reason.dispose();
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
      _remarks.text = c.remarks ?? '';
      _loaded = true;
    }
    if (detail?.isLoading == true && !_loaded) return _loading();
    if (detail?.hasError == true) {
      return Scaffold(body: AppErrorWidget(message: detail!.error.toString()));
    }
    final user = ref.watch(currentUserProvider);
    final pageTitle = widget.postConfirmEdit
        ? 'Update confirmed consignment'
        : isEdit
        ? 'Consignment details'
        : 'Start a consignment';
    final description = widget.postConfirmEdit
        ? 'Confirmed consignments require a reason before header notes are changed.'
        : isEdit
        ? 'Update the draft consignment header before confirmation.'
        : 'Start a draft consignment before adding the lots to be supplied.';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: widget.postConfirmEdit
            ? 'Post-confirm edit'
            : isEdit
            ? 'Edit consignment'
            : 'New consignment',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: [
              Text(
                pageTitle,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              if (widget.postConfirmEdit)
                _postConfirmForm()
              else
                _headerForm(user?.id, user?.name ?? user?.email ?? '-'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: widget.postConfirmEdit
                          ? 'Save post-confirm edit'
                          : isEdit
                          ? 'Save changes'
                          : 'Create consignment',
                      isLoading: _saving,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
  Widget _headerForm(int? userId, String userName) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ConsignmentSection(
        title: 'Header details',
        description:
            'Choose the client. The date and PIC are set automatically.',
        child: ContentCard(
          child: Column(
            children: [
              InkWell(
                onTap: _chooseClient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Client',
                    prefixIcon: const Icon(Icons.business_outlined, size: 18),
                    suffixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                  ),
                  child: Text(
                    _client?.name ?? 'Search and choose client',
                    style: _client == null
                        ? AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          )
                        : AppTextStyles.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Consignment date'),
                subtitle: Text(displayDate(_date)),
                trailing: const Icon(Icons.lock_outline, size: 18),
                onTap: null,
              ),
              Text(
                'Auto-set to today',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('PIC user'),
                subtitle: Text(userName),
                trailing: const Icon(Icons.lock_outline, size: 18),
              ),
              Text(
                'Auto-filled from your account',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      ConsignmentSection(
        title: 'Notes',
        description: 'Optional context for the consignment workflow.',
        child: ContentCard(
          child: AppTextField(
            controller: _remarks,
            label: 'Remarks',
            hint: 'Enter any consignment notes',
            maxLines: 4,
            maxLength: 1000,
          ),
        ),
      ),
    ],
  );
  Widget _postConfirmForm() => ConsignmentSection(
    title: 'Reason',
    description: 'The backend requires a reason for edits after confirmation.',
    child: ContentCard(
      child: Column(
        children: [
          AppTextField(
            controller: _reason,
            label: 'Reason',
            hint: 'Explain why this confirmed consignment needs updating',
            maxLines: 3,
            maxLength: 1000,
            validator: (v) => (v ?? '').trim().length < 5
                ? 'Reason must be at least 5 characters.'
                : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _remarks,
            label: 'Updated remarks',
            hint: 'Revise the remarks if needed',
            maxLines: 4,
            maxLength: 1000,
          ),
        ],
      ),
    ),
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
    if (picked != null) setState(() => _client = picked);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(consignmentRepositoryProvider);
    final current = ref.read(currentUserProvider);
    if (widget.postConfirmEdit) {
      if (widget.consignmentId == null) return;
      setState(() => _saving = true);
      try {
        await repo.postConfirmEdit(
          widget.consignmentId!,
          _reason.text,
          _remarks.text,
        );
        if (mounted) {
          ref.invalidate(consignmentDetailProvider(widget.consignmentId!));
          context.go(RouteNames.consignmentDetailPath(widget.consignmentId!));
        }
      } catch (e) {
        _error(e);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }
    if (_client == null) {
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
              remarks: _remarks.text,
            )
          : await repo.update(
              widget.consignmentId!,
              clientId: _client!.id,
              date: _date,
              picUserId: current.id,
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

  void _error(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
