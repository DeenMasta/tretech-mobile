import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../consignment/data/models/consignment_models.dart';
import '../../../consignment/data/repositories/consignment_repository.dart';

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

  static const EventChannel _scannerChannel = EventChannel(
    'com.tretech/scanner',
  );
  StreamSubscription<dynamic>? _scannerSub;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool _isLookingUp = false;
  bool _isLoadingConsignmentItems = false;
  bool _consignmentItemsLoadFailed = false;
  int? _loadedConsignmentId;
  List<ConsignmentItem> _consignmentItems = const [];
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
  void initState() {
    super.initState();
    _scannerSub = _scannerChannel.receiveBroadcastStream().listen((data) {
      if (!mounted || _isLookingUp) return;
      _lookupScannedLot(data.toString());
    });
  }

  @override
  void dispose() {
    _lotCtl.dispose();
    _returnedCtl.dispose();
    _usedCtl.dispose();
    _damagedCtl.dispose();
    _missingCtl.dispose();
    _remarksCtl.dispose();
    _scannerSub?.cancel();
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
    await _lookupScannedLot(result);
  }

  /// Stock-in QR labels contain metadata such as
  /// `V=1;REF=IMP-003;LOT=3456;MFG=-;EXP=-;PAD=0000`.
  /// Returns must look up the lot value, not the whole QR payload.
  String _lotNumberFromQrPayload(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return value;

    try {
      final json = jsonDecode(value);
      if (json is Map<String, dynamic>) {
        final lot = json['lot_number']?.toString().trim();
        if (lot?.isNotEmpty == true) return lot!;
      }
    } catch (_) {
      // Continue with the compact and legacy QR label formats.
    }

    final match = RegExp(
      r'(?:^|;)LOT[=:]([^;]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (match?.group(1)?.trim().isNotEmpty == true) {
      return match!.group(1)!.trim();
    }

    var parsed = value.split(';').first.trim();
    if (parsed.contains('MFG=')) parsed = parsed.split('MFG=').first.trim();
    if (parsed.contains('EXP=')) parsed = parsed.split('EXP=').first.trim();
    return parsed;
  }

  Future<void> _lookupScannedLot(String rawValue) async {
    final lotNumber = _lotNumberFromQrPayload(rawValue);
    _lotCtl.text = lotNumber;
    await _lookupLot(lotNumber);
  }

  Future<void> _selectConsignmentItem() async {
    final returnedItems = [
      ...?ref.read(returnDetailProvider(widget.sessionId)).session?.items,
      ..._recentItems,
    ];
    final returnedLotIds = returnedItems
        .map((item) => item.lotId)
        .whereType<int>()
        .toSet();
    final returnedSetIds = returnedItems
        .map((item) => item.instrumentSetId)
        .whereType<int>()
        .toSet();
    final selectableItems = _consignmentItems.where((item) {
      if (item.isSet) {
        return item.instrumentSetId != null &&
            !returnedSetIds.contains(item.instrumentSetId);
      }
      return item.lot != null && !returnedLotIds.contains(item.lot!.id);
    }).toList();

    final selected = await showModalBottomSheet<ConsignmentItem>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
          children: [
            const ListTile(title: Text('Items in this consignment')),
            if (selectableItems.isEmpty)
              const ListTile(
                title: Text('All consignment items have already been added.'),
              ),
            ...selectableItems.map(
              (item) => ListTile(
                leading: Icon(
                  item.isSet
                      ? Icons.medical_services_outlined
                      : Icons.inventory_2_outlined,
                ),
                title: Text(
                  item.isSet
                      ? item.instrumentSetName ?? 'Instrument set'
                      : item.lot!.productName ?? item.lot!.lotNumber,
                ),
                subtitle: Text(
                  item.isSet
                      ? item.instrumentSetCode ?? ''
                      : 'Lot: ${item.lot!.lotNumber}${item.lot!.refNum?.isNotEmpty == true ? ' · ${item.lot!.refNum}' : ''}',
                ),
                onTap: () => Navigator.pop(context, item),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;

    if (!selected.isSet) {
      _lotCtl.text = selected.lot!.lotNumber;
      await _lookupLot(selected.lot!.lotNumber);
      return;
    }

    setState(() {
      _isLookingUp = true;
      _scanError = null;
    });
    try {
      final set = await ref
          .read(stockInMasterDataRepositoryProvider)
          .getInstrumentSet(selected.instrumentSetId!);
      if (!mounted) return;
      _applyInstrumentSet(set);
    } catch (_) {
      if (mounted) {
        setState(() => _scanError = 'Instrument set could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  void _clearInstrumentResults() {
    _instrumentResults.clear();
    for (final ctl in _instrumentResultsCtls.values) {
      ctl.dispose();
    }
    _instrumentResultsCtls.clear();
  }

  /// Mirrors the web return form: include every set component at its expected
  /// quantity, replacing any partial component selection currently entered.
  void _addAllInstrumentComponents() {
    final set = _resolvedInstrumentSet;
    if (set == null) return;

    setState(() {
      for (final item in set.items) {
        _instrumentResults[item.id] = item.quantity;
        final controller = _instrumentResultsCtls[item.id];
        if (controller != null) {
          controller.text = item.quantity.toString();
        } else {
          _instrumentResultsCtls[item.id] = TextEditingController(
            text: item.quantity.toString(),
          );
        }
      }
    });
  }

  void _applyInstrumentSet(InstrumentSetModel set) {
    setState(() {
      _lotCtl.clear();
      _resolvedLot = null;
      _resolvedLotUnit = null;
      _resolvedInstrumentSet = set;
      _clearInstrumentResults();
      for (final item in set.items) {
        _instrumentResults[item.id] = 0;
        _instrumentResultsCtls[item.id] = TextEditingController(text: '0');
      }
    });
  }

  Future<void> _loadConsignmentItems(int consignmentId) async {
    if (_isLoadingConsignmentItems || _loadedConsignmentId == consignmentId) {
      return;
    }
    setState(() {
      _isLoadingConsignmentItems = true;
      _loadedConsignmentId = consignmentId;
      _consignmentItemsLoadFailed = false;
    });
    try {
      final items = await ref
          .read(consignmentRepositoryProvider)
          .items(consignmentId);
      if (mounted) {
        setState(() {
          _consignmentItems = items;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _consignmentItemsLoadFailed = true;
          _scanError = 'Consignment items could not be loaded.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingConsignmentItems = false);
    }
  }

  Future<void> _lookupLot(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _resolvedLot = null;
        _resolvedLotUnit = null;
        _resolvedInstrumentSet = null;
        _clearInstrumentResults();
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
      _clearInstrumentResults();
    });

    try {
      final unit = await ref
          .read(inventoryRepositoryProvider)
          .lookupByLot(value);
      if (!_consignmentItems.any((item) => item.lot?.id == unit.id)) {
        throw StateError('Lot is not registered in this consignment');
      }
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
          _clearInstrumentResults();
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
    } on StateError {
      if (mounted) {
        setState(
          () => _scanError = 'This lot is not registered in this consignment.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _scanError = 'Lot not found or could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit({bool andNext = false}) async {
    if (_resolvedLot == null && _resolvedInstrumentSet == null) {
      setState(
        () => _scanError =
            'Please scan a lot or instrument set from this consignment.',
      );
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
        lotNumber: null,
        instrumentSetId: _resolvedLot == null
            ? _resolvedInstrumentSet?.id
            : null,
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
      _clearInstrumentResults();
      _scanError = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(returnDetailProvider(widget.sessionId));
    final session = state.session;
    final consignmentId = session?.consignment?.id;
    final consignmentItemsReady =
        consignmentId != null &&
        _loadedConsignmentId == consignmentId &&
        !_isLoadingConsignmentItems &&
        !_consignmentItemsLoadFailed;

    if (consignmentId != null && _loadedConsignmentId != consignmentId) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadConsignmentItems(consignmentId),
      );
    }

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
                const SectionHeader(title: 'Scan returned item'),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  consignmentItemsReady
                      ? 'Scan a registered lot, or use the list to select a lot or instrument set.'
                      : 'Loading items registered in this consignment…',
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
                  onBrowse: _selectConsignmentItem,
                  enabled: consignmentItemsReady,
                  onSubmitted: _lookupScannedLot,
                ),
                if (_resolvedLot != null) ...[
                  const SizedBox(height: AppDimensions.spaceSm),
                  _ResolvedLotCard(lot: _resolvedLot!),
                ],
                if (_resolvedLot == null && _resolvedInstrumentSet != null) ...[
                  const SizedBox(height: AppDimensions.spaceSm),
                  _ResolvedItemCard(
                    label: _resolvedInstrumentSet!.displayLabel,
                    icon: Icons.medical_services_outlined,
                  ),
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
                        integerOnly: true,
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
                          integerOnly: true,
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
                          integerOnly: true,
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
                          integerOnly: true,
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
          const SizedBox(height: AppDimensions.spaceMd),
          AppButton(
            label: 'Add all missing components',
            icon: Icons.add_circle_outline_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: _addAllInstrumentComponents,
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
                      integerOnly: true,
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

class _ResolvedItemCard extends StatelessWidget {
  const _ResolvedItemCard({
    required this.label,
    this.icon = Icons.inventory_2_outlined,
  });

  final String label;
  final IconData icon;

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
          Icon(icon, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

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
