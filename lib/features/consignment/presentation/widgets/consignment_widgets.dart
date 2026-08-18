import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/content_card.dart';

String displayDate(DateTime? value, {bool time = false}) => value == null
    ? '-'
    : DateFormat(
        time ? 'dd MMM yyyy HH:mm' : 'dd MMM yyyy',
      ).format(value.toLocal());

class ConsignmentStatusBadge extends StatelessWidget {
  const ConsignmentStatusBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final draft = status == 'draft';
    final color = draft ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        draft ? 'Draft' : 'Confirmed',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ConsignmentSection extends StatelessWidget {
  const ConsignmentSection({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.trailing,
  });
  final String title, description;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: trailing == null ? null : 2,
                  overflow: trailing == null
                      ? TextOverflow.clip
                      : TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppDimensions.spaceMd),
            trailing!,
          ],
        ],
      ),
      const SizedBox(height: AppDimensions.spaceSm),
      child,
    ],
  );
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ContentCard(
    padding: const EdgeInsets.all(AppDimensions.spaceLg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 124,
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) label,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.background,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppDimensions.radiusXl),
    ),
  ),
  builder: (context) => SafeArea(
    child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: .62,
      maxChildSize: .9,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            child: Text(title, style: AppTextStyles.titleMedium),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No options found.',
                      style: AppTextStyles.bodySmall,
                    ),
                  )
                : ListView.separated(
                    controller: scroll,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) => ListTile(
                      title: Text(label(items[index])),
                      onTap: () => Navigator.pop(context, items[index]),
                    ),
                  ),
          ),
        ],
      ),
    ),
  ),
);

Future<T?> showSearchPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) label,
  required String searchHint,
  String Function(T)? subtitle,
}) {
  final searchController = TextEditingController();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusXl),
      ),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final query = searchController.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? items
            : items
                  .where((item) => label(item).toLowerCase().contains(query))
                  .toList();
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .72,
            maxChildSize: .9,
            builder: (context, scrollController) => Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceLg),
              child: Column(
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
                  Text(title, style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppDimensions.spaceMd),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No matching results.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) => ListTile(
                              title: Text(label(filtered[index])),
                              subtitle: subtitle == null
                                  ? null
                                  : Text(subtitle(filtered[index])),
                              onTap: () =>
                                  Navigator.pop(context, filtered[index]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
