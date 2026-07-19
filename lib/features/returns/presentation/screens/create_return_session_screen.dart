import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/return_session_model.dart';
import '../../data/repositories/returns_repository.dart';
import '../providers/returns_list_provider.dart';
import '../widgets/consignment_search_sheet.dart';

class CreateReturnSessionScreen extends ConsumerStatefulWidget {
  const CreateReturnSessionScreen({super.key});

  @override
  ConsumerState<CreateReturnSessionScreen> createState() =>
      _CreateReturnSessionScreenState();
}

class _CreateReturnSessionScreenState
    extends ConsumerState<CreateReturnSessionScreen> {
  final _remarksCtl = TextEditingController();

  ReturnConsignmentBrief? _consignment;
  bool _saving = false;
  bool _showConsignmentError = false;

  @override
  void dispose() {
    _remarksCtl.dispose();
    super.dispose();
  }

  Future<void> _pickConsignment() async {
    final selected = await ConsignmentSearchSheet.show(context);
    if (selected == null || !mounted) return;
    setState(() {
      _consignment = selected;
      _showConsignmentError = false;
    });
  }

  Future<void> _submit() async {
    final currentUser = ref.read(currentUserProvider);
    final picUserId = currentUser?.id;

    if (_consignment == null || picUserId == null) {
      setState(() => _showConsignmentError = _consignment == null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a consignment.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(returnsRepositoryProvider);
      final session = await repo.create(
        consignmentId: _consignment!.id,
        picUserId: picUserId,
        remarks: _remarksCtl.text.trim().isEmpty
            ? null
            : _remarksCtl.text.trim(),
      );
      ref.invalidate(returnListProvider);
      if (!mounted) return;
      context.go(RouteNames.returnsDetailPath(session.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create return session: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text('Create return session', style: AppTextStyles.titleMedium),
      ),
      // ── Bottom action bar — per UI rules: bottom actions, no Cancel button ──
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
                label: 'Create return session',
                isLoading: _saving,
                isFullWidth: false,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          children: [
            Text(
              'Select the consignment to start a return workflow.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              'Once created, scan returned lots from the session detail screen.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),

            // ── Return session details ────────────────────────────────────────
            ContentCard(
              padding: const EdgeInsets.all(AppDimensions.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Session details'),
                  const SizedBox(height: AppDimensions.spaceXs),
                  Text(
                    'Link this session to a confirmed consignment.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  _PickerField(
                    label: 'Consignment',
                    value: _consignment?.label,
                    hint: 'Search confirmed consignments',
                    icon: Icons.receipt_long_outlined,
                    onTap: _pickConsignment,
                    errorText: _showConsignmentError
                        ? 'Consignment is required.'
                        : null,
                    helperText: 'Only confirmed consignments are eligible',
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  // PIC — system-owned, display only
                  _ReadOnlyField(
                    label: 'PIC user',
                    value: currentUser?.name ?? '—',
                    helperText: 'Automatically assigned to your account',
                    icon: Icons.person_outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),

            // ── Notes ────────────────────────────────────────────────────────
            ContentCard(
              padding: const EdgeInsets.all(AppDimensions.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Notes'),
                  const SizedBox(height: AppDimensions.spaceXs),
                  Text(
                    'Optional context for the return workflow.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  AppTextField(
                    controller: _remarksCtl,
                    label: 'Remarks',
                    hint: 'Enter any notes for the return team',
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
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
}

// ── Shared field widgets (mirrors create_session_screen.dart) ─────────────────

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
  Widget build(BuildContext context) {
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
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.value,
    this.helperText,
    this.errorText,
  });

  final String label;
  final String hint;
  final String? value;
  final String? helperText;
  final String? errorText;
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
                Icon(icon, size: 18, color: AppColors.textMuted),
                const SizedBox(width: AppDimensions.spaceMd),
                Expanded(
                  child: Text(
                    hasValue ? value! : hint,
                    style: hasValue
                        ? AppTextStyles.bodyMedium
                        : AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceMd),
                Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
