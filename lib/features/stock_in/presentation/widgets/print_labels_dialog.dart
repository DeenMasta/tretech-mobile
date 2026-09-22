import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/stock_in_item_model.dart';
import '../providers/qr_print_provider.dart';

/// Bottom-sheet dialog for selecting and printing QR labels for a session.
/// Supports "Print All" and selective individual lot printing.
class PrintLabelsDialog extends ConsumerStatefulWidget {
  const PrintLabelsDialog({super.key, required this.items});

  /// All items from the session (only those with a lotId will be printable).
  final List<StockInItemModel> items;

  /// Show the dialog.
  static Future<void> show(BuildContext context, List<StockInItemModel> items) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrintLabelsDialog(items: items),
    );
  }

  @override
  ConsumerState<PrintLabelsDialog> createState() => _PrintLabelsDialogState();
}

class _PrintLabelsDialogState extends ConsumerState<PrintLabelsDialog> {
  late final List<StockInItemModel> _printable;
  late final Set<int> _selected; // lotId set
  late final Map<int, int> _labelQuantities; // lotId -> requested copies

  @override
  void initState() {
    super.initState();
    _printable = widget.items
        .where((i) => i.lotId != null && !i.missingLotFlag)
        .toList();
    _selected = _printable.map((i) => i.lotId!).toSet();
    _labelQuantities = {};
  }

  bool get _allSelected => _selected.length == _printable.length;

  int get _selectedLabelCount => _printable
      .where((item) => _selected.contains(item.lotId))
      .fold(0, (total, item) => total + _quantityFor(item));

  int get _printableLabelCount =>
      _printable.fold(0, (total, item) => total + _quantityFor(item));

  int _quantityFor(StockInItemModel item) =>
      _labelQuantities[item.lotId] ?? item.labelPrintQuantity;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected.addAll(_printable.map((i) => i.lotId!));
      }
    });
  }

  void _toggle(int lotId) {
    setState(() {
      if (_selected.contains(lotId)) {
        _selected.remove(lotId);
      } else {
        _selected.add(lotId);
      }
    });
  }

  Future<void> _print(
    String macAddress, {
    required Map<int, int> labelQuantities,
  }) async {
    final selectedItems = _printable
        .where((i) => _selected.contains(i.lotId))
        .toList();

    await ref
        .read(qrPrintNotifierProvider.notifier)
        .printSelected(
          selectedItems,
          macAddress,
          labelQuantities: labelQuantities,
        );
  }

  Future<void> _requestPrintQuantities(String macAddress) async {
    final selectedItems = _printable
        .where((item) => _selected.contains(item.lotId))
        .toList();
    final quantities = await showDialog<Map<int, int>>(
      context: context,
      builder: (_) => _LabelQuantityDialog(
        items: selectedItems,
        initialQuantities: _labelQuantities,
      ),
    );

    if (!mounted || quantities == null) return;

    setState(() => _labelQuantities.addAll(quantities));
    await _print(macAddress, labelQuantities: quantities);
  }

  @override
  Widget build(BuildContext context) {
    final printer = ref.watch(settingsProvider);
    final printState = ref.watch(qrPrintNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceLg,
                  AppDimensions.spaceSm,
                  AppDimensions.spaceLg,
                  0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.print_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Text(
                      'Print QR Labels',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: printState.isPrinting
                          ? null
                          : () => Navigator.pop(context),
                      color: AppColors.textMuted,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              const Divider(),

              if (printState.isPrinting || printState.isDone) ...[
                // ── Progress / Result view ─────────────────────────────────
                Expanded(
                  child: _PrintProgressView(
                    state: printState,
                    onDone: () {
                      ref.read(qrPrintNotifierProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ] else ...[
                // ── Selection view ─────────────────────────────────────────
                // Printer info banner
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceLg,
                    vertical: AppDimensions.spaceSm,
                  ),
                  child: _printerBanner(
                    context,
                    printer.isConfigured,
                    printer.printerName,
                    printer.macAddress,
                  ),
                ),

                if (_printable.isEmpty) ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.print_disabled_rounded,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: AppDimensions.spaceMd),
                          Text(
                            'No printable lots found.\nItems with missing lots cannot be printed.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Select All toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceLg,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _allSelected,
                          tristate: true,
                          onChanged: (_) => _toggleAll(),
                          activeColor: AppColors.primary,
                        ),
                        Text(
                          'Select All (${_printable.length} lots, $_printableLabelCount labels)',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_selectedLabelCount labels',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Lot list
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: _printable.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = _printable[i];
                        final lotId = item.lotId!;
                        final checked = _selected.contains(lotId);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (_) => _toggle(lotId),
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            item.productLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${item.lot?.lotNumber ?? item.scannedLotNumber ?? '—'} · ${_quantityFor(item)} label${_quantityFor(item) == 1 ? '' : 's'}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          secondary: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: checked
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              size: 16,
                              color: checked
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom action bar
                  const Divider(height: 1),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spaceLg),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Print All',
                              icon: Icons.print_rounded,
                              onPressed:
                                  !printer.isConfigured || _printable.isEmpty
                                  ? null
                                  : () async {
                                      // Select all then print
                                      setState(
                                        () => _selected.addAll(
                                          _printable.map((i) => i.lotId!),
                                        ),
                                      );
                                      await _requestPrintQuantities(
                                        printer.macAddress,
                                      );
                                    },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceSm),
                          Expanded(
                            child: AppButton(
                              label: 'Print Selected ($_selectedLabelCount)',
                              icon: Icons.checklist_rounded,
                              variant: AppButtonVariant.secondary,
                              onPressed:
                                  !printer.isConfigured || _selected.isEmpty
                                  ? null
                                  : () => _requestPrintQuantities(
                                      printer.macAddress,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _printerBanner(
    BuildContext context,
    bool isConfigured,
    String name,
    String mac,
  ) {
    if (isConfigured) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
          vertical: AppDimensions.spaceSm,
        ),
        decoration: BoxDecoration(
          color: AppColors.successContainer,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bluetooth_connected_rounded,
              size: 16,
              color: AppColors.success,
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: Text(
                'Printer: $name',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: AppDimensions.spaceSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(
              'No printer configured.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(RouteNames.settings);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }
}

// ── Progress view ─────────────────────────────────────────────────────────────

class _LabelQuantityDialog extends StatefulWidget {
  const _LabelQuantityDialog({
    required this.items,
    required this.initialQuantities,
  });

  final List<StockInItemModel> items;
  final Map<int, int> initialQuantities;

  @override
  State<_LabelQuantityDialog> createState() => _LabelQuantityDialogState();
}

class _LabelQuantityDialogState extends State<_LabelQuantityDialog> {
  late final Map<int, TextEditingController> _controllers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final item in widget.items)
        item.lotId!: TextEditingController(
          text: widget.initialQuantities[item.lotId]?.toString() ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    final quantities = <int, int>{};
    for (final item in widget.items) {
      final quantity = int.tryParse(_controllers[item.lotId]!.text);
      if (quantity == null || quantity < 1) {
        setState(
          () => _error = 'Enter a label quantity of at least 1 for every item.',
        );
        return;
      }
      quantities[item.lotId!] = quantity;
    }
    Navigator.pop(context, quantities);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold<int>(
      0,
      (sum, item) => sum + (int.tryParse(_controllers[item.lotId]!.text) ?? 0),
    );

    return AlertDialog(
      title: const Text('Label print quantity'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set how many labels to print for each selected item.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              ...widget.items.map((item) {
                final lotNumber =
                    item.lot?.lotNumber ?? item.scannedLotNumber ?? '-';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lot: $lotNumber',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMd),
                      SizedBox(
                        width: 88,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Labels',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHighest,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.inputRadius,
                                ),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.25,
                                ),
                              ),
                              child: TextField(
                                controller: _controllers[item.lotId],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (_) => setState(() => _error = null),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.print_rounded),
                label: Text('Print $total labels'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrintProgressView extends StatelessWidget {
  const _PrintProgressView({required this.state, required this.onDone});

  final QrPrintJobState state;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final progress = state.total > 0 ? state.printed / state.total : 0.0;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.isPrinting) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: AppDimensions.spaceLg),
            Text(
              'Printing ${state.printed} of ${state.total}…',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ] else if (state.isDone) ...[
            Icon(
              state.hasErrors
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              size: 56,
              color: state.hasErrors ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Text(
              state.hasErrors
                  ? 'Printed with ${state.errors.length} error(s)'
                  : 'All ${state.total} label(s) printed successfully!',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.hasErrors) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: state.errors
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• $e',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceLg),
            SizedBox(
              width: double.infinity,
              child: AppButton(label: 'Done', onPressed: onDone),
            ),
          ],
        ],
      ),
    );
  }
}
