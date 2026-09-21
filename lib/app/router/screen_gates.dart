import 'package:flutter/material.dart';

import '../../core/permissions/permission_set.dart';
import '../../core/permissions/permissions.dart';
import '../../l10n/app_localizations.dart';

/// Every screen the app has, and the permission that unlocks it.
///
/// This is the role map in `docs/MOBILE-API.md` section 4, written as data. Both
/// the navigation shell and the route guards read it, so a menu entry and its
/// route can never disagree about who is allowed in — and a role's app is
/// described in one place instead of being scattered across widgets.
enum AppScreen {
  dashboard,
  pos,
  invoices,
  customers,
  products,
  packages,
  catalogue,
  suggestions,
  purchase,
  accounts,
  reports,
  team,
  platform,
}

/// The gate for one screen. [anyOf] means holding *any* of the listed
/// permissions opens it — which is how the doc phrases Dashboard, Invoices and
/// Reports.
class ScreenGate {
  const ScreenGate({
    required this.screen,
    required this.path,
    required this.icon,
    required this.anyOf,
  });

  final AppScreen screen;
  final String path;
  final IconData icon;
  final List<String> anyOf;

  bool isOpenTo(PermissionSet permissions) => permissions.hasAny(anyOf);

  String label(AppL10n l10n) => switch (screen) {
        AppScreen.dashboard => l10n.dashboard,
        AppScreen.pos => l10n.sell,
        AppScreen.invoices => l10n.invoices,
        AppScreen.customers => l10n.customers,
        AppScreen.products => l10n.products,
        AppScreen.packages => l10n.packages,
        AppScreen.catalogue => l10n.catalogue,
        AppScreen.suggestions => l10n.suggestions,
        AppScreen.purchase => l10n.purchase,
        AppScreen.accounts => l10n.accounts,
        AppScreen.reports => l10n.reports,
        AppScreen.team => l10n.team,
        AppScreen.platform => l10n.platform,
      };
}

/// In the order a person should meet them. A cashier's first tab is Sell; an
/// owner's is the dashboard. Both fall out of this one list plus the filter.
const List<ScreenGate> screenGates = [
  ScreenGate(
    screen: AppScreen.dashboard,
    path: '/dashboard',
    icon: Icons.insights_outlined,
    anyOf: [P.reportSalesView, P.inventoryStockView],
  ),
  ScreenGate(
    screen: AppScreen.pos,
    path: '/sell',
    icon: Icons.point_of_sale_outlined,
    anyOf: [P.posSaleCreate],
  ),
  ScreenGate(
    screen: AppScreen.invoices,
    path: '/invoices',
    icon: Icons.receipt_long_outlined,
    anyOf: [P.salesInvoiceView, P.salesInvoiceViewAll],
  ),
  ScreenGate(
    screen: AppScreen.customers,
    path: '/customers',
    icon: Icons.people_outline,
    anyOf: [P.customersCustomerView],
  ),
  ScreenGate(
    screen: AppScreen.products,
    path: '/products',
    icon: Icons.inventory_2_outlined,
    anyOf: [P.inventoryProductView],
  ),
  ScreenGate(
    screen: AppScreen.packages,
    path: '/packages',
    icon: Icons.widgets_outlined,
    anyOf: [P.inventoryPackageView],
  ),
  ScreenGate(
    screen: AppScreen.catalogue,
    path: '/catalogue',
    icon: Icons.menu_book_outlined,
    anyOf: [P.catalogProductSearch],
  ),
  ScreenGate(
    screen: AppScreen.suggestions,
    path: '/suggestions',
    icon: Icons.rule_outlined,
    anyOf: [P.catalogSuggestionReview],
  ),
  ScreenGate(
    screen: AppScreen.purchase,
    path: '/purchase',
    icon: Icons.local_shipping_outlined,
    anyOf: [P.purchaseBillView],
  ),
  ScreenGate(
    screen: AppScreen.accounts,
    path: '/accounts',
    icon: Icons.account_balance_wallet_outlined,
    anyOf: [P.accountsAccountView],
  ),
  ScreenGate(
    screen: AppScreen.reports,
    path: '/reports',
    icon: Icons.bar_chart_outlined,
    anyOf: [
      P.reportSalesView,
      P.reportProfitView,
      P.reportStockView,
      P.reportDueView,
    ],
  ),
  ScreenGate(
    screen: AppScreen.team,
    path: '/team',
    icon: Icons.badge_outlined,
    anyOf: [P.settingsStoreView],
  ),
  ScreenGate(
    screen: AppScreen.platform,
    path: '/platform',
    icon: Icons.apartment_outlined,
    anyOf: [P.adminStoreView],
  ),
];

/// The screens this person gets, in order.
List<ScreenGate> screensFor(PermissionSet permissions) =>
    screenGates.where((gate) => gate.isOpenTo(permissions)).toList();

ScreenGate gateFor(AppScreen screen) =>
    screenGates.firstWhere((gate) => gate.screen == screen);

ScreenGate? gateForPath(String path) {
  for (final gate in screenGates) {
    if (path == gate.path || path.startsWith('${gate.path}/')) return gate;
  }
  return null;
}
