import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/supplier_model.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/stock_in_repository.dart';
import '../providers/stock_in_list_provider.dart';
import '../widgets/supplier_search_sheet.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() =>
      _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doCtl = TextEditingController();
  final _remarksCtl = TextEditingController();

  SupplierModel? _supplier;
  final DateTime _stockInAt = DateTime.now();
  bool _saving = false;
  bool _showSupplierError = false;

  StockInMasterDataRepository get _masterRepo =>
      ref.read(stockInMasterDataRepositoryProvider);

  @override
  void dispose() {
    _doCtl.dispose();
    _remarksCtl.dispose();
    super.dispose();
  }

  Future<void> _pickSupplier() async {
    final selected = await SupplierSearchSheet.show(
      context,
      repository: _masterRepo,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _supplier = selected;
      _showSupplierError = false;
    });
  }

  Future<void> _submit() async {
    final currentUser = ref.read(currentUserProvider);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final picUserId = currentUser?.id;
    if (_supplier == null || picUserId == null) {
      setState(() => _showSupplierError = _supplier == null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier and PIC are required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(stockInRepositoryProvider);
      final session = await repo.createSession(
        supplierId: _supplier!.id,
        doNumber: _doCtl.text.trim(),
        stockInAt: _stockInAt,
        picUserId: picUserId,
        remarks: _remarksCtl.text.trim(),
      );
      ref.invalidate(stockInListProvider);
      if (!mounted) {
        return;
      }
      context.go(RouteNames.stockInDetailPath(session.id));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create session: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text(
          'Create stock-in session',
          style: AppTextStyles.titleMedium,
        ),
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
                label: 'Create session',
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
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: [
              Text(
                'Capture the stock-in header before items are added.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Text(
                'After save, the draft session opens so you can add product or set entries.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              ContentCard(
                padding: const EdgeInsets.all(AppDimensions.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Receiving session'),
                    const SizedBox(height: AppDimensions.spaceXs),
                    Text(
                      'Match the web draft-session flow before item capture starts.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceLg),
                    _PickerField(
                      label: 'Supplier',
                      value: _supplier?.supplierName,
                      hint: 'Choose supplier',
                      helperText: 'Search active suppliers',
                      icon: Icons.local_shipping_outlined,
                      onTap: _pickSupplier,
                      errorText: _showSupplierError
                          ? 'Supplier is required.'
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    AppTextField(
                      controller: _doCtl,
                      label: 'DO number',
                      hint: 'DO-2026-001',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'DO number is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _ReadOnlyField(
                      label: 'Stock-in date',
                      value: DateFormatter.toDisplay(_stockInAt),
                      helperText: 'Automatically set when the draft is created',
                      icon: Icons.event_outlined,
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _ReadOnlyField(
                      label: 'PIC user',
                      value: currentUser?.name ?? '-',
                      helperText: 'Automatically assigned to your account',
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
                      'Optional receiving context for downstream review.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceLg),
                    AppTextField(
                      controller: _remarksCtl,
                      label: 'Remarks',
                      hint: 'Enter any notes for the receiving team',
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
      ),
    );
  }
}

// Retained for the shared session-field visual treatment when a field is read-only.
// ignore: unused_element
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
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
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
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
