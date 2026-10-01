import 'package:bizpos_app/app/router/app_router.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/session/session_scope.dart';
import 'package:bizpos_app/core/session/session_state.dart';
import 'package:bizpos_app/features/home/placeholder_screen.dart';
import 'package:bizpos_app/features/pos/ui/pos_screen.dart';
import 'package:bizpos_app/features/settings/profile_screen.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_controller.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_session.dart';
import '../support/role_fixtures.dart';

/// One build, seven apps. These drive the real router, so the redirect, the
/// gate table and the navigation bar are all exercised together.
void main() {
  setUp(() {
    // Theme and language are mirrored in SharedPreferences, which has no
    // platform side in a widget test.
    SharedPreferences.setMockInitialValues(const {});
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    required SessionState session,
    ThemeVariant variant = ThemeVariant.daylight,
    Locale locale = localeEn,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fakeSession(session)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
            theme: AppTheme.of(variant, locale: locale.languageCode),
            locale: locale,
            supportedLocales: supportedLocales,
            localizationsDelegates: const [
              AppL10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A label in the navigation bar, not the same word wherever else it appears
  /// — the landing screen's own app bar carries its name too.
  Finder tab(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );

  group('the navigation bar is built from permissions', () {
    testWidgets('a cashier opens on the counter and never sees Accounts',
        (tester) async {
      await pumpApp(tester, session: activeSession(Roles.cashier));

      expect(tab('Sell'), findsOneWidget);
      expect(tab('Invoices'), findsOneWidget);
      expect(tab('Accounts'), findsNothing);
      expect(tab('Team'), findsNothing);
    });

    testWidgets('a stock keeper gets no Sell tab', (tester) async {
      await pumpApp(tester, session: activeSession(Roles.stockKeeper));

      expect(tab('Products'), findsOneWidget);
      expect(tab('Sell'), findsNothing);
      expect(tab('Customers'), findsNothing);
    });

    testWidgets('an accountant gets no Sell tab but does get Invoices',
        (tester) async {
      await pumpApp(tester, session: activeSession(Roles.accountant));

      expect(tab('Invoices'), findsOneWidget);
      expect(tab('Sell'), findsNothing);
    });

    testWidgets('an owner lands on Sell, with the dashboard one tab away',
        (tester) async {
      await pumpApp(tester, session: activeSession(Roles.owner));

      expect(tab('Dashboard'), findsOneWidget);
      expect(tab('Sell'), findsOneWidget);
      // Sell is the first tab and the one selected: the till is where a shop
      // opens, not the dashboard and never the profile.
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 0);
      expect(find.byType(PosScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(PlaceholderScreen), findsNothing);
    });

    testWidgets('a person with no permissions is sent to their profile',
        (tester) async {
      await pumpApp(tester, session: activeSession(const []));

      // No tabs to show, so the only place to be is the profile.
      expect(find.text('Profile'), findsWidgets);
    });
  });

  group('signing in', () {
    testWidgets('lands on Sell, not Profile, the moment the session arrives',
        (tester) async {
      // The real sign-in path: the app sits on the login form, then the
      // session flips to active. The redirect runs inside that change, which
      // is when a derived permission provider can still be the signed-out
      // empty set — and an empty set lands on Profile.
      final controller = _SwitchableSession(const SessionLoggedOut());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionControllerProvider.overrideWith(() => controller)],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(
              routerConfig: ref.watch(routerProvider),
              theme: AppTheme.of(ThemeVariant.daylight, locale: 'en'),
              locale: localeEn,
              supportedLocales: supportedLocales,
              localizationsDelegates: const [
                AppL10n.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Email'), findsOneWidget);

      controller.become(activeSession(Roles.owner));
      await tester.pumpAndSettle();

      expect(find.byType(PosScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('switching store from Profile lands on Sell in the new shop',
        (tester) async {
      final start = activeSession(Roles.owner) as SessionActive;
      final controller = _SwitchableSession(start);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionControllerProvider.overrideWith(() => controller)],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(
              routerConfig: ref.watch(routerProvider),
              theme: AppTheme.of(ThemeVariant.daylight, locale: 'en'),
              locale: localeEn,
              supportedLocales: supportedLocales,
              localizationsDelegates: const [
                AppL10n.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Store and branch pickers live on Profile.
      tester.element(tab('Sell')).go('/profile');
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      controller.become(
        start.copyWith(scope: const SessionScope(storeId: 2, branchId: 5)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PosScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
    });
  });

  group('the screens a role cannot reach', () {
    testWidgets('a cashier deep-linked into Accounts is refused', (tester) async {
      await pumpApp(tester, session: activeSession(Roles.cashier));

      // Navigating straight to a path is what a saved link or a notification
      // would do, and it must not get past the gate.
      tester.element(tab('Sell')).go('/accounts');
      await tester.pumpAndSettle();

      expect(find.text('Not allowed'), findsWidgets);
    });
  });

  group('sessions that are not a normal signed-in store user', () {
    testWidgets('no store at all gets its own screen', (tester) async {
      await pumpApp(tester, session: noStoreSession());

      expect(find.text('No store assigned'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('signed out lands on the login form', (tester) async {
      await pumpApp(tester, session: const SessionLoggedOut());

      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('an impersonating super admin sees the support banner',
        (tester) async {
      await pumpApp(
        tester,
        session: activeSession(
          Roles.owner,
          impersonating: true,
          isSuperAdmin: true,
        ),
      );

      expect(
        find.textContaining('Support mode'),
        findsOneWidget,
        reason: 'platform staff must never forget whose store they are in',
      );
    });
  });

  group('both locales and both themes render', () {
    testWidgets('the login form in Bangla', (tester) async {
      await pumpApp(
        tester,
        session: const SessionLoggedOut(),
        locale: localeBn,
      );

      expect(find.text('ইমেইল'), findsOneWidget);
      expect(find.text('পাসওয়ার্ড'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a cashier shell in Bangla and dark, without overflowing',
        (tester) async {
      await pumpApp(
        tester,
        session: activeSession(Roles.cashier),
        locale: localeBn,
        variant: ThemeVariant.midnight,
      );

      // Bangla labels are much wider than the English ones, and a bottom bar is
      // where that first shows up as an overflow.
      expect(find.text('বিক্রি'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _SwitchableSession extends SessionController {
  _SwitchableSession(this._initial);

  final SessionState _initial;

  @override
  Future<SessionState> build() async => _initial;

  void become(SessionState next) => state = AsyncData(next);
}
