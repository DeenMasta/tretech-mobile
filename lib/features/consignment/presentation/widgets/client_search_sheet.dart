import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../data/models/consignment_models.dart';

class ClientSearchSheet extends StatefulWidget {
  const ClientSearchSheet({super.key, required this.clients});

  final List<ClientBrief> clients;

  static Future<ClientBrief?> show(
    BuildContext context, {
    required List<ClientBrief> clients,
  }) => showModalBottomSheet<ClientBrief>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusXl),
      ),
    ),
    builder: (_) => ClientSearchSheet(clients: clients),
  );

  @override
  State<ClientSearchSheet> createState() => _ClientSearchSheetState();
}

class _ClientSearchSheetState extends State<ClientSearchSheet> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtl.text.trim().toLowerCase();
    final clients = query.isEmpty
        ? widget.clients
        : widget.clients
              .where((client) => client.name.toLowerCase().contains(query))
              .toList();
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * .85;

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
                      'Filter by client',
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
                  hintText: 'Search clients',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchCtl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(_searchCtl.clear),
                        )
                      : null,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: clients.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppDimensions.space3xl),
                      child: Text(
                        query.isEmpty
                            ? 'No clients found.'
                            : 'No results for "$query".',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: clients.length,
                      itemBuilder: (_, index) {
                        final client = clients[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceLg,
                            vertical: AppDimensions.spaceXs,
                          ),
                          title: Text(
                            client.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, client),
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
