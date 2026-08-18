import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
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
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/return_session_model.dart';
import '../../data/repositories/returns_repository.dart';
import '../providers/returns_detail_provider.dart';
import '../providers/returns_list_provider.dart';
import '../widgets/return_status_badge.dart';

class ReturnDetailScreen extends ConsumerWidget {
  const ReturnDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(returnDetailProvider(sessionId));
    final session = state.session;

    if (state.isLoading || (session == null && state.error == null)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Text('Return session', style: AppTextStyles.titleMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Text('Return session', style: AppTextStyles.titleMedium),
        ),
        body: AppErrorWidget(
          message: state.error ?? 'Session not found.',
          onRetry: () =>
              ref.read(returnDetailProvider(sessionId).notifier).refresh(),
        ),
      );
    }

    final permissions = ref.watch(currentUserProvider)?.permissions ?? const [];
    final canComplete =
        !session.isReadOnly &&
        !state.isSaving &&
        (session.items?.isNotEmpty == true || (session.itemsCount ?? 0) > 0) &&
        permissions.contains('returns.finalize');
    final canReopen =
        session.isCompleted &&
        permissions.contains('returns.reopen_reconciliation');
    final canEditItemRemarks =
        !session.isReadOnly && permissions.contains('returns.create');
    final canEditReconciliationRemarks =
        session.reconciliation != null &&
        permissions.contains('returns.finalize');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Returns',
          onPressed: () => context.go(RouteNames.returns),
        ),
        title: Text(session.returnSessionNo, style: AppTextStyles.titleMedium),
        actions: [
          if (session.reconciliation != null)
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print usage / invoice note',
              onPressed: () => _print(context, ref, session.id),
            ),
          const SizedBox(width: AppDimensions.spaceXs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(returnDetailProvider(sessionId).notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          children: [
            // ── Session detail card ────────────────────────────────────────
            _SessionCard(session: session),

            // ── Complete action card (prominent, full-width per UI rules) ──
            if (canComplete) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              _CompleteActionCard(
                itemCount: session.items?.length ?? (session.itemsCount ?? 0),
                isSaving: state.isSaving,
                onPressed: () => _confirmComplete(context, ref, session),
              ),
            ],

            // ── Reopen action ──────────────────────────────────────────────
            if (canReopen) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              _ReopenActionCard(
                isSaving: state.isSaving,
                onPressed: () => _showReopenDialog(context, ref),
              ),
            ],

            const SizedBox(height: AppDimensions.spaceLg),

            // ── Returned lots section ──────────────────────────────────────
            _ItemsSection(
              sessionId: sessionId,
              session: session,
              isSaving: state.isSaving,
              canEditRemarks: canEditItemRemarks,
              onEditRemarks: (item) => _editRemarks(
                context: context,
                title: 'Edit returned item remarks',
                initialValue: item.remarks,
                onSave: (remarks) => ref
                    .read(returnDetailProvider(sessionId).notifier)
                    .updateItemRemarks(item.id, remarks),
              ),
            ),

            // ── Usage / invoice report (after reconciliation) ──────────────
            if (session.reconciliation != null &&
                session.reconciliation!.items.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spaceLg),
              _ReconciliationSection(
                items: session.reconciliation!.items,
                canEditRemarks: canEditReconciliationRemarks,
                onEditItemRemarks: (item) => _editRemarks(
                  context: context,
                  title: 'Edit usage item remarks',
                  initialValue: item.remarks,
                  onSave: (remarks) => ref
                      .read(returnDetailProvider(sessionId).notifier)
                      .updateReconciliationItemRemarks(
                        session.reconciliation!.id,
                        item.id,
                        remarks,
                      ),
                ),
                onEditComponentRemarks: (item, component) => _editRemarks(
                  context: context,
                  title: 'Edit component remarks',
                  initialValue: component.remarks,
                  onSave: (remarks) => ref
                      .read(returnDetailProvider(sessionId).notifier)
                      .updateReconciliationComponentRemarks(
                        session.reconciliation!.id,
                        item.id,
                        component.id,
                        remarks,
                      ),
                ),
              ),
            ],

            // ── Error banner ───────────────────────────────────────────────
            if (state.error != null) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              StatusBanner(
                message: state.error!,
                icon: Icons.warning_amber_rounded,
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.errorContainer,
                borderColor: AppColors.error.withValues(alpha: 0.3),
              ),
            ],

            const SizedBox(height: 88),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmComplete(
    BuildContext context,
    WidgetRef ref,
    ReturnSessionModel session,
  ) async {
    final itemCount = session.items?.length ?? (session.itemsCount ?? 0);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete this return session?'),
        content: Text(
          'This will finalize $itemCount returned lot${itemCount == 1 ? '' : 's'} '
          'and generate the usage/invoice report. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete return'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await ref
        .read(returnDetailProvider(session.id).notifier)
        .complete();
    if (success && context.mounted) {
      ref.invalidate(returnListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return session completed.')),
      );
    }
  }

  Future<void> _editRemarks({
    required BuildContext context,
    required String title,
    required String? initialValue,
    required Future<bool> Function(String? remarks) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(hintText: 'Optional remarks'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await onSave(controller.text);
              if (dialogContext.mounted && success) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Remarks saved.')));
    }
  }

  Future<void> _print(
    BuildContext context,
    WidgetRef ref,
    int sessionId,
  ) async {
    try {
      final bytes = await ref.read(returnsRepositoryProvider).print(sessionId);
      if (bytes.isEmpty) throw StateError('The return PDF was empty.');
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to print return: $e')));
      }
    }
  }

  Future<void> _showReopenDialog(BuildContext context, WidgetRef ref) async {
    final reasonCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reopen return session?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will discard the usage report and allow scanning again. '
              'All items marked as "used" will be reverted.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtl,
              decoration: const InputDecoration(
                labelText: 'Reason for reopening',
                hintText: 'Briefly explain why',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reopen'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final reason = reasonCtl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for reopening.')),
      );
      return;
    }
    await ref.read(returnDetailProvider(sessionId).notifier).reopen(reason);
  }
}

// ── Session summary card ──────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final ReturnSessionModel session;

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
                      session.returnSessionNo,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.consignment?.consignmentNo ?? '—',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ReturnStatusBadge(status: session.status),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.spaceMd),
          _kv('PIC', session.picUserName),
          if (session.consignment?.clientName != null)
            _kv('Client', session.consignment!.clientName!),
          if (session.startedAt != null)
            _kv('Started', DateFormatter.toDisplayDateTime(session.startedAt!)),
          if (session.completedAt != null)
            _kv(
              'Completed',
              DateFormatter.toDisplayDateTime(session.completedAt!),
            ),
          if (session.completedByUser != null)
            _kv('Completed By', session.completedByUser!.fullName),
          _kv('Lots', '${session.itemsCount ?? session.items?.length ?? 0}'),
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
            width: 80,
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

// ── Returned lots section ─────────────────────────────────────────────────────

class _ItemsSection extends ConsumerWidget {
  const _ItemsSection({
    required this.sessionId,
    required this.session,
    required this.isSaving,
    required this.canEditRemarks,
    this.onEditRemarks,
  });

  final int sessionId;
  final ReturnSessionModel session;
  final bool isSaving;
  final bool canEditRemarks;
  final ValueChanged<ReturnSessionItem>? onEditRemarks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = session.items ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Returned lots',
          count: session.itemsCount ?? items.length,
          trailing: !session.isReadOnly
              ? AppButton(
                  label: 'Scan lot',
                  icon: Icons.qr_code_scanner_rounded,
                  size: AppButtonSize.sm,
                  isFullWidth: false,
                  onPressed: () =>
                      context.push(RouteNames.returnsScanPath(sessionId)),
                )
              : null,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        if (items.isEmpty)
          ContentCard(
            padding: const EdgeInsets.all(AppDimensions.space3xl),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_return_outlined,
                    size: 40,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  Text(
                    !session.isReadOnly
                        ? 'No lots yet. Tap "Scan lot" to begin.'
                        : 'No lots in this session.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...items.map(
            (item) => _ItemTile(
              item: item,
              isDraft: !session.isReadOnly,
              isSaving: isSaving,
              onDelete: !session.isReadOnly
                  ? () => _confirmDelete(context, ref, item)
                  : null,
              onEditRemarks: canEditRemarks
                  ? () => onEditRemarks?.call(item)
                  : null,
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ReturnSessionItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove lot?'),
        content: Text(
          'Remove lot ${item.displayLabel} from this return session?',
        ),
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
        .read(returnDetailProvider(sessionId).notifier)
        .deleteItem(item.id);
  }
}

// ── Item tile ─────────────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.isDraft,
    required this.isSaving,
    this.onDelete,
    this.onEditRemarks,
  });

  final ReturnSessionItem item;
  final bool isDraft;
  final bool isSaving;
  final VoidCallback? onDelete;
  final VoidCallback? onEditRemarks;

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
                return false;
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
              child: _cardContent(),
            )
          : _cardContent(),
    );
  }

  Widget _cardContent() {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              if (isDraft && onDelete != null)
                Icon(
                  Icons.swipe_left_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              if (onEditRemarks != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit remarks',
                  onPressed: isSaving ? null : onEditRemarks,
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (item.lot?.lotNumber != null) _kv('Lot', item.lot!.lotNumber),
          _kv('Returned', '${item.quantity ?? 0}'),
          if ((item.usedQuantity ?? 0) > 0) _kv('Used', '${item.usedQuantity}'),
          if ((item.damagedQuantity ?? 0) > 0)
            _kv('Damaged', '${item.damagedQuantity}'),
          if ((item.missingQuantity ?? 0) > 0)
            _kv('Missing', '${item.missingQuantity}'),
          if (item.returnedAt != null)
            _kv('Scanned', DateFormatter.toDisplayDateTime(item.returnedAt!)),
          if (item.remarks != null && item.remarks!.isNotEmpty)
            _kv('Remarks', item.remarks!),
          const SizedBox(height: 6),
          // Neutral quantity-type metadata — not coloured pills per UI rules
          Wrap(
            spacing: 6,
            children: [
              _badge('Total: ${item.totalScanned}', AppColors.textMuted),
            ],
          ),
        ],
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

// ── Complete / Reopen action cards ────────────────────────────────────────────

class _CompleteActionCard extends StatelessWidget {
  const _CompleteActionCard({
    required this.itemCount,
    required this.isSaving,
    required this.onPressed,
  });

  final int itemCount;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to complete',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'This will finalize $itemCount returned lot${itemCount == 1 ? '' : 's'} '
            'and generate the usage/invoice report.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppButton(
            label: 'Complete return',
            icon: Icons.check_circle_outline_rounded,
            isLoading: isSaving,
            onPressed: isSaving ? null : onPressed,
          ),
        ],
      ),
    );
  }
}

class _ReopenActionCard extends StatelessWidget {
  const _ReopenActionCard({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      borderColor: AppColors.warning.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reopen session',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'Discards the usage report and allows scanning again.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppButton(
            label: 'Reopen return',
            icon: Icons.undo_rounded,
            variant: AppButtonVariant.secondary,
            isLoading: isSaving,
            onPressed: isSaving ? null : onPressed,
          ),
        ],
      ),
    );
  }
}

// ── Reconciliation / Usage report section ─────────────────────────────────────

class _ReconciliationSection extends StatelessWidget {
  const _ReconciliationSection({
    required this.items,
    required this.canEditRemarks,
    this.onEditItemRemarks,
    this.onEditComponentRemarks,
  });
  final List<ReconciliationItem> items;
  final bool canEditRemarks;
  final ValueChanged<ReconciliationItem>? onEditItemRemarks;
  final void Function(
    ReconciliationItem item,
    ReconciliationInstrumentResult component,
  )?
  onEditComponentRemarks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Usage / Invoice Report', count: items.length),
        const SizedBox(height: AppDimensions.spaceSm),
        ...items.map(
          (item) => _ReconciliationTile(
            item: item,
            canEditRemarks: canEditRemarks,
            onEditItemRemarks: onEditItemRemarks == null
                ? null
                : () => onEditItemRemarks!(item),
            onEditComponentRemarks: onEditComponentRemarks == null
                ? null
                : (component) => onEditComponentRemarks!(item, component),
          ),
        ),
      ],
    );
  }
}

class _ReconciliationTile extends StatelessWidget {
  const _ReconciliationTile({
    required this.item,
    required this.canEditRemarks,
    this.onEditItemRemarks,
    this.onEditComponentRemarks,
  });
  final ReconciliationItem item;
  final bool canEditRemarks;
  final VoidCallback? onEditItemRemarks;
  final ValueChanged<ReconciliationInstrumentResult>? onEditComponentRemarks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName ??
                        item.instrumentSetName ??
                        item.lotNumber ??
                        '#${item.id}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (canEditRemarks && onEditItemRemarks != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit remarks',
                    onPressed: onEditItemRemarks,
                  ),
              ],
            ),
            if (item.refNum != null) ...[
              const SizedBox(height: 2),
              Text(
                item.refNum!,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 6),
            if (item.lotNumber != null) _kv('Lot', item.lotNumber!),
            if (item.instrumentResults.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...item.instrumentResults.map(
                (component) => _componentRow(component),
              ),
            ],
            if (item.result != null) _kv('Result', item.result!),
            if (item.remarks?.isNotEmpty == true) _kv('Remarks', item.remarks!),
            if (item.totalConsigned != null)
              _kv('Consigned', '${item.totalConsigned}'),
            if (item.totalReturned != null)
              _kv('Returned', '${item.totalReturned}'),
            if ((item.totalUsed ?? 0) > 0) _kv('Used', '${item.totalUsed}'),
            if ((item.totalDamaged ?? 0) > 0)
              _kv('Damaged', '${item.totalDamaged}'),
            if ((item.totalMissing ?? 0) > 0)
              _kv('Missing', '${item.totalMissing}'),
            if (item.invoiceQuantity != null)
              _kv('Invoice qty', '${item.invoiceQuantity}'),
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
            width: 88,
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

  Widget _componentRow(ReconciliationInstrumentResult component) {
    final quantities = [
      if (component.expectedQuantity != null)
        'Expected: ${component.expectedQuantity}',
      if (component.returnedQuantity != null)
        'Returned: ${component.returnedQuantity}',
      if (component.usedQuantity != null) 'Used: ${component.usedQuantity}',
      if ((component.missingQuantity ?? 0) > 0)
        'Missing: ${component.missingQuantity}',
      if ((component.damagedQuantity ?? 0) > 0)
        'Damaged: ${component.damagedQuantity}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${component.productName ?? 'Component'}\nLots: ${component.lotNumbers.isEmpty ? '-' : component.lotNumbers.join(', ')}${quantities.isEmpty ? '' : '\n${quantities.join(' · ')}'}${component.remarks?.isNotEmpty == true ? '\nRemarks: ${component.remarks}' : ''}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (canEditRemarks && onEditComponentRemarks != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit component remarks',
              onPressed: () => onEditComponentRemarks!(component),
            ),
        ],
      ),
    );
  }
}
