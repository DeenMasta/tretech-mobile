import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../data/models/supplier_model.dart';
import '../../data/repositories/master_data_repository.dart';

class SupplierSearchSheet extends StatefulWidget {
  const SupplierSearchSheet({
    super.key,
    required this.repository,
    this.title = 'Select supplier',
  });

  final StockInMasterDataRepository repository;
  final String title;

  static Future<SupplierModel?> show(
    BuildContext context, {
    required StockInMasterDataRepository repository,
    String title = 'Select supplier',
  }) {
    return showModalBottomSheet<SupplierModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => SupplierSearchSheet(repository: repository, title: title),
    );
  }

  @override
  State<SupplierSearchSheet> createState() => _SupplierSearchSheetState();
}

class _SupplierSearchSheetState extends State<SupplierSearchSheet> {
  final _searchCtl = TextEditingController();
  List<SupplierModel> _results = [];
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
      final results = await widget.repository.listSuppliers(
        search: query,
        perPage: 50,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _lastQuery = query;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = []);
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
                      widget.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
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
                  hintText: 'Search suppliers',
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
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) => _search(value.trim()),
                onSubmitted: (value) => _search(value.trim()),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppDimensions.space3xl),
                      child: Text(
                        _lastQuery.isEmpty
                            ? 'No suppliers found.'
                            : 'No results for "$_lastQuery".',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      itemBuilder: (_, index) {
                        final supplier = _results[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceLg,
                            vertical: AppDimensions.spaceXs,
                          ),
                          title: Text(
                            supplier.supplierName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle:
                              supplier.email != null &&
                                  supplier.email!.trim().isNotEmpty
                              ? Text(
                                  supplier.email!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, supplier),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
