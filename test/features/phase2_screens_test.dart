import 'dart:convert';
import 'dart:typed_data';

import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/catalogue/ui/catalogue_screen.dart';
import 'package:bizpos_app/features/catalogue/ui/suggestions_screen.dart';
import 'package:bizpos_app/features/packages/ui/packages_screen.dart';
import 'package:bizpos_app/features/purchases/ui/goods_in_screen.dart';
import 'package:bizpos_app/features/purchases/ui/purchases_screen.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_session.dart';
import '../support/role_fixtures.dart';

/// The rest of phase 2 on screen: packages, catalogue, suggestions, goods in.
void main() {
  late _Backend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    backend = _Backend();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    required List<String> permissions,
  }) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('packages', () {
    testWidgets('a stock keeper may make one',
        (tester) async {
      await pump(tester, const PackagesScreen(), permissions: Roles.stockKeeper);
      expect(tester.takeException(), isNull);
      expect(find.text('Cold & Fever Pack'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('New package'), findsOneWidget);
    });

    testWidgets('a cashier sees the bundles and changes none', (tester) async {
      await pump(tester, const PackagesScreen(), permissions: Roles.cashier);
      expect(find.text('Cold & Fever Pack'), findsOneWidget);
      expect(find.text('New package'), findsNothing);
      expect(find.text('On sale'), findsNothing);
    });
  });

  group('the catalogue', () {
    testWidgets('adding a line fills the form from the catalogue',
        (tester) async {
      await pump(tester, const CatalogueScreen(), permissions: Roles.stockKeeper);
      expect(tester.takeException(), isNull);
      expect(find.text('In my store'), findsOneWidget);
      expect(find.text('Not in my store (1)'), findsOneWidget);

      await tester.tap(find.text('Monas 10'));
      await tester.pumpAndSettle();

      // The catalogue's own prices and MRP, so the shopkeeper only corrects.
      expect(find.text('9.50'), findsOneWidget);
      expect(find.text('12'), findsWidgets);
      expect(find.text('13'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Add to my store'));
      await tester.pumpAndSettle();

      final body = backend.bodies['POST /api/v1/catalog/77/adopt']!;
      expect(body['purchasePrice'], 9.5);
      expect(body['salePrice'], 12);
      expect(body['mrp'], 13);
      // Shown as 1 and sent as 1: adopting means the shop already has it.
      expect(body['openingStock'], 1);
    });

    testWidgets('approving a suggestion puts it on the shelf', (tester) async {
      await pump(tester, const SuggestionsScreen(), permissions: Roles.owner);
      expect(find.text('Maxpro 20mg'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
      await tester.pumpAndSettle();

      final body = backend.bodies['POST /api/v1/catalog/suggestions/3/review']!;
      expect(body['approve'], isTrue);
      expect(body['openingStock'], 1);
    });
  });

  group('purchases', () {
    testWidgets('an accountant reads bills but cannot write one',
        (tester) async {
      await pump(tester, const PurchasesScreen(), permissions: Roles.accountant);
      expect(tester.takeException(), isNull);
      expect(find.text('Incepta Sales'), findsOneWidget);
      expect(find.text('Goods in'), findsNothing);
    });

    testWidgets('goods in from a new party, paid in full', (tester) async {
      await pump(tester, const GoodsInScreen(), permissions: Roles.stockKeeper);
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Who is it from?'),
        'Karim Traders',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('is new'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Add').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Napa 500 (510 Pcs) 500mg'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Quantity'),
        '10',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('10 × ৳520'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Save bill  ৳5,200'));
      await tester.pumpAndSettle();

      final body = backend.bodies['POST /api/v1/purchases']!;
      expect(body['supplierName'], 'Karim Traders');
      expect(body.containsKey('supplierId'), isFalse);
      expect((body['items'] as List).single['qty'], 10);
      expect((body['items'] as List).single['unitCost'], 520);
      // Untouched, the paid figure follows the total.
      expect(body['paidAmount'], 5200);
    });
  });
}

/// Answers the phase 2 endpoints with shapes taken from the live server.
class _Backend implements HttpClientAdapter {
  final Map<String, Map<String, dynamic>> bodies = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final key = '${options.method} $path';
    if (options.data is Map<String, dynamic>) {
      bodies[key] = options.data as Map<String, dynamic>;
    }

    Object body = {'data': <String, dynamic>{}};
    var status = 200;

    if (path.endsWith('/packages')) {
      body = {
        'data': [
          {
            'id': 1,
            'name': 'Cold & Fever Pack',
            'price': 1050,
            'isActive': true,
            'availability': 'live',
            'sellable': true,
            'buildable': 5,
            'componentTotal': 1115.7,
            'saving': 65.7,
            'items': [
              {
                'storeProductId': 108,
                'name': 'Alatrol 10',
                'qty': 1,
                'salePrice': 390,
              },
            ],
          },
        ],
        'meta': {'mayManage': true},
      };
    } else if (path.endsWith('/catalog')) {
      body = {
        'data': [
          {
            'id': 1,
            'name': '3 F 500',
            'brand': 'edruc Ltd.',
            'defaultSalePrice': 154.22,
            'alreadyInStore': 1,
            'pending': false,
          },
          {
            'id': 77,
            'name': 'Monas 10',
            'brand': 'ACI',
            'defaultPurchasePrice': 9.5,
            'defaultSalePrice': 12,
            'defaultMrp': 13,
            'alreadyInStore': null,
            'pending': false,
          },
        ],
        'meta': {
          'total': 2,
          'page': 1,
          'perPage': 30,
          'pages': 1,
          'mineCount': 1,
          'missingCount': 1,
        },
      };
    } else if (path.endsWith('/catalog/77/adopt')) {
      status = 201;
      body = {
        'data': {'id': 1800, 'created': true},
      };
    } else if (path.endsWith('/catalog/suggestions')) {
      body = {
        'data': [
          {
            'id': 3,
            'status': 'pending',
            'payload': {'name': 'Maxpro 20mg', 'brand': 'Renata'},
            'economics': {'cost': 5.4, 'sale': 7, 'margin': 22.9},
            'askedBy': 'Jamal Uddin',
          },
        ],
        'meta': {'pending': 1, 'mayEndorse': true},
      };
    } else if (path.endsWith('/catalog/suggestions/3/review')) {
      status = 201;
      body = {
        'data': {'endorsed': true, 'storeProductId': 1801},
      };
    } else if (path.endsWith('/purchases/products')) {
      body = {
        'data': [
          {
            'id': 1105,
            'name': 'Napa 500 (510 Pcs) 500mg',
            'purchasePrice': 520,
            'trackBatch': false,
            'unit': 'pc',
          },
        ],
      };
    } else if (path.endsWith('/purchases') && options.method == 'POST') {
      status = 201;
      body = {
        'data': {
          'id': 21,
          'refNo': 'PUR-00021',
          'total': 5200,
          'due': 0,
          'supplierId': 9,
        },
      };
    } else if (path.endsWith('/purchases')) {
      body = {
        'data': [
          {
            'id': 19,
            'refNo': 'PUR-00019',
            'total': 62282.79,
            'paid': 24290.29,
            'due': 37992.5,
            'paymentStatus': 'partial',
            'supplier': 'Incepta Sales',
            'itemCount': 42,
            'photos': [],
          },
        ],
        'meta': {
          'suppliers': [],
          'summary': {'count': 1, 'total': 62282.79, 'due': 37992.5},
          'maxPhotos': 5,
        },
      };
    } else if (path.endsWith('/suppliers/search')) {
      body = {'data': []};
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
