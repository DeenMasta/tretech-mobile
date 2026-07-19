import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../data/models/return_session_model.dart';

/// Bottom sheet for searching and selecting a confirmed consignment
/// that does not yet have an active return session (hasReturnSession=false).
class ConsignmentSearchSheet extends ConsumerStatefulWidget {
  const ConsignmentSearchSheet({super.key});

  static Future<ReturnConsignmentBrief?> show(BuildContext context) {
    return showModalBottomSheet<ReturnConsignmentBrief>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => const ConsignmentSearchSheet(),
    );
  }

  @override
  ConsumerState<ConsignmentSearchSheet> createState() =>
      _ConsignmentSearchSheetState();
}

class _ConsignmentSearchSheetState
    extends ConsumerState<ConsignmentSearchSheet> {
  final _searchCtl = TextEditingController();
  List<ReturnConsignmentBrief> _results = [];
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
      final dio = ref.read(dioProvider);
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.consignments,
        queryParameters: {
          'page': 1,
          'per_page': 20,
          'status': 'confirmed',
          if (query.trim().isNotEmpty) 'search': query.trim(),
        },
      );
      final list = (response.data?['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ReturnConsignmentBrief.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _results = list;
        _lastQuery = query;
      });
    } catch (_) {
      // silently fail — user can retry by typing
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollCtl) => SafeArea(
          top: false,
          child: Column(
            children: [
              // ── Handle ───────────────────────────────────────────────────
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
              // ── Title + Search ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceLg,
                  AppDimensions.spaceMd,
                  AppDimensions.spaceLg,
                  AppDimensions.spaceSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select consignment',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    TextField(
                      controller: _searchCtl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by consignment no.',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _loading
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != _lastQuery) _search(v);
                      },
                    ),
                  ],
                ),
              ),
              // ── Results ──────────────────────────────────────────────────
              Expanded(
                child: _results.isEmpty && !_loading
                    ? Center(
                        child: Text(
                          'No confirmed consignments found.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollCtl,
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.spaceLg,
                          0,
                          AppDimensions.spaceLg,
                          AppDimensions.spaceLg,
                        ),
                        itemCount: _results.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (_, i) {
                          final c = _results[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.spaceXs,
                            ),
                            title: Text(
                              c.consignmentNo,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: c.clientName != null
                                ? Text(
                                    c.clientName!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                : null,
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onTap: () => Navigator.pop(context, c),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
