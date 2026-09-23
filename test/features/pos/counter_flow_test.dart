import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/pos/ui/pos_screen.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_session.dart';
import '../../support/pos_backend.dart';
import '../../support/role_fixtures.dart';

/// The counter, driven the way a cashier drives it.
///
/// These are the tests that would have caught the two faults that made phase 1
/// unsellable: a product list that never arrived, and a charge button that
/// crashed its own layout.
void main() {
  late PosBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    backend = PosBackend();
  });

  Future<void> pumpCounter(
    WidgetTester tester, {
    List<String> permissions = Roles.cashier,
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
        child: MaterialApp(
          theme: AppTheme.of(ThemeVariant.daylight, locale: 'en'),
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: const [
            AppL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const PosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the till opens showing products, without being asked',
      (tester) async {
    await pumpCounter(tester);

    // The list is fetched through a provider rather than in initState. A
    // hand-rolled fetch there was cancelled by the scope epoch bump that a
    // start-up `/me` refresh causes, and the counter was left on a spinner it
    // could not retry — no products, no sale.
    expect(backend.hit, contains('GET /api/v1/pos/search'));
    expect(find.text(PosBackend.product['name']! as String), findsOneWidget);
  });

  testWidgets('tapping a product fills the cart bar', (tester) async {
    await pumpCounter(tester);
    await tester.tap(find.text(PosBackend.product['name']! as String));
    await tester.pumpAndSettle();

    // The bar carries the charge button, which is a FilledButton in a Row. With
    // the theme's minimum width set to infinity it asserted during layout and
    // the whole bar rendered as a grey box — a cart that could never be paid.
    expect(tester.takeException(), isNull);
    expect(find.text('Charge'), findsOneWidget);
    expect(find.text('৳154.22'), findsWidgets);

    // The confirmation sits inside the bar, where the count usually is — a
    // snack bar floated over the bar and hid the very thing tapped next.
    final name = PosBackend.product['name']! as String;
    expect(find.text('$name added'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('$name added'), findsNothing);
    expect(find.text('1 item'), findsOneWidget);
  });

  testWidgets('a whole sale: product, cart, payment, receipt', (tester) async {
    await pumpCounter(tester);
    await tester.tap(find.text(PosBackend.product['name']! as String));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Charge'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Complete the sale'), findsOneWidget);

    await tester.tap(find.textContaining('Complete the sale'));
    await tester.pumpAndSettle();

    final body = backend.checkoutBody;
    expect(body, isNotNull);
    expect(body!['lines'], [
      {'storeProductId': 1, 'qty': 1},
    ]);
    // A cashier has neither `change_price` nor `give_discount`, so neither
    // field may travel — the server would ignore them silently.
    expect(body.containsKey('orderDiscount'), isFalse);
    expect((body['payments'] as List).single, {
      'method': 'cash',
      'amount': 154.22,
      'accountId': 1,
    });
    // Walk-in means nobody in particular: no customerId goes out.
    expect(body.containsKey('customerId'), isFalse);

    // The receipt shows the server's invoice, not the app's arithmetic.
    expect(find.textContaining('INV-2026-005521'), findsOneWidget);
  });

  testWidgets('the packages tab loads its own list', (tester) async {
    await pumpCounter(tester);
    await tester.tap(find.text('Packages'));
    await tester.pumpAndSettle();

    expect(backend.hit, contains('GET /api/v1/packages/sellable'));
    expect(find.text('Cold & Fever Pack'), findsOneWidget);
  });

  testWidgets('held carts list without crashing their resume button',
      (tester) async {
    backend.held = [
      {'id': 2, 'label': 'Mr Salam, back at 6', 'createdAt': null},
    ];
    await pumpCounter(tester);

    await tester.tap(find.byTooltip('Held carts'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Mr Salam, back at 6'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('the drawer can be opened from the banner', (tester) async {
    await pumpCounter(tester);
    expect(find.text('Open the drawer'), findsOneWidget);

    await tester.tap(find.text('Open the drawer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).last, '2000');
    await tester.tap(find.textContaining('Open the drawer').last);
    await tester.pumpAndSettle();

    expect(backend.hit, contains('POST /api/v1/pos/shift/open'));
    // Opening a drawer refetches the lookups, so the banner goes on its own.
    expect(find.text('Open the drawer'), findsNothing);
  });

  testWidgets('a named customer unlocks redeeming points', (tester) async {
    await pumpCounter(tester);
    await tester.tap(find.text(PosBackend.product['name']! as String));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    // Through the cart, which is where a customer is attached to a sale.
    await tester.tap(find.text('1 item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Walk-in customer').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hasan Mahmud'));
    await tester.pumpAndSettle();

    // The recent list from `/pos/lookups` carries no `loyaltyPoints`, so the
    // picker fetches the balance rather than hiding a redemption that the same
    // customer, found by searching, would have been offered.
    expect(backend.hit, contains('GET /api/v1/customers/4/points'));

    await tester.tap(find.textContaining('Charge').last);
    await tester.pumpAndSettle();

    // "Use the most allowed" is a FilledButton in a Row — the third of the
    // three that the theme's infinite minimum width used to break.
    expect(tester.takeException(), isNull);
    expect(find.text('Use the most allowed'), findsOneWidget);
  });

  testWidgets('a bill discount can be applied without tearing the sheet down',
      (tester) async {
    // The prompt used to dispose its text controller the moment it returned,
    // while its sheet was still animating closed — an assertion
    // (`_dependents.isEmpty`) and a red screen instead of a discount.
    await pumpCounter(tester, permissions: Roles.owner);
    await tester.tap(find.text(PosBackend.product['name']! as String));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 item'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('10%'), findsOneWidget);
  });
}
