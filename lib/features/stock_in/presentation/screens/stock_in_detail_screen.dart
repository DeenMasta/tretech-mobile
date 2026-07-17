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
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_banner.dart';
import '../../data/models/stock_in_item_model.dart';
import '../../data/models/stock_in_session_model.dart';
import '../providers/stock_in_list_provider.dart';
import '../providers/stock_in_session_provider.dart';
import '../widgets/print_labels_dialog.dart';
import '../widgets/stock_in_status_badge.dart';

class StockInDetailScreen extends ConsumerWidget {
  const StockInDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockInSessionControllerProvider(sessionId));
    final session = state.session;

    if (state.isLoading || (session == null && state.error == null)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Text('Stock-in session', style: AppTextStyles.titleMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Text('Stock-in session', style: AppTextStyles.titleMedium),
        ),
        body: AppErrorWidget(
          message: state.error ?? 'Session not found.',
          onRetry: () => ref
              .read(stockInSessionControllerProvider(sessionId).notifier)
              .refresh(),
        ),
      );
    }

    final isDraft = session.isDraft;
    final items = state.items;
    final canFinalize = isDraft && items.isNotEmpty && !state.isSaving;
    final holdingCount = items.where((item) => item.missingLotFlag).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text(session.sessionNo, style: AppTextStyles.titleMedium),
        actions: [
          if (isDraft)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit session',
              onPressed: () =>
                  context.push(RouteNames.stockInEditPath(sessionId)),
            ),
          if (session.isConfirmed && items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print_rounded),
              tooltip: 'Print QR labels',
              onPressed: () => PrintLabelsDialog.show(context, items),
            ),
          const SizedBox(width: AppDimensions.spaceXs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(stockInSessionControllerProvider(sessionId).notifier)
            .refresh(),
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          children: [
            _SessionCard(session: session),
            if (canFinalize) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              _FinalizeActionCard(
                itemCount: items.length,
                holdingCount: holdingCount,
                isSaving: state.isSaving,
                onPressed: () =>
                    _confirmFinalize(context, ref, items.length, holdingCount),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceLg),
            _ItemsSection(
              sessionId: sessionId,
              items: items,
              isDraft: isDraft,
              isSaving: state.isSaving,
            ),
            if (state.error != null) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              _ErrorBanner(message: state.error!),
            ],
            // Extra padding so FAB doesn't cover last item
            const SizedBox(height: 88),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmFinalize(
    BuildContext context,
    WidgetRef ref,
    int itemCount,
    int holdingCount,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalize this session?'),
        content: Text(
          holdingCount > 0
              ? 'This will finalize $itemCount item${itemCount == 1 ? '' : 's'} '
                    'and place $holdingCount missing-lot item${holdingCount == 1 ? '' : 's'} '
                    'into holding. This action cannot be undone.'
              : 'This will create lots for all $itemCount '
                    'item${itemCount == 1 ? '' : 's'}. '
                    'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final notifier = ref.read(
      stockInSessionControllerProvider(sessionId).notifier,
    );
    final success = await notifier.finalize();
    if (!context.mounted) return;
    if (success) {
      ref.invalidate(stockInListProvider);
      context.pushReplacement(RouteNames.stockInFinalizedPath(sessionId));
    }
  }
}

// ── Session detail card ──────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final StockInSessionModel session;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.sessionNo,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DO ${session.doNumber}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StockInStatusBadge(status: session.status),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.spaceMd),
          _kv('Supplier', session.supplierName),
          _kv('PIC', session.picUserName),
          _kv('Date', DateFormatter.toDisplay(session.stockInAt)),
          _kv('Items', '${session.itemsCount ?? 0}'),
          if (session.remarks != null && session.remarks!.isNotEmpty)
            _kv('Remarks', session.remarks!),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
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
}

// ── Items section ────────────────────────────────────────────────────────────

class _ItemsSection extends ConsumerWidget {
  const _ItemsSection({
    required this.sessionId,
    required this.items,
    required this.isDraft,
    required this.isSaving,
  });

  final int sessionId;
  final List<StockInItemModel> items;
  final bool isDraft;
  final bool isSaving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missingLotCount = items.where((i) => i.missingLotFlag).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Items',
          count: items.length,
          metaText: missingLotCount > 0 ? '$missingLotCount missing lot' : null,
          trailing: isDraft
              ? AppButton(
                label: 'Add item',
                icon: Icons.add_rounded,
                size: AppButtonSize.sm,
                isFullWidth: false,
                onPressed: () =>
                  context.push(RouteNames.stockInItemAddPath(sessionId)),
                )
              : null,
        ),
        const SizedBox(height: AppDimensions.spaceSm),

        // Empty state
        if (items.isEmpty)
          ContentCard(
            padding: const EdgeInsets.all(AppDimensions.space3xl),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                Text(
                  isDraft
                      ? 'No items yet. Tap "Add item" to begin capturing.'
                      : 'No items in this session.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...items.map(
            (item) => _ItemTile(
              item: item,
              isDraft: isDraft,
              isSaving: isSaving,
              onEdit: isDraft
                  ? () => context.push(
                      RouteNames.stockInItemEditPath(sessionId, item.id),
                    )
                  : null,
              onDelete: isDraft
                  ? () => _confirmDelete(context, ref, item)
                  : null,
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    StockInItemModel item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove ${item.productLabel} from this draft session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(stockInSessionControllerProvider(sessionId).notifier)
        .removeItem(item.id);
  }
}

class _FinalizeActionCard extends StatelessWidget {
  const _FinalizeActionCard({
    required this.itemCount,
    required this.holdingCount,
    required this.isSaving,
    required this.onPressed,
  });

  final int itemCount;
  final int holdingCount;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to finalize',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            holdingCount > 0
                ? 'This will finalize $itemCount item${itemCount == 1 ? '' : 's'} and move $holdingCount missing-lot item${holdingCount == 1 ? '' : 's'} to holding.'
                : 'This will finalize $itemCount captured item${itemCount == 1 ? '' : 's'} and create inventory lots.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppButton(
            label: 'Finalize session',
            icon: Icons.check_circle_outline_rounded,
            isFullWidth: false,
            isLoading: isSaving,
            onPressed: isSaving ? null : onPressed,
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.isDraft,
    required this.isSaving,
    this.onEdit,
    this.onDelete,
  });

  final StockInItemModel item;
  final bool isDraft;
  final bool isSaving;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: isDraft
          ? Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                onDelete?.call();
                return false; // let the dialog handle actual deletion
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppDimensions.spaceLg),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
              ),
              child: _cardContent(context),
            )
          : _cardContent(context),
    );
  }

  Widget _cardContent(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: ContentCard(
        borderColor: item.missingLotFlag
            ? AppColors.warning.withValues(alpha: 0.4)
            : AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name row
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isDraft)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _kv(
              item.isSetEntry ? 'Kind' : 'Lot',
              item.isSetEntry ? item.entryKindLabel : item.lotLabel,
            ),
            _kv('Qty', '${item.quantity ?? 1}'),
            _kv('Mfg date', item.manufacturingDateLabel),
            if (item.expiryDate != null)
              _kv('Expiry', DateFormatter.toDisplay(item.expiryDate!)),
            if (item.isSetEntry &&
                (item.instrumentSet?.items.isNotEmpty ?? false)) ...[
              const SizedBox(height: 6),
              ...item.instrumentSet!.items
                  .take(5)
                  .map(
                    (component) => Text(
                      '${component.name}${component.code?.trim().isNotEmpty == true ? ' (${component.code})' : ''} x ${component.quantity}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
            ],
            // Badges row
            if (item.isSetEntry ||
                item.missingLotFlag ||
                item.lotEntryMode == LotEntryMode.manual ||
                item.expiryEntryMode == LotEntryMode.manual) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  if (item.isSetEntry) _badge('Set entry', AppColors.info),
                  if (item.missingLotFlag)
                    _badge('Missing lot', AppColors.warning),
                  if (item.lotEntryMode == LotEntryMode.manual ||
                      item.expiryEntryMode == LotEntryMode.manual)
                    _badge('Manual entry', AppColors.info),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
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

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
}

// ── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return StatusBanner(
      message: message,
      icon: Icons.warning_amber_rounded,
      foregroundColor: AppColors.error,
      backgroundColor: AppColors.errorContainer,
      borderColor: AppColors.error.withValues(alpha: 0.3),
    );
  }
}
