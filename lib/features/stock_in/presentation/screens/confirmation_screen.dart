import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/lot_model.dart';
import '../../data/repositories/qr_print_repository.dart';
import '../providers/stock_in_list_provider.dart';
import '../providers/stock_in_session_provider.dart';

/// Final step of the stock-in workflow:
/// shows confirmation, lets the user view/print QR labels for the new lots.
class ConfirmationScreen extends ConsumerWidget {
  const ConfirmationScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockInSessionControllerProvider(sessionId));
    final session = state.session;
    final result = state.finalizeResult;
    final lots = result?.createdLots ?? const <LotModel>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        automaticallyImplyLeading: false,
        title: Text('Session confirmed', style: AppTextStyles.titleMedium),
      ),
      body: session == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.spaceLg),
              children: [
                _successBanner(session.sessionNo, lots.length),
                const SizedBox(height: AppDimensions.spaceLg),
                if (lots.isEmpty)
                  _emptyLotsBox()
                else ...[
                  Text(
                    'Generated lots',
                    style: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  ...lots.map((l) => _LotCard(lot: l)),
                ],
                const SizedBox(height: AppDimensions.spaceLg),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Back to list',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.list_alt_rounded,
                  onPressed: () {
                    ref.invalidate(stockInListProvider);
                    context.go(RouteNames.stockIn);
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: AppButton(
                  label: 'Done',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    ref.invalidate(stockInListProvider);
                    context.go(RouteNames.dashboard);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successBanner(String sessionNo, int lotCount) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 32),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session $sessionNo finalized',
                    style: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '$lotCount lot${lotCount == 1 ? '' : 's'} created and ready for QR printing.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyLotsBox() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'No new lots were created. Open the session detail to view items.',
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}

class _LotCard extends ConsumerStatefulWidget {
  const _LotCard({required this.lot});

  final LotModel lot;

  @override
  ConsumerState<_LotCard> createState() => _LotCardState();
}

class _LotCardState extends ConsumerState<_LotCard> {
  bool _expanded = false;
  bool _printing = false;
  String? _qrPayload;

  Future<void> _ensurePayload() async {
    if (_qrPayload != null) return;
    try {
      final repo = ref.read(qrPrintRepositoryProvider);
      final label = await repo.getOrCreateLabel(widget.lot.id);
      if (!mounted) return;
      setState(() => _qrPayload = label.qrPayload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load QR: $e')),
        );
      }
    }
  }

  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      await ref.read(qrPrintRepositoryProvider).createPrintJob(
            lotId: widget.lot.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Print job queued.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to queue print: $e')),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lot = widget.lot;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.qr_code_2_rounded,
                  color: AppColors.primary, size: 18),
            ),
            title: Text(lot.lotNumber,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700)),
            subtitle: Text(
              [
                if (lot.supplierBatchCode != null)
                  'Batch ${lot.supplierBatchCode}',
                if (lot.expiryDate != null)
                  'Exp ${lot.expiryDate!.toIso8601String().substring(0, 10)}',
                lot.status,
              ].join(' • '),
              style: AppTextStyles.bodySmall,
            ),
            trailing: IconButton(
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
              onPressed: () async {
                setState(() => _expanded = !_expanded);
                if (_expanded) await _ensurePayload();
              },
            ),
          ),
          if (_expanded) _buildExpanded(),
        ],
      ),
    );
  }

  Widget _buildExpanded() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceLg,
        0,
        AppDimensions.spaceLg,
        AppDimensions.spaceLg,
      ),
      child: Column(
        children: [
          if (_qrPayload == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceLg),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(AppDimensions.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: _qrPayload!,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppButton(
            label: 'Send to printer',
            icon: Icons.print_rounded,
            isLoading: _printing,
            onPressed: _print,
          ),
        ],
      ),
    );
  }
}
