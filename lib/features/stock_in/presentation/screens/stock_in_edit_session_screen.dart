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
import '../../data/models/supplier_model.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/stock_in_repository.dart';
import '../providers/master_data_providers.dart';
import '../providers/stock_in_list_provider.dart';
import '../providers/stock_in_session_provider.dart';
import '../widgets/supplier_search_sheet.dart';

class StockInEditSessionScreen extends ConsumerStatefulWidget {
  const StockInEditSessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<StockInEditSessionScreen> createState() =>
      _StockInEditSessionScreenState();
}

class _StockInEditSessionScreenState
    extends ConsumerState<StockInEditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doCtl = TextEditingController();
  final _remarksCtl = TextEditingController();

  SupplierModel? _supplier;
  DateTime? _stockInAt;
  bool _saving = false;
  bool _initialised = false;

  StockInMasterDataRepository get _masterRepo =>
      ref.read(stockInMasterDataRepositoryProvider);

  @override
  void dispose() {
    _doCtl.dispose();
    _remarksCtl.dispose();
    super.dispose();
  }

  void _seedForm({
    required List<SupplierModel> suppliers,
    required StockInSessionState state,
  }) {
    if (_initialised || state.session == null) {
      return;
    }
    _initialised = true;

    final session = state.session!;
    _supplier = suppliers.cast<SupplierModel?>().firstWhere(
      (item) => item?.id == session.supplierId,
      orElse: () => null,
    );
    _stockInAt = session.stockInAt;
    _doCtl.text = session.doNumber;
    _remarksCtl.text = session.remarks ?? '';
  }

  Future<void> _pickSupplier() async {
    final selected = await SupplierSearchSheet.show(
      context,
      repository: _masterRepo,
    );
    if (selected == null || !mounted) return;
    setState(() => _supplier = selected);
  }

  Future<void> _pickDate() async {
    final initialDate = _stockInAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _stockInAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        initialDate.hour,
        initialDate.minute,
      );
    });
  }

  Future<void> _submit(StockInSessionState state) async {
    final session = state.session;
    if (session == null || !_formKey.currentState!.validate()) {
      return;
    }
    if (_supplier == null || _stockInAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier and date are required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(stockInRepositoryProvider)
          .updateSession(
            session.id,
            supplierId: _supplier!.id,
            doNumber: _doCtl.text.trim(),
            stockInAt: _stockInAt,
            remarks: _remarksCtl.text.trim(),
          );
      ref.invalidate(stockInListProvider);
      ref.invalidate(stockInSessionControllerProvider(widget.sessionId));
      if (!mounted) {
        return;
      }
      context.go(RouteNames.stockInDetailPath(updated.id));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update session: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockInSessionControllerProvider(widget.sessionId));
    final suppliersAsync = ref.watch(suppliersProvider);
    final session = state.session;

    if (state.isLoading && session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Text(
            'Edit stock-in session',
            style: AppTextStyles.titleMedium,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Text(
            'Edit stock-in session',
            style: AppTextStyles.titleMedium,
          ),
        ),
        body: AppErrorWidget(
          message: state.error ?? 'Session not found.',
          onRetry: () => ref
              .read(stockInSessionControllerProvider(widget.sessionId).notifier)
              .refresh(),
        ),
      );
    }

    if (!session.isDraft) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Text(
            'Edit stock-in session',
            style: AppTextStyles.titleMedium,
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spaceLg),
            child: Text('Only draft stock-in sessions can be edited.'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text('Edit stock-in session', style: AppTextStyles.titleMedium),
      ),
      body: SafeArea(
        child: suppliersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorWidget(
            message: 'Failed to load suppliers.',
            onRetry: () => ref.invalidate(suppliersProvider),
          ),
          data: (suppliers) {
            _seedForm(suppliers: suppliers, state: state);
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.spaceLg),
                children: [
                  Text(
                    'Update the draft receiving header. Only draft sessions are editable.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  _PickerField(
                    label: 'Supplier',
                    value: _supplier?.supplierName,
                    hint: 'Tap to search suppliers',
                    icon: Icons.local_shipping_outlined,
                    onTap: _pickSupplier,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  AppTextField(
                    controller: _doCtl,
                    label: 'DO number',
                    hint: 'DO-2026-001',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'DO number is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  _PickerField(
                    label: 'Stock-in date',
                    value: _stockInAt == null
                        ? null
                        : DateFormatter.toDisplay(_stockInAt!),
                    hint: 'Pick stock-in date',
                    helperText: 'Captured when the session was created',
                    icon: Icons.event_outlined,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  _ReadOnlyField(
                    label: 'PIC user',
                    value: session.picUserName,
                    helperText: 'Read-only in mobile flow',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  AppTextField(
                    controller: _remarksCtl,
                    label: 'Remarks',
                    hint: 'Enter any notes for the receiving team',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppDimensions.space3xl),
                  AppButton(
                    label: 'Save changes',
                    isLoading: _saving,
                    onPressed: _saving ? null : () => _submit(state),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  AppButton(
                    label: 'Back',
                    variant: AppButtonVariant.ghost,
                    onPressed: _saving
                        ? null
                        : () => context.go(
                            RouteNames.stockInDetailPath(session.id),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
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
        InputDecorator(
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: AppColors.surfaceElevated,
          ),
          child: Text(value, style: AppTextStyles.bodyMedium),
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
  });

  final String label;
  final String hint;
  final String? value;
  final String? helperText;
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
              suffixIcon: const Icon(Icons.search_rounded, size: 18),
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
        if (helperText != null) ...[
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
