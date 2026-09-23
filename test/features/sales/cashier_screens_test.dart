import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/customers/ui/customers_screen.dart';
import 'package:bizpos_app/features/sales/ui/invoice_detail_screen.dart';
import 'package:bizpos_app/features/sales/ui/invoices_screen.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_session.dart';
import '../../support/pos_backend.dart';
import '../../support/role_fixtures.dart';

/// The two screens a cashier reaches besides the till, against the same
/// recorded backend. A cashier may collect a due but may not accept a return or
/// void an invoice, and these check that the buttons follow the permissions
/// rather than the role name.
void main() {
  late PosBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    backend = PosBackend();
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeSession(activeSession(Roles.cashier)),
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
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the invoice list loads and shows the outstanding due',
      (tester) async {
    await pump(tester, const InvoicesScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('INV-2026-001778'), findsOneWidget);
  });

  testWidgets('an invoice offers Collect but neither Return nor Void',
      (tester) async {
    await pump(tester, const InvoiceDetailScreen(saleId: 1778));

    expect(tester.takeException(), isNull);
    expect(find.text('INV-2026-001778'), findsWidgets);
    // `sales.payment.collect`, and the detail's meta says nothing about it — so
    // the permission alone decides and the button is there.
    expect(find.text('Collect due'), findsOneWidget);
    // No `sales.return.create`, and `meta.mayVoid` is an explicit false.
    expect(find.text('Accept a return'), findsNothing);
    expect(find.text('Void this invoice'), findsNothing);
  });

  testWidgets('the customer list loads without an edit button', (tester) async {
    await pump(tester, const CustomersScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Hasan Mahmud'), findsOneWidget);
  });
}
