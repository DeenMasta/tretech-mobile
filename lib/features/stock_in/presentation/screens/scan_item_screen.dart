import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_in_item_model.dart';
import '../../data/repositories/master_data_repository.dart';
import '../providers/master_data_providers.dart';
import '../providers/stock_in_session_provider.dart';
import '../widgets/barcode_scanner_sheet.dart';
import '../widgets/scan_step_card.dart';
import '../widgets/stock_in_status_badge.dart';

class ScanItemScreen extends ConsumerStatefulWidget {
  const ScanItemScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<ScanItemScreen> createState() => _ScanItemScreenState();
}

class _ScanItemScreenState extends ConsumerState<ScanItemScreen> {
  final _batchCtl = TextEditingController();
  final _overrideCtl = TextEditingController();

  @override
  void dispose() {
    _batchCtl.dispose();
    _overrideCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(stockInSessionControllerProvider(widget.sessionId));
    final draft = ref.watch(itemDraftProvider);
    final session = state.session;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text(
          session?.sessionNo ?? 'Stock-in session',
          style: AppTextStyles.titleMedium,
        ),
        actions: [
          if (session != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spaceMd),
              child: Center(child: StockInStatusBadge(status: session.status)),
            ),
        ],
      ),
      body: state.isLoading || session == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(state, draft),
      bottomNavigationBar: state.session == null
          ? null
          : _buildBottomBar(state, draft),
    );
  }

  // — Body & helpers populated below via replace_in_file —

  Widget _buildBody(StockInSessionState state, ItemDraft draft) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      children: [
        _buildSessionInfo(state),
        const SizedBox(height: AppDimensions.spaceLg),
        _buildSteps(draft),
        const SizedBox(height: AppDimensions.spaceLg),
        _buildItemsList(state),
        if (state.error != null) ...[
          const SizedBox(height: AppDimensions.spaceMd),
          _buildError(state.error!),
        ],
      ],
    );
  }

  Widget _buildSessionInfo(StockInSessionState state) {
    final s = state.session!;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Supplier', s.supplierName),
          _kv('DO number', s.doNumber),
          _kv('PIC', s.picUserName),
          _kv('Date', DateFormatter.toDisplayDateTime(s.stockInAt)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              k,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(v, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ── Steps ────────────────────────────────────────────────────
  Widget _buildSteps(ItemDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scan a new item',
            style: AppTextStyles.titleSmall
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          'Follow each step to capture the lot details.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        ScanStepCard(
          index: 1,
          title: 'Scan product',
          subtitle: 'Tap to scan the product ref-num barcode',
          icon: Icons.qr_code_2_rounded,
          completed: draft.hasProduct,
          active: !draft.hasProduct,
          value: draft.product != null
              ? '${draft.product!.refNum} • ${draft.product!.productName}'
              : null,
          onTap: _onScanProduct,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        ScanStepCard(
          index: 2,
          title: 'Scan lot number',
          subtitle: draft.missingLotFlag
              ? 'Lot flagged as missing — manual override active'
              : 'Tap to scan the lot number on the package',
          icon: Icons.inventory_2_rounded,
          completed: draft.hasLot,
          active: draft.hasProduct && !draft.hasLot,
          value: draft.scannedLotNumber,
          onTap: draft.hasProduct ? _onScanLot : null,
          trailing: draft.hasProduct
              ? IconButton(
                  tooltip: draft.missingLotFlag
                      ? 'Clear missing-lot flag'
                      : 'Mark as missing',
                  icon: Icon(
                    draft.missingLotFlag
                        ? Icons.report_problem_rounded
                        : Icons.report_problem_outlined,
                    color: draft.missingLotFlag
                        ? AppColors.warning
                        : AppColors.textMuted,
                  ),
                  onPressed: () => ref
                      .read(itemDraftProvider.notifier)
                      .setMissingLot(!draft.missingLotFlag),
                )
              : null,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        ScanStepCard(
          index: 3,
          title: 'Scan / pick expiry',
          subtitle: 'Scan expiry barcode or pick the date',
          icon: Icons.event_outlined,
          completed: draft.hasExpiry,
          active: draft.hasLot && !draft.hasExpiry,
          value: draft.expiryDate != null
              ? DateFormatter.toDisplay(draft.expiryDate!)
              : null,
          onTap: draft.hasLot ? _onPickExpiry : null,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        ScanStepCard(
          index: 4,
          title: 'Supplier batch code',
          subtitle: 'Type the supplier batch code (required)',
          icon: Icons.tag_rounded,
          completed: draft.hasBatch,
          active: draft.hasLot,
          value: draft.supplierBatchCode.isEmpty
              ? null
              : draft.supplierBatchCode,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        AppTextField(
          controller: _batchCtl,
          hint: 'Supplier batch code',
          prefixIcon: Icons.tag_rounded,
          onChanged: (v) =>
              ref.read(itemDraftProvider.notifier).setBatch(v),
        ),
        if (draft.requiresOverrideReason) ...[
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            controller: _overrideCtl,
            label: 'Override reason (required for manual entries)',
            hint: 'e.g. Lot label damaged on package',
            maxLines: 2,
            onChanged: (v) => ref
                .read(itemDraftProvider.notifier)
                .setOverrideReason(v.trim().isEmpty ? null : v.trim()),
          ),
        ],
      ],
    );
  }

  // ── Scan handlers ────────────────────────────────────────────
  Future<void> _onScanProduct() async {
    final result = await BarcodeScannerSheet.show(
      context,
      title: 'Scan product',
      helperText: 'Aim at the product ref-num barcode',
    );
    if (result == null || !mounted) return;

    ProductModel? product;
    try {
      final cached = ref.read(productsProvider).valueOrNull ?? const [];
      for (final p in cached) {
        if (p.refNum.toUpperCase() == result.value.toUpperCase()) {
          product = p;
          break;
        }
      }
      product ??= await ref
          .read(stockInMasterDataRepositoryProvider)
          .findProductByRef(result.value);
    } catch (_) {
      product = null;
    }

    if (product == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product "${result.value}" not found.')),
        );
      }
      return;
    }
    ref.read(itemDraftProvider.notifier).setProduct(product);
  }

  Future<void> _onScanLot() async {
    final result = await BarcodeScannerSheet.show(
      context,
      title: 'Scan lot number',
      helperText: 'Aim at the lot-number barcode on the package',
    );
    if (result == null) return;
    ref.read(itemDraftProvider.notifier).setLot(
          lotNumber: result.value,
          mode: result.manual ? LotEntryMode.manual : LotEntryMode.scan,
        );
  }

  Future<void> _onPickExpiry() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner_rounded),
              title: const Text('Scan expiry barcode'),
              onTap: () => Navigator.pop(context, 'scan'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Pick from calendar'),
              onTap: () => Navigator.pop(context, 'pick'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (action == 'scan') {
      final scan = await BarcodeScannerSheet.show(
        context,
        title: 'Scan expiry',
        helperText: 'Scan the expiry barcode (YYYY-MM-DD or YYYYMMDD)',
      );
      if (scan == null) return;
      final parsed = _parseExpiry(scan.value);
      if (parsed == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not parse the expiry value.')),
          );
        }
        return;
      }
      ref.read(itemDraftProvider.notifier).setExpiry(
            date: parsed,
            mode: scan.manual ? LotEntryMode.manual : LotEntryMode.scan,
          );
    } else if (action == 'pick') {
      final now = DateTime.now();
      if (!mounted) return;
      final picked = await showDatePicker(
        context: context,
        initialDate: now.add(const Duration(days: 365)),
        firstDate: now,
        lastDate: now.add(const Duration(days: 365 * 10)),
      );
      if (picked == null) return;
      ref
          .read(itemDraftProvider.notifier)
          .setExpiry(date: picked, mode: LotEntryMode.manual);
    }
  }

  DateTime? _parseExpiry(String raw) {
    final s = raw.trim();
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed;
    if (RegExp(r'^\d{8}$').hasMatch(s)) {
      return DateTime.tryParse(
          '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}');
    }
    return null;
  }

  // ── Items list ───────────────────────────────────────────────
  Widget _buildItemsList(StockInSessionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Scanned items',
              style: AppTextStyles.titleSmall
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                '${state.items.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        if (state.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'No items scanned yet. Complete the steps above to add the first item.',
              style: AppTextStyles.bodySmall,
            ),
          )
        else
          ...state.items.map(_buildItemTile),
      ],
    );
  }

  Widget _buildItemTile(StockInItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productLabel,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Lot: ${item.lotLabel}  •  Batch: ${item.supplierBatchCode}',
                  style: AppTextStyles.bodySmall,
                ),
                if (item.expiryDate != null)
                  Text(
                    'Exp: ${DateFormatter.toDisplay(item.expiryDate!)}',
                    style: AppTextStyles.labelSmall,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: Icon(Icons.delete_outline_rounded,
                color: AppColors.textMuted),
            onPressed: () => _confirmRemove(item.id),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(int itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove item?'),
        content: const Text('This will remove the scanned item from the session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(stockInSessionControllerProvider(widget.sessionId).notifier)
        .removeItem(itemId);
  }

  // ── Bottom bar ───────────────────────────────────────────────
  Widget _buildBottomBar(StockInSessionState state, ItemDraft draft) {
    final canAdd = draft.readyToSubmit && !state.isSaving;
    final overrideOk = !draft.requiresOverrideReason ||
        (draft.entryOverrideReason?.isNotEmpty ?? false);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceLg,
          AppDimensions.spaceMd,
          AppDimensions.spaceLg,
          AppDimensions.spaceMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.sidebarBg,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Add item',
                icon: Icons.add_rounded,
                isLoading: state.isSaving,
                onPressed: (canAdd && overrideOk) ? _onAddItem : null,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceMd),
            Expanded(
              child: AppButton(
                label: 'Review',
                variant: AppButtonVariant.secondary,
                icon: Icons.checklist_rounded,
                onPressed: state.items.isEmpty
                    ? null
                    : () => context.push(
                          '/stock-in/${widget.sessionId}/review',
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAddItem() async {
    final draft = ref.read(itemDraftProvider);
    final ok = await ref
        .read(stockInSessionControllerProvider(widget.sessionId).notifier)
        .addItem(draft);
    if (!mounted) return;
    if (ok) {
      ref.read(itemDraftProvider.notifier).reset();
      _batchCtl.clear();
      _overrideCtl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added.')),
      );
    }
  }
}
