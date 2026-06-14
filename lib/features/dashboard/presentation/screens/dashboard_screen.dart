import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/kpi_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: RouteNames.dashboard),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Stock In', route: RouteNames.stockIn),
    _NavItem(icon: Icons.qr_code_2_rounded, label: 'QR Printing', route: RouteNames.qrPrinting),
    _NavItem(icon: Icons.local_shipping_rounded, label: 'Consignment', route: RouteNames.consignment),
    _NavItem(icon: Icons.assignment_return_rounded, label: 'Returns', route: RouteNames.returns),
    _NavItem(icon: Icons.delete_sweep_rounded, label: 'Disposal', route: RouteNames.disposal),
    _NavItem(icon: Icons.warehouse_rounded, label: 'Inventory', route: RouteNames.inventory),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isWide
          ? null
          : _buildMobileAppBar(user?.name ?? 'User'),
      drawer: isWide ? null : _buildDrawer(),
      body: isWide
          ? Row(
              children: [
                _buildSidebar(user?.name ?? 'User'),
                Expanded(child: _buildMainContent()),
              ],
            )
          : _buildMainContent(),
    );
  }

  // ── Mobile App Bar ──────────────────────────────────────────
  PreferredSizeWidget _buildMobileAppBar(String userName) {
    return AppBar(
      backgroundColor: AppColors.sidebarBg,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        _navItems[_selectedIndex].label,
        style: AppTextStyles.titleMedium,
      ),
      actions: [
        _buildNotificationBell(),
        _buildAvatarButton(userName),
        const SizedBox(width: AppDimensions.spaceMd),
      ],
    );
  }

  // ── Sidebar ──────────────────────────────────────────────────
  Widget _buildSidebar(String userName) {
    final width = _sidebarExpanded
        ? AppDimensions.sidebarWidth
        : AppDimensions.sidebarCollapsedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        gradient: AppColors.sidebarGradient,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Logo / Brand
          _buildSidebarHeader(),
          const SizedBox(height: AppDimensions.spaceXl),

          // Nav Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMd,
              ),
              itemCount: _navItems.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.spaceXs),
              itemBuilder: (_, i) => _buildNavItem(_navItems[i], i),
            ),
          ),

          // Bottom section
          _buildSidebarFooter(userName),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceLg,
        AppDimensions.space3xl,
        AppDimensions.spaceLg,
        AppDimensions.spaceLg,
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'T',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          if (_sidebarExpanded) ...[
            const SizedBox(width: AppDimensions.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRETECH',
                    style: AppTextStyles.titleSmall.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Warehouse Manager',
                    style: AppTextStyles.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Collapse toggle
            GestureDetector(
              onTap: () => setState(() => _sidebarExpanded = false),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          ] else ...[
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _sidebarExpanded = true),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int index) {
    final isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.sidebarItemActive : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.sidebarItemRadius),
        border: isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          context.go(item.route);
        },
        borderRadius: BorderRadius.circular(AppDimensions.sidebarItemRadius),
        hoverColor: AppColors.sidebarItemHover,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _sidebarExpanded
                ? AppDimensions.spaceMd
                : AppDimensions.spaceSm,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: _sidebarExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: AppDimensions.iconMd,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: AppDimensions.spaceMd),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(String userName) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: InkWell(
        onTap: () async {
          await ref.read(authProvider.notifier).logout();
          if (mounted) context.go(RouteNames.login);
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceSm),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  (userName.isNotEmpty ? userName[0] : 'U').toUpperCase(),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: AppDimensions.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Sign out',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.logout_rounded,
                  size: AppDimensions.iconMd,
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Mobile Drawer ────────────────────────────────────────────
  Widget _buildDrawer() {
    final user = ref.watch(currentUserProvider);
    return Drawer(
      backgroundColor: AppColors.sidebarBg,
      child: _buildSidebar(user?.name ?? 'User'),
    );
  }

  // ── Main Content ─────────────────────────────────────────────
  Widget _buildMainContent() {
    if (_selectedIndex != 0) {
      return _buildComingSoon(_navItems[_selectedIndex].label);
    }
    return _buildDashboardContent();
  }

  Widget _buildDashboardContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildTopBar()),
        SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildPageHeader(),
              const SizedBox(height: AppDimensions.spaceXxl),
              _buildKpiGrid(),
              const SizedBox(height: AppDimensions.spaceXxl),
              _buildRecentActivity(),
              const SizedBox(height: AppDimensions.spaceXxl),
              _buildAlertPanel(),
              const SizedBox(height: AppDimensions.space4xl),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    final user = ref.watch(currentUserProvider);
    return Container(
      height: AppDimensions.topBarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceLg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: Container(
              height: 36,
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppDimensions.spaceMd),
                  const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Text(
                    'Search inventory, orders...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _buildNotificationBell(),
          const SizedBox(width: AppDimensions.spaceMd),
          _buildAvatarButton(user?.name ?? 'U'),
        ],
      ),
    );
  }

  Widget _buildNotificationBell() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () {},
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarButton(String name) {
    return GestureDetector(
      onTap: () {},
      child: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primaryContainer,
        child: Text(
          (name.isNotEmpty ? name[0] : 'U').toUpperCase(),
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final user = ref.watch(currentUserProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, ${user?.name.split(' ').first ?? 'User'} 👋',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: AppDimensions.spaceXs),
              Text(
                'Here\'s what\'s happening with your warehouse today.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Date chip
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMd,
            vertical: AppDimensions.spaceXs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppDimensions.spaceXs),
              Text(
                _formatDate(now),
                style: AppTextStyles.labelMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Key Metrics', style: AppTextStyles.titleMedium),
            const SizedBox(width: AppDimensions.spaceSm),
            const StatusBadge(label: 'Live', status: BadgeStatus.success),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppDimensions.spaceMd,
              mainAxisSpacing: AppDimensions.spaceMd,
              childAspectRatio: 1.3,
              children: const [
                KpiCard(
                  title: 'Total Stock In',
                  value: '1,284',
                  subtitle: 'Items received',
                  icon: Icons.inventory_2_rounded,
                  trend: 12.5,
                  gradient: AppColors.cardGradientGreen,
                  accentColor: AppColors.primary,
                ),
                KpiCard(
                  title: 'Pending QR Print',
                  value: '47',
                  subtitle: 'Labels queued',
                  icon: Icons.qr_code_2_rounded,
                  trend: -3.2,
                  trendLabel: '-3 items',
                  gradient: AppColors.cardGradientBlue,
                  accentColor: AppColors.accent,
                ),
                KpiCard(
                  title: 'Consignments',
                  value: '23',
                  subtitle: 'Active shipments',
                  icon: Icons.local_shipping_rounded,
                  trend: 8.1,
                  gradient: AppColors.cardGradientGreen,
                  accentColor: AppColors.success,
                ),
                KpiCard(
                  title: 'Returns & Disposal',
                  value: '9',
                  subtitle: 'Pending review',
                  icon: Icons.assignment_return_rounded,
                  trend: -1.0,
                  trendLabel: '-1 item',
                  gradient: AppColors.cardGradientOrange,
                  accentColor: AppColors.warning,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    const activities = [
      _ActivityItem(
        'Stock In — Batch #0042',
        '48 items received from Supplier A',
        '10 min ago',
        Icons.inventory_2_rounded,
        BadgeStatus.success,
        'Completed',
      ),
      _ActivityItem(
        'QR Print Job',
        '15 labels printed via Bluetooth',
        '32 min ago',
        Icons.qr_code_2_rounded,
        BadgeStatus.info,
        'Printed',
      ),
      _ActivityItem(
        'Consignment #C-0017',
        'Shipped to Distributor XYZ',
        '1 hr ago',
        Icons.local_shipping_rounded,
        BadgeStatus.success,
        'Dispatched',
      ),
      _ActivityItem(
        'Return #R-0008',
        'Item rejected — damaged unit',
        '2 hr ago',
        Icons.assignment_return_rounded,
        BadgeStatus.warning,
        'Pending',
      ),
      _ActivityItem(
        'Disposal #D-0003',
        '5 expired units disposed',
        '3 hr ago',
        Icons.delete_sweep_rounded,
        BadgeStatus.error,
        'Disposed',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppTextStyles.titleMedium),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.divider,
            ),
            itemBuilder: (_, i) => _buildActivityTile(activities[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile(_ActivityItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceLg,
        vertical: AppDimensions.spaceMd,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              item.icon,
              size: AppDimensions.iconMd,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(label: item.statusLabel, status: item.status),
              const SizedBox(height: 4),
              Text(item.time, style: AppTextStyles.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alerts & Notifications', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppDimensions.spaceMd),
        _buildAlertCard(
          icon: Icons.warning_amber_rounded,
          title: 'Low Stock Alert',
          message: '3 items have fallen below minimum stock level.',
          status: BadgeStatus.warning,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        _buildAlertCard(
          icon: Icons.bluetooth_rounded,
          title: 'Printer Disconnected',
          message: 'Bluetooth thermal printer is not connected.',
          status: BadgeStatus.error,
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String message,
    required BadgeStatus status,
  }) {
    final color = switch (status) {
      BadgeStatus.warning => AppColors.warning,
      BadgeStatus.error => AppColors.error,
      BadgeStatus.success => AppColors.success,
      _ => AppColors.info,
    };

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceSm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, size: AppDimensions.iconMd, color: color),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon(String moduleName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.construction_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Text(moduleName, style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'This module is being developed\nand will be available soon.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ── Helper Models ───────────────────────────────────────────────
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String route;
}

class _ActivityItem {
  const _ActivityItem(
    this.title,
    this.subtitle,
    this.time,
    this.icon,
    this.status,
    this.statusLabel,
  );
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final BadgeStatus status;
  final String statusLabel;
}
