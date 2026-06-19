import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../data/models/instrument_set_model.dart';
import '../../data/repositories/master_data_repository.dart';

class InstrumentSetSearchSheet extends StatefulWidget {
  const InstrumentSetSearchSheet({super.key, required this.repository});

  final StockInMasterDataRepository repository;

  static Future<InstrumentSetModel?> show(
    BuildContext context, {
    required StockInMasterDataRepository repository,
  }) {
    return showModalBottomSheet<InstrumentSetModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => InstrumentSetSearchSheet(repository: repository),
    );
  }

  @override
  State<InstrumentSetSearchSheet> createState() =>
      _InstrumentSetSearchSheetState();
}

class _InstrumentSetSearchSheetState extends State<InstrumentSetSearchSheet> {
  final _searchCtl = TextEditingController();
  List<InstrumentSetModel> _results = [];
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
      final results = await widget.repository.listInstrumentSets(
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
                      'Select instrument set',
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
                  hintText: 'Search instrument sets',
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
                            ? 'No instrument sets found.'
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
                        final set = _results[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceLg,
                            vertical: AppDimensions.spaceXs,
                          ),
                          title: Text(
                            set.setName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            set.setCode?.trim().isNotEmpty == true
                                ? '${set.setCode} • ${set.items.length} components'
                                : '${set.items.length} components',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, set),
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
