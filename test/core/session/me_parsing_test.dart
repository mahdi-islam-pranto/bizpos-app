import 'dart:convert';
import 'dart:io';

import 'package:bizpos_app/core/network/envelope.dart';
import 'package:bizpos_app/core/permissions/permissions.dart';
import 'package:bizpos_app/core/session/me.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /me` is the one response that answers in snake_case while the rest of
/// the API is camelCase. The fixture is the doc's own example, copied verbatim,
/// so a convention-based codec quietly dropping `is_super_admin` cannot pass.
void main() {
  Map<String, dynamic> fixture(String name) {
    final file = File('test/fixtures/$name');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  group('GET /me, from the documented example', () {
    late Me me;

    setUp(() {
      me = Me.fromJson(asObject(readData(fixture('me.json'))));
    });

    test('binds the snake_case keys', () {
      expect(me.user.isSuperAdmin, isFalse, reason: 'is_super_admin');
      expect(me.store!.storeTypeId, 1, reason: 'store_type_id');
      expect(me.store!.storeTypeName, 'Pharmacy', reason: 'store_type_name');
      expect(me.role!.labelBn, 'ক্যাশিয়ার', reason: 'label_bn');
    });

    test('reads the person, store and branch', () {
      expect(me.user.name, 'Karim');
      expect(me.user.locale, 'bn');
      expect(me.store!.currency, 'BDT');
      expect(me.branch!.code, 'MAIN');
    });

    test('knows the switchers are needed for branches but not stores', () {
      expect(me.canSwitchStore, isFalse, reason: 'one store');
      expect(me.canSwitchBranch, isTrue, reason: 'two branches');
    });

    test('permissions land in the set', () {
      expect(me.permissions.has(P.posSaleCreate), isTrue);
      expect(me.permissions.has(P.reportProfitView), isFalse);
    });

    test('survives a round trip through the cache', () {
      final again = Me.fromJson(me.toJson());
      expect(again.user.isSuperAdmin, me.user.isSuperAdmin);
      expect(again.store!.storeTypeName, me.store!.storeTypeName);
      expect(again.role!.labelBn, me.role!.labelBn);
      expect(again.permissions.all, me.permissions.all);
      expect(again.branches, hasLength(me.branches.length));
    });
  });

  group('the trial clock', () {
    Me withStore(Map<String, dynamic> store) => Me.fromJson({
          'user': {'id': 1, 'name': 'A', 'email': 'a@b.c'},
          'store': {
            'id': 42,
            'name': 'Rahman Pharmacy',
            'slug': 'rahman-pharmacy',
            'currency': 'BDT',
            ...store,
          },
          'permissions': <String>[],
        });

    test('reads the snake_case trial keys', () {
      final me = withStore({
        'trial_ends_at': '2026-09-28T23:59:59+06:00',
        'trial_days_left': 1,
      });

      expect(me.store!.trialDaysLeft, 1);
      expect(me.store!.trialEndsAt, isNotNull);
      expect(me.store!.trialEndingSoon, isTrue);
    });

    test('a shop with no clock is never ending', () {
      // The live server answers null for both on a platform-created shop.
      final me = withStore({'trial_ends_at': null, 'trial_days_left': null});

      expect(me.store!.trialEndsAt, isNull);
      expect(me.store!.trialEndingSoon, isFalse);
    });

    test('the clock survives the cache', () {
      final me = withStore({
        'trial_ends_at': '2026-09-28T23:59:59+06:00',
        'trial_days_left': 3,
      });
      final again = Me.fromJson(me.toJson());

      expect(again.store!.trialDaysLeft, 3);
      expect(again.store!.trialEndsAt, me.store!.trialEndsAt);
      expect(again.store!.trialEndingSoon, isFalse);
    });
  });

  group('the shapes that are easy to crash on', () {
    test('no store is a state, not a parse failure', () {
      final me = Me.fromJson({
        'user': {'id': 9, 'name': 'Rafi', 'email': 'r@x.test'},
        'store': null,
        'branch': null,
        'stores': [],
        'branches': [],
        'role': null,
        'permissions': [],
        'impersonating': false,
      });

      expect(me.hasStore, isFalse);
      expect(me.store, isNull);
      expect(me.role, isNull);
      expect(me.permissions.length, 0);
    });

    test('a super admin holds everything without listing it', () {
      final me = Me.fromJson({
        'user': {
          'id': 1,
          'name': 'Platform',
          'email': 'super@bizpos.test',
          'is_super_admin': true,
        },
        'permissions': <String>[],
      });

      expect(me.permissions.isSuperAdmin, isTrue);
      expect(me.permissions.has(P.adminStoreView), isTrue);
      expect(me.permissions.has(P.reportProfitView), isTrue);
    });

    test('login answers camelCase for the same field', () {
      // POST /auth/login says isSuperAdmin; /me says is_super_admin. One model
      // reads both, so neither response needs a second class.
      final result = LoginResult.fromJson({
        'token': '17|Xk2fQ9',
        'tokenType': 'Bearer',
        'expiresAt': '2026-12-12T10:00:00+06:00',
        'user': {
          'id': 4,
          'name': 'Karim',
          'email': 'cashier@rahman.test',
          'isSuperAdmin': false,
        },
      });

      expect(result.token, '17|Xk2fQ9');
      expect(result.user.isSuperAdmin, isFalse);
      expect(result.expiresAt?.year, 2026);
    });

    test('an impersonating super admin is flagged', () {
      final me = Me.fromJson({
        'user': {'id': 1, 'name': 'P', 'email': 'p@x.test', 'is_super_admin': true},
        'store': {'id': 3, 'name': 'Other Shop', 'slug': 'other', 'currency': 'BDT'},
        'permissions': <String>[],
        'impersonating': true,
      });

      expect(me.impersonating, isTrue);
    });
  });

  group('meta flags are tri-state', () {
    test('absent is not false', () {
      const meta = Meta({'total': 10});

      // Absent means the endpoint said nothing, so the permission decides. A
      // `false` here would hide buttons that actually work.
      expect(meta.flag('mayReturn'), isNull);
      expect(meta.flag('mayCollect'), isNull);
    });

    test('present false is a real denial', () {
      const meta = Meta({'mayReturn': false, 'mayCollect': true});

      expect(meta.flag('mayReturn'), isFalse);
      expect(meta.flag('mayCollect'), isTrue);
    });

    test('a cashier response hides cost without failing', () {
      // GET /products answers 0 for cost fields and says so in meta, rather
      // than refusing the call.
      const meta = Meta({'showCost': false, 'total': 311});

      expect(meta.flag('showCost'), isFalse);
      expect(meta.intValue('total'), 311);
    });
  });
}
