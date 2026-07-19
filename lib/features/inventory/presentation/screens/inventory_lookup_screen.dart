import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/module_app_bar.dart';
import '../../../stock_in/presentation/widgets/barcode_scanner_sheet.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_unit_tile.dart';

class InventoryLookupScreen extends ConsumerStatefulWidget {
  const InventoryLookupScreen({super.key});

  @override
  ConsumerState<InventoryLookupScreen> createState() =>
      _InventoryLookupScreenState();
}

class _InventoryLookupScreenState extends ConsumerState<InventoryLookupScreen> {
  late final TextEditingController _queryCtl;
  String _mode = 'lot';
  String _submitted = '';

  @override
  void initState() {
    super.initState();
    _queryCtl = TextEditingController();
  }

  @override
  void dispose() {
    _queryCtl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _submitted = _queryCtl.text.trim();
    });
  }

  Future<void> _scan() async {
    final result = await BarcodeScannerSheet.show(
      context,
      title: _mode == 'lot' ? 'Scan lot number' : 'Scan reference number',
      helperText: _mode == 'lot'
          ? 'Scan the lot barcode or QR code to find its inventory record.'
          : 'Scan the product reference barcode or QR code to find matching lots.',
    );
    if (!mounted || result == null) return;

    _queryCtl.text = result.value;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _submitted.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Inventory Lookup',
        onBack: () => context.go(RouteNames.inventory),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.sidebarBg,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceLg,
              AppDimensions.spaceMd,
              AppDimensions.spaceLg,
              AppDimensions.spaceMd,
            ),
            child: Column(
              children: [
                AppTextField(
                  controller: _queryCtl,
                  hint: _mode == 'lot'
                      ? 'Enter lot number'
                      : 'Enter product reference number',
                  textInputAction: TextInputAction.search,
                  prefixIcon: Icons.search_rounded,
                  suffixIcon: Icons.qr_code_scanner_rounded,
                  onSuffixIconTap: _scan,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'lot',
                            label: Text('By Lot Number'),
                          ),
                          ButtonSegment<String>(
                            value: 'ref',
                            label: Text('By Ref Number'),
                          ),
                        ],
                        selected: <String>{_mode},
                        onSelectionChanged: (values) {
                          setState(() {
                            _mode = values.first;
                            _submitted = '';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Search'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: !hasQuery
                ? Center(
                    child: Text(
                      'Enter a lookup value to search inventory.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : _mode == 'lot'
                ? _buildLotLookup()
                : _buildRefLookup(),
          ),
        ],
      ),
    );
  }

  Widget _buildLotLookup() {
    final asyncData = ref.watch(inventoryLookupByLotProvider(_submitted));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (lot) => ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        children: [
          InventoryUnitTile(
            unit: lot,
            onTap: () => context.push(RouteNames.inventoryDetailPath(lot.id)),
          ),
        ],
      ),
    );
  }

  Widget _buildRefLookup() {
    final asyncData = ref.watch(inventoryLookupByRefProvider(_submitted));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (lots) {
        if (lots.isEmpty) {
          return Center(
            child: Text(
              'No lots found for this reference number.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          itemBuilder: (_, index) {
            final lot = lots[index];
            return InventoryUnitTile(
              unit: lot,
              onTap: () => context.push(RouteNames.inventoryDetailPath(lot.id)),
            );
          },
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDimensions.spaceSm),
          itemCount: lots.length,
        );
      },
    );
  }
}
