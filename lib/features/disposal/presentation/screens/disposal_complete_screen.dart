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
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/disposal_repository.dart';
import '../providers/disposal_providers.dart';
import '../widgets/disposal_widgets.dart';

class DisposalCompleteScreen extends ConsumerStatefulWidget {
  const DisposalCompleteScreen({super.key, required this.disposalId});
  final int disposalId;
  @override
  ConsumerState<DisposalCompleteScreen> createState() =>
      _DisposalCompleteScreenState();
}

class _DisposalCompleteScreenState
    extends ConsumerState<DisposalCompleteScreen> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    final disposalAsync = ref.watch(disposalDetailProvider(widget.disposalId));
    final itemsAsync = ref.watch(disposalItemsProvider(widget.disposalId));
    final canCreate =
        ref
            .watch(currentUserProvider)
            ?.permissions
            .contains('disposals.create') ??
        false;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Complete disposal',
        onBack: () => context.pop(),
      ),
      body: disposalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(disposalDetailProvider(widget.disposalId)),
        ),
        data: (disposal) {
          final items = itemsAsync.asData?.value ?? disposal.items;
          final itemCount = disposal.itemsCount ?? items.length;
          if (!canCreate) {
            return const Center(
              child: Text('You do not have permission to manage disposals.'),
            );
          }
          if (!disposal.isDraft) {
            return const Center(
              child: Text('This disposal is already completed.'),
            );
          }
          if (itemsAsync.isLoading && disposal.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (itemsAsync.hasError) {
            return AppErrorWidget(
              message: itemsAsync.error.toString(),
              onRetry: () =>
                  ref.invalidate(disposalItemsProvider(widget.disposalId)),
            );
          }
          if (itemCount < 1) {
            return const Center(
              child: Text('Add at least one disposal item before completing.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: [
              Text(
                'Review before completion',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The server will deduct each quantity and create inventory movements.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              ContentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(disposal.disposalNo, style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppDimensions.spaceSm),
                    Text(
                      '$itemCount lot(s) to dispose',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
                  child: DisposalItemTile(item: item),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              AppButton(
                onPressed: _saving ? null : () => _confirm(disposal.disposalNo),
                icon: Icons.check_circle_outline_rounded,
                isLoading: _saving,
                label: 'Complete disposal',
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirm(String number) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete disposal?'),
        content: Text(
          'Complete $number? This will deduct the listed quantities and create inventory movements. This action cannot be undone from mobile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(disposalRepositoryProvider).complete(widget.disposalId);
      ref.invalidate(disposalListProvider);
      ref.invalidate(disposalDetailProvider(widget.disposalId));
      ref.invalidate(disposalItemsProvider(widget.disposalId));
      ref.invalidate(inventorySummaryProvider);
      ref.invalidate(inventoryProductsProvider);
      ref.invalidate(inventorySetsProvider);
      ref.invalidate(inventoryUnitsProvider);
      ref.invalidate(inventoryLedgerProvider);
      ref.invalidate(inventoryExpiringSoonProvider);
      ref.invalidate(dashboardSummaryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disposal completed. Inventory has been refreshed.'),
          ),
        );
        context.go(RouteNames.disposalDetailPath(widget.disposalId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
