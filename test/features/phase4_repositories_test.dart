import 'dart:convert';
import 'dart:typed_data';

import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/network/api_exception.dart';
import 'package:bizpos_app/core/session/me_cache.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/session/session_state.dart';
import 'package:bizpos_app/features/platform/data/platform_models.dart';
import 'package:bizpos_app/features/platform/data/platform_repository.dart';
import 'package:bizpos_app/features/team/data/team_models.dart';
import 'package:bizpos_app/features/team/data/team_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_adapter.dart';
import '../support/fake_session.dart';
import '../support/role_fixtures.dart';

/// Phase 4 against `docs/MOBILE-API-NEW.md` sections 5.9, 5.10 and 6:
/// settings and team, and the super admin's platform.
void main() {
  late FakeAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = FakeAdapter();
    client = ApiClient.create(
      baseUrl: 'https://example.test/api/v1',
      readToken: () => 'tok',
      onUnauthenticated: () async {},
    );
    client.dio.httpClientAdapter = adapter;
  });

  Map<String, dynamic> sentBody() =>
      adapter.lastRequest.data as Map<String, dynamic>;

  /// Every PATCH leaves as a POST carrying the real verb.
  void expectOverridden(String verb) {
    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.headers['X-HTTP-Method-Override'], verb);
  }

  group('settings and team', () {
    late TeamRepository repo;
    setUp(() => repo = TeamRepository(client, CancelToken()));

    test(
      'GET /settings reads members, roles, the store and the may flags',
      () async {
        adapter.body = {
          'data': {
            'store': {
              'id': 1,
              'name': 'Rahman Pharmacy',
              'phone': '01711000000',
              'city': 'Dhaka',
              'currency': 'BDT',
            },
            'branches': [
              {'id': 1, 'name': 'Main Branch', 'code': 'MAIN', 'is_default': 1},
              {'id': 2, 'name': 'Mirpur', 'code': 'MRP', 'phone': '0199'},
            ],
            'members': [
              {
                'storeUserId': 31,
                'status': 'active',
                'id': 4,
                'name': 'Karim',
                'email': 'cashier@rahman.test',
                'lastLoginAt': '2026-10-05T09:00:00+06:00',
                'roleName': 'cashier',
              },
              {
                'storeUserId': 32,
                'status': 'suspended',
                'id': 9,
                'name': 'Rafi',
                'email': 'rafi@rahman.test',
                'lastLoginAt': null,
                'roleName': 'Stock Keeper',
              },
            ],
            'roles': [
              {
                'id': 3,
                'name': 'manager',
                'label': 'Manager',
                'label_bn': 'ম্যানেজার',
              },
              {'id': 4, 'name': 'cashier', 'label': 'Cashier'},
              {'id': 5, 'name': 'stock_keeper', 'label': 'Stock Keeper'},
            ],
            // The web workspace's own key/value settings: snake_case.
            'settings': {
              'vat_mode': 'inclusive',
              'receipt_paper': '58mm',
              'invoice_prefix': 'RP-',
              'allow_credit_sale': '0',
            },
            'activity': [],
            'permissionModules': {},
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
            'mayManageRole': false,
          },
        };

        final o = await repo.overview();
        expect(adapter.lastRequest.uri.path, '/api/v1/settings');

        expect(o.members, hasLength(2));
        final karim = o.members.first;
        expect(karim.storeUserId.value, 31);
        expect(karim.userId.value, 4);
        expect(karim.isActive, isTrue);
        expect(karim.lastLoginAt, isNotNull);
        expect(o.members.last.isActive, isFalse);
        expect(o.members.last.lastLoginAt, isNull);

        // The member row names its role by key or by label.
        expect(o.roleOf(karim)?.id, 4);
        expect(o.roleOf(o.members.last)?.id, 5);
        expect(o.roles.first.labelFor('bn'), 'ম্যানেজার');
        expect(o.roles[1].labelFor('bn'), 'Cashier');

        expect(o.branches.first.isDefault, isTrue);
        expect(o.branches.last.phone, '0199');

        expect(o.store.name, 'Rahman Pharmacy');
        expect(o.store.city, 'Dhaka');
        expect(o.store.vatMode, 'inclusive');
        expect(o.store.receiptPaper, '58mm');
        expect(o.store.invoicePrefix, 'RP-');
        expect(o.store.allowCreditSale, isFalse);

        expect(o.loyalty.enabled, isTrue);
        expect(o.loyalty.minRedeem, 50);

        // Tri-state: absent is "nothing said", not false.
        expect(o.mayManageUser, isTrue);
        expect(o.mayManageRole, isFalse);
        expect(o.maySeeActivity, isNull);
      },
    );

    test(
      'suspending goes by storeUserId, changing a role by user id',
      () async {
        const member = TeamMember(
          storeUserId: StoreUserId(31),
          userId: UserId(4),
          name: 'Karim',
          status: 'active',
        );

        await repo.setMemberActive(member.storeUserId, active: false);
        expect(
          adapter.lastRequest.uri.path,
          '/api/v1/settings/members/31/status',
        );
        expectOverridden('PATCH');
        expect(sentBody(), {'active': false});

        await repo.changeRole(member.userId, roleId: 3);
        expect(adapter.lastRequest.uri.path, '/api/v1/settings/members/4/role');
        expectOverridden('PATCH');
        expect(sentBody(), {'roleId': 3});
      },
    );

    test(
      'adding a member sends the doc\'s body and reads the reuse flag',
      () async {
        adapter
          ..statusCode = 201
          ..body = {
            'data': {'userId': 12, 'reusedExistingAccount': true},
          };

        final added = await repo.addMember(
          const MemberDraft(
            name: ' Rafi ',
            email: 'rafi@shop.com ',
            password: 'secret1',
            roleId: 4,
            branchId: 1,
          ),
        );

        expect(adapter.lastRequest.uri.path, '/api/v1/settings/members');
        expect(sentBody(), {
          'name': 'Rafi',
          'email': 'rafi@shop.com',
          'password': 'secret1',
          'roleId': 4,
          'branchId': 1,
        });
        expect(added.userId.value, 12);
        expect(added.reusedExistingAccount, isTrue);
      },
    );

    test('plan_limit comes back as the server\'s own words', () async {
      adapter
        ..statusCode = 422
        ..body = {
          'error': {
            'message': 'Your plan allows 3 users.',
            'code': 'plan_limit',
          },
        };

      expect(
        () => repo.addMember(
          const MemberDraft(
            name: 'A',
            email: 'a@b.c',
            password: 'secret1',
            roleId: 4,
          ),
        ),
        throwsA(
          isA<BusinessRuleException>()
              .having((e) => e.code, 'code', 'plan_limit')
              .having((e) => e.message, 'message', 'Your plan allows 3 users.'),
        ),
      );
    });

    test('a branch code is sent upper-case, and blanks are left out', () async {
      adapter
        ..statusCode = 201
        ..body = {
          'data': {'id': 7},
        };
      final id = await repo.createBranch(
        const BranchDraft(
          name: 'Mirpur ',
          code: 'mrp',
          phone: ' ',
          address: '',
        ),
      );
      expect(id, 7);
      expect(sentBody(), {'name': 'Mirpur', 'code': 'MRP'});

      await repo.updateBranch(
        7,
        const BranchDraft(name: 'Mirpur', code: 'MRP', phone: '0199'),
      );
      expect(adapter.lastRequest.uri.path, '/api/v1/settings/branches/7');
      expectOverridden('PATCH');
      expect(sentBody()['phone'], '0199');
    });

    test('a loyalty change carries the name the endpoint requires', () async {
      await repo.updateStore(
        StoreDraft.loyaltyOnly(
          'Rahman Pharmacy',
          const LoyaltySettings(
            enabled: true,
            earnPer: 200,
            earnPoints: 2,
            valuePer: 0.5,
            minRedeem: 20,
            maxRedeemPct: 30,
            round: 'nearest',
          ),
        ),
      );
      expect(adapter.lastRequest.uri.path, '/api/v1/settings/store');
      expectOverridden('PATCH');
      expect(sentBody(), {
        'name': 'Rahman Pharmacy',
        'loyalty': {
          'loyalty_enabled': true,
          'loyalty_earn_per': 200,
          'loyalty_earn_points': 2,
          'loyalty_value_per': 0.5,
          'loyalty_min_redeem': 20,
          'loyalty_max_redeem_pct': 30,
          'loyalty_round': 'nearest',
        },
      });
    });

    test(
      'the activity log sends its filters and reads the server\'s lists',
      () async {
        adapter.body = {
          'data': [
            {
              'id': 1,
              'event': 'updated',
              'subjectType': 'StoreProduct',
              'subjectId': 44,
              'subjectLabel': 'Napa 500mg',
              'changes': [
                {'field': 'sale_price', 'from': 10, 'to': 12},
              ],
              'createdAt': '2026-10-05T10:00:00+06:00',
              'user': {'id': 4, 'name': 'Karim'},
              'ip': '10.0.0.2',
            },
          ],
          'meta': {
            'subjects': ['StoreProduct', 'Sale'],
            'events': ['created', 'updated'],
            'days': 7,
          },
        };

        final log = await repo.activity(
          const ActivityQuery(days: 7, subject: 'StoreProduct', q: ' napa '),
        );
        expect(adapter.lastRequest.uri.path, '/api/v1/settings/activity');
        expect(adapter.lastRequest.queryParameters, {
          'days': 7,
          'subject': 'StoreProduct',
          'q': 'napa',
        });
        expect(log.entries.single.userName, 'Karim');
        expect(log.entries.single.changes.single.from, '10');
        expect(log.entries.single.changes.single.to, '12');
        expect(log.subjects, ['StoreProduct', 'Sale']);
        expect(log.days, 7);
      },
    );

    test('a role\'s permissions group by module', () async {
      adapter.body = {
        'data': {
          'id': 4,
          'name': 'cashier',
          'label': 'Cashier',
          'isLocked': true,
          'permissions': [
            'pos.sale.create',
            'pos.sale.hold',
            'customers.customer.view',
          ],
        },
      };
      final role = await repo.role(4);
      expect(adapter.lastRequest.uri.path, '/api/v1/settings/roles/4');
      expect(role.byModule.keys, ['pos', 'customers']);
      expect(role.byModule['pos'], hasLength(2));
      expect(role.isLocked, isTrue);
    });
  });

  group('platform', () {
    late PlatformRepository repo;
    setUp(() => repo = PlatformRepository(client, CancelToken()));

    test(
      'GET /admin/overview reads trials, locks, databases and totals',
      () async {
        adapter.body = {
          'data': {
            'stores': [
              {
                'id': 1,
                'name': 'Rahman Pharmacy',
                'slug': 'rahman-pharmacy',
                'status': 'active',
                'storeTypeId': 1,
                'planId': 2,
                'phone': '01711',
                'trialEndsAt': '2026-10-08T23:59:59+06:00',
                'trialDaysLeft': 2,
                'locked': false,
                'dbName': 'bizpos_store_1',
                'dbReady': true,
                'dbMigratedAt': null,
                'usersCount': 6,
                'products_count': 420,
              },
              {
                'id': 2,
                'name': 'Closed Shop',
                'status': 'suspended',
                'locked': true,
                'trialEndsAt': null,
              },
            ],
            'storeTypes': [
              {'id': 1, 'name': 'Pharmacy'},
              {'id': 2, 'name': 'Grocery'},
            ],
            'plans': [
              {'id': 2, 'name': 'Starter'},
            ],
            'suggestions': [
              {
                'id': 5,
                'name': 'Sergel 20',
                'brand': 'Healthcare',
                'storeName': 'Rahman Pharmacy',
              },
            ],
            'totals': {'stores': 2, 'users': 9, 'salesToday': 15400.5},
          },
        };

        final o = await repo.overview();
        final first = o.stores.first;
        expect(first.trialDaysLeft, 2);
        expect(first.hasTrial, isTrue);
        expect(first.dbReady, isTrue);
        expect(first.dbMigratedAt, isNull);
        expect(first.counts, {'users': 6, 'products': 420});
        expect(o.storeTypeName(first.storeTypeId), 'Pharmacy');
        expect(o.planName(first.planId), 'Starter');

        final closed = o.stores.last;
        expect(closed.isSuspended, isTrue);
        expect(closed.locked, isTrue);
        expect(closed.hasTrial, isFalse);

        expect(o.suggestions.single.storeName, 'Rahman Pharmacy');
        expect(o.totals['salesToday'], 15400.5);

        expect(first.matches('rahman'), isTrue);
        expect(first.matches('01711'), isTrue);
        expect(first.matches('grocery'), isFalse);
      },
    );

    test('creating a store sends the phone and reports the database', () async {
      adapter
        ..statusCode = 201
        ..body = {
          'data': {
            'storeId': 12,
            'ownerEmail': 'nadia@shop.test',
            'reusedExistingAccount': false,
            'dbName': 'bizpos_store_12',
            'dbCreated': true,
            'dbMigrated': false,
            'dbProblem': 'Migrations failed',
            'dbDetail': 'SQLSTATE[42000]',
          },
        };

      final created = await repo.createStore(
        const NewStoreDraft(
          name: 'Nadia Store ',
          storeTypeId: 2,
          ownerName: 'Nadia',
          ownerEmail: 'nadia@shop.test',
          ownerPassword: 'secret1',
          phone: ' 01800000000',
          branchName: '',
        ),
      );

      expect(adapter.lastRequest.uri.path, '/api/v1/admin/stores');
      expect(sentBody(), {
        'name': 'Nadia Store',
        'storeTypeId': 2,
        'ownerName': 'Nadia',
        'ownerEmail': 'nadia@shop.test',
        'ownerPassword': 'secret1',
        'phone': '01800000000',
      });
      expect(created.storeId, 12);
      expect(created.dbOk, isFalse);
      expect(created.dbProblem, 'Migrations failed');
    });

    test('an edit sends only what changed', () async {
      const before = AdminStore(
        id: 1,
        name: 'Rahman Pharmacy',
        status: 'active',
        storeTypeId: 1,
        planId: 2,
        phone: '01711',
        city: 'Dhaka',
      );
      final edit = StoreEdit.diff(
        before,
        const StoreEdit(
          name: 'Rahman Pharmacy',
          storeTypeId: 2,
          planId: 2,
          phone: '01711',
          city: 'Chattogram',
          email: '',
        ),
      );
      expect(edit.toBody(), {'storeTypeId': 2, 'city': 'Chattogram'});

      adapter.body = {
        'data': {'id': 1, 'storeTypeChanged': true},
      };
      final updated = await repo.updateStore(1, edit);
      expect(adapter.lastRequest.uri.path, '/api/v1/admin/stores/1');
      expectOverridden('PATCH');
      expect(updated.storeTypeChanged, isTrue);
    });

    test(
      'extend sends days, or unlimited, and only says activate when false',
      () async {
        adapter.body = {
          'data': {
            'id': 1,
            'status': 'active',
            'trialEndsAt': '2026-11-07T23:59:59+06:00',
            'trialDaysLeft': 32,
            'locked': false,
          },
        };

        final state = await repo.extend(1, days: 30);
        expect(adapter.lastRequest.uri.path, '/api/v1/admin/stores/1/extend');
        expect(sentBody(), {'days': 30});
        expect(state.trialDaysLeft, 32);

        await repo.extend(1, unlimited: true, activate: false);
        expect(sentBody(), {'unlimited': true, 'activate': false});
      },
    );

    test('suspend and reactivate send the status word', () async {
      await repo.setStatus(3, active: false);
      expect(adapter.lastRequest.uri.path, '/api/v1/admin/stores/3/status');
      expectOverridden('PATCH');
      expect(sentBody(), {'status': 'suspended'});

      await repo.setStatus(3, active: true);
      expect(sentBody(), {'status': 'active'});
    });

    test('reviewing a suggestion reads whether an entry was created', () async {
      adapter
        ..statusCode = 201
        ..body = {
          'data': {'created': true, 'globalProductId': 900},
        };
      expect(await repo.reviewSuggestion(5, approve: true), isTrue);
      expect(
        adapter.lastRequest.uri.path,
        '/api/v1/admin/suggestions/5/review',
      );
      expect(sentBody(), {'approve': true});

      adapter
        ..statusCode = 200
        ..body = {
          'data': {'created': false},
        };
      expect(
        await repo.reviewSuggestion(6, approve: false, note: 'Duplicate'),
        isFalse,
      );
      expect(sentBody(), {'approve': false, 'note': 'Duplicate'});
    });

    test('the shared catalogue pages, filters and soft-deletes', () async {
      adapter.body = {
        'data': [
          {
            'id': 70,
            'name': 'Napa 500mg',
            'brand': 'Beximco',
            'storeTypeId': 1,
            'status': 'pending',
            'inStores': 312,
            'salePrice': 12,
            'deletedAt': null,
          },
        ],
        'meta': {
          'total': 61,
          'page': 1,
          'perPage': 30,
          'trashedCount': 4,
          'pendingCount': 9,
          'storeTypes': [
            {'id': 1, 'name': 'Pharmacy'},
          ],
        },
      };

      final page = await repo.catalog(
        filter: const AdminCatalogFilter(
          q: 'napa',
          storeTypeId: 1,
          status: 'pending',
          trashed: true,
        ),
      );
      expect(adapter.lastRequest.uri.path, '/api/v1/admin/catalog');
      expect(adapter.lastRequest.queryParameters, {
        'q': 'napa',
        'storeType': 1,
        'status': 'pending',
        'trashed': 1,
        'page': 1,
        'perPage': 30,
      });
      expect(page.hasMore, isTrue);
      expect(page.items.single.inStores, 312);
      final meta = AdminCatalogMeta(page.meta);
      expect(meta.trashedCount, 4);
      expect(meta.pendingCount, 9);
      expect(meta.storeTypes.single.name, 'Pharmacy');

      adapter.body = {
        'data': {'ok': true, 'storesAffected': 312},
      };
      expect(await repo.deleteEntry(70), 312);
      expect(adapter.lastRequest.uri.path, '/api/v1/admin/catalog/70');
      expectOverridden('DELETE');

      await repo.restoreEntry(70);
      expect(adapter.lastRequest.uri.path, '/api/v1/admin/catalog/70/restore');
    });

    test('an entry edit sends every field, a cleared one as null', () {
      const draft = CatalogEntryDraft(
        storeTypeId: 1,
        name: 'Napa',
        barcode: '  ',
        salePrice: 12,
      );
      final body = draft.toBody();
      expect(body['barcode'], isNull);
      expect(body.containsKey('barcode'), isTrue);
      expect(body['salePrice'], 12);
      expect(body.containsKey('status'), isFalse);
    });
  });

  group('support mode', () {
    setUp(() => SharedPreferences.setMockInitialValues(const {}));

    test(
      'entering a store remembers the way back, and leaving takes it',
      () async {
        final backend = _MeBackend();
        final container = ProviderContainer(
          overrides: [
            fakeSession(
              activeSession(Roles.owner, isSuperAdmin: true, name: 'Platform'),
            ),
            apiClientProvider.overrideWith((ref) {
              final c = ApiClient.create(
                baseUrl: 'https://example.test/api/v1',
                readToken: () => 'tok',
                onUnauthenticated: () async {},
              );
              c.dio.httpClientAdapter = backend;
              return c;
            }),
          ],
        );
        addTearDown(container.dispose);
        await container.read(sessionControllerProvider.future);
        final session = container.read(sessionControllerProvider.notifier);

        await session.impersonate(7);
        expect(
          backend.hit,
          contains('POST /api/v1/admin/stores/7/impersonate'),
        );
        var state = container.read(sessionControllerProvider).value;
        expect(state, isA<SessionActive>());
        expect((state as SessionActive).me.impersonating, isTrue);
        expect(state.scope.storeId, 7);
        expect(await SupportReturn.read(), 1);

        // A second shop entered from the first keeps the original way back.
        await session.impersonate(8);
        expect(await SupportReturn.read(), 1);

        await session.leaveSupport();
        expect(backend.switchedTo, 1);
        state = container.read(sessionControllerProvider).value;
        expect((state as SessionActive).me.impersonating, isFalse);
        expect(state.scope.storeId, 1);
        expect(await SupportReturn.read(), isNull);
      },
    );
  });
}

/// Answers `/me` for whichever store this device was last moved into.
class _MeBackend implements HttpClientAdapter {
  final List<String> hit = [];
  int store = 1;
  bool impersonating = false;
  int? switchedTo;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.uri.path}';
    hit.add(key);
    final impersonate = RegExp(r'/admin/stores/(\d+)/impersonate$')
        .firstMatch(options.uri.path);

    Object body = {'data': <String, dynamic>{}};
    if (impersonate != null) {
      store = int.parse(impersonate.group(1)!);
      impersonating = true;
      body = {
        'data': {'storeId': store, 'branchId': 1},
      };
    } else if (key == 'POST /api/v1/auth/switch-store') {
      store = (options.data as Map)['storeId'] as int;
      switchedTo = store;
      impersonating = false;
      body = {
        'data': {'storeId': store},
      };
    } else if (key == 'GET /api/v1/me') {
      body = {
        'data': {
          'user': {
            'id': 1,
            'name': 'Platform',
            'email': 'super@bizpos.test',
            'is_super_admin': true,
          },
          'store': {
            'id': store,
            'name': 'Store $store',
            'slug': 'store-$store',
            'currency': 'BDT',
          },
          'branch': {'id': 1, 'name': 'Main', 'code': 'MAIN'},
          'stores': [
            {'id': 1, 'name': 'Store 1'},
          ],
          'branches': [],
          'role': {'id': 1, 'name': 'super_admin', 'label': 'Super Admin'},
          'permissions': ['admin.store.view'],
          'impersonating': impersonating,
        },
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
