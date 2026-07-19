import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/scan_input_field.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/models/return_session_model.dart';
import '../../data/repositories/returns_repository.dart';
import '../providers/returns_detail_provider.dart';
import '../widgets/barcode_scanner_sheet.dart';
import '../../../inventory/data/models/inventory_unit_model.dart';
import '../../../inventory/data/repositories/inventory_repository.dart';
import '../../../stock_in/data/models/instrument_set_model.dart';
import '../../../stock_in/data/repositories/master_data_repository.dart';

class ReturnScanItemScreen extends ConsumerStatefulWidget {
  const ReturnScanItemScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<ReturnScanItemScreen> createState() =>
      _ReturnScanItemScreenState();
}

class _ReturnScanItemScreenState extends ConsumerState<ReturnScanItemScreen> {
  // ── Scan input ────────────────────────────────────────────────────────────
  final _lotCtl = TextEditingController();

  // ── Quantity controllers ──────────────────────────────────────────────────
  final _returnedCtl = TextEditingController(text: '1');
  final _usedCtl = TextEditingController(text: '0');
  final _damagedCtl = TextEditingController(text: '0');
  final _missingCtl = TextEditingController(text: '0');
  final _remarksCtl = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool _isLookingUp = false;
  ReturnLotBrief? _resolvedLot;
  InventoryUnitModel? _resolvedLotUnit;
  InstrumentSetModel? _resolvedInstrumentSet;
  final Map<int, int> _instrumentResults = {};
  final Map<int, TextEditingController> _instrumentResultsCtls = {};
  String? _scanError;
  String? _submitError;

  // ── Recent scans shown below ───────────────────────────────────────────────
  final List<ReturnSessionItem> _recentItems = [];

  @override
  void dispose() {
    _lotCtl.dispose();
    _returnedCtl.dispose();
    _usedCtl.dispose();
    _damagedCtl.dispose();
    _missingCtl.dispose();
    _remarksCtl.dispose();
    for (var ctl in _instrumentResultsCtls.values) {
      ctl.dispose();
    }
    super.dispose();
  }

  // ── Scanning helpers ──────────────────────────────────────────────────────

  Future<void> _onScanLot() async {
    final result = await ReturnBarcodeScannerSheet.show(
      context,
      title: 'Scan lot number',
      helperText: 'Aim at the lot-number barcode or QR code on the package',
    );
    if (result == null || !mounted) return;
    _lotCtl.text = result;
    await _lookupLot(result);
  }

  Future<void> _lookupLot(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _resolvedLot = null;
        _resolvedLotUnit = null;
        _resolvedInstrumentSet = null;
        _instrumentResults.clear();
        for (var ctl in _instrumentResultsCtls.values) {
          ctl.dispose();
        }
        _instrumentResultsCtls.clear();
        _scanError = null;
      });
      return;
    }
    setState(() {
      _isLookingUp = true;
      _scanError = null;
      _resolvedLot = null;
      _resolvedLotUnit = null;
      _resolvedInstrumentSet = null;
      _instrumentResults.clear();
      for (var ctl in _instrumentResultsCtls.values) {
        ctl.dispose();
      }
      _instrumentResultsCtls.clear();
    });

    try {
      final unit = await ref
          .read(inventoryRepositoryProvider)
          .lookupByLot(value);
      final lotBrief = ReturnLotBrief(
        id: unit.id,
        lotNumber: unit.lotNumber,
        productName: unit.product?.productName,
        refNum: unit.product?.refNum,
      );
      final InstrumentSetModel? setModel = unit.instrumentSet == null
          ? null
          : await ref
                .read(stockInMasterDataRepositoryProvider)
                .getInstrumentSet(unit.instrumentSet!.id);

      if (mounted) {
        setState(() {
          _resolvedLotUnit = unit;
          _resolvedLot = lotBrief;
          _resolvedInstrumentSet = setModel;
          if (setModel != null) {
            for (final item in setModel.items) {
              _instrumentResults[item.id] = 0;
              _instrumentResultsCtls[item.id] = TextEditingController(
                text: '0',
              );
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanError = 'Lot not found or could not be loaded.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit({bool andNext = false}) async {
    final lotNumber = _lotCtl.text.trim();
    if (lotNumber.isEmpty && _resolvedLot == null) {
      setState(() => _scanError = 'Please scan or enter a lot number.');
      return;
    }

    final qty = int.tryParse(_returnedCtl.text) ?? 0;
    final used = int.tryParse(_usedCtl.text) ?? 0;
    final damaged = int.tryParse(_damagedCtl.text) ?? 0;
    final missing = int.tryParse(_missingCtl.text) ?? 0;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final results = _instrumentResults.entries
        .where((e) => e.value > 0)
        .map((e) => {'product_id': e.key, 'returned_quantity': e.value})
        .toList();

    try {
      final repo = ref.read(returnsRepositoryProvider);
      final item = await repo.scanItem(
        widget.sessionId,
        lotId: _resolvedLot?.id,
        lotNumber: _resolvedLot == null ? lotNumber : null,
        quantity: qty,
        usedQuantity: used,
        damagedQuantity: damaged,
        missingQuantity: missing,
        remarks: _remarksCtl.text.trim().isEmpty
            ? null
            : _remarksCtl.text.trim(),
        instrumentResults: results,
      );

      // Refresh detail state so the list updates
      ref.read(returnDetailProvider(widget.sessionId).notifier).refresh();

      setState(() {
        _recentItems.insert(0, item);
      });

      if (andNext) {
        _resetForm();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lot added. Ready for next scan.')),
          );
        }
      } else {
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _lotCtl.clear();
    _returnedCtl.text = '1';
    _usedCtl.text = '0';
    _damagedCtl.text = '0';
    _missingCtl.text = '0';
    _remarksCtl.clear();
    setState(() {
      _resolvedLot = null;
      _resolvedLotUnit = null;
      _resolvedInstrumentSet = null;
      _instrumentResults.clear();
      for (var ctl in _instrumentResultsCtls.values) {
        ctl.dispose();
      }
      _instrumentResultsCtls.clear();
      _scanError = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(returnDetailProvider(widget.sessionId));
    final session = state.session;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text(
          session?.returnSessionNo ?? 'Scan returned lot',
          style: AppTextStyles.titleMedium,
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        children: [
          // ── Session context ──────────────────────────────────────────────
          if (session != null) _buildSessionInfo(session),
          const SizedBox(height: AppDimensions.spaceLg),

          // ── Lot scan ─────────────────────────────────────────────────────
          ContentCard(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Scan lot'),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  'Scan the barcode / QR code on the returned package.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                // ── ScanInputField — per UI rules: always use shared widget ──
                ScanInputField(
                  controller: _lotCtl,
                  label: 'Lot number',
                  hint: 'Scan or type lot number',
                  isLoading: _isLookingUp,
                  errorText: _scanError,
                  onScan: _onScanLot,
                  onChanged: (v) => _lookupLot(v),
                  onSubmitted: (v) => _lookupLot(v),
                ),
                if (_resolvedLot != null) ...[
                  const SizedBox(height: AppDimensions.spaceSm),
                  _ResolvedLotCard(lot: _resolvedLot!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),

          // ── Quantities ───────────────────────────────────────────────────
          ContentCard(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Quantities'),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  'Enter the returned counts.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _returnedCtl,
                        label: 'Returned',
                        hint: '1',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    if (_resolvedLotUnit?.product?.productType ==
                            'instrument' ||
                        _resolvedLotUnit?.instrumentSet != null) ...[
                      const SizedBox(width: AppDimensions.spaceMd),
                      Expanded(
                        child: AppTextField(
                          controller: _usedCtl,
                          label: 'Used',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_resolvedLotUnit?.product?.productType == 'instrument' ||
                    _resolvedLotUnit?.instrumentSet != null) ...[
                  const SizedBox(height: AppDimensions.spaceMd),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _damagedCtl,
                          label: 'Damaged',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMd),
                      Expanded(
                        child: AppTextField(
                          controller: _missingCtl,
                          label: 'Missing',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),

          // ── Instrument Set Components ─────────────────────────────────────
          if (_resolvedInstrumentSet != null) ...[
            _buildInstrumentSetSection(),
            const SizedBox(height: AppDimensions.spaceLg),
          ],

          // ── Remarks ───────────────────────────────────────────────────────
          ContentCard(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Notes'),
                const SizedBox(height: AppDimensions.spaceLg),
                AppTextField(
                  controller: _remarksCtl,
                  label: 'Remarks',
                  hint: 'Optional notes for this lot',
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),

          // ── Submit error banner ───────────────────────────────────────────
          if (_submitError != null) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _submitError!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Recent scans ──────────────────────────────────────────────────
          if (_recentItems.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceLg),
            SectionHeader(
              title: 'Scanned this session',
              count: _recentItems.length,
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            ..._recentItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
                child: _ScannedItemTile(item: item),
              ),
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(ReturnSessionModel session) {
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
          _kv('Consignment', session.consignment?.consignmentNo ?? '—'),
          _kv('PIC', session.picUserName),
          _kv(
            'Lots scanned',
            '${session.itemsCount ?? session.items?.length ?? 0}',
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentSetSection() {
    return ContentCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Returned Set Components'),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'Choose the returned components and enter the returned quantity for each.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          ..._resolvedInstrumentSet!.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${item.code != null ? 'Ref: ${item.code} | ' : ''}Expected: ${item.quantity}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMd),
                  Expanded(
                    flex: 1,
                    child: AppTextField(
                      controller:
                          _instrumentResultsCtls[item.id] ??
                          TextEditingController(text: '0'),
                      onChanged: (val) {
                        setState(() {
                          _instrumentResults[item.id] = int.tryParse(val) ?? 0;
                        });
                      },
                      label: 'Returned Qty',
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            );
          }),
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
            width: 110,
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

  // ── Bottom bar — pair of actions per UI rules ─────────────────────────────
  Widget _buildBottomBar() {
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
            // Save & next — left per UI rules
            Expanded(
              child: AppButton(
                label: 'Save & next',
                variant: AppButtonVariant.secondary,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : () => _submit(andNext: true),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceMd),
            // Add item (primary) — right per UI rules
            Expanded(
              child: AppButton(
                label: 'Add lot',
                icon: Icons.add_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : () => _submit(andNext: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Resolved lot card ─────────────────────────────────────────────────────────

class _ResolvedLotCard extends StatelessWidget {
  const _ResolvedLotCard({required this.lot});
  final ReturnLotBrief lot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lot.productName != null
                  ? '${lot.lotNumber} — ${lot.productName}'
                  : lot.lotNumber,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent scan tile ──────────────────────────────────────────────────────────

class _ScannedItemTile extends StatelessWidget {
  const _ScannedItemTile({required this.item});
  final ReturnSessionItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Icon(
              Icons.assignment_return_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (item.lot?.lotNumber != null)
                  Text(
                    'Lot: ${item.lot!.lotNumber}',
                    style: AppTextStyles.bodySmall,
                  ),
                Text(
                  'Returned: ${item.quantity ?? 0}'
                  '${(item.usedQuantity ?? 0) > 0 ? ' · Used: ${item.usedQuantity}' : ''}'
                  '${(item.damagedQuantity ?? 0) > 0 ? ' · Damaged: ${item.damagedQuantity}' : ''}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
