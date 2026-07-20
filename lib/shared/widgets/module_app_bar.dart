import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class ModuleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ModuleAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: AppColors.sidebarBg,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      tooltip: 'Back',
      onPressed: onBack ?? () => Navigator.maybePop(context),
    ),
    title: Text(title, style: AppTextStyles.titleMedium),
    actions: [
      ...actions,
      const SizedBox(width: AppDimensions.spaceXs),
    ],
    bottom: bottom,
  );
}
