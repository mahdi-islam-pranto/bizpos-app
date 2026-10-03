import 'package:bizpos_app/app/router/app_shell.dart';
import 'package:bizpos_app/app/router/screen_gates.dart';
import 'package:bizpos_app/app/router/shell_nav.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/role_fixtures.dart';

/// The bottom bar and the Back button, which together replaced "More".
void main() {
  List<AppScreen> tabsOf(List<String> role) =>
      AppShell.tabsFor(screensFor(Roles.set(role)))
          .map((gate) => gate.screen)
          .toList();

  group('the bottom bar', () {
    test('an owner gets four screens and then Products', () {
      expect(tabsOf(Roles.owner), [
        AppScreen.pos,
        AppScreen.dashboard,
        AppScreen.invoices,
        AppScreen.customers,
        AppScreen.products,
      ]);
    });

    test('Products is not doubled when it is already among the first four', () {
      final tabs = tabsOf(Roles.stockKeeper);
      expect(tabs.where((s) => s == AppScreen.products), hasLength(1));
      expect(tabs, hasLength(AppShell.maxTabs));
    });

    test('never more than five tabs', () {
      for (final role in [
        Roles.owner,
        Roles.manager,
        Roles.cashier,
        Roles.stockKeeper,
        Roles.accountant,
        Roles.auditor,
      ]) {
        expect(tabsOf(role).length, lessThanOrEqualTo(AppShell.maxTabs));
      }
    });
  });

  group('Back', () {
    test('walks back through the pages visited', () {
      final history = NavHistory()
        ..startFrom('/sell')
        ..record('/invoices')
        ..record('/invoices/12')
        ..record('/customers/4');

      expect(history.popBack(), '/invoices/12');
      expect(history.popBack(), '/invoices');
      expect(history.popBack(), '/sell');
      expect(history.popBack(), isNull);
    });

    test('a menu choice starts again from home', () {
      final history = NavHistory()
        ..startFrom('/sell')
        ..record('/invoices')
        ..record('/invoices/12');

      history
        ..startFrom('/sell')
        ..record('/accounts');

      expect(history.popBack(), '/sell');
      expect(history.canGoBack, isFalse);
    });

    test('returning to the page below is a pop, not a new visit', () {
      final history = NavHistory()
        ..startFrom('/sell')
        ..record('/profile')
        ..record('/devices')
        ..record('/profile');

      expect(history.popBack(), '/sell');
    });

    test('leaving the shell forgets everything', () {
      final history = NavHistory()
        ..startFrom('/sell')
        ..record('/invoices')
        ..record('/login');

      expect(history.canGoBack, isFalse);
      expect(history.popBack(), isNull);
    });
  });
}
