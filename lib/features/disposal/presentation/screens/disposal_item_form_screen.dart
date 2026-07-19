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
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/module_app_bar.dart';
import '../../../inventory/data/models/inventory_unit_model.dart';
import '../../../inventory/data/repositories/inventory_repository.dart';
import '../../../stock_in/presentation/widgets/barcode_scanner_sheet.dart';
import '../../data/repositories/disposal_repository.dart';
import '../providers/disposal_providers.dart';

class DisposalItemFormScreen extends ConsumerStatefulWidget {
  const DisposalItemFormScreen({super.key, required this.disposalId});
  final int disposalId;

  @override
  ConsumerState<DisposalItemFormScreen> createState() =>
      _DisposalItemFormScreenState();
}

class _DisposalItemFormScreenState
    extends ConsumerState<DisposalItemFormScreen> {
  final _lotCtl = TextEditingController();
  final _qtyCtl = TextEditingController(text: '1');
  final _reasonCtl = TextEditingController();
  final _remarksCtl = TextEditingController();
  InventoryUnitModel? _lot;
  String _category = 'expired';
  bool _saving = false;
  bool _isScanning = false;
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
      _lotCtl.text = data.toString();
      if (!_isScanning) setState(() => _isScanning = true);
      _findLot();
    });
  }

  @override
  void dispose() {
    _lotCtl.dispose();
    _qtyCtl.dispose();
    _reasonCtl.dispose();
    _remarksCtl.dispose();
    _debounce?.cancel();
    _scannerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(disposalDetailProvider(widget.disposalId));
    if (detail.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (detail.hasError) {
      return Scaffold(body: AppErrorWidget(message: detail.error.toString()));
    }
    if (detail.value?.isDraft != true) {
      return Scaffold(
        appBar: ModuleAppBar(
          title: 'Disposal item',
          onBack: () => context.pop(),
        ),
        body: const Center(
          child: Text('Only draft disposals can accept items.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Add disposal item',
        onBack: () => context.pop(),
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
          child: FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text(_saving ? 'Adding...' : 'Add item'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceLg,
          AppDimensions.spaceLg,
          AppDimensions.spaceLg,
          AppDimensions.space6xl,
        ),
        children: [
          _introCard(),
          const SizedBox(height: AppDimensions.spaceLg),
          _sectionCard(
            title: 'Lot information',
            description:
                'Scan the lot barcode or QR code, or search inventory manually.',
            child: Column(
              children: [
                AppTextField(
                  controller: _lotCtl,
                  label: 'Lot',
                  hint: 'Scan or enter lot number',
                  prefixIcon: Icons.qr_code_scanner_rounded,
                  onPrefixIconTap: _scanLot,
                  suffixIcon: Icons.list_alt_rounded,
                  onSuffixIconTap: _chooseLot,
                  textInputAction: TextInputAction.search,
                  isLoading: _isScanning,
                  onSubmitted: (_) => _findLot(),
                  onChanged: (value) {
                    if (value.contains('=') ||
                        value.contains(';') ||
                        value.contains('{')) {
                      if (!_isScanning) setState(() => _isScanning = true);
                    }
                    setState(() => _lot = null);
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 150), () {
                      if (_lotCtl.text.trim().isNotEmpty) {
                        _findLot();
                      } else if (mounted) {
                        setState(() => _isScanning = false);
                      }
                    });
                  },
                ),
                if (_lot != null) ...[
                  const SizedBox(height: AppDimensions.spaceMd),
                  _selectedLotContext(),
                ],
                if (_lot != null && _terminal(_lot!.status)) ...[
                  const SizedBox(height: AppDimensions.spaceSm),
                  Text(
                    'This lot is already terminal and cannot be disposed.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(
                  controller: _qtyCtl,
                  label: 'Quantity',
                  hint: _lot == null
                      ? 'Enter quantity'
                      : 'Maximum ${_lot!.quantityAvailable ?? 0}',
                  prefixIcon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          _sectionCard(
            title: 'Disposal details',
            description: 'Record why this lot is being removed from inventory.',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Disposal category',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                    DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                    DropdownMenuItem(value: 'lost', child: Text('Lost')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'expired'),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(
                  controller: _reasonCtl,
                  label: 'Reason *',
                  hint: 'Describe why this lot is being disposed',
                  prefixIcon: Icons.edit_note_rounded,
                  maxLines: 3,
                ),
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
          ),
        ],
      ),
    );
  }

  Widget _introCard() => Container(
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
          child: Icon(Icons.playlist_add_rounded, color: AppColors.textPrimary),
        ),
        const SizedBox(width: AppDimensions.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Capture one disposal lot at a time',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXs),
              Text(
                'Scan the package, verify available quantity, then record the reason.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionCard({
    required String title,
    required String description,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(AppDimensions.spaceLg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(description, style: AppTextStyles.bodySmall),
        const SizedBox(height: AppDimensions.spaceMd),
        child,
      ],
    ),
  );

  Widget _selectedLotContext() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppDimensions.spaceMd),
    decoration: BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _lot!.product?.productName ?? 'Inventory lot',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          '${_lot!.product?.refNum ?? '-'} · Available: ${_lot!.quantityAvailable ?? 0}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  bool _terminal(String status) =>
      status == 'disposed' || status == 'returned_to_supplier';

  Future<void> _chooseLot() async {
    final existing = await ref.read(
      disposalItemsProvider(widget.disposalId).future,
    );
    if (!mounted) return;
    final selected = await showModalBottomSheet<InventoryUnitModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) =>
          _LotPicker(excludedLotIds: existing.map((e) => e.lotId).toSet()),
    );
    if (selected == null || !mounted) return;
    _selectLot(selected);
  }

  Future<void> _scanLot() async {
    final result = await BarcodeScannerSheet.show(
      context,
      title: 'Scan stock-in QR label',
      helperText: 'Scan the QR label generated when stock-in was finalized.',
    );
    if (result == null || !mounted) return;
    setState(() {
      _lotCtl.text = _lotNumberFromQrPayload(result.value);
      _lot = null;
      _isScanning = true;
    });
    await _findLot();
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
      // Current labels use V=1;...;LOT=... payloads.
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

  Future<void> _findLot() async {
    final rawQuery = _lotCtl.text.trim();
    if (rawQuery.isEmpty) return;
    final query = _lotNumberFromQrPayload(rawQuery);
    if (query != rawQuery) _lotCtl.text = query;
    try {
      final results = await ref
          .read(inventoryRepositoryProvider)
          .listInventoryUnits(search: query, status: 'all', perPage: 50);
      final existing = await ref.read(
        disposalItemsProvider(widget.disposalId).future,
      );
      if (!mounted) return;
      final usedIds = existing.map((item) => item.lotId).toSet();
      final match = results.items
          .where(
            (lot) =>
                lot.lotNumber.toLowerCase() == query.toLowerCase() &&
                !usedIds.contains(lot.id),
          )
          .firstOrNull;
      if (match != null) {
        _selectLot(match);
        FocusScope.of(context).unfocus();
      } else {
        setState(() => _isScanning = false);
        _error(
          'No available lot matches "$query". Use the list button to browse lots.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isScanning = false);
      _error(e);
    }
  }

  void _selectLot(InventoryUnitModel lot) {
    setState(() {
      _lot = lot;
      _lotCtl.text = lot.lotNumber;
      _qtyCtl.text = '1';
      _isScanning = false;
    });
  }

  void _error(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_qtyCtl.text.trim());
    final max = _lot?.quantityAvailable ?? 0;
    final message = _lot == null
        ? 'Scan or choose a lot.'
        : _terminal(_lot!.status)
        ? 'This lot cannot be disposed.'
        : quantity == null || quantity < 1
        ? 'Quantity must be at least 1.'
        : quantity > max
        ? 'Quantity cannot exceed available stock ($max).'
        : _reasonCtl.text.trim().isEmpty
        ? 'Reason is required.'
        : _reasonCtl.text.trim().length > 500
        ? 'Reason must be 500 characters or less.'
        : _remarksCtl.text.trim().length > 1000
        ? 'Remarks must be 1,000 characters or less.'
        : null;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(disposalRepositoryProvider)
          .addItem(
            widget.disposalId,
            lotId: _lot!.id,
            quantity: quantity!,
            category: _category,
            reasonText: _reasonCtl.text,
            remarks: _remarksCtl.text,
          );
      ref.invalidate(disposalItemsProvider(widget.disposalId));
      ref.invalidate(disposalDetailProvider(widget.disposalId));
      ref.invalidate(disposalListProvider);
      if (mounted) context.go(RouteNames.disposalDetailPath(widget.disposalId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _LotPicker extends ConsumerStatefulWidget {
  const _LotPicker({required this.excludedLotIds});
  final Set<int> excludedLotIds;
  @override
  ConsumerState<_LotPicker> createState() => _LotPickerState();
}

class _LotPickerState extends ConsumerState<_LotPicker> {
  final _searchCtl = TextEditingController();
  List<InventoryUnitModel> _lots = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(inventoryRepositoryProvider)
          .listInventoryUnits(
            search: _searchCtl.text,
            status: 'all',
            perPage: 50,
          );
      if (mounted) {
        setState(
          () => _lots = page.items
              .where((lot) => !widget.excludedLotIds.contains(lot.id))
              .toList(),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text('Choose inventory lot', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            controller: _searchCtl,
            hint: 'Search lot or product',
            prefixIcon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          SizedBox(
            height: 360,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : ListView.separated(
                    itemCount: _lots.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, index) {
                      final lot = _lots[index];
                      return ListTile(
                        title: Text(lot.lotNumber),
                        subtitle: Text(
                          '${lot.product?.productName ?? '-'} · Available: ${lot.quantityAvailable ?? 0}',
                        ),
                        trailing: Text(lot.status),
                        onTap: () => Navigator.pop(context, lot),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
