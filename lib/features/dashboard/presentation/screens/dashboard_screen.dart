import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  // ── Filter state (mirrors web Operations Dashboard) ────────
  // ignore: unused_field
  DateTimeRange? _appliedRange;
  String _quickRange = 'all'; // '7d' | '30d' | 'all'

  static const _navItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: RouteNames.dashboard,
    ),
    _NavItem(
      icon: Icons.inventory_2_rounded,
      label: 'Stock In',
      route: RouteNames.stockIn,
    ),
    _NavItem(
      icon: Icons.local_shipping_rounded,
      label: 'Consignment',
      route: RouteNames.consignment,
    ),
    _NavItem(
      icon: Icons.assignment_return_rounded,
      label: 'Returns',
      route: RouteNames.returns,
    ),
    _NavItem(
      icon: Icons.delete_sweep_rounded,
      label: 'Disposal',
      route: RouteNames.disposal,
    ),
    _NavItem(
      icon: Icons.warehouse_rounded,
      label: 'Inventory',
      route: RouteNames.inventory,
    ),
    _NavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: RouteNames.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isWide ? null : _buildMobileAppBar(user?.name ?? 'User'),
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
          icon: Icon(Icons.menu_rounded, color: AppColors.textSecondary),

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
      decoration: BoxDecoration(
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
              separatorBuilder: (_, _) =>
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
              gradient: LinearGradient(
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
            child: Center(
              child: Text(
                'T',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onPrimary,
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
              child: Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          ] else ...[
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _sidebarExpanded = true),
              child: Icon(
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
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
      decoration: BoxDecoration(
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
                Icon(
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
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final summaryAsync = ref.watch(dashboardSummaryProvider(_quickRange));

    return summaryAsync.when(
      loading: () => _buildDashboardScrollView(isWide, null),
      error: (error, _) =>
          _buildDashboardScrollView(isWide, null, error: error.toString()),
      data: (summary) => _buildDashboardScrollView(isWide, summary),
    );
  }

  Widget _buildDashboardScrollView(
    bool isWide,
    DashboardSummary? summary, {
    String? error,
  }) {
    return CustomScrollView(
      slivers: [
        if (isWide) SliverToBoxAdapter(child: _buildTopBar()),
        SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (error != null) ...[
                _buildErrorBanner(error),
                const SizedBox(height: AppDimensions.spaceMd),
              ],
              _buildHeroPanel(summary),
              const SizedBox(height: AppDimensions.spaceLg),
              _buildStatCardsGrid(summary),
              const SizedBox(height: AppDimensions.spaceLg),
              _buildDailyFlowPanel(summary),
              const SizedBox(height: AppDimensions.spaceLg),
              _buildActionBoard(summary),
              const SizedBox(height: AppDimensions.spaceLg),
              _buildMonthlyThroughput(summary),
              const SizedBox(height: AppDimensions.spaceLg),
              _buildStatusDistribution(summary),
              const SizedBox(height: AppDimensions.spaceLg),
              _buildTopMovedProducts(summary),
              const SizedBox(height: AppDimensions.spaceLg),
              _buildPipelineDrafts(summary),
              const SizedBox(height: AppDimensions.space4xl),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(
              'Failed to load dashboard data. Tap Refresh to try again.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final user = ref.watch(currentUserProvider);
    return Container(
      height: AppDimensions.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),

      child: Row(
        children: [
          // Search
          Expanded(
            child: Tooltip(
              message: 'Open inventory lookup',
              child: InkWell(
                onTap: () => context.go(RouteNames.inventoryLookup),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
                      Icon(
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
          icon: Icon(
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
            decoration: BoxDecoration(
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
      onTap: () => context.push(RouteNames.settings),
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

  // ── Hero panel — page header + applied range chip + filters ──
  Widget _buildHeroPanel(DashboardSummary? summary) {
    final user = ref.watch(currentUserProvider);
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
                      '$greeting, ${user?.name.split(' ').first ?? 'User'}',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: AppDimensions.spaceXs),
                    Text(
                      'Live overview of lot lifecycle, consignments, and stock movements.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              _appliedRangeChip(),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimensions.spaceLg),
          // Quick range chips
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceSm,
            children: [
              _quickRangeChip('Last 7 days', '7d'),
              _quickRangeChip('Last 30 days', '30d'),
              _quickRangeChip('All dates', 'all'),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          // Live stats
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceSm,
            children: [
              _outlineChip(
                summary != null
                    ? 'Total Lots: ${summary.lotCounts.total}'
                    : 'Total Lots: —',
              ),
              _outlineChip(
                summary != null
                    ? 'Movements Today: ${summary.todayActivity.movementsTotal}'
                    : 'Movements Today: —',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appliedRangeChip() {
    final label = _quickRange == '7d'
        ? 'Last 7 days'
        : _quickRange == '30d'
        ? 'Last 30 days'
        : 'All available dates';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 12,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppDimensions.spaceXs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickRangeChip(String label, String key) {
    final isActive = _quickRange == key;
    return InkWell(
      onTap: () => setState(() => _quickRange = key),
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _outlineChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Stat cards grid (4 KPI cards with tone badges + sparklines) ──
  Widget _buildStatCardsGrid(DashboardSummary? summary) {
    // Extract last N transaction counts from a trend list for sparkline display
    List<int> sparkline(List<DashboardTrendPoint> trend, {int n = 7}) {
      if (trend.isEmpty) return [];
      final slice = trend.length > n ? trend.sublist(trend.length - n) : trend;
      return slice.map((t) => t.transactionCount).toList();
    }

    final stockInSpark = summary != null
        ? sparkline(summary.stockInTrend)
        : <int>[];
    final consignSpark = summary != null
        ? sparkline(summary.consignmentTrend)
        : <int>[];
    final holdingCount = summary?.lotCounts.holding ?? 0;

    final cards = <_StatCardData>[
      _StatCardData(
        label: 'Available stock',
        value: summary != null ? summary.lotCounts.available.toString() : '—',
        helper: 'Lots currently in warehouse.',
        trend: 'Ready for consignment',
        tone: _StatTone.positive,
        sparkline: stockInSpark,
      ),
      _StatCardData(
        label: 'Holding area',
        value: summary != null ? holdingCount.toString() : '—',
        helper: 'Lots pending admin assignment.',
        trend: holdingCount > 0 ? 'Requires lot assignment' : 'All assigned',
        tone: holdingCount > 0 ? _StatTone.negative : _StatTone.positive,
        sparkline: const [],
      ),
      _StatCardData(
        label: 'Supplied to clients',
        value: summary != null ? summary.lotCounts.supplied.toString() : '—',
        helper: 'Active consignments at client locations.',
        trend: 'Currently consigned',
        tone: _StatTone.neutral,
        sparkline: consignSpark,
      ),
      _StatCardData(
        label: 'Movements today',
        value: summary != null
            ? summary.todayActivity.movementsTotal.toString()
            : '—',
        helper: 'Total stock movements recorded today.',
        trend: 'Active operations',
        tone: _StatTone.positive,
        sparkline: const [],
      ),
    ];

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
              childAspectRatio: 0.95,
              children: [for (final c in cards) _buildStatCard(c)],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatCardData c) {
    final toneColor = _toneColor(c.tone);
    final toneLabel = _toneLabel(c.tone);
    final toneIcon = _toneIcon(c.tone);
    final hasActivity = c.sparkline.any((v) => v > 0);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceXs),
              _toneChip(toneColor, toneLabel, toneIcon),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            c.value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            c.helper,
            style: AppTextStyles.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            c.trend,
            style: AppTextStyles.labelSmall.copyWith(
              color: toneColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          SizedBox(
            height: 32,
            width: double.infinity,
            child: hasActivity
                ? CustomPaint(
                    painter: _SparklinePainter(
                      data: c.sparkline,
                      color: toneColor,
                    ),
                  )
                : Center(
                    child: Text(
                      'No recent activity',
                      style: AppTextStyles.labelSmall,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _toneChip(Color color, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _toneColor(_StatTone tone) => switch (tone) {
    _StatTone.positive => AppColors.success,
    _StatTone.negative => AppColors.error,
    _StatTone.neutral => AppColors.textMuted,
  };

  String _toneLabel(_StatTone tone) => switch (tone) {
    _StatTone.positive => 'Healthy',
    _StatTone.negative => 'Risk',
    _StatTone.neutral => 'Watch',
  };

  IconData _toneIcon(_StatTone tone) => switch (tone) {
    _StatTone.positive => Icons.check_circle_rounded,
    _StatTone.negative => Icons.warning_amber_rounded,
    _StatTone.neutral => Icons.schedule_rounded,
  };

  // ── Section card shell (mirrors web Paper) ───────────────────
  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title, String subtitle, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppDimensions.spaceSm),
          trailing,
        ],
      ],
    );
  }

  // ── Daily stock flow chart ──────────────────────────────────
  Widget _buildDailyFlowPanel(DashboardSummary? summary) {
    // Merge both trend series on a shared date axis (up to 30 days)
    final siMap = <String, double>{};
    final cnMap = <String, double>{};
    if (summary != null) {
      for (final t in summary.stockInTrend) {
        siMap[t.date] = t.transactionCount.toDouble();
      }
      for (final t in summary.consignmentTrend) {
        cnMap[t.date] = t.transactionCount.toDouble();
      }
    }
    final allDates = ({
      ...siMap.keys,
      ...cnMap.keys,
    }.toList()..sort()).take(30).toList();
    final stockIn = allDates.isEmpty
        ? <double>[0, 0]
        : allDates.map((d) => siMap[d] ?? 0.0).toList();
    final consigned = allDates.isEmpty
        ? <double>[0, 0]
        : allDates.map((d) => cnMap[d] ?? 0.0).toList();
    final labels = allDates.isEmpty
        ? <String>['—', '—']
        : allDates.map((d) {
            final parts = d.split('-');
            return parts.length == 3 ? parts[2] : d;
          }).toList();

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Daily stock flow',
            'Compare stock-in and consignment movements over time.',
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: _AreaChartPainter(
                seriesA: stockIn,
                seriesB: consigned,
                colorA: AppColors.info,
                colorB: AppColors.warning,
                gridColor: AppColors.divider,
                labels: labels,
                axisLabelColor: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Wrap(
            spacing: AppDimensions.spaceMd,
            runSpacing: AppDimensions.spaceXs,
            children: [
              _legendDot('Stock in events', AppColors.info),
              _legendDot('Consigned events', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Operations action board ─────────────────────────────────
  Widget _buildActionBoard(DashboardSummary? summary) {
    final al = summary?.alerts;
    final holdPending = al?.holdingLotsPending ?? 0;
    final expiring = al?.expiringSoon30Days ?? 0;
    final overdueDrafts = al?.overdueStockInDrafts ?? 0;
    final reconPending = al?.reconciliationPending ?? 0;

    final items = <_ActionAlert>[
      _ActionAlert(
        'Lots in holding',
        holdPending,
        holdPending > 0 ? BadgeStatus.warning : BadgeStatus.success,
      ),
      _ActionAlert(
        'Lots expiring (<30 days)',
        expiring,
        expiring > 0 ? BadgeStatus.error : BadgeStatus.success,
      ),
      _ActionAlert(
        'Overdue stock-in drafts',
        overdueDrafts,
        overdueDrafts > 0 ? BadgeStatus.warning : BadgeStatus.success,
      ),
      _ActionAlert(
        'Pending reconciliations',
        reconPending,
        reconPending > 0 ? BadgeStatus.warning : BadgeStatus.success,
      ),
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operations action board',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          for (var i = 0; i < items.length; i++) ...[
            _actionAlertTile(items[i]),
            if (i < items.length - 1)
              const SizedBox(height: AppDimensions.spaceXs),
          ],
          const SizedBox(height: AppDimensions.spaceLg),
          OutlinedButton.icon(
            onPressed: () =>
                ref.invalidate(dashboardSummaryProvider(_quickRange)),
            icon: Icon(
              Icons.refresh_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
            label: Text(
              'Refresh dashboard',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceLg,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionAlertTile(_ActionAlert a) {
    final tone = switch (a.status) {
      BadgeStatus.error => AppColors.error,
      BadgeStatus.warning => AppColors.warning,
      BadgeStatus.success => AppColors.success,
      _ => AppColors.info,
    };
    final bg = switch (a.status) {
      BadgeStatus.error => AppColors.errorContainer,
      BadgeStatus.warning => AppColors.warningContainer,
      BadgeStatus.success => AppColors.successContainer,
      _ => AppColors.infoContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              a.label,
              style: AppTextStyles.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            a.value.toString(),
            style: AppTextStyles.titleSmall.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Monthly throughput (grouped bars) ───────────────────────
  Widget _buildMonthlyThroughput(DashboardSummary? summary) {
    // Aggregate daily trend data by month (last 6 months)
    Map<String, double> byMonth(List<DashboardTrendPoint> trend) {
      final result = <String, double>{};
      for (final t in trend) {
        if (t.date.length >= 7) {
          final key = t.date.substring(0, 7); // 'YYYY-MM'
          result[key] = (result[key] ?? 0) + t.transactionCount;
        }
      }
      return result;
    }

    const monthAbbr = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final siM = summary != null
        ? byMonth(summary.stockInTrend)
        : <String, double>{};
    final cnM = summary != null
        ? byMonth(summary.consignmentTrend)
        : <String, double>{};
    final allKeys = ({...siM.keys, ...cnM.keys}.toList()..sort()).toList();
    final last6 = allKeys.length > 6
        ? allKeys.sublist(allKeys.length - 6)
        : allKeys;

    final months = last6.isEmpty
        ? <String>['—']
        : last6.map((k) {
            final parts = k.split('-');
            if (parts.length == 2) {
              final m = int.tryParse(parts[1]);
              if (m != null && m >= 1 && m <= 12) return monthAbbr[m - 1];
            }
            return k;
          }).toList();
    final stockIn = last6.isEmpty
        ? <double>[0]
        : last6.map((k) => siM[k] ?? 0.0).toList();
    final consigned = last6.isEmpty
        ? <double>[0]
        : last6.map((k) => cnM[k] ?? 0.0).toList();

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Monthly throughput',
            'Stock-in versus consignment transactions.',
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarChartPainter(
                seriesA: stockIn,
                seriesB: consigned,
                colorA: AppColors.info,
                colorB: AppColors.warning,
                gridColor: AppColors.divider,
                labels: months,
                axisLabelColor: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Wrap(
            spacing: AppDimensions.spaceMd,
            runSpacing: AppDimensions.spaceXs,
            children: [
              _legendDot('Stock in events', AppColors.info),
              _legendDot('Consignment events', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  // ── Inventory status distribution (horizontal bars) ─────────
  Widget _buildStatusDistribution(DashboardSummary? summary) {
    final lc = summary?.lotCounts;
    final data = <_StatusBarItem>[
      _StatusBarItem('Available', lc?.available ?? 0),
      _StatusBarItem('Holding', lc?.holding ?? 0),
      _StatusBarItem('Supplied', lc?.supplied ?? 0),
      _StatusBarItem('Used', lc?.used ?? 0),
      _StatusBarItem('Disposed', lc?.disposed ?? 0),
      _StatusBarItem('Ret. to supplier', lc?.returnedToSupplier ?? 0),
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Inventory status distribution',
            'Current item count by lifecycle status.',
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _HorizontalBarChartPainter(
                items: data,
                barColor: AppColors.info,
                gridColor: AppColors.divider,
                axisLabelColor: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top moved products (list) ───────────────────────────────
  Widget _buildTopMovedProducts(DashboardSummary? summary) {
    final products = (summary?.topMovedProducts ?? <DashboardTopProduct>[])
        .map((p) => _TopMovedProduct(p.productName, p.productCode, p.movedQty))
        .toList();
    final total = products.fold<int>(0, (sum, p) => sum + p.movedQty);

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Top moved products',
            'Most active items in the selected range.',
            trailing: _outlineChip('Total: $total'),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          for (var i = 0; i < products.length; i++) ...[
            _topMovedTile(products[i], i + 1, total),
            if (i < products.length - 1)
              Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }

  Widget _topMovedTile(_TopMovedProduct p, int rank, int total) {
    final share = total > 0 ? (p.movedQty / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '#$rank',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: AppTextStyles.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(p.code, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                p.movedQty.toString(),
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 80,
                child: Stack(
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: share,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(share * 100).toStringAsFixed(1)}%',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Operations pipeline drafts ──────────────────────────────
  Widget _buildPipelineDrafts(DashboardSummary? summary) {
    final pipeline = summary?.operationsPipeline;
    final items = <_PipelineItem>[
      _PipelineItem('Stock-In drafts', pipeline?.stockInDraft ?? 0),
      _PipelineItem('Consignment drafts', pipeline?.consignmentDraft ?? 0),
      _PipelineItem(
        'Returns in progress',
        pipeline?.returnSessionsInProgress ?? 0,
      ),
      _PipelineItem(
        'Reconciliations pending',
        pipeline?.reconciliationPending ?? 0,
      ),
      _PipelineItem('Disposal drafts', pipeline?.disposalDraft ?? 0),
      _PipelineItem(
        'Supplier return drafts',
        pipeline?.supplierReturnDraft ?? 0,
      ),
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operations pipeline drafts',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          for (var i = 0; i < items.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMd,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      items[i].label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    items[i].value.toString(),
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              const SizedBox(height: AppDimensions.spaceXs),
          ],
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
            child: Icon(
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

  // ignore: unused_element
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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

// ignore: unused_element
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

// ── Stat Card Models ────────────────────────────────────────────

enum _StatTone { positive, negative, neutral }

class _StatCardData {
  const _StatCardData({
    required this.label,
    required this.value,
    required this.helper,
    required this.trend,
    required this.tone,
    required this.sparkline,
  });

  final String label;
  final String value;
  final String helper;
  final String trend;
  final _StatTone tone;
  final List<int> sparkline;
}

class _ActionAlert {
  const _ActionAlert(this.label, this.value, this.status);

  final String label;
  final int value;
  final BadgeStatus status;
}

class _StatusBarItem {
  const _StatusBarItem(this.label, this.value);

  final String label;
  final int value;
}

class _TopMovedProduct {
  const _TopMovedProduct(this.name, this.code, this.movedQty);

  final String name;
  final String code;
  final int movedQty;
}

class _PipelineItem {
  const _PipelineItem(this.label, this.value);

  final String label;
  final int value;
}

// ── Custom Painters ──────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.data, required this.color});

  final List<int> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal == 0) return;

    final step = size.width / (data.length - 1);
    const vPad = 2.0;
    final drawH = size.height - vPad * 2;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = vPad + drawH - (data[i] / maxVal) * drawH;
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo((data.length - 1) * step, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.color != color;
}

class _AreaChartPainter extends CustomPainter {
  const _AreaChartPainter({
    required this.seriesA,
    required this.seriesB,
    required this.colorA,
    required this.colorB,
    required this.gridColor,
    required this.labels,
    required this.axisLabelColor,
  });

  final List<double> seriesA;
  final List<double> seriesB;
  final Color colorA;
  final Color colorB;
  final Color gridColor;
  final List<String> labels;
  final Color axisLabelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 20.0;
    const gridLines = 4;
    final chartH = size.height - labelH;
    final n = seriesA.length;
    if (n < 2) return;

    final allVals = [...seriesA, ...seriesB];
    final maxVal = allVals.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final step = size.width / (n - 1);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int g = 0; g <= gridLines; g++) {
      final y = (g / gridLines) * chartH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    void drawSeries(List<double> series, Color color) {
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartH))
        ..style = PaintingStyle.fill;

      final linePath = Path();
      final fillPath = Path();

      for (int i = 0; i < series.length; i++) {
        final x = i * step;
        final y = chartH - (series[i] / maxVal) * chartH * 0.9;
        if (i == 0) {
          linePath.moveTo(x, y);
          fillPath.moveTo(x, chartH);
          fillPath.lineTo(x, y);
        } else {
          linePath.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }
      fillPath.lineTo((series.length - 1) * step, chartH);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(linePath, linePaint);
    }

    drawSeries(seriesA, colorA);
    drawSeries(seriesB, colorB);

    if (labels.isNotEmpty) {
      final tp = TextPainter(textDirection: TextDirection.ltr);
      for (int i = 0; i < labels.length && i < n; i++) {
        final x = i * step;
        tp.text = TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: 9, color: axisLabelColor),
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartH + 4));
      }
    }
  }

  @override
  bool shouldRepaint(_AreaChartPainter old) =>
      old.seriesA != seriesA || old.seriesB != seriesB;
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.seriesA,
    required this.seriesB,
    required this.colorA,
    required this.colorB,
    required this.gridColor,
    required this.labels,
    required this.axisLabelColor,
  });

  final List<double> seriesA;
  final List<double> seriesB;
  final Color colorA;
  final Color colorB;
  final Color gridColor;
  final List<String> labels;
  final Color axisLabelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 20.0;
    const gridLines = 4;
    const groupPad = 6.0;
    const barGap = 2.0;
    final chartH = size.height - labelH;
    final n = seriesA.length;
    if (n == 0) return;

    final allVals = [...seriesA, ...seriesB];
    final maxVal = allVals.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final groupW = size.width / n;
    final barW = (groupW - groupPad * 2 - barGap) / 2;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int g = 0; g <= gridLines; g++) {
      final y = (g / gridLines) * chartH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final paintA = Paint()..color = colorA;
    final paintB = Paint()..color = colorB;

    for (int i = 0; i < n; i++) {
      final groupX = i * groupW + groupPad;
      final hA = (seriesA[i] / maxVal) * chartH * 0.9;
      final hB = (seriesB[i] / maxVal) * chartH * 0.9;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(groupX, chartH - hA, barW, hA),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paintA,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(groupX + barW + barGap, chartH - hB, barW, hB),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paintB,
      );
    }

    if (labels.isNotEmpty) {
      final tp = TextPainter(textDirection: TextDirection.ltr);
      for (int i = 0; i < labels.length && i < n; i++) {
        final cx = i * groupW + groupW / 2;
        tp.text = TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: 9, color: axisLabelColor),
        );
        tp.layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, chartH + 4));
      }
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.seriesA != seriesA || old.seriesB != seriesB;
}

class _HorizontalBarChartPainter extends CustomPainter {
  const _HorizontalBarChartPainter({
    required this.items,
    required this.barColor,
    required this.gridColor,
    required this.axisLabelColor,
  });

  final List<_StatusBarItem> items;
  final Color barColor;
  final Color gridColor;
  final Color axisLabelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;
    const labelW = 110.0;
    const barH = 14.0;
    const valuePad = 6.0;

    final maxVal = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final rowH = size.height / items.length;
    final availW = size.width - labelW - 50.0;

    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final bgPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final cy = i * rowH + rowH / 2;
      final barY = cy - barH / 2;
      final fillW = (item.value / maxVal) * availW;

      tp.text = TextSpan(
        text: item.label,
        style: TextStyle(fontSize: 10, color: axisLabelColor),
      );
      tp.layout(maxWidth: labelW - 8);
      tp.paint(canvas, Offset(0, cy - tp.height / 2));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(labelW, barY, availW, barH),
          const Radius.circular(3),
        ),
        bgPaint,
      );

      if (fillW > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(labelW, barY, fillW, barH),
            const Radius.circular(3),
          ),
          barPaint,
        );
      }

      tp.text = TextSpan(
        text: item.value.toString(),
        style: TextStyle(
          fontSize: 10,
          color: axisLabelColor,
          fontWeight: FontWeight.w600,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(labelW + availW + valuePad, cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_HorizontalBarChartPainter old) => old.items != items;
}
