import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/stock_in_session_provider.dart';

class StockInItemCorrectionScreen extends ConsumerStatefulWidget {
  const StockInItemCorrectionScreen({
    super.key,
    required this.sessionId,
    required this.itemId,
  });
  final int sessionId;
  final int itemId;
  @override
  ConsumerState<StockInItemCorrectionScreen> createState() =>
      _StockInItemCorrectionScreenState();
}

class _StockInItemCorrectionScreenState
    extends ConsumerState<StockInItemCorrectionScreen> {
  final _lotCtl = TextEditingController();
  final _reasonCtl = TextEditingController();
  DateTime? _manufacturingDate;
  DateTime? _expiryDate;
  bool _saving = false;

  @override
  void dispose() {
    _lotCtl.dispose();
    _reasonCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool manufacturing) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: (manufacturing ? _manufacturingDate : _expiryDate) ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null && mounted) {
      setState(() {
        if (manufacturing) {
          _manufacturingDate = selected;
        } else {
          _expiryDate = selected;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_reasonCtl.text.trim().length < 5 ||
        (_lotCtl.text.trim().isEmpty &&
            _manufacturingDate == null &&
            _expiryDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Provide a correction and an admin reason of at least 5 characters.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final success = await ref
        .read(stockInSessionControllerProvider(widget.sessionId).notifier)
        .correctItem(
          widget.itemId,
          lotNumber: _lotCtl.text,
          manufacturingDate: _manufacturingDate,
          expiryDate: _expiryDate,
          adminReason: _reasonCtl.text,
        );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stock-in item corrected.')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.sidebarBg,
      title: Text('Correct stock-in item', style: AppTextStyles.titleMedium),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: AppButton(
          label: 'Apply correction',
          icon: Icons.verified_outlined,
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      children: [
        Text(
          'Apply an audited correction to a finalized item. Only changed fields are sent.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        AppTextField(
          controller: _lotCtl,
          label: 'Corrected lot number',
          hint: 'LOT-2026-001',
          prefixIcon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        _dateField(
          'Corrected manufacturing date',
          _manufacturingDate,
          () => _pickDate(true),
          () => setState(() => _manufacturingDate = null),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        _dateField(
          'Corrected expiry date',
          _expiryDate,
          () => _pickDate(false),
          () => setState(() => _expiryDate = null),
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        AppTextField(
          controller: _reasonCtl,
          label: 'Admin reason *',
          hint: 'Explain why this finalized item needs correction',
          prefixIcon: Icons.edit_note_rounded,
          maxLines: 3,
        ),
      ],
    ),
  );

  Widget _dateField(
    String label,
    DateTime? value,
    VoidCallback pick,
    VoidCallback clear,
  ) => InkWell(
    onTap: pick,
    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    child: Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 18),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value == null
                      ? 'Tap to select'
                      : DateFormatter.toDisplay(value),
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          if (value != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: clear,
            ),
        ],
      ),
    ),
  );
}
