import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/scan_input_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/instrument_set_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_in_item_model.dart';
import '../../data/repositories/master_data_repository.dart';
import '../providers/master_data_providers.dart';
import '../providers/stock_in_session_provider.dart';
import '../widgets/barcode_scanner_sheet.dart';
import '../widgets/instrument_set_search_sheet.dart';
import '../widgets/product_search_sheet.dart';

class StockInItemFormScreen extends ConsumerStatefulWidget {
  const StockInItemFormScreen({
    super.key,
    required this.sessionId,
    this.itemId,
  });

  final int sessionId;
  final int? itemId;

  bool get isEdit => itemId != null;

  @override
  ConsumerState<StockInItemFormScreen> createState() =>
      _StockInItemFormScreenState();
}

class _StockInItemFormScreenState extends ConsumerState<StockInItemFormScreen> {
  final _lotCtl = TextEditingController();
  final _quantityCtl = TextEditingController(text: '1');
  final _remarksCtl = TextEditingController();
  final Map<int, TextEditingController> _componentLotCtls = {};
  final Set<int> _generatedComponentLotIds = {};

  StockInEntryKind _entryKind = StockInEntryKind.product;
  ProductModel? _product;
  InstrumentSetModel? _instrumentSet;
  DateTime? _expiryDate;
  DateTime? _manufacturingDate;
  LotEntryMode _lotEntryMode = LotEntryMode.scan;
  LotEntryMode _expiryEntryMode = LotEntryMode.scan;
  bool _missingLotFlag = false;
  bool _generateLotNumber = false;
  bool _saving = false;

  static const EventChannel _scannerChannel = EventChannel(
    'com.tretech/scanner',
  );
  StreamSubscription<dynamic>? _scannerSub;

  String? _productError;
  String? _instrumentSetError;
  String? _expiryError;
  String? _componentLotsError;

  bool _initialised = false;

  StockInMasterDataRepository get _masterRepo =>
      ref.read(stockInMasterDataRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _scannerSub = _scannerChannel.receiveBroadcastStream().listen((data) {
      final value = data?.toString().trim() ?? '';
      if (value.isEmpty || !mounted || _missingLotFlag || _generateLotNumber) {
        return;
      }
      setState(() {
        _lotCtl.text = value;
        _lotEntryMode = LotEntryMode.scan;
      });
    });
  }

  @override
  void dispose() {
    _lotCtl.dispose();
    _scannerSub?.cancel();
    _quantityCtl.dispose();
    _remarksCtl.dispose();
    for (final controller in _componentLotCtls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initFromItem(
    StockInItemModel item,
    List<ProductModel> productCache,
    List<InstrumentSetModel> instrumentSetCache,
  ) {
    if (_initialised) return;
    _initialised = true;

    _entryKind = item.entryKind;
    if (item.product != null) {
      _product = productCache.cast<ProductModel?>().firstWhere(
        (p) => p?.id == item.product!.id,
        orElse: () => ProductModel(
          id: item.product!.id,
          refNum: item.product!.refNum,
          productName: item.product!.productName,
        ),
      );
    }
    if (item.instrumentSet != null) {
      _instrumentSet = item.instrumentSet!.items.isNotEmpty
          ? item.instrumentSet
          : instrumentSetCache.cast<InstrumentSetModel?>().firstWhere(
              (set) => set?.id == item.instrumentSet!.id,
              orElse: () => item.instrumentSet,
            );
    }

    _lotCtl.text = item.scannedLotNumber ?? '';
    _expiryDate = item.expiryDate;
    _manufacturingDate = item.manufacturingDate;
    _quantityCtl.text = '${item.quantity ?? 1}';
    _lotEntryMode = item.lotEntryMode;
    _expiryEntryMode = item.expiryEntryMode;
    _missingLotFlag = item.missingLotFlag;
    _generateLotNumber = item.generateLotNumber;
    _remarksCtl.text = item.remarks ?? '';
    if (_instrumentSet != null) {
      _setComponentLotDecisions(_instrumentSet!, item.componentLots);
    }
  }

  bool get _isProductEntry => _entryKind == StockInEntryKind.product;

  bool get _requiresLot =>
      _isProductEntry ? (_product?.requiresLot ?? true) : false;

  bool get _requiresExpiry =>
      _isProductEntry ? (_product?.requiresExpiry ?? true) : false;

  bool get _isInstrumentProduct => _product?.isInstrumentProduct ?? false;

  bool get _canGenerateProductLot => _isInstrumentProduct;

  DateTime get _malaysiaNow =>
      DateTime.now().toUtc().add(const Duration(hours: 8));

  String _initials(String value, int length) {
    final normalized = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return normalized.length >= length
        ? normalized.substring(0, length)
        : normalized.padRight(length, 'X');
  }

  String get _expectedGeneratedProductLotNumber {
    final product = _product;
    if (product == null) return '';
    final now = _malaysiaNow;
    final date =
        '${(now.year % 100).toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return '${_initials(product.refNum, 3)}-${_initials(product.productName, 4)}-$date-01';
  }

  String _expectedGeneratedComponentLotNumber(
    InstrumentSetComponentModel component,
  ) {
    final set = _instrumentSet;
    if (set == null) return '';
    final rawCode =
        (set.setCode?.trim().isNotEmpty == true ? set.setCode! : 'SET${set.id}')
            .toUpperCase()
            .replaceAll(RegExp(r'[^A-Z0-9_-]+'), '');
    final code = rawCode.isEmpty ? 'SET${set.id}' : rawCode;
    final now = _malaysiaNow;
    final date =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'COMP-$code-P${component.id}-$date';
  }

  bool _validate() {
    setState(() {
      _productError = _isProductEntry && _product == null
          ? 'Please select a product.'
          : null;
      _instrumentSetError = !_isProductEntry && _instrumentSet == null
          ? 'Please select an instrument set.'
          : null;
      _expiryError = _requiresExpiry && _expiryDate == null
          ? 'Expiry date is required for this product.'
          : null;
      _componentLotsError = !_isProductEntry && !_hasCompleteComponentLots
          ? 'Enter a lot number or choose generation for every set component.'
          : null;
    });

    return _productError == null &&
        _instrumentSetError == null &&
        _expiryError == null &&
        _componentLotsError == null &&
        (int.tryParse(_quantityCtl.text.trim()) ?? 0) > 0;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _saving = true);
    try {
      final notifier = ref.read(
        stockInSessionControllerProvider(widget.sessionId).notifier,
      );

      final success = _isProductEntry
          ? widget.isEdit
                ? await notifier.updateItem(
                    widget.itemId!,
                    productId: _product!.id,
                    scannedLotNumber:
                        _requiresLot && !_missingLotFlag && !_generateLotNumber
                        ? _normalizedLot
                        : null,
                    clearLot:
                        _requiresLot && (_missingLotFlag || _generateLotNumber),
                    expiryDate: _requiresExpiry ? _expiryDate : null,
                    manufacturingDate: _manufacturingDate,
                    quantity: int.tryParse(_quantityCtl.text.trim()) ?? 1,
                    clearExpiry: !_requiresExpiry,
                    lotEntryMode: _lotEntryMode,
                    expiryEntryMode: _expiryEntryMode,
                    missingLotFlag: _requiresLot ? _missingLotFlag : false,
                    generateLotNumber:
                        _canGenerateProductLot && _generateLotNumber,
                    remarks: _normalizedRemarks,
                  )
                : await notifier.addItem(
                    ItemDraft(
                      product: _product,
                      scannedLotNumber:
                          _requiresLot &&
                              !_missingLotFlag &&
                              !_generateLotNumber
                          ? _normalizedLot
                          : null,
                      expiryDate: _requiresExpiry ? _expiryDate : null,
                      manufacturingDate: _manufacturingDate,
                      quantity: int.tryParse(_quantityCtl.text.trim()) ?? 1,
                      lotEntryMode: _lotEntryMode,
                      expiryEntryMode: _expiryEntryMode,
                      missingLotFlag: _requiresLot ? _missingLotFlag : false,
                      generateLotNumber:
                          _canGenerateProductLot && _generateLotNumber,
                      remarks: _normalizedRemarks,
                    ),
                  )
          : widget.isEdit
          ? await notifier.updateSetItem(
              widget.itemId!,
              componentLots: _componentLotDecisions,
              quantity: int.tryParse(_quantityCtl.text.trim()) ?? 1,
              remarks: _normalizedRemarks,
            )
          : await notifier.addSetItem(
              instrumentSetId: _instrumentSet!.id,
              componentLots: _componentLotDecisions,
              quantity: int.tryParse(_quantityCtl.text.trim()) ?? 1,
              remarks: _normalizedRemarks,
            );

      if (success && mounted) {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitAndAddAnother() async {
    if (!_isProductEntry || !_validate()) return;

    setState(() => _saving = true);
    try {
      final notifier = ref.read(
        stockInSessionControllerProvider(widget.sessionId).notifier,
      );

      final success = await notifier.addItem(
        ItemDraft(
          product: _product,
          scannedLotNumber:
              _requiresLot && !_missingLotFlag && !_generateLotNumber
              ? _normalizedLot
              : null,
          expiryDate: _requiresExpiry ? _expiryDate : null,
          manufacturingDate: _manufacturingDate,
          quantity: int.tryParse(_quantityCtl.text.trim()) ?? 1,
          lotEntryMode: _lotEntryMode,
          expiryEntryMode: _expiryEntryMode,
          missingLotFlag: _requiresLot ? _missingLotFlag : false,
          generateLotNumber: _canGenerateProductLot && _generateLotNumber,
          remarks: _normalizedRemarks,
        ),
      );

      if (success && mounted) {
        final keepProduct = _product;
        setState(() {
          _lotCtl.clear();
          _expiryDate = null;
          _manufacturingDate = null;
          _quantityCtl.text = '1';
          _lotEntryMode = LotEntryMode.scan;
          _expiryEntryMode = LotEntryMode.scan;
          _missingLotFlag = false;
          _generateLotNumber = false;
          _remarksCtl.clear();
          _product = keepProduct;
          _productError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added. Ready for next lot.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? get _normalizedLot {
    final value = _lotCtl.text.trim();
    return value.isEmpty ? null : value;
  }

  String? get _normalizedRemarks {
    final value = _remarksCtl.text.trim();
    return value.isEmpty ? null : value;
  }

  bool get _hasCompleteComponentLots {
    final components = _instrumentSet?.items ?? const [];
    return components.isNotEmpty &&
        components.every((component) {
          final id = component.instrumentSetItemId;
          return id != null &&
              (_generatedComponentLotIds.contains(id) ||
                  (_componentLotCtls[id]?.text.trim().isNotEmpty ?? false));
        });
  }

  List<StockInComponentLotDecision> get _componentLotDecisions =>
      (_instrumentSet?.items ?? const []).map((component) {
        final id = component.instrumentSetItemId;
        if (id == null) {
          throw StateError(
            'Instrument set component is missing its identifier.',
          );
        }
        final generated = _generatedComponentLotIds.contains(id);
        final lotNumber = _componentLotCtls[id]?.text.trim();
        return StockInComponentLotDecision(
          instrumentSetItemId: id,
          lotNumber: generated || lotNumber == null || lotNumber.isEmpty
              ? null
              : lotNumber,
          generateLotNumber: generated,
        );
      }).toList();

  void _setComponentLotDecisions(
    InstrumentSetModel set, [
    List<StockInComponentLotDecision> existing = const [],
  ]) {
    _clearComponentLotDecisions();
    final decisionsById = {
      for (final decision in existing) decision.instrumentSetItemId: decision,
    };
    for (final component in set.items) {
      final id = component.instrumentSetItemId;
      if (id == null) continue;
      final decision = decisionsById[id];
      _componentLotCtls[id] = TextEditingController(
        text: decision?.lotNumber ?? '',
      );
      if (decision?.generateLotNumber ?? false) {
        _generatedComponentLotIds.add(id);
      }
    }
  }

  void _clearComponentLotDecisions() {
    for (final controller in _componentLotCtls.values) {
      controller.dispose();
    }
    _componentLotCtls.clear();
    _generatedComponentLotIds.clear();
  }

  Future<void> _scanComponentLot(int componentId) async {
    final result = await BarcodeScannerSheet.show(
      context,
      title: 'Capture component lot number',
      helperText: 'Scan the lot for this instrument-set component.',
    );
    if (result == null || !mounted) return;
    setState(() {
      _componentLotCtls[componentId]?.text = result.value;
      _generatedComponentLotIds.remove(componentId);
      _componentLotsError = null;
    });
  }

  Future<void> _pickProduct() async {
    final picked = await ProductSearchSheet.show(context);
    if (picked == null || !mounted) return;

    setState(() {
      final changed = _product?.id != picked.id;
      _product = picked;
      _productError = null;
      if (changed) {
        _lotCtl.clear();
        _expiryDate = null;
        _lotEntryMode = LotEntryMode.scan;
        _missingLotFlag = false;
        _generateLotNumber = false;
      }
    });
  }

  Future<void> _pickInstrumentSet() async {
    final picked = await InstrumentSetSearchSheet.show(
      context,
      repository: _masterRepo,
    );
    if (picked == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final detailed = await _masterRepo.getInstrumentSet(picked.id);
      if (!mounted) return;
      setState(() {
        _instrumentSet = detailed;
        _instrumentSetError = null;
        _setComponentLotDecisions(detailed);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _instrumentSet = picked;
        _instrumentSetError = null;
        _setComponentLotDecisions(picked);
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _scanLot() async {
    final result = await BarcodeScannerSheet.show(
      context,
      title: 'Capture lot number',
      helperText: 'Use the device camera to scan the package lot.',
    );
    if (result == null || !mounted) return;
    setState(() {
      _lotCtl.text = result.value;
      _lotEntryMode = LotEntryMode.scan;
      _missingLotFlag = false;
      _generateLotNumber = false;
    });
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365 * 10)),
      helpText: 'Select expiry date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _expiryDate = picked;
      _expiryEntryMode = LotEntryMode.scan;
      _expiryError = null;
    });
  }

  Future<void> _pickManufacturingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _manufacturingDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _manufacturingDate = picked);
  }

  void _setEntryKind(StockInEntryKind kind) {
    if (widget.isEdit || _entryKind == kind) return;
    setState(() {
      _entryKind = kind;
      _product = null;
      _instrumentSet = null;
      _clearComponentLotDecisions();
      _lotCtl.clear();
      _remarksCtl.clear();
      _expiryDate = null;
      _manufacturingDate = null;
      _quantityCtl.text = '1';
      _lotEntryMode = LotEntryMode.scan;
      _expiryEntryMode = LotEntryMode.scan;
      _missingLotFlag = false;
      _productError = null;
      _instrumentSetError = null;
      _componentLotsError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canCapture =
        ref
            .watch(currentUserProvider)
            ?.permissions
            .contains('stock_in.edit_draft') ??
        false;

    if (!canCapture) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Text('Add item', style: AppTextStyles.titleMedium),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spaceLg),
            child: Text(
              'You do not have permission to capture stock-in items.',
            ),
          ),
        ),
      );
    }

    final state = ref.watch(stockInSessionControllerProvider(widget.sessionId));
    final errorFromProvider = state.error;
    final productCache =
        ref.watch(productsProvider).value ?? const <ProductModel>[];
    final instrumentSetCache =
        ref.watch(instrumentSetsProvider).value ?? const <InstrumentSetModel>[];

    if (!state.isLoading && state.session != null && !state.session!.isDraft) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          title: Text('Add item', style: AppTextStyles.titleMedium),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spaceLg),
            child: Text(
              'Items can only be captured while the session is a draft.',
            ),
          ),
        ),
      );
    }

    if (widget.isEdit && !_initialised) {
      final item = state.items.firstWhere(
        (i) => i.id == widget.itemId,
        orElse: () => const StockInItemModel(
          id: 0,
          stockInId: 0,
          entryKind: StockInEntryKind.product,
        ),
      );
      if (item.id != 0) {
        _initFromItem(item, productCache, instrumentSetCache);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        title: Text(
          widget.isEdit ? 'Edit item' : 'Add item',
          style: AppTextStyles.titleMedium,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spaceLg,
            AppDimensions.spaceMd,
            AppDimensions.spaceLg,
            AppDimensions.spaceLg,
          ),
          decoration: BoxDecoration(
            color: AppColors.sidebarBg,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isEdit && _isProductEntry)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Save & next',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.add_rounded,
                        isLoading: _saving,
                        onPressed: _saving ? null : _submitAndAddAnother,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceMd),
                    Expanded(
                      child: AppButton(
                        label: 'Add item',
                        icon: Icons.add_circle_outline_rounded,
                        isLoading: _saving,
                        onPressed: _saving ? null : _submit,
                      ),
                    ),
                  ],
                )
              else
                AppButton(
                  label: widget.isEdit ? 'Save changes' : 'Add item',
                  icon: widget.isEdit
                      ? Icons.save_outlined
                      : Icons.add_circle_outline_rounded,
                  isLoading: _saving,
                  onPressed: _saving ? null : _submit,
                ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spaceLg,
            AppDimensions.spaceLg,
            AppDimensions.spaceLg,
            AppDimensions.space6xl,
          ),
          children: [
            if (errorFromProvider != null) ...[
              _ErrorBanner(message: errorFromProvider),
              const SizedBox(height: AppDimensions.spaceMd),
            ],
            _buildIntroCard(),
            const SizedBox(height: AppDimensions.spaceLg),
            _buildEntryKindSection(),
            const SizedBox(height: AppDimensions.spaceLg),
            if (_isProductEntry) ...[
              _buildProductSection(),
              const SizedBox(height: AppDimensions.spaceLg),
              if (_product != null) ...[
                _buildLotSection(),
                const SizedBox(height: AppDimensions.spaceLg),
              ],
              _buildDetailsSection(),
            ] else ...[
              _buildInstrumentSetSection(),
              const SizedBox(height: AppDimensions.spaceLg),
              if (_instrumentSet != null) ...[
                _buildSetComponentLotsSection(),
                const SizedBox(height: AppDimensions.spaceLg),
              ],
              _buildSetNotesSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Icon(
              widget.isEdit ? Icons.edit_outlined : Icons.playlist_add_rounded,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit
                      ? 'Adjust the captured stock-in details'
                      : 'Capture one stock-in line at a time',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  _isProductEntry
                      ? 'Use product capture for standard lots and expiry details.'
                      : 'Use set capture when the incoming line represents a full instrument set instance.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryKindSection() {
    return _SectionCard(
      title: 'Entry type',
      description:
          'Choose whether this receiving line is a catalog product or a full instrument set instance.',
      child: Row(
        children: [
          Expanded(
            child: _EntryKindButton(
              label: 'Product',
              active: _entryKind == StockInEntryKind.product,
              locked: widget.isEdit,
              onTap: () => _setEntryKind(StockInEntryKind.product),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: _EntryKindButton(
              label: 'Instrument set',
              active: _entryKind == StockInEntryKind.set,
              locked: widget.isEdit,
              onTap: () => _setEntryKind(StockInEntryKind.set),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    return _SectionCard(
      title: 'Product',
      description: 'Select the catalog item that matches the incoming stock.',
      child: Column(
        children: [
          _selectionField(
            value: _product?.displayLabel,
            emptyLabel: 'Tap to search and select a product',
            icon: Icons.medication_outlined,
            errorText: _productError,
            onTap: _saving ? null : _pickProduct,
          ),
          if (_product != null) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            _productInfoCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildInstrumentSetSection() {
    return _SectionCard(
      title: 'Instrument set',
      description:
          'Record the instrument set being received. Finalization will mint a unique lot number for the set instance.',
      child: Column(
        children: [
          _selectionField(
            value: _instrumentSet?.displayLabel,
            emptyLabel: 'Tap to search and select an instrument set',
            icon: Icons.precision_manufacturing_outlined,
            errorText: _instrumentSetError,
            onTap: _saving ? null : _pickInstrumentSet,
          ),
          if (_instrumentSet != null) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            _instrumentSetInfoCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildLotSection() {
    return _SectionCard(
      title: 'Lot information',
      description: _requiresLot
          ? 'Scan the supplier lot, or generate a system lot number for instrument products when needed.'
          : 'This product does not require lot tracking. The backend will generate the lot on finalize.',
      child: Column(
        children: [
          if (_requiresLot) ...[
            ScanInputField(
              controller: _lotCtl,
              label: 'Lot number',
              hint: 'Scan supplier lot number',
              onScan: _scanLot,
              enabled: !_generateLotNumber,
            ),
            if (_generateLotNumber) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              _infoBanner(
                icon: Icons.auto_awesome_rounded,
                text:
                    'Expected generated lot: $_expectedGeneratedProductLotNumber. The server may add a sequence if this lot already exists.',
              ),
            ],
            const SizedBox(height: AppDimensions.spaceMd),
            if (_canGenerateProductLot) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              _switchTile(
                title: 'Generate lot number',
                subtitle:
                    'Create a system lot number when the session is finalized.',
                value: _generateLotNumber,
                onChanged: (value) => setState(() {
                  _generateLotNumber = value;
                  if (value) {
                    _lotCtl.clear();
                    _missingLotFlag = false;
                    _lotEntryMode = LotEntryMode.scan;
                  }
                }),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceMd),
          ] else
            _infoBanner(
              icon: Icons.auto_awesome_rounded,
              text:
                  '${_product!.productName} will receive an auto-generated lot number when the session is finalized.',
            ),
          if (_requiresExpiry) _expiryField(),
          if (_isProductEntry) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            _manufacturingDateField(),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              controller: _quantityCtl,
              label: 'Received quantity *',
              hint: '1',
              keyboardType: TextInputType.number,
              integerOnly: true,
              prefixIcon: Icons.numbers_rounded,
              validator: (value) => (int.tryParse(value?.trim() ?? '') ?? 0) > 0
                  ? null
                  : 'Quantity must be at least 1.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return _SectionCard(
      title: 'Notes',
      description: 'Record receiving exceptions and any optional notes.',
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            controller: _remarksCtl,
            label: 'Remarks (optional)',
            hint: 'Any additional notes',
            prefixIcon: Icons.notes_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSetNotesSection() {
    return _SectionCard(
      title: 'Receiving notes',
      description:
          'Set quantity applies to every component. Add an optional note for this set receipt.',
      child: Column(
        children: [
          AppTextField(
            controller: _quantityCtl,
            label: 'Received quantity *',
            hint: '1',
            keyboardType: TextInputType.number,
            integerOnly: true,
            prefixIcon: Icons.numbers_rounded,
            validator: (value) => (int.tryParse(value?.trim() ?? '') ?? 0) > 0
                ? null
                : 'Quantity must be at least 1.',
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            controller: _remarksCtl,
            label: 'Remarks (optional)',
            hint: 'Optional notes for this set instance',
            prefixIcon: Icons.notes_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSetComponentLotsSection() {
    final components = _instrumentSet!.items;
    return _SectionCard(
      title: 'Component lot numbers',
      description:
          'Record a lot number for each component, or choose generation when no supplier lot is available.',
      child: Column(
        children: [
          if (components.isEmpty)
            _infoBanner(
              icon: Icons.error_outline_rounded,
              text:
                  'This instrument set has no components. Choose a set with configured components.',
            )
          else
            ...components.map((component) {
              final id = component.instrumentSetItemId;
              if (id == null) {
                return _infoBanner(
                  icon: Icons.error_outline_rounded,
                  text: 'A component is missing its backend identifier.',
                );
              }
              final generated = _generatedComponentLotIds.contains(id);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${component.name}${component.code?.isNotEmpty == true ? ' (${component.code})' : ''} x ${component.quantity}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    AppTextField(
                      controller: _componentLotCtls[id],
                      label: 'Lot number',
                      hint: 'Scan or enter supplier lot',
                      prefixIcon: Icons.qr_code_scanner_outlined,
                      onPrefixIconTap: () => _scanComponentLot(id),
                      enabled: !generated && !_saving,
                      onChanged: (_) => setState(() {
                        _generatedComponentLotIds.remove(id);
                        _componentLotsError = null;
                      }),
                    ),
                    if (generated) ...[
                      const SizedBox(height: AppDimensions.spaceXs),
                      Text(
                        'Expected generated lot: ${_expectedGeneratedComponentLotNumber(component)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spaceXs),
                    _switchTile(
                      title: 'Generate lot number',
                      subtitle: 'Create a system lot number when finalized.',
                      value: generated,
                      onChanged: _saving
                          ? (_) {}
                          : (value) => setState(() {
                              if (value) {
                                _componentLotCtls[id]?.clear();
                                _generatedComponentLotIds.add(id);
                              } else {
                                _generatedComponentLotIds.remove(id);
                              }
                              _componentLotsError = null;
                            }),
                    ),
                  ],
                ),
              );
            }),
          if (_componentLotsError != null)
            Text(
              _componentLotsError!,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
            ),
        ],
      ),
    );
  }

  Widget _selectionField({
    required String? value,
    required String emptyLabel,
    required IconData icon,
    required VoidCallback? onTap,
    String? errorText,
  }) {
    final hasError = errorText != null;
    final hasValue = value != null && value.trim().isNotEmpty;
    final displayValue = hasValue ? value : emptyLabel;
    final resolvedErrorText = errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMd,
              vertical: AppDimensions.spaceMd,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: hasError ? AppColors.error : AppColors.textMuted,
                ),
                const SizedBox(width: AppDimensions.spaceMd),
                Expanded(
                  child: Text(
                    displayValue,
                    style: hasValue
                        ? AppTextStyles.bodyMedium
                        : AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (resolvedErrorText != null) ...[
          const SizedBox(height: AppDimensions.spaceSm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              resolvedErrorText,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _productInfoCard() {
    final product = _product!;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  product.productName,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'Ref: ${product.refNum}${product.uom != null ? '   UOM: ${product.uom}' : ''}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Row(
            children: [
              Expanded(
                child: _ProductRequirement(
                  icon: Icons.inventory_2_outlined,
                  label: 'Lot tracking',
                  value: product.requiresLot ? 'Required' : 'Not required',
                  emphasized: product.requiresLot,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceLg),
              Expanded(
                child: _ProductRequirement(
                  icon: Icons.event_outlined,
                  label: 'Expiry tracking',
                  value: product.requiresExpiry ? 'Required' : 'Not required',
                  emphasized: product.requiresExpiry,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _instrumentSetInfoCard() {
    final instrumentSet = _instrumentSet!;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instrumentSet.displayLabel,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (instrumentSet.items.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceSm),
            ...instrumentSet.items
                .take(6)
                .map(
                  (component) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${component.name}${component.code?.trim().isNotEmpty == true ? ' (${component.code})' : ''} x ${component.quantity}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _expiryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _saving ? null : _pickExpiry,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMd,
              vertical: AppDimensions.spaceMd,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: _expiryError == null
                    ? AppColors.border
                    : AppColors.error,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: _expiryError == null
                      ? AppColors.textMuted
                      : AppColors.error,
                ),
                const SizedBox(width: AppDimensions.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expiry date *',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceXxs),
                      Text(
                        _expiryDate == null
                            ? 'Tap to pick expiry date'
                            : DateFormatter.toDisplay(_expiryDate!),
                        style: _expiryDate == null
                            ? AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                              )
                            : AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (_expiryDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    color: AppColors.textMuted,
                    onPressed: () => setState(() {
                      _expiryDate = null;
                      _expiryError = null;
                    }),
                  ),
              ],
            ),
          ),
        ),
        if (_expiryError != null) ...[
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            _expiryError!,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _manufacturingDateField() {
    return InkWell(
      onTap: _saving ? null : _pickManufacturingDate,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
          vertical: AppDimensions.spaceMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.factory_outlined, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppDimensions.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manufacturing date',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXxs),
                  Text(
                    _manufacturingDate == null
                        ? 'Tap to pick manufacturing date (optional)'
                        : DateFormatter.toDisplay(_manufacturingDate!),
                    style: _manufacturingDate == null
                        ? AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          )
                        : AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            if (_manufacturingDate != null)
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                color: AppColors.textMuted,
                onPressed: () => setState(() => _manufacturingDate = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value
            ? AppColors.warning.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: value
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
          vertical: AppDimensions.spaceXs,
        ),
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
        ),
        activeThumbColor: AppColors.warning,
      ),
    );
  }

  Widget _infoBanner({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.info),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRequirement extends StatelessWidget {
  const _ProductRequirement({
    required this.icon,
    required this.label,
    required this.value,
    required this.emphasized,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized ? AppColors.textPrimary : AppColors.textMuted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(description, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppDimensions.spaceLg),
          child,
        ],
      ),
    );
  }
}

class _EntryKindButton extends StatelessWidget {
  const _EntryKindButton({
    required this.label,
    required this.active,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryContainer
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: active ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

extension on ProductModel {
  String get displayLabel => '$refNum - $productName';
}
