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
import '../../../../shared/widgets/module_app_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/disposal_repository.dart';
import '../providers/disposal_providers.dart';
import '../widgets/disposal_widgets.dart';

class DisposalDetailScreen extends ConsumerWidget {
  const DisposalDetailScreen({super.key, required this.disposalId});
  final int disposalId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentUserProvider)?.permissions ?? const [];
    if (!permissions.contains('disposals.view')) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: ModuleAppBar(
          title: 'Disposal',
          onBack: () => context.go(RouteNames.disposal),
        ),
        body: const Center(
          child: Text('You do not have permission to view disposals.'),
        ),
      );
    }
    final disposalAsync = ref.watch(disposalDetailProvider(disposalId));
    final itemsAsync = ref.watch(disposalItemsProvider(disposalId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Disposals',
          onPressed: () => context.go(RouteNames.disposal),
        ),
        title: Text('Disposal', style: AppTextStyles.titleMedium),
        actions: [
          if (disposalAsync.value?.isDraft == true && permissions.contains('disposals.create'))
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit disposal',
              onPressed: () => context.push(RouteNames.disposalEditPath(disposalId)),
            ),
          const SizedBox(width: AppDimensions.spaceXs),
        ],
      ),
      body: disposalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(disposalDetailProvider(disposalId)),
        ),
        data: (disposal) {
          final items = itemsAsync.asData?.value ?? disposal.items;
          final itemCount = disposal.itemsCount ?? items.length;
          final canManageDraft =
              disposal.isDraft && permissions.contains('disposals.create');
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      disposal.disposalNo,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DisposalStatusBadge(status: disposal.status),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              ContentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Disposal context', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppDimensions.spaceMd),
                    DisposalInfoRow(
                      label: 'Disposal date',
                      value: disposal.disposedAt == null
                          ? '-'
                          : DateFormatter.toDisplay(disposal.disposedAt!),
                    ),
                    DisposalInfoRow(
                      label: 'PIC user',
                      value: disposal.picUser?.fullName ?? '-',
                    ),
                    DisposalInfoRow(
                      label: 'Lots',
                      value: '${disposal.itemsCount ?? items.length}',
                    ),
                    DisposalInfoRow(
                      label: 'Remarks',
                      value: disposal.remarks?.trim().isNotEmpty == true
                          ? disposal.remarks!
                          : '-',
                    ),
                    DisposalInfoRow(
                      label: 'Completed at',
                      value: disposal.completedAt == null
                          ? '-'
                          : DateFormatter.toDisplayDateTime(
                              disposal.completedAt!,
                            ),
                    ),
                    DisposalInfoRow(
                      label: 'Completed by',
                      value: disposal.completedByUser?.fullName ?? '-',
                    ),
                  ],
                ),
              ),
              if (canManageDraft && itemCount > 0) ...[
                const SizedBox(height: AppDimensions.spaceMd),
                _CompleteActionCard(
                  itemCount: itemCount,
                  onPressed: () => context.push(
                    RouteNames.disposalCompletePath(disposalId),
                  ),
                ),
              ],
              const SizedBox(height: AppDimensions.spaceLg),
              SectionHeader(
                title: 'Disposal lots',
                count: itemCount,
                trailing: canManageDraft
                    ? AppButton(
                        label: 'Add item',
                        icon: Icons.add_rounded,
                        size: AppButtonSize.sm,
                        isFullWidth: false,
                        onPressed: () => context.push(
                          RouteNames.disposalItemAddPath(disposalId),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              itemsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppDimensions.spaceLg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(disposalItemsProvider(disposalId)),
                ),
                data: (items) => items.isEmpty
                    ? Text(
                        'No disposal items yet.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Column(
                        children: items
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppDimensions.spaceSm,
                                ),
                                child: canManageDraft
                                    ? Dismissible(
                                        key: ValueKey(item.id),
                                        direction: DismissDirection.endToStart,
                                        confirmDismiss: (_) async {
                                          _delete(context, ref, item.id);
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
                                        child: DisposalItemTile(item: item),
                                      )
                                    : DisposalItemTile(item: item),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int itemId) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove disposal item?'),
        content: const Text('This removes the lot from the draft disposal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    try {
      await ref.read(disposalRepositoryProvider).deleteItem(disposalId, itemId);
      ref.invalidate(disposalItemsProvider(disposalId));
      ref.invalidate(disposalDetailProvider(disposalId));
      ref.invalidate(disposalListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _CompleteActionCard extends StatelessWidget {
  const _CompleteActionCard({
    required this.itemCount,
    required this.onPressed,
  });

  final int itemCount;
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
            'Review $itemCount lot${itemCount == 1 ? '' : 's'} before completing the disposal.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppButton(
            label: 'Complete disposal',
            icon: Icons.check_circle_outline_rounded,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
