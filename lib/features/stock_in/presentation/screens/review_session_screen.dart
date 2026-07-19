import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/stock_in_item_model.dart';
import '../providers/stock_in_session_provider.dart';
import '../widgets/stock_in_status_badge.dart';

class ReviewSessionScreen extends ConsumerWidget {
  const ReviewSessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockInSessionControllerProvider(sessionId));
    final session = state.session;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text('Review session', style: AppTextStyles.titleMedium),
      ),
      body: state.isLoading || session == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.spaceLg),
              children: [
                _sessionPanel(state),
                const SizedBox(height: AppDimensions.spaceLg),
                _itemsPanel(state),
                if (state.error != null) ...[
                  const SizedBox(height: AppDimensions.spaceMd),
                  _errorBox(state.error!),
                ],
                const SizedBox(height: AppDimensions.spaceLg),
              ],
            ),
      bottomNavigationBar: session == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceLg),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Back to scan',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.qr_code_scanner_rounded,
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceMd),
                    Expanded(
                      child: AppButton(
                        label: session.isConfirmed
                            ? 'Already confirmed'
                            : 'Confirm',
                        icon: Icons.check_circle_outline,
                        isLoading: state.isSaving,
                        onPressed: session.isConfirmed
                            ? null
                            : () => _confirm(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sessionPanel(StockInSessionState state) {
    final s = state.session!;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.sessionNo,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StockInStatusBadge(status: s.status),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          _kv('Supplier', s.supplierName),
          _kv('DO number', s.doNumber),
          _kv('PIC', s.picUserName),
          _kv('Date / time', DateFormatter.toDisplayDateTime(s.stockInAt)),
          if (s.remarks != null && s.remarks!.isNotEmpty)
            _kv('Remarks', s.remarks!),
        ],
      ),
    );
  }

  Widget _itemsPanel(StockInSessionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Items',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
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
        ...state.items.map(_itemTile),
      ],
    );
  }

  Widget _itemTile(StockInItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productLabel,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _kv('Lot', item.lotLabel),
          _kv('Batch', item.supplierBatchCode),
          if (item.expiryDate != null)
            _kv('Expiry', DateFormatter.toDisplay(item.expiryDate!)),
          if (item.missingLotFlag)
            _badge('Missing lot — flagged', AppColors.warning),
          if (item.lotEntryMode == LotEntryMode.manual ||
              item.expiryEntryMode == LotEntryMode.manual)
            _badge('Manual entry', AppColors.info),
          if (item.entryOverrideReason != null &&
              item.entryOverrideReason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reason: ${item.entryOverrideReason}',
              style: AppTextStyles.labelSmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
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
          Expanded(child: Text(v, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        msg,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalize this session?'),
        content: const Text(
          'Confirming will create lots and QR labels for every item. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final notifier = ref.read(
      stockInSessionControllerProvider(sessionId).notifier,
    );
    final success = await notifier.finalize();
    if (!context.mounted) return;
    if (success) {
      context.pushReplacement('/stock-in/$sessionId/confirmation');
    }
  }
}
