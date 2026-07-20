import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_formatter.dart';
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
import '../../../../shared/widgets/section_header.dart';
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
    final user = ref.watch(currentUserProvider);
    final canCreate = user?.permissions.contains('disposals.create') ?? false;
    final detail = isEdit
        ? ref.watch(disposalDetailProvider(widget.disposalId!))
        : null;
    if (detail?.hasValue == true && !_loaded) {
      final model = detail!.value!;
      _date = model.disposedAt ?? DateTime.now();
      _remarks.text = model.remarks ?? '';
      _loaded = true;
    }
    if (detail?.isLoading == true && !_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (detail?.hasError == true) {
      return Scaffold(body: AppErrorWidget(message: detail!.error.toString()));
    }
    if (isEdit && !detail!.value!.isDraft) {
      return Scaffold(
        appBar: ModuleAppBar(title: 'Disposal', onBack: () => context.pop()),
        body: const Center(child: Text('Only draft disposals can be edited.')),
      );
    }
    if (!canCreate) {
      return Scaffold(
        appBar: ModuleAppBar(
          title: isEdit ? 'Edit disposal' : 'Create disposal',
          onBack: () => context.pop(),
        ),
        body: const Center(
          child: Text('You do not have permission to manage disposals.'),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: isEdit ? 'Edit disposal' : 'Create disposal',
        onBack: () => context.pop(),
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
          child: AppButton(
            onPressed: _saving ? null : () => _submit(user?.id),
            isLoading: _saving,
            icon: Icons.save_outlined,
            label: isEdit ? 'Save changes' : 'Create disposal',
          ),
        ),
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
            ContentCard(
              padding: const EdgeInsets.all(AppDimensions.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Disposal header'),
                  const SizedBox(height: AppDimensions.spaceXs),
                  Text(
                    'System-owned values are recorded when the draft is created.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  _ReadOnlyField(
                    label: 'Disposal date',
                    value: DateFormatter.toDisplay(_date),
                    helperText: 'Automatically set when the draft is created',
                    icon: Icons.event_outlined,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  _ReadOnlyField(
                    label: 'PIC user',
                    value: isEdit
                        ? detail!.value!.picUser?.fullName ?? '-'
                        : user?.name ?? user?.email ?? '-',
                    helperText: 'Automatically assigned to the draft owner',
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
                    hint: 'Enter any disposal notes',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space5xl),
          ],
        ),
      ),
    );
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
              picUserId: detailPicUserId,
              remarks: _remarks.text,
            );
      ref.invalidate(disposalListProvider);
      ref.invalidate(disposalDetailProvider(result.id));
      if (mounted) {
        context.go(RouteNames.disposalDetailPath(result.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  int get detailPicUserId => widget.disposalId == null
      ? 0
      : ref.read(disposalDetailProvider(widget.disposalId!)).value?.picUserId ??
            0;
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
      Text(label, style: AppTextStyles.labelMedium),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
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
