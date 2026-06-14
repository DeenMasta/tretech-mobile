import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/stock_in_session_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/repositories/stock_in_repository.dart';
import '../providers/master_data_providers.dart';
import '../providers/stock_in_list_provider.dart';

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
  StockInUserBrief? _pic;
  DateTime _stockInAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _doCtl.dispose();
    _remarksCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _stockInAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_stockInAt),
    );
    if (time == null) return;
    setState(() {
      _stockInAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supplier == null || _pic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a supplier and PIC.')),
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
        picUserId: _pic!.id,
        remarks: _remarksCtl.text.trim(),
      );
      ref.invalidate(stockInListProvider);
      if (!mounted) return;
      context.pushReplacement('/stock-in/${session.id}/scan');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final picUsersAsync = ref.watch(picUsersProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Default PIC to current user.
    if (_pic == null && currentUser != null) {
      _pic = StockInUserBrief(id: currentUser.id, fullName: currentUser.name);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text('Create stock-in session', style: AppTextStyles.titleMedium),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: [
              _sectionHeader('Session information'),
              const SizedBox(height: AppDimensions.spaceMd),
              suppliersAsync.when(
                loading: () => const _Loading(),
                error: (e, _) => const _ErrorBox('Failed to load suppliers'),
                data: (suppliers) => _supplierField(suppliers),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppTextField(
                controller: _doCtl,
                label: 'DO number',
                hint: 'e.g. DO-2026-001',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _dateTimeField(),
              const SizedBox(height: AppDimensions.spaceMd),
              picUsersAsync.when(
                loading: () => const _Loading(),
                error: (e, _) => const SizedBox.shrink(),
                data: (users) => _picField(users, currentUser),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppTextField(
                controller: _remarksCtl,
                label: 'Remarks (optional)',
                hint: 'Add any notes for this session',
                maxLines: 3,
              ),
              const SizedBox(height: AppDimensions.space3xl),
              AppButton(
                label: 'Create & start scanning',
                icon: Icons.qr_code_scanner_rounded,
                isLoading: _saving,
                onPressed: _submit,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.ghost,
                onPressed: _saving ? null : () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _supplierField(List<SupplierModel> suppliers) {
    return DropdownButtonFormField<SupplierModel>(
      initialValue: _supplier,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Supplier',
        prefixIcon: Icon(Icons.local_shipping_outlined, size: 18),
      ),
      items: suppliers
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s.supplierName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _supplier = v),
      validator: (v) => v == null ? 'Pick a supplier' : null,
    );
  }

  Widget _picField(List<StockInUserBrief> users, UserModel? currentUser) {
    final list = [
      if (currentUser != null &&
          !users.any((u) => u.id == currentUser.id))
        StockInUserBrief(id: currentUser.id, fullName: currentUser.name),
      ...users,
    ];

    if (list.isEmpty) {
      return AppTextField(
        controller: TextEditingController(
          text: currentUser?.name ?? '—',
        ),
        label: 'PIC',
        readOnly: true,
        prefixIcon: Icons.person_outline,
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _pic?.id,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'PIC (Person in charge)',
        prefixIcon: Icon(Icons.person_outline, size: 18),
      ),
      items: list
          .map(
            (u) => DropdownMenuItem(
              value: u.id,
              child: Text(u.fullName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (id) {
        if (id == null) return;
        setState(() => _pic = list.firstWhere((u) => u.id == id));
      },
      validator: (v) => v == null ? 'Pick a PIC' : null,
    );
  }

  Widget _dateTimeField() {
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Stock-in date & time',
          prefixIcon: Icon(Icons.event_outlined, size: 18),
        ),
        child: Text(
          DateFormatter.toDisplayDateTime(_stockInAt),
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),
    );
  }
}
