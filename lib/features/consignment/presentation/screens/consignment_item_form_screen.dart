import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/scan_input_field.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/module_app_bar.dart';
import '../../../stock_in/data/models/instrument_set_model.dart';
import '../../../stock_in/presentation/widgets/barcode_scanner_sheet.dart';
import '../../data/models/consignment_models.dart';
import '../../data/repositories/consignment_repository.dart';
import '../providers/consignment_providers.dart';
import '../widgets/consignment_widgets.dart';

class ConsignmentItemFormScreen extends ConsumerStatefulWidget {
  const ConsignmentItemFormScreen({super.key, required this.consignmentId});
  final int consignmentId;
  @override
  ConsumerState<ConsignmentItemFormScreen> createState() =>
      _ConsignmentItemFormScreenState();
}

class _ConsignmentItemFormScreenState
    extends ConsumerState<ConsignmentItemFormScreen> {
  bool _isSet = false, _saving = false, _isScanning = false;
  ConsignmentLot? _lot;
  InstrumentSetModel? _set;
  final _proposed = TextEditingController(text: '1');
  final _quantity = TextEditingController(text: '1');
  final _remarks = TextEditingController();
  final _lotSearch = TextEditingController();
  Timer? _debounce;

  static const EventChannel _scannerChannel = EventChannel(
    'com.tretech/scanner',
  );
  StreamSubscription<dynamic>? _scannerSub;

  @override
  void initState() {
    super.initState();
    _scannerSub = _scannerChannel.receiveBroadcastStream().listen((data) {
      if (!mounted) return;
      final val = data.toString();
      _lotSearch.text = val;
      if (!_isScanning) setState(() => _isScanning = true);
      _findScannedLot();
    });
  }

  @override
  void dispose() {
    _proposed.dispose();
    _quantity.dispose();
    _remarks.dispose();
    _lotSearch.dispose();
    _debounce?.cancel();
    _scannerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(consignmentDetailProvider(widget.consignmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(title: 'Add item', onBack: () => context.pop()),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (consignment) {
          if (!consignment.isDraft) {
            return Center(
              child: Text(
                'Draft consignment required',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: [
              Text(
                'Add an item to ${consignment.number}.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              ConsignmentSection(
                title: 'Entry type',
                description:
                    'Choose whether this consignment line is a lot from inventory or an instrument set.',
                child: ContentCard(
                  child: DropdownButtonFormField<bool>(
                    initialValue: _isSet,
                    decoration: const InputDecoration(labelText: 'Capture as'),
                    items: const [
                      DropdownMenuItem(value: false, child: Text('Lot')),
                      DropdownMenuItem(
                        value: true,
                        child: Text('Instrument set'),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _isSet = v ?? false;
                      _lot = null;
                      _set = null;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ConsignmentSection(
                title: 'Item selection',
                description: 'Select a lot or instrument set to add.',
                trailing: AppButton(
                  label: 'Add item',
                  isLoading: _saving,
                  isFullWidth: false,
                  onPressed: _save,
                ),
                child: ContentCard(
                  child: Column(
                    children: [
                      if (_isSet)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Instrument set'),
                          subtitle: Text(
                            _set?.displayLabel ?? 'Choose instrument set',
                          ),
                          trailing: const Icon(Icons.search_rounded),
                          onTap: _choose,
                        )
                      else ...[
                        ScanInputField(
                          controller: _lotSearch,
                          label: 'Lot',
                          hint: 'Scan or enter lot number',
                          onScan: _scanLot,
                          onBrowse: _browseLots,
                          isLoading: _isScanning,
                          onSubmitted: (_) {
                            _debounce?.cancel();
                            _findScannedLot();
                          },
                          onChanged: (val) {
                            if (val.contains('=') ||
                                val.contains(';') ||
                                val.contains('{')) {
                              if (!_isScanning) {
                                setState(() => _isScanning = true);
                              }
                            }
                            setState(() => _lot = null);
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 150),
                              () {
                                if (_lotSearch.text.trim().isNotEmpty) {
                                  _findScannedLot();
                                } else {
                                  if (mounted) {
                                    setState(() => _isScanning = false);
                                  }
                                }
                              },
                            );
                          },
                        ),
                        if (_lot != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .05),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: .2),
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _lot!.lotNumber,
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        _lot!.productName ?? 'Selected',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _proposed,
                              label: 'Proposed Qty',
                              keyboardType: TextInputType.number,
                              integerOnly: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _quantity,
                              label: 'Qty Out',
                              keyboardType: TextInputType.number,
                              integerOnly: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _remarks,
                        label: 'Remarks',
                        hint: 'Optional item notes',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
            ],
          );
        },
      ),
    );
  }

  Future<void> _choose() async {
    if (_isSet) {
      final options = await ref.read(consignmentSetsProvider.future);
      if (!mounted) return;
      final picked = await showSearchPickerSheet(
        context,
        title: 'Choose instrument set',
        items: options,
        label: (InstrumentSetModel x) => x.displayLabel,
        subtitle: (InstrumentSetModel x) =>
            'Available: ${x.availableSetsCount ?? 0} unit${x.availableSetsCount == 1 ? '' : 's'}',
        searchHint: 'Search instrument sets',
      );
      if (picked != null) setState(() => _set = picked);
    } else {
      _lotSearch.clear();
      setState(() => _lot = null);
    }
  }

  Future<void> _browseLots() async {
    final options = await ref.read(consignmentRepositoryProvider).lots();
    final existing = await ref.read(
      consignmentItemsProvider(widget.consignmentId).future,
    );
    if (!mounted) return;

    final available = options.where((lot) {
      return !existing.any((item) => item.lot?.id == lot.id);
    }).toList();

    final picked = await showSearchPickerSheet(
      context,
      title: 'Choose available lot',
      items: available,
      label: (ConsignmentLot x) => '${x.lotNumber} (${x.productName ?? '-'})',
      searchHint: 'Search lot number or product',
    );

    if (picked != null) {
      setState(() {
        _lot = picked;
        _lotSearch.text = picked.lotNumber;
      });
    }
  }

  Future<void> _scanLot() async {
    final result = await BarcodeScannerSheet.show(
      context,
      title: 'Scan stock-in QR label',
      helperText: 'Scan the QR label generated when stock-in was finalized.',
    );
    if (result == null || !mounted) return;
    setState(() {
      _lotSearch.text = _lotNumberFromQrPayload(result.value);
      _lot = null;
    });
    await _findScannedLot();
  }

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
      // Current stock-in QR labels use the compact V=1;...;LOT=... payload.
    }

    final match = RegExp(
      r'(?:^|;)LOT[=:]([^;]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (match?.group(1)?.trim().isNotEmpty == true) {
      return match!.group(1)!.trim();
    }

    // Legacy stock-in labels put the lot in the first segment, followed by
    // metadata such as ;MFG=... and ;EXP=.... or sometimes just MFG=... without semicolons
    var parsed = value.split(';').first.trim();
    if (parsed.contains('MFG=')) {
      parsed = parsed.split('MFG=').first.trim();
    }
    if (parsed.contains('EXP=')) {
      parsed = parsed.split('EXP=').first.trim();
    }
    return parsed;
  }

  Future<void> _findScannedLot() async {
    final rawQuery = _lotSearch.text.trim();
    if (rawQuery.isEmpty) return;

    final query = _lotNumberFromQrPayload(rawQuery);
    if (query != rawQuery) {
      _lotSearch.text = query;
    }

    final options = await ref
        .read(consignmentRepositoryProvider)
        .lots(search: query);
    final existing = await ref.read(
      consignmentItemsProvider(widget.consignmentId).future,
    );
    if (!mounted) return;

    final available = options.where((lot) {
      return !existing.any((item) => item.lot?.id == lot.id);
    }).toList();

    final match = available
        .where((lot) => lot.lotNumber.toLowerCase() == query.toLowerCase())
        .firstOrNull;

    if (match != null) {
      setState(() {
        _lot = match;
        _isScanning = false;
      });
      FocusScope.of(context).unfocus();
      return;
    }
    setState(() => _isScanning = false);
    _error('No available lot matches "$query". Browse lots to find it.');
  }

  Future<void> _save() async {
    final proposed = int.tryParse(_proposed.text);
    final quantity = int.tryParse(_quantity.text);
    if ((_isSet ? _set == null : _lot == null) ||
        proposed == null ||
        proposed < 1 ||
        quantity == null ||
        quantity < 1) {
      _error('Choose an item and enter quantities of at least 1.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(consignmentRepositoryProvider)
          .addItem(
            widget.consignmentId,
            isSet: _isSet,
            lotId: _lot?.id,
            setId: _set?.id,
            proposedQuantity: proposed,
            quantity: quantity,
            remarks: _remarks.text,
          );
      ref.invalidate(consignmentItemsProvider(widget.consignmentId));
      ref.invalidate(consignmentDetailProvider(widget.consignmentId));
      if (!mounted) return;
      context.go(RouteNames.consignmentDetailPath(widget.consignmentId));
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _error(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
