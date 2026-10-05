import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/permissions/permission_set.dart';
import '../../core/session/me.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_state.dart';
import '../../features/accounts/ui/accounts_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/no_store_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/catalogue/ui/catalogue_screen.dart';
import '../../features/catalogue/ui/suggestions_screen.dart';
import '../../features/customers/ui/customer_detail_screen.dart';
import '../../features/customers/ui/customers_screen.dart';
import '../../features/dashboard/ui/dashboard_screen.dart';
import '../../features/home/not_allowed_screen.dart';
import '../../features/packages/ui/packages_screen.dart';
import '../../features/products/ui/product_detail_screen.dart';
import '../../features/products/ui/products_screen.dart';
import '../../features/platform/ui/platform_screen.dart';
import '../../features/pos/ui/pos_screen.dart';
import '../../features/purchases/ui/goods_in_screen.dart';
import '../../features/purchases/ui/purchases_screen.dart';
import '../../features/reports/ui/reports_screen.dart';
import '../../features/sales/ui/invoice_detail_screen.dart';
import '../../features/sales/ui/invoices_screen.dart';
import '../../features/settings/devices_screen.dart';
import '../../features/settings/profile_screen.dart';
import '../../features/team/ui/team_screen.dart';
import 'app_shell.dart';
import 'screen_gates.dart';
import 'shell_nav.dart';

class Routes {
  const Routes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const noStore = '/no-store';
  static const notAllowed = '/not-allowed';
  static const profile = '/profile';
  static const devices = '/devices';
}

final routerProvider = Provider<GoRouter>((ref) {
  // go_router needs a Listenable to know when to re-run `redirect`; the session
  // is the only thing that changes the answer.
  final refresh = ValueNotifier<int>(0);
  late final GoRouter router;
  ref.listen(sessionControllerProvider, (previous, next) {
    refresh.value++;

    // A store or branch switch starts the day somewhere else, and both are
    // made from Profile — which the redirect otherwise leaves alone, so the
    // person stayed on Profile in the new shop. Go where signing in goes:
    // Sell, for anyone who may sell.
    final before = previous?.value;
    final after = next.value;
    if (before is SessionActive &&
        after is SessionActive &&
        (before.scope.storeId != after.scope.storeId ||
            before.scope.branchId != after.scope.branchId)) {
      // Ids from the old shop answer 404 in the new one: nothing behind
      // this point is somewhere Back should go.
      final home = homeFor(after.me.permissions);
      ref.read(navHistoryProvider).startFrom(home);
      router.go(home);
    }
  });
  ref.onDispose(refresh.dispose);

  router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final where = state.matchedLocation;

      // Still reading the stored token, or signing in.
      if (session.isLoading && !session.hasValue) {
        return where == Routes.splash ? null : Routes.splash;
      }

      // Signed out, the two doors in are signing in and signing a shop up.
      final outside = where == Routes.login || where == Routes.register;

      // A failed sign-in leaves the login screen in place to show the error.
      if (session.hasError) {
        return outside ? null : Routes.login;
      }

      return switch (session.value) {
        SessionLoggedOut() => outside ? null : Routes.login,

        // Signed in with no active store: every other call would answer
        // `400 bad_request`, so there is exactly one screen to be on.
        SessionNoStore() => where == Routes.noStore ? null : Routes.noStore,

        SessionActive(:final me) => _redirectActive(ref, me, where),

        _ => where == Routes.splash ? null : Routes.splash,
      };
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.login,
        // `?email=` arrives from a sign-up whose email already has an
        // account: the person is sent here to prove it, then opens the new
        // shop from inside.
        builder: (_, state) =>
            LoginScreen(initialEmail: state.uri.queryParameters['email']),
      ),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.noStore, builder: (_, _) => const NoStoreScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Every screen the gate table names gets a route, whether or not
          // its phase has been built: the table is what both the nav bar and
          // the redirect read, so a gap here would be a menu entry with
          // nowhere to go. [screenFor] decides which of them is real yet.
          for (final gate in screenGates)
            GoRoute(path: gate.path, builder: (_, _) => screenFor(gate)),
          // Detail routes sit outside the gate table because they are not
          // menu entries. They inherit their parent's gate: /invoices/12 is
          // only reachable by someone who may open /invoices at all, which
          // `_redirectActive` enforces by prefix.
          GoRoute(
            path: '/invoices/:id',
            builder: (_, state) => InvoiceDetailScreen(
              saleId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
          GoRoute(
            path: '/customers/:id',
            builder: (_, state) => CustomerDetailScreen(
              customerId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
          // Before the gate's own `/purchase` in spirit: inherits its gate by
          // prefix, and checks `purchase.bill.create` itself.
          GoRoute(
            path: '/purchase/new',
            builder: (_, _) => const GoodsInScreen(),
          ),
          GoRoute(
            path: '/products/:id',
            builder: (_, state) => ProductDetailScreen(
              productId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (_, _) => const ProfileScreen(),
          ),
          GoRoute(
            path: Routes.notAllowed,
            builder: (_, _) => const NotAllowedScreen(),
          ),
        ],
      ),
      GoRoute(path: Routes.devices, builder: (_, _) => const DevicesScreen()),
    ],
  );

  // Every location the router settles on, so the shell's Back has a stack to
  // walk even though in-shell navigation replaces pages with `go`.
  final history = ref.read(navHistoryProvider);
  void record() =>
      history.record(router.routerDelegate.currentConfiguration.uri.toString());
  router.routerDelegate.addListener(record);
  ref.onDispose(() => router.routerDelegate.removeListener(record));

  return router;
});

/// Where an active session may go.
///
/// The gate table is the single authority: a deep link into a screen this
/// person does not hold the permission for lands on "not allowed" instead of
/// rendering a screen that would only 403 on its first call.
///
/// Permissions are read off the [Me] the session just produced, **not** through
/// `permissionsProvider`. The redirect runs from inside the session's own change
/// notification, and at that instant the derived provider can still hold the
/// signed-out empty set — which made the landing screen "nowhere", i.e. Profile.
String? _redirectActive(Ref ref, Me me, String where) {
  final permissions = me.permissions;
  final home = homeFor(permissions);

  // Nothing to do on the pre-session screens once we are in.
  if (where == Routes.splash ||
      where == Routes.login ||
      where == Routes.register ||
      where == Routes.noStore) {
    return home;
  }

  final gate = gateForPath(where);
  if (gate != null && (gate.hidden || !gate.isOpenTo(permissions))) {
    return Routes.notAllowed;
  }

  return null;
}

/// The screen behind a gate, or a placeholder when its phase has not arrived.
///
/// Phase 1 is the counter: Sell, Invoices and Customers. Phase 2 adds Products
/// and stock, Packages, the Catalogue with its Suggestions queue, and
/// Purchases. Phase 3 adds the Dashboard, Accounts and Reports; phase 4 Team
/// and store settings and the Platform. Every gate now has a real screen;
/// `PlaceholderScreen` stays for whatever the gate table names next.
Widget screenFor(ScreenGate gate) => switch (gate.screen) {
  AppScreen.pos => const PosScreen(),
  AppScreen.invoices => const InvoicesScreen(),
  AppScreen.customers => const CustomersScreen(),
  AppScreen.products => const ProductsScreen(),
  AppScreen.packages => const PackagesScreen(),
  AppScreen.catalogue => const CatalogueScreen(),
  AppScreen.suggestions => const SuggestionsScreen(),
  AppScreen.purchase => const PurchasesScreen(),
  AppScreen.dashboard => const DashboardScreen(),
  AppScreen.accounts => const AccountsScreen(),
  AppScreen.reports => const ReportsScreen(),
  AppScreen.team => const TeamScreen(),
  AppScreen.platform => const PlatformScreen(),
};

/// The screens [screenFor] has something real behind. Kept beside it so the two
/// cannot drift: landing a phase is still one edit in this file.
const Set<AppScreen> builtScreens = {
  AppScreen.pos,
  AppScreen.invoices,
  AppScreen.customers,
  AppScreen.products,
  AppScreen.packages,
  AppScreen.catalogue,
  AppScreen.suggestions,
  AppScreen.purchase,
  AppScreen.dashboard,
  AppScreen.accounts,
  AppScreen.reports,
  AppScreen.team,
  AppScreen.platform,
};

/// Where somebody lands when they sign in.
///
/// **Sell comes first for anyone who may sell** — the till is the screen a
/// shop opens on, owner included; the dashboard is one tab away. Everyone
/// else starts on the first screen in gate order that has something built
/// behind it, so a phase that has not landed is never the landing screen.
String homeFor(PermissionSet permissions) {
  final available = screensFor(permissions);
  for (final gate in available) {
    if (gate.screen == AppScreen.pos) return gate.path;
  }
  for (final gate in available) {
    if (builtScreens.contains(gate.screen)) return gate.path;
  }
  return available.isEmpty ? Routes.profile : available.first.path;
}
