import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/stock_in/presentation/screens/stock_in_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/qr_printing/presentation/screens/qr_printing_screen.dart';
import '../features/consignment/presentation/screens/consignment_screen.dart';
import '../features/returns/presentation/screens/returns_screen.dart';
import '../features/disposal/presentation/screens/disposal_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isInitial = authState.status == AuthStatus.initial;

      final isOnSplash = state.matchedLocation == RouteNames.splash;
      final isOnLogin = state.matchedLocation == RouteNames.login;
      final isOnPublic = isOnSplash || isOnLogin;

      // Still initializing — stay on splash
      if (isInitial || authState.isLoading) {
        return isOnSplash ? null : RouteNames.splash;
      }

      // Not authenticated and trying to access protected route
      if (!isAuthenticated && !isOnPublic) {
        return RouteNames.login;
      }

      // Already authenticated and trying to access login
      if (isAuthenticated && isOnLogin) {
        return RouteNames.dashboard;
      }

      return null;
    },
    routes: [
      // ── Public ────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      ),

      // ── Protected ─────────────────────────────────────────────
      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        builder: (_, __) => const DashboardScreen(),
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.stockIn,
        name: 'stockIn',
        builder: (_, __) => const StockInScreen(),
      ),
      GoRoute(
        path: RouteNames.inventory,
        name: 'inventory',
        builder: (_, __) => const InventoryScreen(),
      ),
      GoRoute(
        path: RouteNames.qrPrinting,
        name: 'qrPrinting',
        builder: (_, __) => const QrPrintingScreen(),
      ),
      GoRoute(
        path: RouteNames.consignment,
        name: 'consignment',
        builder: (_, __) => const ConsignmentScreen(),
      ),
      GoRoute(
        path: RouteNames.returns,
        name: 'returns',
        builder: (_, __) => const ReturnsScreen(),
      ),
      GoRoute(
        path: RouteNames.disposal,
        name: 'disposal',
        builder: (_, __) => const DisposalScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.error}'),
      ),
    ),
  );
});
