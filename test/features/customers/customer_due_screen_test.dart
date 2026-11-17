import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/customers/ui/customer_detail_screen.dart';
import 'package:bizpos_app/features/customers/ui/customers_screen.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_session.dart';
import '../../support/pos_backend.dart';
import '../../support/role_fixtures.dart';

/// Collect due and Add due on the customer list — two actions that are not
/// tied to any one invoice.
void main() {
  late PosBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    backend = PosBackend();
  });

  Future<void> pump(
    WidgetTester tester, {
    List<String> permissions = Roles.owner,
    Widget home = const CustomersScreen(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeSession(activeSession(permissions, roleName: 'owner')),
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
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, String action) async {
    await tester.tap(find.byTooltip('Collect or add due'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action).last);
    await tester.pumpAndSettle();
  }

  testWidgets('collecting the whole due sends the amount received',
      (tester) async {
    await pump(tester);
    await openMenu(tester, 'Collect due');

    expect(find.text('TOTAL OWED'), findsOneWidget);
    expect(find.text('Amount received'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Collect due'));
    await tester.pumpAndSettle();

    expect(backend.collectBody, isNotNull);
    expect(backend.collectBody!['amount'], 357.36);
    // No discount was typed, so nothing about one is sent.
    expect(backend.collectBody!.containsKey('discount'), isFalse);
    // The row's due is now stale, so the list is asked for again rather than
    // left showing money that has already been collected.
    expect(
      backend.hit.where((h) => h == 'GET /api/v1/customers').length,
      greaterThan(1),
    );
  });

  testWidgets('the row, its menu and the sheet fit a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pump(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Collect or add due'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Add due'), findsOneWidget);

    // The sheet is the tightest thing here: the two tabs, the discount and its
    // reason side by side, and three preview figures in a row.
    await tester.tap(find.text('Collect due').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Reason for discount'), findsOneWidget);
    expect(find.text('Still owed'), findsOneWidget);
  });

  testWidgets('a discount needs a reason, and both travel together',
      (tester) async {
    await pump(tester);
    await openMenu(tester, 'Collect due');

    await tester.enterText(
      find.widgetWithText(TextField, 'Amount received'),
      '300',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Discount'), '57.36');
    await tester.pumpAndSettle();

    // The amount is filled in; the reason for the discount is not.
    final collect = find.widgetWithText(FilledButton, 'Collect due');
    expect(tester.widget<FilledButton>(collect).onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Reason for discount'),
      'Regular customer',
    );
    await tester.pumpAndSettle();

    await tester.tap(collect);
    await tester.pumpAndSettle();

    expect(backend.collectBody!['amount'], 300);
    expect(backend.collectBody!['discount'], 57.36);
    expect(backend.collectBody!['discountReason'], 'Regular customer');
  });

  testWidgets('adding a due writes the remark alongside the amount',
      (tester) async {
    await pump(tester);
    await openMenu(tester, 'Add due');

    await tester.enterText(find.widgetWithText(TextField, 'Amount to add'), '100');
    await tester.enterText(
      find.widgetWithText(TextField, 'Remark'),
      'Old notebook balance',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add due'));
    await tester.pumpAndSettle();

    expect(backend.addDueBody, isNotNull);
    expect(backend.addDueBody!['amount'], 100);
    expect(backend.addDueBody!['remark'], 'Old notebook balance');
  });

  testWidgets('a cashier may collect but not add a due', (tester) async {
    await pump(tester, permissions: Roles.cashier);

    await tester.tap(find.byTooltip('Collect or add due'));
    await tester.pumpAndSettle();

    expect(find.text('Collect due'), findsOneWidget);
    // `customers.credit.manage` belongs to the owner.
    expect(find.text('Add due'), findsNothing);
  });

  testWidgets('the detail page offers both actions in the open', (tester) async {
    await pump(tester, home: const CustomerDetailScreen(customerId: 4));

    expect(find.text('Collect due'), findsOneWidget);
    expect(find.text('Add due'), findsOneWidget);

    await tester.tap(find.text('Collect due'));
    await tester.pumpAndSettle();

    // The sheet starts on Collect for the button that opened it.
    expect(find.text('TOTAL OWED'), findsOneWidget);
    expect(find.text('Amount received'), findsOneWidget);

    // Closing it and opening the other lands on Add.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add due'));
    await tester.pumpAndSettle();

    expect(find.text('Amount to add'), findsOneWidget);
    expect(find.text('Amount received'), findsNothing);
  });
}
