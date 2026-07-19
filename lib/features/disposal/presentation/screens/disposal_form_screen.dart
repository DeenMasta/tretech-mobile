import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/module_app_bar.dart';
import '../../data/repositories/disposal_repository.dart';
import '../providers/disposal_providers.dart';

class DisposalFormScreen extends ConsumerStatefulWidget {
  const DisposalFormScreen({super.key, this.disposalId});
  final int? disposalId;
  @override
  ConsumerState<DisposalFormScreen> createState() => _DisposalFormScreenState();
}

class _DisposalFormScreenState extends ConsumerState<DisposalFormScreen> {
  final _form = GlobalKey<FormState>();
  final _remarks = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loaded = false, _saving = false;
  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.disposalId != null;
    final detail = isEdit
        ? ref.watch(disposalDetailProvider(widget.disposalId!))
        : null;
    if (detail?.hasValue == true && !_loaded) {
      final model = detail!.value!;
      _date = model.disposedAt ?? DateTime.now();
      _remarks.text = model.remarks ?? '';
      _loaded = true;
    }
    if (detail?.isLoading == true && !_loaded)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (detail?.hasError == true)
      return Scaffold(body: AppErrorWidget(message: detail!.error.toString()));
    if (isEdit && !detail!.value!.isDraft)
      return Scaffold(
        appBar: ModuleAppBar(title: 'Disposal', onBack: () => context.pop()),
        body: const Center(child: Text('Only draft disposals can be edited.')),
      );
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: isEdit ? 'Edit disposal' : 'Create disposal',
        onBack: () => context.pop(),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          children: [
            Text(
              isEdit ? 'Edit draft disposal' : 'Start a disposal draft',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add affected lots after saving the disposal header.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disposal date'),
              subtitle: Text(DateFormatter.toDisplay(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('PIC user'),
              subtitle: Text(user?.name ?? user?.email ?? '-'),
              leading: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              controller: _remarks,
              hint: 'Remarks (optional)',
              maxLines: 4,
            ),
            const SizedBox(height: AppDimensions.spaceXl),
            FilledButton.icon(
              onPressed: _saving ? null : () => _submit(user?.id),
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _saving
                    ? 'Saving...'
                    : isEdit
                    ? 'Save changes'
                    : 'Create disposal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _submit(int? userId) async {
    if (!(_form.currentState?.validate() ?? false) || userId == null) return;
    if (_remarks.text.trim().length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remarks must be 1,000 characters or less.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(disposalRepositoryProvider);
      final result = widget.disposalId == null
          ? await repo.create(
              disposedAt: DateFormatter.toApi(_date),
              picUserId: userId,
              remarks: _remarks.text,
            )
          : await repo.update(
              widget.disposalId!,
              disposedAt: DateFormatter.toApi(_date),
              picUserId: userId,
              remarks: _remarks.text,
            );
      ref.invalidate(disposalListProvider);
      ref.invalidate(disposalDetailProvider(result.id));
      if (mounted) context.go(RouteNames.disposalDetailPath(result.id));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
