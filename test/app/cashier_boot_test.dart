import 'package:bizpos_app/app/router/app_router.dart';
import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_session.dart';
import '../support/pos_backend.dart';
import '../support/role_fixtures.dart';

/// The app as a cashier actually starts it: the real router, the real shell,
/// the real redirect — and a till that must have products in it by the time the
/// first frame settles.
void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    PosBackend backend, {
    required List<String> permissions,
    Locale locale = const Locale('en'),
    ThemeVariant variant = ThemeVariant.daylight,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeSession(activeSession(permissions)),
          apiClientProvider.overrideWith((ref) {
            final client = ApiClient.create(
              baseUrl: 'http://bizpos.test/api/v1',
              readToken: () => 'token',
              onUnauthenticated: () async {},
            );
            client.dio.httpClientAdapter = backend;
            return client;
          }),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
            theme: AppTheme.of(variant, locale: locale.languageCode),
            locale: locale,
            supportedLocales: AppL10n.supportedLocales,
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

  testWidgets('a cashier boots straight onto a till with stock in it',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final backend = PosBackend();
    await pumpApp(tester, backend, permissions: Roles.cashier);

    expect(tester.takeException(), isNull);
    // Not the Dashboard: its gate opens on `inventory.stock.view`, which a
    // cashier holds, but the screen behind it is a later phase. Landing there
    // put a counter app on an empty page.
    expect(find.text('Dashboard arrives in a later phase.'), findsNothing);
    expect(backend.hit, contains('GET /api/v1/pos/search'));
    expect(find.text(PosBackend.product['name']! as String), findsOneWidget);

    // And it can be sold: tapping it must raise a cart bar that lays out.
    await tester.tap(find.text(PosBackend.product['name']! as String));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Charge'), findsOneWidget);
  });

  testWidgets('a stock keeper boots onto the shelves', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final backend = PosBackend();
    await pumpApp(tester, backend, permissions: Roles.stockKeeper);

    // The Dashboard gate opens on `inventory.stock.view`, which a stock keeper
    // holds too — and its screen is still a later phase.
    expect(tester.takeException(), isNull);
    expect(backend.hit, contains('GET /api/v1/products'));
    expect(find.text('3 F 500(20 Pcs) 500 mg'), findsOneWidget);
  });

  testWidgets('the shelves render in Bangla and dark without overflowing',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final backend = PosBackend();
    await pumpApp(
      tester,
      backend,
      permissions: Roles.stockKeeper,
      locale: const Locale('bn'),
      variant: ThemeVariant.midnight,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('পণ্য'), findsWidgets);
  });
}
