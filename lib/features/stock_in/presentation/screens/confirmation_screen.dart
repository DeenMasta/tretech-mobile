import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/services/bluetooth_print_service.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/status_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
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
    final canView =
        ref.watch(currentUserProvider)?.permissions.contains('stock_in.view') ??
        false;

    if (!canView) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Text('Finalize result', style: AppTextStyles.titleMedium),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spaceLg),
            child: Text('You do not have permission to view Stock In.'),
          ),
        ),
      );
    }

    final state = ref.watch(stockInSessionControllerProvider(sessionId));
    final session = state.session;
    final result = state.finalizeResult;
    final lots = result?.createdLots ?? const <LotModel>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        automaticallyImplyLeading: false,
        title: Text('Finalize result', style: AppTextStyles.titleMedium),
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
                    'Created lots',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                  label: 'Back to details',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
                    context.go(RouteNames.stockInDetailPath(sessionId));
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
    return ContentCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      backgroundColor: AppColors.successContainer,
      borderColor: AppColors.success.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sessionNo,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          StatusBanner(
            message:
                'Stock-in confirmation completed successfully. $lotCount lot${lotCount == 1 ? '' : 's'} created.',
            icon: Icons.check_circle_rounded,
            foregroundColor: AppColors.success,
            backgroundColor: AppColors.successContainer,
            borderColor: AppColors.success.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _emptyLotsBox() {
    return ContentCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Text(
        'The session is finalized, but no created lot result is available in this view.',
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
      if (label.qrPayload.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR payload is empty for this lot.')),
        );
        return;
      }
      setState(() => _qrPayload = label.qrPayload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load QR: $e')));
      }
    }
  }

  Future<void> _print() async {
    final printer = ref.read(settingsProvider);
    if (!printer.isConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No printer configured. Go to Settings to add one.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => context.push(RouteNames.settings),
          ),
        ),
      );
      return;
    }

    setState(() => _printing = true);
    try {
      final repo = ref.read(qrPrintRepositoryProvider);
      final bt = ref.read(bluetoothPrintServiceProvider);
      final messenger = ScaffoldMessenger.of(context);

      final job = await repo.createPrintJob(
        lotId: widget.lot.id,
        printerName: printer.printerName,
        deviceId: printer.macAddress,
      );

      final tspl = job.tsplPayload;
      if (tspl == null || tspl.isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('No TSPL payload returned.')),
        );
        await repo.markFailed(job.id, errorMessage: 'Empty TSPL payload');
        return;
      }

      final result = await bt.printTspl(printer.macAddress, tspl);
      if (!mounted) return;

      if (result.success) {
        await repo.markPrinted(job.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('Label sent to printer.')),
        );
      } else {
        await repo.markFailed(job.id, errorMessage: result.error);
        messenger.showSnackBar(
          SnackBar(content: Text('Print failed: ${result.error}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
              child: Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            title: Text(
              lot.productLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              [
                lot.lotNumber,
                if (lot.supplierBatchCode != null)
                  'Batch ${lot.supplierBatchCode}',
                if (lot.manufacturingDate != null)
                  'Mfg ${lot.manufacturingDate!.toIso8601String().substring(0, 10)}',
                if (lot.expiryDate != null)
                  'Exp ${lot.expiryDate!.toIso8601String().substring(0, 10)}',
                'Qty ${lot.displayedQuantity}',
                lot.isSystemGeneratedLot ? 'System generated' : 'Captured',
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
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: SizedBox.square(
                dimension: 180,
                child: QrImageView(
                  data: _qrPayload!,
                  backgroundColor: Colors.white,
                ),
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
