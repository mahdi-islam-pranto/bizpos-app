import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/shell_nav.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../pos/data/pos_models.dart' show PosLookups;
import '../../pos/data/pos_repository.dart' show posLookupsProvider;
import '../../products/data/product_models.dart' show ProductStats;
import '../../products/data/products_repository.dart' show productStatsProvider;
import '../../reports/ui/figures.dart';
import '../../reports/ui/reports_screen.dart' show methodLabel;
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

/// The first screen of an owner's, manager's, accountant's or auditor's day,
/// and a smaller one for the counter and the stockroom.
///
/// `GET /dashboard` needs `report.sales.view`. A cashier or stock keeper opens
/// this screen on `inventory.stock.view` alone, so they get what the doc gives
/// them instead: `GET /products/stats` and, at the till, the open drawer.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    return permissions.has(P.reportSalesView)
        ? const _OwnerDashboard()
        : const _CounterDashboard();
  }
}

class _OwnerDashboard extends ConsumerStatefulWidget {
  const _OwnerDashboard();

  @override
  ConsumerState<_OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<_OwnerDashboard> {
  DashboardQuery _query = const DashboardQuery(DashboardRange.today);

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      initialDateRange:
          _query.range == DashboardRange.custom &&
              _query.from != null &&
              _query.to != null
          ? DateTimeRange(start: _query.from!, end: _query.to!)
          : DateTimeRange(
              start: today.subtract(const Duration(days: 6)),
              end: today,
            ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _query = DashboardQuery(
        DashboardRange.custom,
        from: picked.start,
        to: picked.end,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final dashboard = ref.watch(dashboardProvider(_query));

    String rangeLabel(DashboardRange r) => switch (r) {
      DashboardRange.today => l10n.today,
      DashboardRange.yesterday => l10n.yesterday,
      DashboardRange.d7 => l10n.lastDays(7),
      DashboardRange.d15 => l10n.lastDays(15),
      DashboardRange.m1 => l10n.lastMonths(1),
      DashboardRange.m2 => l10n.lastMonths(2),
      DashboardRange.custom => l10n.customRange,
    };

    return Scaffold(
      appBar: ShellAppBar(title: Text(l10n.dashboard)),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
              children: [
                for (final r in DashboardRange.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.s8),
                    child: ChoiceChip(
                      label: Text(rangeLabel(r)),
                      selected: _query.range == r,
                      onSelected: (_) {
                        if (r == DashboardRange.custom) {
                          _pickCustom();
                        } else {
                          setState(() => _query = DashboardQuery(r));
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<Dashboard>(
              value: dashboard,
              onRetry: () => ref.invalidate(dashboardProvider(_query)),
              builder: (context, d) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(dashboardProvider(_query)),
                child: _DashboardBody(dashboard: d),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final permissions = ref.watch(permissionsProvider);
    final d = dashboard;

    Widget section(
      String title,
      Object? data,
      Widget Function() build, {
      ReportScope? scope,
    }) => ReportSection(
      title: title,
      scope: scope,
      child: data == null ? const LockedSection() : build(),
    );

    final window = d.window;
    final windowText = [
      if (window.from != null) AppDates.day(window.from, locale: locale),
      if (window.to != null && window.to != window.from)
        AppDates.day(window.to, locale: locale),
    ].join(' – ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.gutter,
        0,
        Insets.gutter,
        Insets.s32,
      ),
      children: [
        if (windowText.isNotEmpty)
          Text(
            windowText,
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
        if (window.capped)
          Padding(
            padding: const EdgeInsets.only(top: Insets.s4),
            child: Text(
              l10n.rangeCapped(DashboardQuery.maxDays),
              style: text.bodySmall?.copyWith(color: palette.warning),
            ),
          ),

        // The headline. Profit is locked, not zero, for a manager.
        section(l10n.headline, d.headline, () {
          final h = d.headline!;
          return FigureGrid([
            Figure(l10n.revenue, money.format(h.revenue)),
            Figure(l10n.invoices, '${h.invoices}'),
            Figure(l10n.averageSale, money.format(h.averageSale)),
            Figure(
              l10n.grossProfit,
              money.format(h.grossProfit),
              locked: h.grossProfit == null,
            ),
            Figure(
              l10n.netProfit,
              money.format(h.netProfit),
              locked: h.netProfit == null,
              tone: (h.netProfit ?? 0) < 0 ? palette.danger : palette.positive,
            ),
            Figure(l10n.expensesLabel, money.format(h.expenses)),
            Figure(l10n.discountGiven, money.format(h.discountGiven)),
            Figure(
              l10n.dueRaised,
              money.format(h.dueRaised),
              tone: h.dueRaised > 0 ? palette.warning : null,
            ),
            Figure(l10n.returnsLabel, money.format(h.returned)),
          ]);
        }, scope: ReportScope.branch),

        if (d.daily != null && d.daily!.length > 1)
          ReportSection(
            title: l10n.dailySales,
            child: RowsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Insets.s12),
                  child: TrendBars(
                    points: [for (final day in d.daily!) (day.date, day.sales)],
                    format: money.format,
                    dayLabel: (day) => bucketLabel(day, locale),
                  ),
                ),
              ],
            ),
          ),

        section(l10n.moneyIn, d.collections, () {
          final c = d.collections!;
          final methods = c.byMethod.fold<num>(0, (s, m) => s + m.total);
          return RowsCard(
            children: [
              FigureRow(
                label: l10n.collectedTotal,
                value: money.format(c.total),
                tone: palette.positive,
              ),
              FigureRow(
                label: l10n.onTodaysBills,
                value: money.format(c.onSales),
              ),
              FigureRow(label: l10n.onOldDues, value: money.format(c.onDues)),
              if (c.onPreviousDue > 0)
                FigureRow(
                  label: l10n.onPreviousDue,
                  value: money.format(c.onPreviousDue),
                ),
              for (final m in c.byMethod)
                FigureRow(
                  label: methodLabel(l10n, m.label),
                  value: money.format(m.total),
                  share: shareOf(m.total, methods),
                ),
            ],
          );
        }),

        if (d.payments != null && d.payments!.isNotEmpty)
          ReportSection(
            title: l10n.billsSettledBy,
            child: RowsCard(
              children: [
                for (final m in d.payments!)
                  FigureRow(
                    label: methodLabel(l10n, m.label),
                    value: money.format(m.total),
                    share: shareOf(
                      m.total,
                      d.payments!.fold<num>(0, (s, p) => s + p.total),
                    ),
                  ),
              ],
            ),
          ),

        section(l10n.capital, d.capital, () {
          final c = d.capital!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FigureGrid([
                Figure(l10n.stockAtCost, money.format(c.stock)),
                Figure(l10n.receivable, money.format(c.receivable)),
                Figure(l10n.inAccounts, money.format(c.inAccounts)),
                Figure(l10n.payable, money.format(c.payable)),
                Figure(l10n.invested, money.format(c.invested)),
                Figure(
                  l10n.netWorth,
                  money.format(c.net),
                  tone: c.net < 0 ? palette.danger : null,
                ),
              ]),
              if (c.accounts.isNotEmpty) ...[
                const SizedBox(height: Insets.s8),
                RowsCard(
                  children: [
                    for (final a in c.accounts)
                      FigureRow(label: a.label, value: money.format(a.total)),
                  ],
                ),
              ],
            ],
          );
        }, scope: ReportScope.store),

        if (d.topProducts != null)
          ReportSection(
            title: l10n.topProducts,
            child: d.topProducts!.isEmpty
                ? SectionEmpty(l10n.nothingSold)
                : RowsCard(
                    children: [
                      for (final p in d.topProducts!)
                        FigureRow(
                          label: p.name,
                          detail: [
                            l10n.qtySold(qtyText(p.qty)),
                            if (p.profit != null)
                              '${l10n.profit} ${money.format(p.profit)}',
                          ].join(' · '),
                          value: money.format(p.revenue),
                        ),
                    ],
                  ),
          ),

        if (d.movers != null) ..._movers(context, d.movers!, l10n, palette),

        if (d.staff != null && d.staff!.isNotEmpty)
          ReportSection(
            title: l10n.byStaff,
            child: RowsCard(
              children: [
                for (final s in d.staff!)
                  FigureRow(
                    label: s.name,
                    detail: [
                      l10n.salesCount(s.invoices),
                      if (s.discount > 0)
                        '${l10n.discount} ${money.format(s.discount)}',
                      if (s.dueRaised > 0)
                        '${l10n.dueLabel} ${money.format(s.dueRaised)}',
                    ].join(' · '),
                    value: money.format(s.revenue),
                  ),
              ],
            ),
          ),

        section(l10n.dues, d.dues, () {
          final due = d.dues!;
          final mayOpen = permissions.has(P.customersCustomerView);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FigureGrid([
                Figure(
                  l10n.owedToShop,
                  money.format(due.receivableTotal),
                  tone: due.receivableTotal > 0 ? palette.warning : null,
                ),
                Figure(l10n.owedToSuppliers, money.format(due.payableTotal)),
              ]),
              if (due.customers.isNotEmpty) ...[
                const SizedBox(height: Insets.s8),
                RowsCard(
                  children: [
                    for (final c in due.customers.take(5))
                      FigureRow(
                        label: c.name,
                        detail: c.phone,
                        value: money.format(c.due),
                        tone: palette.warning,
                        onTap: mayOpen && c.id != null
                            ? () => context.go('/customers/${c.id}')
                            : null,
                      ),
                  ],
                ),
              ],
              if (due.suppliers.isNotEmpty) ...[
                const SizedBox(height: Insets.s8),
                RowsCard(
                  children: [
                    for (final s in due.suppliers.take(5))
                      FigureRow(
                        label: s.name,
                        detail: l10n.supplier,
                        value: money.format(s.due),
                      ),
                  ],
                ),
              ],
            ],
          );
        }, scope: ReportScope.store),

        section(l10n.expensesLabel, d.expenses, () {
          final e = d.expenses!;
          return RowsCard(
            children: [
              FigureRow(label: l10n.total, value: money.format(e.total)),
              for (final c in e.byCategory)
                FigureRow(
                  label: c.label,
                  detail: c.count == null ? null : l10n.timesCount(c.count!),
                  value: money.format(c.total),
                  share: shareOf(c.total, e.total),
                ),
            ],
          );
        }, scope: ReportScope.store),

        section(l10n.purchase, d.purchases, () {
          final p = d.purchases!;
          return FigureGrid([
            Figure(l10n.billsCount(p.count), money.format(p.total)),
            Figure(
              l10n.owedToSuppliers,
              money.format(p.due),
              tone: p.due > 0 ? palette.warning : null,
            ),
          ]);
        }),

        section(l10n.stockOnHand, d.stock, () {
          final s = d.stock!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FigureGrid([
                if (s.value != null)
                  Figure(l10n.stockValue, money.format(s.value)),
                Figure(l10n.unitsOnHand, qtyText(s.units)),
                Figure(
                  l10n.outOfStock,
                  '${s.outOfStock}',
                  tone: s.outOfStock > 0 ? palette.danger : null,
                ),
              ]),
              if (s.low.isNotEmpty) ...[
                const SizedBox(height: Insets.s8),
                RowsCard(
                  children: stockLineRows(
                    context,
                    s.low.take(5).toList(),
                    value: (l) => qtyText(l.qty ?? 0),
                    detail: (_) => l10n.lowStock,
                    tone: palette.warning,
                  ),
                ),
              ],
              if (s.expiring.isNotEmpty) ...[
                const SizedBox(height: Insets.s8),
                RowsCard(
                  children: stockLineRows(
                    context,
                    s.expiring.take(5).toList(),
                    value: (l) => AppDates.day(l.expiresAt, locale: locale),
                    detail: (_) => l10n.expiringSoon,
                    tone: palette.danger,
                  ),
                ),
              ],
            ],
          );
        }, scope: ReportScope.branch),

        if (d.shifts != null && d.shifts!.isNotEmpty)
          ReportSection(
            title: l10n.cashDrawers,
            child: RowsCard(
              children: [
                for (final s in d.shifts!)
                  FigureRow(
                    label: [
                      AppDates.stamp(s.openedAt, locale: locale),
                      ?s.userName,
                    ].join(' · '),
                    detail: s.closedAt == null
                        ? l10n.drawerOpen
                        : '${l10n.expectedCash} ${money.format(s.expected)}'
                              ' · ${l10n.countedLabel} ${money.format(s.counted)}',
                    value: s.difference == null || s.closedAt == null
                        ? money.format(s.sold ?? 0)
                        : s.difference == 0
                        ? l10n.balanced
                        : s.difference! < 0
                        ? l10n.shortBy(money.format(-s.difference!))
                        : l10n.overBy(money.format(s.difference)),
                    tone: (s.difference ?? 0) < 0 && s.closedAt != null
                        ? palette.danger
                        : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// What to buy and what to stop buying. `restock` first: it is the only
  /// list with a deadline on it.
  List<Widget> _movers(
    BuildContext context,
    Movers m,
    AppL10n l10n,
    AppPalette palette,
  ) {
    String change(Mover r) {
      if (r.changePercent == null) {
        return r.verdict == 'stopped' ? l10n.moverStopped : l10n.moverNew;
      }
      final p = r.changePercent!;
      return '${p > 0 ? '+' : ''}${p.toStringAsFixed(0)}%';
    }

    String pace(Mover r) => [
      if (r.perDay != null) l10n.perDay(qtyText(r.perDay!)),
      if (r.onHand != null) l10n.onHand(qtyText(r.onHand!)),
      if (r.daysCover != null) l10n.daysCover(qtyText(r.daysCover!)),
    ].join(' · ');

    return [
      if (m.restock != null && m.restock!.isNotEmpty)
        ReportSection(
          title: l10n.restockSoon,
          child: RowsCard(
            children: [
              for (final r in m.restock!)
                FigureRow(
                  label: r.name,
                  detail: pace(r),
                  value: r.daysCover == null
                      ? qtyText(r.onHand ?? 0)
                      : l10n.daysLeft(qtyText(r.daysCover!)),
                  tone: palette.danger,
                ),
            ],
          ),
        ),
      if (m.rising.isNotEmpty)
        ReportSection(
          title: l10n.rising,
          child: RowsCard(
            children: [
              for (final r in m.rising.take(8))
                FigureRow(
                  label: r.name,
                  detail: pace(r),
                  value: change(r),
                  tone: palette.positive,
                ),
            ],
          ),
        ),
      if (m.falling.isNotEmpty)
        ReportSection(
          title: l10n.falling,
          child: RowsCard(
            children: [
              for (final r in m.falling.take(8))
                FigureRow(
                  label: r.name,
                  detail: pace(r),
                  value: change(r),
                  tone: palette.warning,
                ),
            ],
          ),
        ),
    ];
  }
}

/// The cashier's and stock keeper's version: the shelf's alerts, and the
/// drawer when this person works the till.
class _CounterDashboard extends ConsumerWidget {
  const _CounterDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final permissions = ref.watch(permissionsProvider);
    final atTill = permissions.has(P.posSaleCreate);
    final stats = ref.watch(productStatsProvider);

    return Scaffold(
      appBar: ShellAppBar(title: Text(l10n.dashboard)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productStatsProvider);
          if (atTill) ref.invalidate(posLookupsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.gutter,
            0,
            Insets.gutter,
            Insets.s32,
          ),
          children: [
            if (atTill) const _DrawerCard(),
            ReportSection(
              title: l10n.stockOnHand,
              scope: ReportScope.branch,
              child: switch (stats) {
                AsyncData(:final value) => _StatsBody(stats: value),
                AsyncError(:final error) => _InlineError(
                  error: error,
                  onRetry: () => ref.invalidate(productStatsProvider),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(Insets.s24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A failure inside one section: the rest of the page still stands, so the
/// error takes a row, not the screen.
class _InlineError extends StatelessWidget {
  const _InlineError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    if (error is CancelledException) {
      return const Padding(
        padding: EdgeInsets.all(Insets.s24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final retryable = error is! ForbiddenException;
    return RowsCard(
      children: [
        ListTile(
          leading: Icon(
            retryable ? Icons.error_outline : Icons.lock_outline,
            color: palette.muted,
          ),
          title: Text(
            error is ApiException
                ? (error as ApiException).message
                : l10n.genericError,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: retryable
              ? TextButton(onPressed: onRetry, child: Text(l10n.retry))
              : null,
        ),
      ],
    );
  }
}

class _DrawerCard extends ConsumerWidget {
  const _DrawerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final lookups = ref.watch(posLookupsProvider);

    final PosLookups? data = lookups.value;
    final shift = data?.shift;

    return ReportSection(
      title: l10n.cashDrawer,
      child: RowsCard(
        children: [
          if (lookups.isLoading && data == null)
            const LinearProgressIndicator()
          else if (lookups.hasError && data == null)
            FigureRow(label: l10n.genericError, value: '')
          else
            FigureRow(
              label: shift == null ? l10n.drawerClosed : l10n.drawerOpen,
              detail: shift == null
                  ? l10n.drawerClosedBody
                  : l10n.openedAt(
                      AppDates.stamp(shift.openedAt, locale: locale),
                    ),
              value: shift == null ? '' : money.format(shift.openingCash),
              tone: shift == null ? palette.muted : palette.positive,
              onTap: () => context.go('/sell'),
            ),
        ],
      ),
    );
  }
}

class _StatsBody extends ConsumerWidget {
  const _StatsBody({required this.stats});

  final ProductStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FigureGrid([
          Figure(l10n.products, '${stats.active}'),
          Figure(
            l10n.lowStock,
            '${stats.lowCount}',
            tone: stats.lowCount > 0 ? palette.warning : null,
          ),
          Figure(
            l10n.expiringSoon,
            '${stats.expiringCount}',
            tone: stats.expiringCount > 0 ? palette.danger : null,
          ),
          // A cashier's stock value is not a figure, it is a hidden one.
          if (stats.canSeeCost && stats.stockValue != null)
            Figure(l10n.stockValue, money.format(stats.stockValue)),
        ]),
        ReportSection(
          title: l10n.lowStock,
          child: stats.low.isEmpty
              ? SectionEmpty(l10n.nothingLow)
              : RowsCard(
                  children: [
                    for (final a in stats.low)
                      FigureRow(
                        label: a.name,
                        detail: a.minimum == null
                            ? null
                            : l10n.minimumIs(qtyText(a.minimum!)),
                        value: qtyText(a.quantity ?? 0),
                        tone: palette.warning,
                      ),
                  ],
                ),
        ),
        ReportSection(
          title: l10n.expiringSoon,
          child: stats.expiring.isEmpty
              ? SectionEmpty(l10n.nothingExpiring)
              : RowsCard(
                  children: [
                    for (final a in stats.expiring)
                      FigureRow(
                        label: a.name,
                        detail: a.quantity == null
                            ? null
                            : l10n.onHand(qtyText(a.quantity!)),
                        value: AppDates.day(a.expiresAt, locale: locale),
                        tone: palette.danger,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
