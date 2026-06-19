import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/master_data_repository.dart';

/// A bottom sheet for searching and selecting a product.
/// Returns the selected [ProductModel] or null if dismissed.
class ProductSearchSheet extends ConsumerStatefulWidget {
  const ProductSearchSheet({super.key});

  static Future<ProductModel?> show(BuildContext context) {
    return showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => const ProductSearchSheet(),
    );
  }

  @override
  ConsumerState<ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends ConsumerState<ProductSearchSheet> {
  final _searchCtl = TextEditingController();
  List<ProductModel> _results = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(stockInMasterDataRepositoryProvider);
      final results = await repo.listProducts(search: query, perPage: 50);
      if (!mounted) return;
      setState(() {
        _results = results;
        _lastQuery = query;
      });
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spaceMd),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spaceLg,
                AppDimensions.spaceMd,
                AppDimensions.spaceLg,
                AppDimensions.spaceSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select product',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spaceLg,
                0,
                AppDimensions.spaceLg,
                AppDimensions.spaceSm,
              ),
              child: TextField(
                controller: _searchCtl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by ref. number or name',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchCtl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtl.clear();
                            _search('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceMd,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (v) => _search(v.trim()),
                onSubmitted: (v) => _search(v.trim()),
              ),
            ),

            const Divider(height: 1),

            // Results
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(AppDimensions.space3xl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppDimensions.space3xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: AppDimensions.spaceMd),
                          Text(
                            _lastQuery.isEmpty
                                ? 'No products found.'
                                : 'No results for "$_lastQuery".',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      itemBuilder: (_, i) => _ProductTile(product: _results[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceLg,
        vertical: AppDimensions.spaceXs,
      ),
      title: Text(
        product.productName,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        product.refNum,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!product.requiresLot) _chip('No lot', AppColors.info),
          if (!product.requiresExpiry) _chip('No expiry', AppColors.textMuted),
        ],
      ),
      onTap: () => Navigator.pop(context, product),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
