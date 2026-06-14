import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_session_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/session_expired_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/consignment/presentation/screens/consignment_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/disposal/presentation/screens/disposal_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/qr_printing/presentation/screens/qr_printing_screen.dart';
import '../features/returns/presentation/screens/returns_screen.dart';
import '../features/stock_in/presentation/screens/confirmation_screen.dart';
import '../features/stock_in/presentation/screens/create_session_screen.dart';
import '../features/stock_in/presentation/screens/review_session_screen.dart';
import '../features/stock_in/presentation/screens/scan_item_screen.dart';
import '../features/stock_in/presentation/screens/stock_in_list_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (_, __) {
    refreshNotifier.value++;
  });
  ref.listen<AuthSessionState>(authSessionProvider, (_, __) {
    refreshNotifier.value++;
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final sessionState = ref.read(authSessionProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isInitial = authState.status == AuthStatus.initial;

      final isOnSplash = state.matchedLocation == RouteNames.splash;
      final isOnLogin = state.matchedLocation == RouteNames.login;
      final isOnForgotPassword =
          state.matchedLocation == RouteNames.forgotPassword;
      final isOnSessionExpired =
          state.matchedLocation == RouteNames.sessionExpired;
      final isOnPublic =
          isOnSplash || isOnLogin || isOnForgotPassword || isOnSessionExpired;

      if (sessionState.isExpired) {
        return isOnSessionExpired ? null : RouteNames.sessionExpired;
      }

      if (isInitial) {
        return isOnSplash ? null : RouteNames.splash;
      }

      if (!isAuthenticated) {
        if (isOnSplash) {
          return RouteNames.login;
        }

        if (!isOnPublic) {
          return RouteNames.login;
        }

        return null;
      }

      if (isAuthenticated &&
          (isOnSplash ||
              isOnLogin ||
              isOnForgotPassword ||
              isOnSessionExpired)) {
        return RouteNames.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        pageBuilder: (_, state) =>
            _fadePage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        pageBuilder: (_, state) =>
            _fadePage(key: state.pageKey, child: const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: RouteNames.sessionExpired,
        name: 'sessionExpired',
        pageBuilder: (_, state) =>
            _fadePage(key: state.pageKey, child: const SessionExpiredScreen()),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        pageBuilder: (_, state) =>
            _fadePage(key: state.pageKey, child: const DashboardScreen()),
      ),
      GoRoute(
        path: RouteNames.stockIn,
        name: 'stockIn',
        builder: (_, __) => const StockInListScreen(),
      ),
      GoRoute(
        path: RouteNames.stockInCreate,
        name: 'stockInCreate',
        builder: (_, __) => const CreateSessionScreen(),
      ),
      GoRoute(
        path: RouteNames.stockInScan,
        name: 'stockInScan',
        builder: (_, state) => ScanItemScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.stockInReview,
        name: 'stockInReview',
        builder: (_, state) => ReviewSessionScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.stockInConfirmation,
        name: 'stockInConfirmation',
        builder: (_, state) => ConfirmationScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
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
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.error}'))),
  );
});

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (_, animation, __, pageChild) {
      return FadeTransition(opacity: animation, child: pageChild);
    },
  );
}
