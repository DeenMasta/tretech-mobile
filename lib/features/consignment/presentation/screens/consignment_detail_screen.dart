import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/module_app_bar.dart';
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
              _header(context, consignment),
              const SizedBox(height: 16),
              _detailCard(consignment),
              const SizedBox(height: 24),
              _items(context, ref, consignment, items),
              const SizedBox(height: 88),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shell(BuildContext context, Widget child) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: ModuleAppBar(
      title: 'Consignment',
      onBack: () => context.go(RouteNames.consignment),
    ),
    body: child,
  );

  Widget _header(BuildContext context, ConsignmentModel c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.number,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ConsignmentStatusBadge(status: c.status),
          if (c.isDraft) ...[
            const SizedBox(width: 8),
            AppButton(
              label: 'Edit draft',
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.sm,
              isFullWidth: false,
              icon: Icons.edit_outlined,
              onPressed: () =>
                  context.push(RouteNames.consignmentEditPath(c.id)),
            ),
          ],
        ],
      ),
    ],
  );
  Widget _detailCard(ConsignmentModel c) => InfoCard(
    children: [
      Text(
        'Consignment details',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      _labelValue('Client', c.client?.name ?? '-', false),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1),
      ),
      _labelValue('Date', displayDate(c.consignmentAt), false),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _labelValue('PIC user', c.picName ?? '-', false)),
          Expanded(
            child: _labelValue('Total item qty', '${c.itemsCount ?? 0}', false),
          ),
        ],
      ),
      if (c.remarks?.isNotEmpty == true) ...[
        const SizedBox(height: 12),
        Text(
          'Remarks',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(c.remarks!, style: AppTextStyles.bodySmall),
      ],
      if (c.isConfirmed && c.confirmedAt != null) ...[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1),
        ),
        InfoRow(
          label: 'Confirmed',
          value: displayDate(c.confirmedAt, time: true),
        ),
        if (c.confirmedBy?.isNotEmpty == true)
          InfoRow(label: 'Confirmed by', value: c.confirmedBy!),
      ],
    ],
  );
  Widget _labelValue(String label, String value, bool prominent) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style:
            (prominent ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium)
                .copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
  Widget _items(
    BuildContext context,
    WidgetRef ref,
    ConsignmentModel c,
    AsyncValue<List<ConsignmentItem>> data,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(
        title: 'Consigned lots',
        count: c.itemsCount,
        trailing: c.isDraft
            ? ElevatedButton.icon(
                onPressed: () =>
                    context.push(RouteNames.consignmentItemAddPath(c.id)),
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Add lot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF09090B),
                  elevation: 0,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.buttonRadius,
                    ),
                  ),
                  textStyle: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
      ),
      const SizedBox(height: 12),
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
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No items added\nAdd lots or instrument sets to this draft consignment.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              ...items.map((item) => _itemCard(context, ref, c, item)),
            if (c.isDraft && items.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppButton(
                label: 'Confirm consignment',
                icon: Icons.check_circle_outline,
                onPressed: () => _confirm(context, ref, c.id),
              ),
            ],
          ],
        ),
      ),
    ],
  );
  Widget _itemCard(
    BuildContext context,
    WidgetRef ref,
    ConsignmentModel c,
    ConsignmentItem item,
  ) => Padding(
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
          if (item.instrumentSetItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...item.instrumentSetItems.map(
              (v) => Text(
                '• $v',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
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
              if (c.isDraft)
                IconButton(
                  onPressed: () => _delete(context, ref, c.id, item),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: 'Remove item',
                ),
            ],
          ),
        ],
      ),
    ),
  );
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
