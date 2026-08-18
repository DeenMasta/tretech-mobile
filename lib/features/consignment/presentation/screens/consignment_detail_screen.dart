import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/models/consignment_models.dart';
import '../../data/repositories/consignment_repository.dart';
import '../providers/consignment_providers.dart';
import '../widgets/consignment_widgets.dart';

class ConsignmentDetailScreen extends ConsumerWidget {
  const ConsignmentDetailScreen({super.key, required this.consignmentId});
  final int consignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(consignmentDetailProvider(consignmentId));
    final items = ref.watch(consignmentItemsProvider(consignmentId));
    final permissions = ref.watch(currentUserProvider)?.permissions ?? const [];
    return detail.when(
      loading: () =>
          _shell(context, const Center(child: CircularProgressIndicator())),
      error: (error, _) => _shell(
        context,
        AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(consignmentDetailProvider(consignmentId)),
        ),
      ),
      data: (consignment) => _shell(
        context,
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(consignmentDetailProvider(consignmentId));
            ref.invalidate(consignmentItemsProvider(consignmentId));
          },
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: [
              _detailCard(consignment),
              const SizedBox(height: AppDimensions.spaceLg),
              _items(context, ref, consignment, items, permissions),
              const SizedBox(height: 88),
            ],
          ),
        ),
        title: consignment.number,
        actions: _appBarActions(context, ref, consignment, permissions),
        bottomNavigationBar:
            consignment.isDraft &&
                items.asData?.value.isNotEmpty == true &&
                permissions.contains('consignments.confirm')
            ? SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceLg),
                  decoration: BoxDecoration(
                    color: AppColors.sidebarBg,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: AppButton(
                    label: 'Confirm consignment',
                    centerContent: true,
                    onPressed: () => _confirm(context, ref, consignment.id),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _shell(
    BuildContext context,
    Widget child, {
    String title = 'Consignment',
    List<Widget> actions = const [],
    Widget? bottomNavigationBar,
  }) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.sidebarBg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back to Consignments',
        onPressed: () => context.go(RouteNames.consignment),
      ),
      title: Text(title, style: AppTextStyles.titleMedium),
      actions: [
        ...actions,
        const SizedBox(width: AppDimensions.spaceXs),
      ],
    ),
    body: child,
    bottomNavigationBar: bottomNavigationBar,
  );

  List<Widget> _appBarActions(
    BuildContext context,
    WidgetRef ref,
    ConsignmentModel c,
    List<String> permissions,
  ) => [
    if (c.isDraft && permissions.contains('consignments.edit_draft'))
      IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: 'Edit consignment',
        onPressed: () => context.push(RouteNames.consignmentEditPath(c.id)),
      ),
    if (c.isConfirmed)
      IconButton(
        icon: const Icon(Icons.print_outlined),
        tooltip: 'Print consignment',
        onPressed: () => _print(context, ref, c.id),
      ),
    if (c.isDraft && permissions.contains('consignments.edit_draft'))
      IconButton(
        icon: const Icon(Icons.delete_outline),
        color: AppColors.error,
        tooltip: 'Delete draft',
        onPressed: () => _deleteConsignment(context, ref, c),
      ),
  ];

  Widget _detailCard(ConsignmentModel c) => ContentCard(
    padding: const EdgeInsets.all(AppDimensions.spaceLg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                c.number,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ConsignmentStatusBadge(status: c.status),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        const Divider(height: 1),
        const SizedBox(height: AppDimensions.spaceMd),
        _cardValue('Client', c.client?.name ?? '-'),
        _cardValue('PIC', c.picName ?? '-'),
        _cardValue('Date', displayDate(c.consignmentAt)),
        _cardValue('Items', '${c.itemsCount ?? 0}'),
        if (c.surgeonName?.isNotEmpty == true)
          _cardValue('Surgeon', c.surgeonName!),
        if (c.caseDate != null)
          _cardValue('Case date', displayDate(c.caseDate)),
        if (c.caseName?.isNotEmpty == true) _cardValue('Case', c.caseName!),
        if (c.remarks?.isNotEmpty == true) _cardValue('Remarks', c.remarks!),
        if (c.isConfirmed && c.confirmedAt != null)
          _cardValue('Confirmed', displayDate(c.confirmedAt, time: true)),
        if (c.isConfirmed && c.confirmedBy?.isNotEmpty == true)
          _cardValue('Confirmed by', c.confirmedBy!),
      ],
    ),
  );

  Widget _cardValue(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
      ],
    ),
  );

  Widget _items(
    BuildContext context,
    WidgetRef ref,
    ConsignmentModel c,
    AsyncValue<List<ConsignmentItem>> data,
    List<String> permissions,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(
        title: 'Items',
        count: c.itemsCount,
        trailing: c.isDraft && permissions.contains('consignments.edit_draft')
            ? AppButton(
                label: 'Add item',
                icon: Icons.add_rounded,
                size: AppButtonSize.sm,
                isFullWidth: false,
                onPressed: () =>
                    context.push(RouteNames.consignmentItemAddPath(c.id)),
              )
            : null,
      ),
      const SizedBox(height: AppDimensions.spaceSm),
      data.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(consignmentItemsProvider(c.id)),
        ),
        data: (items) => Column(
          children: [
            if (items.isEmpty)
              ContentCard(
                padding: const EdgeInsets.all(AppDimensions.space3xl),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppDimensions.spaceMd),
                      Text(
                        c.isDraft
                            ? 'No items yet. Tap "Add item" to begin capturing.'
                            : 'No items in this consignment.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...items.map(
                (item) => _itemCard(
                  context,
                  ref,
                  c,
                  item,
                  canEdit: permissions.contains('consignments.edit_draft'),
                ),
              ),
          ],
        ),
      ),
    ],
  );
  Widget _itemCard(
    BuildContext context,
    WidgetRef ref,
    ConsignmentModel c,
    ConsignmentItem item, {
    required bool canEdit,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.isSet || item.lot?.productType?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                item.isSet ? 'Instrument set' : item.lot!.productType!,
                style: AppTextStyles.labelSmall,
              ),
            ),
          Text(
            item.isSet
                ? item.instrumentSetName ?? '-'
                : item.lot?.productName ?? '-',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.isSet && item.instrumentSetCode?.isNotEmpty == true)
            Text(
              item.instrumentSetCode!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          if (!item.isSet)
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.lot?.refNum?.isNotEmpty == true
                        ? item.lot!.refNum!
                        : 'No reference number',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Text(
                  item.lot?.lotNumber ?? '-',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          if (item.componentSummaries.isNotEmpty) ...[
            const SizedBox(height: 6),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(
                bottom: AppDimensions.spaceSm,
              ),
              dense: true,
              title: Text(
                'View components (${item.componentSummaries.length})',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                ...item.componentSummaries.map(
                  (v) => Text(
                    '• $v',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 20),
          InfoRow(
            label: 'Expiry',
            value: item.isSet ? '-' : displayDate(item.lot?.expiryDate),
          ),
          InfoRow(label: 'Proposed qty', value: '${item.proposedQuantity}'),
          InfoRow(label: 'Qty out', value: '${item.quantity}'),
          Row(
            children: [
              Expanded(
                child: InfoRow(label: 'Remarks', value: item.remarks ?? '-'),
              ),
              if (c.isDraft && canEdit) ...[
                IconButton(
                  onPressed: () => _editItem(context, ref, c.id, item),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit item',
                ),
                IconButton(
                  onPressed: () => _delete(context, ref, c.id, item),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: 'Remove item',
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    int id,
    ConsignmentItem item,
  ) async {
    final proposed = TextEditingController(text: '${item.proposedQuantity}');
    final quantity = TextEditingController(text: '${item.quantity}');
    final remarks = TextEditingController(text: item.remarks ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit consignment item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: proposed,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Proposed qty'),
            ),
            TextField(
              controller: quantity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Qty out'),
            ),
            TextField(
              controller: remarks,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Remarks'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final proposedValue = int.tryParse(proposed.text);
    final quantityValue = int.tryParse(quantity.text);
    if (saved != true ||
        proposedValue == null ||
        proposedValue < 1 ||
        quantityValue == null ||
        quantityValue < 1) {
      proposed.dispose();
      quantity.dispose();
      remarks.dispose();
      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantities must be at least 1.')),
        );
      }
      return;
    }
    try {
      await ref
          .read(consignmentRepositoryProvider)
          .updateItem(
            id,
            item.id,
            proposedQuantity: proposedValue,
            quantity: quantityValue,
            remarks: remarks.text,
          );
      ref.invalidate(consignmentItemsProvider(id));
      ref.invalidate(consignmentDetailProvider(id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      proposed.dispose();
      quantity.dispose();
      remarks.dispose();
    }
  }

  Future<void> _print(BuildContext context, WidgetRef ref, int id) async {
    try {
      final bytes = await ref.read(consignmentRepositoryProvider).print(id);
      if (bytes.isEmpty) throw StateError('The consignment PDF was empty.');
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to print consignment: $e')),
        );
      }
    }
  }

  Future<void> _deleteConsignment(
    BuildContext context,
    WidgetRef ref,
    ConsignmentModel consignment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete draft consignment?'),
        content: Text('Delete ${consignment.number}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(consignmentRepositoryProvider).delete(consignment.id);
      ref.invalidate(consignmentListProvider);
      if (context.mounted) context.go(RouteNames.consignment);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    int id,
    ConsignmentItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove consigned lot?'),
        content: Text(
          'This will remove ${item.isSet ? item.instrumentSetName : item.lot?.lotNumber ?? 'this item'} from the draft consignment.',
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
    try {
      await ref.read(consignmentRepositoryProvider).deleteItem(id, item.id);
      ref.invalidate(consignmentItemsProvider(id));
      ref.invalidate(consignmentDetailProvider(id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm consignment?'),
        content: const Text(
          'This will move all listed lots to supplied status and assign them to the client location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm consignment'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(consignmentRepositoryProvider).confirm(id);
      ref.invalidate(consignmentDetailProvider(id));
      ref.invalidate(consignmentItemsProvider(id));
      ref.invalidate(consignmentListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Consignment confirmed.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
