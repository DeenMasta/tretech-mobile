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
import '../features/consignment/presentation/screens/consignment_form_screen.dart';
import '../features/consignment/presentation/screens/consignment_detail_screen.dart';
import '../features/consignment/presentation/screens/consignment_item_form_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/disposal/presentation/screens/disposal_screen.dart';
import '../features/disposal/presentation/screens/disposal_complete_screen.dart';
import '../features/disposal/presentation/screens/disposal_detail_screen.dart';
import '../features/disposal/presentation/screens/disposal_form_screen.dart';
import '../features/disposal/presentation/screens/disposal_item_form_screen.dart';
import '../features/inventory/presentation/screens/inventory_all_lots_screen.dart';
import '../features/inventory/presentation/screens/inventory_detail_screen.dart';
import '../features/inventory/presentation/screens/inventory_expiring_soon_screen.dart';
import '../features/inventory/presentation/screens/inventory_ledger_screen.dart';
import '../features/inventory/presentation/screens/inventory_lookup_screen.dart';
import '../features/inventory/presentation/screens/inventory_movements_screen.dart';
import '../features/inventory/presentation/screens/inventory_product_lots_screen.dart';
import '../features/inventory/presentation/screens/inventory_set_lots_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/returns/presentation/screens/returns_list_screen.dart';
import '../features/returns/presentation/screens/create_return_session_screen.dart';
import '../features/returns/presentation/screens/return_detail_screen.dart';
import '../features/returns/presentation/screens/return_scan_item_screen.dart';
import '../features/stock_in/presentation/screens/confirmation_screen.dart';
import '../features/stock_in/presentation/screens/create_session_screen.dart';
import '../features/stock_in/presentation/screens/stock_in_detail_screen.dart';
import '../features/stock_in/presentation/screens/stock_in_edit_session_screen.dart';
import '../features/stock_in/presentation/screens/stock_in_item_form_screen.dart';
import '../features/stock_in/presentation/screens/stock_in_item_correction_screen.dart';
import '../features/stock_in/presentation/screens/stock_in_list_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (_, _) {
    refreshNotifier.value++;
  });
  ref.listen<AuthSessionState>(authSessionProvider, (_, _) {
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
      final isLoading = authState.isLoading;

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

      if (isLoading && isOnSplash) {
        return null;
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
        builder: (_, _) => const SplashScreen(),
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
        builder: (_, _) => const StockInListScreen(),
      ),
      GoRoute(
        path: RouteNames.stockInCreate,
        name: 'stockInCreate',
        builder: (_, _) => const CreateSessionScreen(),
      ),
      GoRoute(
        path: RouteNames.stockInDetail,
        name: 'stockInDetail',
        builder: (_, state) => StockInDetailScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.stockInEdit,
        name: 'stockInEdit',
        builder: (_, state) => StockInEditSessionScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.stockInItemAdd,
        name: 'stockInItemAdd',
        builder: (_, state) => StockInItemFormScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.stockInItemEdit,
        name: 'stockInItemEdit',
        builder: (_, state) => StockInItemFormScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
          itemId: int.parse(state.pathParameters['itemId'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.stockInItemCorrect,
        name: 'stockInItemCorrect',
        builder: (_, state) => StockInItemCorrectionScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
          itemId: int.parse(state.pathParameters['itemId'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.stockInFinalized,
        name: 'stockInFinalized',
        builder: (_, state) => ConfirmationScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.inventory,
        name: 'inventory',
        builder: (_, _) => const InventoryScreen(),
      ),
      GoRoute(
        path: RouteNames.inventoryAllLots,
        name: 'inventoryAllLots',
        builder: (_, _) => const InventoryAllLotsScreen(),
      ),
      GoRoute(
        path: RouteNames.inventoryExpiringSoon,
        name: 'inventoryExpiringSoon',
        builder: (_, _) => const InventoryExpiringSoonScreen(),
      ),
      GoRoute(
        path: RouteNames.inventoryLookup,
        name: 'inventoryLookup',
        builder: (_, _) => const InventoryLookupScreen(),
      ),
      GoRoute(
        path: RouteNames.inventoryLedger,
        name: 'inventoryLedger',
        builder: (_, _) => const InventoryLedgerScreen(),
      ),
      GoRoute(
        path: RouteNames.inventoryProductLots,
        name: 'inventoryProductLots',
        builder: (_, state) => InventoryProductLotsScreen(
          productId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.inventorySetLots,
        name: 'inventorySetLots',
        builder: (_, state) => InventorySetLotsScreen(
          setId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.inventoryDetail,
        name: 'inventoryDetail',
        builder: (_, state) => InventoryDetailScreen(
          lotId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.inventoryMovements,
        name: 'inventoryMovements',
        builder: (_, state) => InventoryMovementsScreen(
          lotId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.consignment,
        name: 'consignment',
        builder: (_, _) => const ConsignmentScreen(),
      ),
      GoRoute(
        path: RouteNames.consignmentCreate,
        name: 'consignmentCreate',
        builder: (_, _) => const ConsignmentFormScreen(),
      ),
      GoRoute(
        path: RouteNames.consignmentDetail,
        name: 'consignmentDetail',
        builder: (_, state) => ConsignmentDetailScreen(
          consignmentId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.consignmentEdit,
        name: 'consignmentEdit',
        builder: (_, state) => ConsignmentFormScreen(
          consignmentId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.consignmentItemAdd,
        name: 'consignmentItemAdd',
        builder: (_, state) => ConsignmentItemFormScreen(
          consignmentId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.returns,
        name: 'returns',
        builder: (_, _) => const ReturnsListScreen(),
      ),
      GoRoute(
        path: RouteNames.returnsCreate,
        name: 'returnsCreate',
        builder: (_, _) => const CreateReturnSessionScreen(),
      ),
      GoRoute(
        path: RouteNames.returnsDetail,
        name: 'returnsDetail',
        builder: (_, state) => ReturnDetailScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.returnsScan,
        name: 'returnsScan',
        builder: (_, state) => ReturnScanItemScreen(
          sessionId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.disposal,
        name: 'disposal',
        builder: (_, _) => const DisposalScreen(),
      ),
      GoRoute(
        path: RouteNames.disposalCreate,
        name: 'disposalCreate',
        builder: (_, _) => const DisposalFormScreen(),
      ),
      GoRoute(
        path: RouteNames.disposalDetail,
        name: 'disposalDetail',
        builder: (_, state) => DisposalDetailScreen(
          disposalId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.disposalEdit,
        name: 'disposalEdit',
        builder: (_, state) => DisposalFormScreen(
          disposalId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.disposalItemAdd,
        name: 'disposalItemAdd',
        builder: (_, state) => DisposalItemFormScreen(
          disposalId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.disposalComplete,
        name: 'disposalComplete',
        builder: (_, state) => DisposalCompleteScreen(
          disposalId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (_, _) => const SettingsScreen(),
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
    transitionsBuilder: (_, animation, _, pageChild) {
      return FadeTransition(opacity: animation, child: pageChild);
    },
  );
}
