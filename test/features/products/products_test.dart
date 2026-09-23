import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/products/ui/product_action_sheets.dart';
import 'package:bizpos_app/features/products/ui/product_detail_screen.dart';
import 'package:bizpos_app/features/products/ui/product_form_sheet.dart';
import 'package:bizpos_app/features/products/ui/products_screen.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_session.dart';
import '../../support/pos_backend.dart';
import '../../support/role_fixtures.dart';

/// Products and stock — phase 2.
///
/// The payloads come from the running backend, including the two things a
/// hand-written fixture would have tidied away: a `salePrice` that is not a
/// round number, and a `purchasePrice` of `null` for a role that may not see
/// costs.
void main() {
  late PosBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    backend = PosBackend();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    List<String> permissions = Roles.stockKeeper,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeSession(activeSession(permissions, roleName: 'stock_keeper')),
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

  group('the list', () {
    testWidgets('loads the shelf with its stock and its cost', (tester) async {
      await pump(tester, const ProductsScreen());

      expect(tester.takeException(), isNull);
      expect(backend.hit, contains('GET /api/v1/products'));
      expect(find.text('3 F 500(20 Pcs) 500 mg'), findsOneWidget);
      expect(find.text('৳154.22'), findsOneWidget);
      // `inventory.product.view_cost`, so the cost line is there.
      expect(find.textContaining('Cost ৳140'), findsOneWidget);
    });

    testWidgets('shows no cost at all when the API withholds it',
        (tester) async {
      // The API answers a role without `inventory.product.view_cost` with a
      // cost of `null` — not zero. Nothing is shown, rather than a shop that
      // paid nothing for its stock.
      backend.hideCost = true;
      await pump(tester, const ProductsScreen(), permissions: Roles.cashier);

      expect(find.text('৳154.22'), findsOneWidget);
      expect(find.textContaining('Cost'), findsNothing);
    });

    testWidgets('a stock keeper may add but not delete', (tester) async {
      await pump(tester, const ProductsScreen());

      // Verified against the seeded account: create yes, delete no. So the
      // "Deleted" list is not offered here at all.
      expect(find.text('Add a product'), findsOneWidget);
      expect(find.text('Deleted'), findsNothing);
    });

    testWidgets('an owner gets the deleted list, and it is a different list',
        (tester) async {
      await pump(tester, const ProductsScreen(), permissions: Roles.owner);

      expect(find.text('Deleted'), findsOneWidget);
      await tester.tap(find.text('Deleted'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Gone From The Shelf 10mg'), findsOneWidget);
      // Nothing to add to a list of things that are gone.
      expect(find.text('Add a product'), findsNothing);
    });

    testWidgets('the low filter travels as lowOnly=1', (tester) async {
      await pump(tester, const ProductsScreen());
      backend.hit.clear();

      await tester.tap(find.textContaining('running low'));
      await tester.pumpAndSettle();

      expect(backend.lastQuery['lowOnly'], 1);
    });
  });

  group('one product', () {
    /// The detail is fed from the loaded list, so the list is pumped first and
    /// the detail is then pushed by id — which is exactly what the router does
    /// when a row is tapped.
    Future<void> openDetail(
      WidgetTester tester, {
      List<String> permissions = Roles.stockKeeper,
    }) async {
      await pump(tester, const ProductsScreen(), permissions: permissions);
      await pump(
        tester,
        const ProductDetailScreen(productId: 1),
        permissions: permissions,
      );
    }

    testWidgets('shows its prices, its stock and both histories',
        (tester) async {
      await openDetail(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('5 on the shelf'), findsOneWidget);
      expect(find.text('Margin'), findsOneWidget);
      expect(backend.hit, contains('GET /api/v1/products/1/history'));
      expect(find.text('Damage'), findsOneWidget);
      expect(find.text('Opening'), findsOneWidget);
      // The current price wears the badge; the superseded one does not.
      expect(find.text('Now'), findsOneWidget);
    });

    testWidgets('an adjustment is signed, and zero cannot be sent',
        (tester) async {
      await openDetail(tester);

      await tester.tap(find.text('Adjust stock'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The screen behind the sheet has its own "Adjust stock" button, so
      // everything here is scoped to the sheet itself.
      final sheet = find.byType(AdjustStockSheet);
      final action = find.descendant(
        of: sheet,
        matching: find.widgetWithText(FilledButton, 'Adjust stock'),
      );

      // Nothing typed yet: the API refuses a zero, so the button does too.
      expect(tester.widget<FilledButton>(action).onPressed, isNull);

      final fields = find.descendant(of: sheet, matching: find.byType(TextField));
      await tester.enterText(fields.first, '3');
      await tester.enterText(fields.last, 'Broken box');
      await tester.pumpAndSettle();

      await tester.tap(action);
      await tester.pumpAndSettle();

      // Taking stock off is the default, so three typed means minus three sent.
      expect(backend.adjustBody, isNotNull);
      expect(backend.adjustBody!['qty'], -3);
      expect(backend.adjustBody!['reason'], 'Broken box');
    });

    testWidgets('editing never offers a price box', (tester) async {
      await openDetail(tester);

      await tester.tap(find.byTooltip('Edit'));
      await tester.pumpAndSettle();

      // Prices belong to `PATCH /products/{id}/prices`, with its own history
      // row. A price typed here would be dropped without a word. Scoped to the
      // sheet, because the detail behind it does show the prices.
      final sheet = find.byType(ProductFormSheet);
      expect(find.descendant(of: sheet, matching: find.text('Name')),
          findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Sale')),
          findsNothing);
      expect(find.descendant(of: sheet, matching: find.text('Opening stock')),
          findsNothing);
    });

    testWidgets('a cashier gets neither of the stock actions', (tester) async {
      await openDetail(tester, permissions: Roles.cashier);

      expect(find.text('Adjust stock'), findsNothing);
      expect(find.text('Change prices'), findsNothing);
      expect(find.text('Delete this product'), findsNothing);
      // But the shelf figure is theirs: a cashier holds `inventory.stock.view`.
      expect(find.text('5 on the shelf'), findsOneWidget);
    });
  });

  group('adding one', () {
    testWidgets('sends an opening stock even when it is zero', (tester) async {
      await pump(tester, const ProductsScreen());

      await tester.tap(find.text('Add a product'));
      await tester.pumpAndSettle();

      final sheet = find.byType(ProductFormSheet);
      await tester.enterText(
        find.descendant(of: sheet, matching: find.byType(TextFormField)).first,
        'Claude Test Item',
      );
      await tester.enterText(
        find.descendant(of: sheet, matching: find.widgetWithText(TextField, 'Cost')),
        '10',
      );
      await tester.enterText(
        find.descendant(of: sheet, matching: find.widgetWithText(TextField, 'Sale')),
        '15',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: sheet,
        matching: find.widgetWithText(FilledButton, 'Save'),
      ));
      await tester.pumpAndSettle();

      final body = backend.createBody;
      expect(body, isNotNull);
      expect(body!['name'], 'Claude Test Item');
      expect(body['purchasePrice'], 10);
      expect(body['salePrice'], 15);
      // Zero is the API's own default for a typed-in product now, but the
      // form sends the figure it shows: a quantity nobody typed is a quantity
      // nobody counted.
      expect(body.containsKey('openingStock'), isTrue);
      expect(body['openingStock'], 0);
      // A price named directly states no markup.
      expect(body.containsKey('profitPercent'), isFalse);
    });

    testWidgets('a markup fills the price in, and both are sent', (tester) async {
      await pump(tester, const ProductsScreen());

      await tester.tap(find.text('Add a product'));
      await tester.pumpAndSettle();

      final sheet = find.byType(ProductFormSheet);
      await tester.enterText(
        find.descendant(of: sheet, matching: find.byType(TextFormField)).first,
        'Markup Item',
      );
      await tester.enterText(
        find.descendant(of: sheet, matching: find.widgetWithText(TextField, 'Cost')),
        '90',
      );
      await tester.enterText(
        find.descendant(
          of: sheet,
          matching: find.widgetWithText(TextField, 'Profit %'),
        ),
        '5',
      );
      await tester.pumpAndSettle();

      // Cost plus five percent, to the paisa.
      expect(
        find.descendant(of: sheet, matching: find.text('94.50')),
        findsOneWidget,
      );

      await tester.tap(find.descendant(
        of: sheet,
        matching: find.widgetWithText(FilledButton, 'Save'),
      ));
      await tester.pumpAndSettle();

      final body = backend.createBody!;
      expect(body['salePrice'], 94.5);
      expect(body['profitPercent'], 5);
    });

    testWidgets('a price under the cost cannot be saved', (tester) async {
      await pump(tester, const ProductsScreen());

      await tester.tap(find.text('Add a product'));
      await tester.pumpAndSettle();

      final sheet = find.byType(ProductFormSheet);
      await tester.enterText(
        find.descendant(of: sheet, matching: find.byType(TextFormField)).first,
        'Loss Leader',
      );
      await tester.enterText(
        find.descendant(of: sheet, matching: find.widgetWithText(TextField, 'Cost')),
        '10',
      );
      await tester.enterText(
        find.descendant(of: sheet, matching: find.widgetWithText(TextField, 'Sale')),
        '8',
      );
      await tester.pumpAndSettle();

      // Refused by the server everywhere a price is set, so the form says so
      // before anybody presses Save.
      expect(find.text("Selling price can't be below the cost."), findsOneWidget);
      final save = tester.widget<FilledButton>(find.descendant(
        of: sheet,
        matching: find.widgetWithText(FilledButton, 'Save'),
      ));
      expect(save.onPressed, isNull);
      expect(backend.createBody, isNull);
    });
  });

  group('paging', () {
    testWidgets('a short first page offers a way to the rest', (tester) async {
      await pump(tester, const ProductsScreen());

      // One of two, and the list is far too short to scroll — so the footer has
      // to be a button. A bare spinner here would turn for ever.
      expect(find.text('Showing 1 of 2'), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);

      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();

      expect(find.text('Second Page Syrup 100ml'), findsOneWidget);
      expect(find.text('Showing 2 of 2'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
    });
  });
}
