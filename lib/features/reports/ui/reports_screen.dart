import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/report_models.dart';
import '../data/reports_repository.dart';
import 'figures.dart';

enum ReportTab { sales, profit, stock, dues }

/// The four reports, one tab each, each behind its own permission.
///
/// A manager has no profit tab; a stock keeper has only stock. Every tab is
/// its own provider, so a 403 on one never takes the others down with it.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _days = 30;

  static const _windows = [7, 30, 90];

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final permissions = ref.watch(permissionsProvider);

    final tabs = [
      if (permissions.has(P.reportSalesView)) ReportTab.sales,
      if (permissions.has(P.reportProfitView)) ReportTab.profit,
      if (permissions.has(P.reportStockView)) ReportTab.stock,
      if (permissions.has(P.reportDueView)) ReportTab.dues,
    ];

    String label(ReportTab tab) => switch (tab) {
          ReportTab.sales => l10n.reportSales,
          ReportTab.profit => l10n.reportProfit,
          ReportTab.stock => l10n.reportStock,
          ReportTab.dues => l10n.reportDues,
        };

    final windowed = tabs.contains(ReportTab.sales) ||
        tabs.contains(ReportTab.profit);

    return DefaultTabController(
      // Keyed on the tab list: a permission change mid-session would otherwise
      // leave a controller with the wrong number of tabs.
      key: ValueKey(tabs.length),
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.reports),
          actions: [
            if (windowed)
              PopupMenuButton<int>(
                tooltip: l10n.reportWindow,
                initialValue: _days,
                onSelected: (d) => setState(() => _days = d),
                itemBuilder: (_) => [
                  for (final d in _windows)
                    PopupMenuItem(value: d, child: Text(l10n.lastDays(d))),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.s16),
                  child: Row(
                    children: [
                      Text(l10n.lastDays(_days)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
          ],
          bottom: tabs.length < 2
              ? null
              : TabBar(
                  isScrollable: tabs.length > 3,
                  tabs: [for (final t in tabs) Tab(text: label(t))],
                ),
        ),
        body: tabs.isEmpty
            ? const SizedBox.shrink()
            : TabBarView(
                children: [
                  for (final t in tabs)
                    switch (t) {
                      ReportTab.sales => _SalesTab(days: _days),
                      ReportTab.profit => _ProfitTab(days: _days),
                      ReportTab.stock => const _StockTab(),
                      ReportTab.dues => const _DuesTab(),
                    },
                ],
              ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.onRefresh, required this.children});

  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.gutter,
            Insets.s8,
            Insets.gutter,
            Insets.s32,
          ),
          children: children,
        ),
      );
}

class _SalesTab extends ConsumerWidget {
  const _SalesTab({required this.days});

  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final report = ref.watch(salesReportProvider(days));

    return AsyncView<SalesReport>(
      value: report,
      onRetry: () => ref.invalidate(salesReportProvider(days)),
      builder: (context, r) {
        final methodTotal = r.byMethod.fold<num>(0, (s, m) => s + m.total);
        final userTotal = r.byUser.fold<num>(0, (s, m) => s + m.total);
        return _Page(
          onRefresh: () async => ref.invalidate(salesReportProvider(days)),
          children: [
            ReportSection(
              title: l10n.lastDays(days),
              scope: ReportScope.branch,
              child: FigureGrid([
                Figure(l10n.revenue, money.format(r.total)),
                Figure(l10n.invoices, '${r.count}'),
                Figure(
                  l10n.averageSale,
                  money.format(r.count == 0 ? 0 : r.total / r.count),
                ),
              ]),
            ),
            if (r.daily.isNotEmpty)
              ReportSection(
                title: l10n.dailySales,
                child: RowsCard(children: [
                  Padding(
                    padding: const EdgeInsets.all(Insets.s12),
                    child: TrendBars(
                      points: [for (final d in r.daily) (d.date, d.total)],
                      format: money.format,
                      dayLabel: (d) => bucketLabel(d, locale),
                    ),
                  ),
                ]),
              ),
            ReportSection(
              title: l10n.topProducts,
              child: r.topProducts.isEmpty
                  ? SectionEmpty(l10n.nothingSold)
                  : RowsCard(children: [
                      for (final p in r.topProducts)
                        FigureRow(
                          label: p.name,
                          detail: [
                            l10n.qtySold(qtyText(p.qty)),
                            if (r.showProfit && p.profit != null)
                              '${l10n.profit} ${money.format(p.profit)}',
                          ].join(' · '),
                          value: money.format(p.revenue),
                        ),
                    ]),
            ),
            if (r.byMethod.isNotEmpty)
              ReportSection(
                title: l10n.byMethod,
                child: RowsCard(children: [
                  for (final m in r.byMethod)
                    FigureRow(
                      label: methodLabel(l10n, m.label),
                      value: money.format(m.total),
                      share: shareOf(m.total, methodTotal),
                    ),
                ]),
              ),
            if (r.byUser.isNotEmpty)
              ReportSection(
                title: l10n.byStaff,
                child: RowsCard(children: [
                  for (final u in r.byUser)
                    FigureRow(
                      label: u.label,
                      detail: u.count == null ? null : l10n.salesCount(u.count!),
                      value: money.format(u.total),
                      share: shareOf(u.total, userTotal),
                    ),
                ]),
              ),
          ],
        );
      },
    );
  }
}

class _ProfitTab extends ConsumerWidget {
  const _ProfitTab({required this.days});

  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final report = ref.watch(profitReportProvider(days));

    return AsyncView<ProfitReport>(
      value: report,
      onRetry: () => ref.invalidate(profitReportProvider(days)),
      builder: (context, r) => _Page(
        onRefresh: () async => ref.invalidate(profitReportProvider(days)),
        children: [
          ReportSection(
            title: l10n.lastDays(days),
            scope: ReportScope.mixed,
            child: FigureGrid([
              Figure(
                l10n.netProfit,
                money.format(r.netProfit),
                tone: r.netProfit < 0 ? palette.danger : palette.positive,
              ),
              Figure(l10n.marginLabel, '${_pct(r.margin)}%'),
            ]),
          ),
          // Laid out as the sum it is, so the scope of each line sits beside
          // it: the first two are this branch, the rest the whole store.
          ReportSection(
            title: l10n.howItAddsUp,
            child: RowsCard(children: [
              FigureRow(
                label: l10n.revenue,
                detail: l10n.scopeBranch,
                value: money.format(r.revenue),
              ),
              FigureRow(
                label: l10n.costOfGoods,
                detail: l10n.scopeBranch,
                value: '−${money.format(r.cost)}',
              ),
              FigureRow(
                label: l10n.returnsLabel,
                detail: l10n.scopeStore,
                value: '−${money.format(r.returnTotal)}',
              ),
              FigureRow(
                label: l10n.grossProfit,
                value: money.format(r.grossProfit),
                tone: r.grossProfit < 0 ? palette.danger : null,
              ),
              FigureRow(
                label: l10n.expensesLabel,
                detail: l10n.scopeStore,
                value: '−${money.format(r.expenses)}',
              ),
              FigureRow(
                label: l10n.netProfit,
                value: money.format(r.netProfit),
                tone: r.netProfit < 0 ? palette.danger : palette.positive,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _StockTab extends ConsumerWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final report = ref.watch(stockReportProvider);

    return AsyncView<StockReport>(
      value: report,
      onRetry: () => ref.invalidate(stockReportProvider),
      builder: (context, r) => _Page(
        onRefresh: () async => ref.invalidate(stockReportProvider),
        children: [
          ReportSection(
            title: l10n.stockOnHand,
            scope: ReportScope.branch,
            child: FigureGrid([
              if (r.stockValue != null)
                Figure(l10n.stockValue, money.format(r.stockValue)),
              Figure(l10n.unitsOnHand, qtyText(r.totalUnits)),
            ]),
          ),
          ReportSection(
            title: l10n.lowStock,
            child: r.low.isEmpty
                ? SectionEmpty(l10n.nothingLow)
                : RowsCard(
                    children: stockLineRows(
                      context,
                      r.low,
                      value: (l) => qtyText(l.qty ?? 0),
                      detail: (l) => l.minimum == null
                          ? null
                          : l10n.minimumIs(qtyText(l.minimum!)),
                      tone: palette.warning,
                    ),
                  ),
          ),
          ReportSection(
            title: l10n.expiringSoon,
            child: r.expiring.isEmpty
                ? SectionEmpty(l10n.nothingExpiring)
                : RowsCard(
                    children: stockLineRows(
                      context,
                      r.expiring,
                      value: (l) => AppDates.day(l.expiresAt, locale: locale),
                      detail: (l) =>
                          l.qty == null ? null : l10n.onHand(qtyText(l.qty!)),
                      tone: palette.danger,
                    ),
                  ),
          ),
          ReportSection(
            title: l10n.deadStock,
            child: r.dead.isEmpty
                ? SectionEmpty(l10n.nothingDead)
                : RowsCard(
                    children: stockLineRows(
                      context,
                      r.dead,
                      value: (l) => qtyText(l.qty ?? 0),
                      detail: (l) => l.value == null
                          ? null
                          : '${l10n.stockValue} ${money.format(l.value)}',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DuesTab extends ConsumerWidget {
  const _DuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final report = ref.watch(duesReportProvider);

    return AsyncView<List<DueRow>>(
      value: report,
      onRetry: () => ref.invalidate(duesReportProvider),
      builder: (context, rows) {
        final total = rows.fold<num>(0, (s, r) => s + r.due);
        return _Page(
          onRefresh: () async => ref.invalidate(duesReportProvider),
          children: [
            ReportSection(
              title: l10n.owedToShop,
              scope: ReportScope.store,
              child: FigureGrid([
                Figure(
                  l10n.owedToShop,
                  money.format(total),
                  tone: total > 0 ? palette.warning : null,
                ),
                Figure(l10n.customers, '${rows.length}'),
              ]),
            ),
            ReportSection(
              title: l10n.whoOwes,
              child: rows.isEmpty
                  ? SectionEmpty(l10n.nobodyOwes)
                  : RowsCard(children: [
                      for (final r in rows)
                        FigureRow(
                          label: r.name,
                          detail: [
                            ?r.phone,
                            if (r.ageDays != null) l10n.daysOld(r.ageDays!),
                            if (r.overLimit) l10n.overCreditLimit,
                          ].join(' · '),
                          value: money.format(r.due),
                          tone: r.overLimit ? palette.danger : palette.warning,
                        ),
                    ]),
            ),
          ],
        );
      },
    );
  }
}

String _pct(num n) => n.toStringAsFixed(n.abs() >= 10 ? 0 : 1);

/// A payment method code as a label, falling back to the code itself.
String methodLabel(AppL10n l10n, String method) => switch (method) {
      'cash' => l10n.payMethodCash,
      'card' => l10n.payMethodCard,
      'bkash' => l10n.payMethodBkash,
      'nagad' => l10n.payMethodNagad,
      'rocket' => l10n.payMethodRocket,
      'bank' => l10n.payMethodBank,
      '' => '—',
      _ => method[0].toUpperCase() + method.substring(1),
    };
