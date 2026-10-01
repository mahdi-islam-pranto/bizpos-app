import 'dart:convert';
import 'dart:typed_data';

import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/accounts/ui/accounts_screen.dart';
import 'package:bizpos_app/features/dashboard/ui/dashboard_screen.dart';
import 'package:bizpos_app/features/reports/ui/reports_screen.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_session.dart';
import '../support/role_fixtures.dart';

/// Phase 3 on screen: accounts, reports and the dashboard, per role.
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
    Locale locale = const Locale('en'),
    ThemeVariant variant = ThemeVariant.daylight,
    Size size = const Size(900, 2400),
  }) async {
    tester.view.physicalSize = size;
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
          theme: AppTheme.of(variant, locale: locale.languageCode),
          locale: locale,
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

  group('accounts', () {
    testWidgets('an accountant records a quick expense in one tap',
        (tester) async {
      await pump(tester, const AccountsScreen(), permissions: Roles.accountant);

      expect(find.text('City Bank'), findsOneWidget);
      expect(find.byTooltip('Transfer'), findsOneWidget);
      expect(find.byTooltip('Expense types'), findsOneWidget);
      expect(find.text('Expense'), findsWidgets);

      await tester.tap(find.text('Tea'));
      await tester.pumpAndSettle();

      expect(backend.bodies['POST /api/v1/expenses'], {'categoryId': 5});
      // The confirmation carries the server's amount.
      expect(find.textContaining('Tea: ৳50 recorded'), findsOneWidget);
    });

    testWidgets('a salary tile opens the form asking for a name',
        (tester) async {
      await pump(tester, const AccountsScreen(), permissions: Roles.accountant);

      await tester.tap(find.text('Salary').first);
      await tester.pumpAndSettle();

      expect(backend.bodies.containsKey('POST /api/v1/expenses'), isFalse);
      expect(find.text('Employee'), findsOneWidget);
      // Names paid before are offered.
      expect(find.widgetWithText(ActionChip, 'Karim Uddin'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, 'Karim Uddin'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Amount'),
        '12000',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Expense'));
      await tester.pumpAndSettle();

      final body = backend.bodies['POST /api/v1/expenses']!;
      expect(body['categoryId'], 9);
      expect(body['amount'], 12000);
      expect(body['employeeName'], 'Karim Uddin');
      expect(body['salaryMonth'], matches(RegExp(r'^\d{4}-\d{2}$')));
    });

    testWidgets('an auditor reads the same screen with every button gone',
        (tester) async {
      await pump(tester, const AccountsScreen(), permissions: Roles.auditor);

      expect(find.text('City Bank'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byTooltip('Transfer'), findsNothing);
      expect(find.byTooltip('Expense types'), findsNothing);
      expect(find.text('Quick expenses'.toUpperCase()), findsNothing);
      expect(find.text('Add account'), findsNothing);
    });
  });

  group('dashboard', () {
    testWidgets('a manager sees profit locked, not zero', (tester) async {
      backend.managerDashboard = true;
      await pump(tester, const DashboardScreen(), permissions: Roles.manager);

      expect(backend.hit, contains('GET /api/v1/dashboard'));
      expect(find.text('৳45,000'), findsWidgets);
      expect(find.text('Not in your access'), findsNWidgets(2));
      // `capital: null` is said, not silently skipped.
      expect(find.text("You don't have access to this section."), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a range chip asks the server for that window',
        (tester) async {
      await pump(tester, const DashboardScreen(), permissions: Roles.owner);
      expect(backend.lastQuery['range'], 'today');

      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();
      expect(backend.lastQuery['range'], '7d');
    });

    testWidgets('a cashier gets the small version: shelf alerts and the drawer',
        (tester) async {
      await pump(tester, const DashboardScreen(), permissions: Roles.cashier);

      expect(backend.hit, isNot(contains('GET /api/v1/dashboard')));
      expect(backend.hit, contains('GET /api/v1/products/stats'));
      expect(backend.hit, contains('GET /api/v1/pos/lookups'));
      expect(find.text('Drawer open'), findsOneWidget);
      expect(find.text('Folive 400mcg'), findsOneWidget);
      // No `view_cost`: the stock value is not a figure for a cashier.
      expect(find.text('Stock value'), findsNothing);
    });

    testWidgets('renders in Bangla and dark at phone width', (tester) async {
      await pump(
        tester,
        const DashboardScreen(),
        permissions: Roles.owner,
        locale: const Locale('bn'),
        variant: ThemeVariant.midnight,
        size: const Size(390, 844),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Bangla and dark at phone width', () {
    for (final (name, screen, role) in [
      ('accounts', const AccountsScreen() as Widget, Roles.accountant),
      ('reports', const ReportsScreen() as Widget, Roles.accountant),
      ('the small dashboard', const DashboardScreen() as Widget, Roles.cashier),
    ]) {
      testWidgets('$name lays out without overflowing', (tester) async {
        await pump(
          tester,
          screen,
          permissions: role,
          locale: const Locale('bn'),
          variant: ThemeVariant.midnight,
          size: const Size(360, 780),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('reports', () {
    testWidgets('a manager has every tab except profit', (tester) async {
      await pump(tester, const ReportsScreen(), permissions: Roles.manager);

      expect(find.widgetWithText(Tab, 'Sales'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Stock'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Dues'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Profit'), findsNothing);
      expect(backend.hit, isNot(contains('GET /api/v1/reports/profit')));
    });

    testWidgets('each tab labels its scope', (tester) async {
      await pump(tester, const ReportsScreen(), permissions: Roles.accountant);

      // Sales is per branch.
      expect(find.text('This branch'), findsWidgets);

      await tester.tap(find.widgetWithText(Tab, 'Dues'));
      await tester.pumpAndSettle();
      // Dues are store-wide.
      expect(find.text('Whole store'), findsWidgets);
      expect(find.text('Rahim'), findsOneWidget);
    });

    testWidgets('a stock keeper gets the stock report alone', (tester) async {
      await pump(tester, const ReportsScreen(), permissions: Roles.stockKeeper);

      expect(find.byType(TabBar), findsNothing);
      expect(backend.hit, contains('GET /api/v1/reports/stock'));
      expect(backend.hit, isNot(contains('GET /api/v1/reports/sales')));
      expect(find.text('Folive 400mcg'), findsOneWidget);
    });
  });
}

class _Backend implements HttpClientAdapter {
  final Map<String, Map<String, dynamic>> bodies = {};
  final List<String> hit = [];
  Map<String, dynamic> lastQuery = {};
  bool managerDashboard = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final key = '${options.method} $path';
    hit.add(key);
    if (options.data is Map<String, dynamic>) {
      bodies[key] = options.data as Map<String, dynamic>;
    }

    Object body = {'data': <String, dynamic>{}};
    var status = 200;

    if (key == 'GET /api/v1/accounts') {
      body = {
        'data': {
          'accounts': [
            {'id': 1, 'name': 'Cash drawer', 'type': 'cash', 'balance': 15400, 'isDefault': true},
            {'id': 3, 'name': 'City Bank', 'type': 'bank', 'balance': 82000},
          ],
          'expenses': [
            {'id': 51, 'amount': 350, 'categoryName': 'Tea', 'accountName': 'Cash drawer', 'createdAt': '2026-09-30T10:00:00+06:00'},
          ],
          'transactions': [],
          'categories': [
            {'id': 5, 'name': 'Tea', 'icon': '☕', 'defaultAmount': 50, 'isQuick': true},
            {'id': 9, 'name': 'Salary', 'icon': '👷', 'isSalary': true, 'isQuick': true},
          ],
          'quick': [
            {'id': 5, 'name': 'Tea', 'icon': '☕', 'defaultAmount': 50},
            {'id': 9, 'name': 'Salary', 'icon': '👷'},
          ],
          'employees': ['Karim Uddin'],
          'monthExpense': 18350,
          'todayExpense': 350,
          'monthSalary': 0,
        },
        'meta': {
          'mayManage': true,
          'mayExpense': true,
          'mayDeleteExpense': true,
          'mayManageCategories': true,
          'mayTransfer': true,
        },
      };
    } else if (key == 'POST /api/v1/expenses') {
      status = 201;
      final sent = options.data as Map<String, dynamic>;
      body = {
        'data': {
          'ok': true,
          'id': 90,
          'amount': sent['amount'] ?? 50,
          'isSalary': sent['categoryId'] == 9,
        },
      };
    } else if (path.endsWith('/dashboard')) {
      lastQuery = Map.of(options.queryParameters);
      body = {
        'data': {
          'range': {'from': '2026-09-30', 'to': '2026-09-30'},
          'headline': {
            'revenue': 45000,
            'invoices': 120,
            'averageSale': 375,
            'discountGiven': 800,
            'dueRaised': 2400,
            'returned': 300,
            'expenses': 5200,
            'grossProfit': managerDashboard ? null : 12000,
            'netProfit': managerDashboard ? null : 6800,
          },
          'capital': managerDashboard
              ? null
              : {
                  'stock': 3462945,
                  'receivable': 18000,
                  'inAccounts': 97400,
                  'invested': 3000000,
                  'payable': 42000,
                  'net': 3536345,
                  'accounts': [
                    {'name': 'Cash drawer', 'balance': 15400},
                  ],
                },
          'daily': [
            {'date': '2026-09-29', 'sales': 5200, 'invoices': 14, 'expenses': 300},
            {'date': '2026-09-30', 'sales': 6100, 'invoices': 17, 'expenses': 350},
          ],
          'payments': [
            {'method': 'cash', 'total': 40000},
            {'method': 'bkash', 'total': 5000},
          ],
          'collections': {
            'total': 43000,
            'onSales': 40000,
            'onDues': 2500,
            'onPreviousDue': 500,
            'byMethod': [
              {'method': 'cash', 'total': 38000},
            ],
          },
          'topProducts': [
            {'id': 44, 'name': 'Napa Extra 500mg with a long name', 'qty': 120, 'revenue': 1440, 'profit': managerDashboard ? null : 300},
          ],
          'movers': {
            'rising': [
              {'name': 'Napa', 'qty': 120, 'wasQty': 80, 'revenue': 1440, 'wasRevenue': 960, 'changePercent': 50, 'perDay': 17, 'onHand': 40, 'daysCover': 2.4},
            ],
            'falling': [],
            'restock': [
              {'name': 'Seclo 20', 'qty': 70, 'wasQty': 60, 'revenue': 700, 'wasRevenue': 600, 'changePercent': 16, 'perDay': 10, 'onHand': 30, 'daysCover': 3},
            ],
          },
          'staff': [
            {'name': 'Karim', 'invoices': 80, 'revenue': 30000, 'discount': 500, 'dueRaised': 1200, 'averageSale': 375},
          ],
          'dues': {
            'receivableTotal': 18000,
            'payableTotal': 42000,
            'customers': [
              {'id': 3, 'name': 'Rahim', 'due': 5400},
            ],
            'suppliers': [
              {'id': 2, 'name': 'Square Pharma', 'due': 42000},
            ],
          },
          'expenses': {
            'total': 5200,
            'byCategory': [
              {'name': 'Tea', 'total': 700, 'count': 14},
            ],
          },
          'purchases': {'total': 90000, 'due': 42000, 'count': 6},
          'stock': {
            'value': 3462945,
            'units': 18000,
            'outOfStock': 12,
            'low': [
              {'id': 774, 'name': 'Folive 400mcg', 'quantity': 0},
            ],
            'expiring': [],
          },
          'shifts': [
            {'id': 9, 'userName': 'Karim', 'openedAt': '2026-09-29T09:00:00+06:00', 'closedAt': '2026-09-29T21:00:00+06:00', 'openingCash': 2000, 'expected': 15400, 'counted': 15300, 'difference': -100},
          ],
        },
        'meta': {'mayProfit': !managerDashboard},
      };
    } else if (path.endsWith('/products/stats')) {
      body = {
        'data': {
          'total': 1607,
          'active': 1607,
          'lowCount': 50,
          'low': [
            {'id': 774, 'name': 'Folive 400mcg', 'quantity': 0, 'minimum': 10},
          ],
          'expiringCount': 0,
          'expiring': [],
          'stockValue': 0,
          'canSeeCost': false,
        },
      };
    } else if (path.endsWith('/pos/lookups')) {
      body = {
        'data': {
          'accounts': [],
          'customers': [],
          'held': [],
          'shift': {'id': 4, 'openingCash': 2000, 'openedAt': '2026-09-30T09:00:00+06:00'},
          'vatInclusive': false,
          'allowCredit': true,
        },
      };
    } else if (path.endsWith('/reports/sales')) {
      body = {
        'data': {
          'daily': [
            {'date': '2026-09-30', 'total': 6100, 'count': 17},
          ],
          'topProducts': [],
          'byUser': [],
          'byMethod': [],
          'showProfit': false,
        },
      };
    } else if (path.endsWith('/reports/profit')) {
      body = {
        'data': {
          'revenue': 100000,
          'cost': 70000,
          'returnTotal': 2000,
          'grossProfit': 28000,
          'expenses': 9000,
          'netProfit': 19000,
          'margin': 19,
        },
      };
    } else if (path.endsWith('/reports/stock')) {
      body = {
        'data': {
          'stockValue': 3462945.39,
          'totalUnits': 18000,
          'low': [
            {'id': 774, 'name': 'Folive 400mcg', 'quantity': 0, 'minimum': 10},
          ],
          'expiring': [],
          'dead': [],
        },
      };
    } else if (path.endsWith('/reports/dues')) {
      body = {
        'data': [
          {'id': 3, 'name': 'Rahim', 'phone': '01711', 'due': 5400, 'creditLimit': 5000, 'ageDays': 41},
        ],
      };
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
