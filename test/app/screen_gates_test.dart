import 'package:bizpos_app/app/router/screen_gates.dart';
import 'package:bizpos_app/core/permissions/permission_set.dart';
import 'package:bizpos_app/core/permissions/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/role_fixtures.dart';

/// The role-wise app map from `docs/MOBILE-API.md` section 4, made executable.
///
/// One build serves seven roles, and the only thing deciding what each one sees
/// is the permission list. If anyone ever reaches for `role.name` instead, a
/// role whose permissions were trimmed keeps its full menu — and this test
/// fails immediately.
void main() {
  List<AppScreen> screensOf(PermissionSet permissions) =>
      screensFor(permissions).map((gate) => gate.screen).toList();

  group('each role gets exactly its own screens', () {
    test('store owner gets the whole app except the platform section', () {
      expect(screensOf(Roles.set(Roles.owner)), [
        AppScreen.dashboard,
        AppScreen.pos,
        AppScreen.invoices,
        AppScreen.customers,
        AppScreen.products,
        AppScreen.packages,
        AppScreen.catalogue,
        AppScreen.suggestions,
        AppScreen.purchase,
        AppScreen.accounts,
        AppScreen.reports,
        AppScreen.team,
      ]);
    });

    test('manager matches the owner: losing profit keeps the Reports tab', () {
      // The tab is gated on *any* report permission, and a manager still has
      // sales, stock and dues — only the profit tab inside it disappears.
      expect(
        screensOf(Roles.set(Roles.manager)),
        screensOf(Roles.set(Roles.owner)),
      );
    });

    test('cashier gets a counter app and nothing else', () {
      expect(screensOf(Roles.set(Roles.cashier)), [
        AppScreen.dashboard,
        AppScreen.pos,
        AppScreen.invoices,
        AppScreen.customers,
        AppScreen.products,
        AppScreen.packages,
        AppScreen.catalogue,
      ]);
    });

    test('stock keeper gets an inventory app: no sales, no customers', () {
      expect(screensOf(Roles.set(Roles.stockKeeper)), [
        AppScreen.dashboard,
        AppScreen.products,
        AppScreen.packages,
        AppScreen.catalogue,
        AppScreen.purchase,
        AppScreen.reports,
      ]);
    });

    test('accountant gets a money app: no POS, no packages', () {
      expect(screensOf(Roles.set(Roles.accountant)), [
        AppScreen.dashboard,
        AppScreen.invoices,
        AppScreen.customers,
        AppScreen.products,
        AppScreen.purchase,
        AppScreen.accounts,
        AppScreen.reports,
      ]);
    });

    test('auditor gets the owner screens minus selling', () {
      expect(screensOf(Roles.set(Roles.auditor)), [
        AppScreen.dashboard,
        AppScreen.invoices,
        AppScreen.customers,
        AppScreen.products,
        AppScreen.packages,
        AppScreen.catalogue,
        AppScreen.purchase,
        AppScreen.accounts,
        AppScreen.reports,
        AppScreen.team,
      ]);
    });

    test('super admin gets everything, including the platform section', () {
      final screens = screensOf(Roles.superAdmin);
      expect(screens, hasLength(AppScreen.values.length));
      expect(screens, contains(AppScreen.platform));
    });
  });

  group('the first screen a role lands on', () {
    test('a cashier opens on the dashboard tile row, then Sell', () {
      final cashier = screensFor(Roles.set(Roles.cashier));
      expect(cashier.first.screen, AppScreen.dashboard);
      expect(cashier[1].screen, AppScreen.pos);
    });

    test('a stock keeper never sees a Sell tab', () {
      expect(
        screensOf(Roles.set(Roles.stockKeeper)),
        isNot(contains(AppScreen.pos)),
      );
    });

    test('nobody but a super admin sees the platform section', () {
      for (final role in [
        Roles.owner,
        Roles.manager,
        Roles.cashier,
        Roles.stockKeeper,
        Roles.accountant,
        Roles.auditor,
      ]) {
        expect(
          screensOf(Roles.set(role)),
          isNot(contains(AppScreen.platform)),
        );
      }
    });
  });

  group('a single revoked permission changes the app, not the role name', () {
    test('an owner without pos.sale.create loses the Sell tab', () {
      final trimmed =
          Roles.owner.where((p) => p != P.posSaleCreate).toList();

      // The role is still "store_owner" server-side. Only the list changed.
      expect(screensOf(Roles.set(trimmed)), isNot(contains(AppScreen.pos)));
      expect(screensOf(Roles.set(trimmed)), contains(AppScreen.invoices));
    });

    test('a person with no permissions at all gets no tabs', () {
      expect(screensOf(const PermissionSet.empty()), isEmpty);
    });
  });

  group('gates and routes cannot disagree', () {
    test('every screen has a gate, a path and an icon', () {
      expect(screenGates, hasLength(AppScreen.values.length));
      for (final screen in AppScreen.values) {
        final gate = gateFor(screen);
        expect(gate.anyOf, isNotEmpty, reason: '${screen.name} has no gate');
        expect(gate.path, startsWith('/'));
      }
    });

    test('paths are unique', () {
      final paths = screenGates.map((g) => g.path).toSet();
      expect(paths, hasLength(screenGates.length));
    });

    test('a path resolves back to its gate, including sub-routes', () {
      expect(gateForPath('/sell')?.screen, AppScreen.pos);
      expect(gateForPath('/invoices/5521')?.screen, AppScreen.invoices);
      expect(gateForPath('/profile'), isNull);
    });

    test('no gate is built on a permission the API cannot serve yet', () {
      // Section 7 lists permissions with no endpoint. A screen for one of them
      // would be a dead end, so none may appear in the gate table.
      const noEndpoint = {
        P.posSaleVoid,
        P.inventoryProductCreate,
        P.inventoryTransferCreate,
        P.accountsClosingManage,
        P.reportVatView,
        P.settingsApikeyManage,
        P.adminPlanManage,
      };

      for (final gate in screenGates) {
        expect(
          gate.anyOf.where(noEndpoint.contains),
          isEmpty,
          reason: '${gate.screen.name} is gated on an endpoint-less permission',
        );
      }
    });
  });
}
