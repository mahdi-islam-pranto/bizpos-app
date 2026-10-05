import 'dart:convert';
import 'dart:typed_data';

import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/platform/ui/platform_screen.dart';
import 'package:bizpos_app/features/team/ui/team_screen.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_session.dart';
import '../support/role_fixtures.dart';

/// Phase 4 on screen: the team and store screen per role, and the platform.
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
    bool isSuperAdmin = false,
    Locale locale = const Locale('en'),
    Size size = const Size(900, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeSession(activeSession(permissions, isSuperAdmin: isSuperAdmin)),
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
          theme: AppTheme.of(
            ThemeVariant.daylight,
            locale: locale.languageCode,
          ),
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

  group('team', () {
    testWidgets('an owner changes a role by the user id', (tester) async {
      await pump(tester, const TeamScreen(), permissions: Roles.owner);

      expect(find.text('Add member'), findsOneWidget);
      expect(find.text('Salma'), findsOneWidget);
      expect(find.text('Rafi'), findsOneWidget);

      await tester.tap(find.text('Salma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change role'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manager'));
      await tester.pumpAndSettle();

      // Salma's user id is 6; her member row is 33.
      expect(backend.bodies['POST /api/v1/settings/members/6/role'], {
        'roleId': 3,
      });
      expect(find.text('Salma is now Manager'), findsOneWidget);
    });

    testWidgets(
      'a manager suspends by the member row, and has no role picker',
      (tester) async {
        await pump(tester, const TeamScreen(), permissions: Roles.manager);

        await tester.tap(find.text('Salma'));
        await tester.pumpAndSettle();
        expect(find.text('Change role'), findsNothing);

        await tester.tap(find.text('Suspend'));
        await tester.pumpAndSettle();
        // The confirm sheet's own button.
        await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
        await tester.pumpAndSettle();

        expect(backend.bodies['POST /api/v1/settings/members/33/status'], {
          'active': false,
        });
      },
    );

    testWidgets('nobody is offered their own row', (tester) async {
      await pump(tester, const TeamScreen(), permissions: Roles.owner);

      // The session's user is id 4: Karim.
      expect(find.text('You'), findsOneWidget);
      await tester.tap(find.text('Karim'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nobody can change their own role'), findsOne);
      expect(find.text('Suspend'), findsNothing);
      expect(find.text('Change role'), findsNothing);
    });

    testWidgets('an auditor reads everything and changes nothing', (
      tester,
    ) async {
      await pump(tester, const TeamScreen(), permissions: Roles.auditor);

      expect(find.text('Add member'), findsNothing);
      await tester.tap(find.text('Salma'));
      await tester.pumpAndSettle();
      expect(find.text('You can see the team but not change it.'), findsOne);
      Navigator.of(tester.element(find.text('Salma').last)).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Store'));
      await tester.pumpAndSettle();
      expect(find.text('Rahman Pharmacy'), findsOneWidget);
      expect(find.text('Included in prices'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);

      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Store product · Napa 500mg'), findsOneWidget);
      expect(backend.queries['GET /api/v1/settings/activity'], {'days': '7'});
    });

    testWidgets('a branch is added from the Branches tab', (tester) async {
      await pump(tester, const TeamScreen(), permissions: Roles.owner);

      await tester.tap(find.text('Branches'));
      await tester.pumpAndSettle();
      expect(find.text('Mirpur'), findsOneWidget);

      await tester.tap(find.text('Add branch'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Uttara');
      await tester.enterText(fields.at(1), 'utr');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(backend.bodies['POST /api/v1/settings/branches'], {
        'name': 'Uttara',
        'code': 'UTR',
      });
    });

    testWidgets('fits in Bengali on a narrow phone', (tester) async {
      await pump(
        tester,
        const TeamScreen(),
        permissions: Roles.owner,
        locale: const Locale('bn'),
        size: const Size(360, 780),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('দোকান'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('platform', () {
    testWidgets('a super admin sees each shop\'s trial and lock at a glance', (
      tester,
    ) async {
      await pump(
        tester,
        const PlatformScreen(),
        permissions: const [],
        isSuperAdmin: true,
      );

      expect(find.text('Rahman Pharmacy'), findsOneWidget);
      expect(find.text('2 days left'), findsOneWidget);
      expect(find.text('Closed Shop'), findsOneWidget);
      expect(find.text('Suspended'), findsOneWidget);
      expect(find.text('Suggestions (1)'), findsOneWidget);
      expect(find.text('New store'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'closed');
      await tester.pumpAndSettle();
      expect(find.text('Rahman Pharmacy'), findsNothing);
      expect(find.text('Closed Shop'), findsOneWidget);
    });

    testWidgets('a trial is extended by thirty days', (tester) async {
      await pump(
        tester,
        const PlatformScreen(),
        permissions: const [],
        isSuperAdmin: true,
      );

      await tester.tap(find.text('Rahman Pharmacy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Extend trial'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Extend trial'));
      await tester.pumpAndSettle();

      expect(backend.bodies['POST /api/v1/admin/stores/1/extend'], {
        'days': 30,
      });
    });

    testWidgets('a suggestion is approved into the shared catalogue', (
      tester,
    ) async {
      await pump(
        tester,
        const PlatformScreen(),
        permissions: const [],
        isSuperAdmin: true,
      );

      await tester.tap(find.text('Suggestions (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Sergel 20'), findsOneWidget);
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(backend.bodies['POST /api/v1/admin/suggestions/5/review'], {
        'approve': true,
      });
      expect(find.text('Added to the shared catalogue'), findsOneWidget);
    });
  });
}

class _Backend implements HttpClientAdapter {
  final Map<String, Map<String, dynamic>> bodies = {};
  final Map<String, Map<String, String>> queries = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final key = '${options.method} $path';
    queries[key] = options.uri.queryParameters;
    if (options.data is Map<String, dynamic>) {
      bodies[key] = options.data as Map<String, dynamic>;
    }

    Object body = {'data': <String, dynamic>{}};
    var status = 200;

    if (key == 'GET /api/v1/settings') {
      body = {
        'data': {
          'store': {'id': 1, 'name': 'Rahman Pharmacy', 'phone': '01711000000'},
          'branches': [
            {'id': 1, 'name': 'Main Branch', 'code': 'MAIN'},
            {'id': 2, 'name': 'Mirpur', 'code': 'MRP'},
          ],
          'members': [
            {
              'storeUserId': 31,
              'status': 'active',
              'id': 4,
              'name': 'Karim',
              'email': 'cashier@rahman.test',
              'roleName': 'cashier',
            },
            {
              'storeUserId': 33,
              'status': 'active',
              'id': 6,
              'name': 'Salma',
              'email': 'salma@rahman.test',
              'roleName': 'cashier',
              'lastLoginAt': '2026-10-05T09:00:00+06:00',
            },
            {
              'storeUserId': 32,
              'status': 'suspended',
              'id': 9,
              'name': 'Rafi',
              'email': 'rafi@rahman.test',
              'roleName': 'stock_keeper',
            },
          ],
          'roles': [
            {'id': 2, 'name': 'store_owner', 'label': 'Store Owner'},
            {
              'id': 3,
              'name': 'manager',
              'label': 'Manager',
              'label_bn': 'ম্যানেজার',
            },
            {
              'id': 4,
              'name': 'cashier',
              'label': 'Cashier',
              'label_bn': 'ক্যাশিয়ার',
            },
            {'id': 5, 'name': 'stock_keeper', 'label': 'Stock Keeper'},
          ],
          'settings': {'vat_mode': 'inclusive', 'receipt_paper': '80mm'},
          'activity': [],
          'loyalty': {
            'loyalty_enabled': true,
            'loyalty_earn_per': 100,
            'loyalty_earn_points': 1,
            'loyalty_value_per': 1,
            'loyalty_min_redeem': 50,
            'loyalty_max_redeem_pct': 50,
            'loyalty_round': 'down',
          },
        },
        'meta': {
          'mayUpdateStore': true,
          'mayManageBranch': true,
          'mayManageUser': true,
          'mayManageRole': true,
          'maySeeActivity': true,
        },
      };
    } else if (key == 'GET /api/v1/settings/activity') {
      body = {
        'data': [
          {
            'id': 1,
            'event': 'updated',
            'subjectType': 'StoreProduct',
            'subjectLabel': 'Napa 500mg',
            'changes': [
              {'field': 'sale_price', 'from': 10, 'to': 12},
            ],
            'createdAt': '2026-10-05T10:00:00+06:00',
            'user': 'Karim',
          },
        ],
        'meta': {
          'subjects': ['StoreProduct'],
          'days': 7,
        },
      };
    } else if (key == 'POST /api/v1/settings/branches') {
      status = 201;
      body = {
        'data': {'id': 3},
      };
    } else if (key == 'GET /api/v1/admin/overview') {
      body = {
        'data': {
          'stores': [
            {
              'id': 1,
              'name': 'Rahman Pharmacy',
              'status': 'active',
              'storeTypeId': 1,
              'ownerName': 'Abdur Rahman',
              'trialEndsAt': '2026-10-08T23:59:59+06:00',
              'trialDaysLeft': 2,
              'locked': false,
            },
            {
              'id': 2,
              'name': 'Closed Shop',
              'status': 'suspended',
              'storeTypeId': 2,
              'locked': true,
            },
          ],
          'storeTypes': [
            {'id': 1, 'name': 'Pharmacy'},
            {'id': 2, 'name': 'Grocery'},
          ],
          'plans': [],
          'suggestions': [
            {
              'id': 5,
              'name': 'Sergel 20',
              'brand': 'Healthcare',
              'storeName': 'Rahman Pharmacy',
            },
          ],
          'totals': {'stores': 2, 'users': 9},
        },
      };
    } else if (key == 'POST /api/v1/admin/stores/1/extend') {
      body = {
        'data': {
          'id': 1,
          'status': 'active',
          'trialEndsAt': '2026-11-07T23:59:59+06:00',
          'trialDaysLeft': 32,
          'locked': false,
        },
      };
    } else if (key == 'POST /api/v1/admin/suggestions/5/review') {
      status = 201;
      body = {
        'data': {'created': true, 'globalProductId': 900},
      };
    } else if (key == 'GET /api/v1/admin/catalog') {
      body = {
        'data': [],
        'meta': {'total': 0, 'page': 1, 'perPage': 30},
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
