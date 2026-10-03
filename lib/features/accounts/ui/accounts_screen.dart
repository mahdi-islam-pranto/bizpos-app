import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/shell_nav.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../reports/ui/figures.dart';
import '../data/account_models.dart';
import '../data/accounts_repository.dart';
import 'account_sheets.dart';

/// Money: where it is, what went out, and the quick tiles for the expenses a
/// shop pays every day.
///
/// Every write is `permission && meta.may*`: an auditor reads the same screen
/// with every button gone.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final permissions = ref.watch(permissionsProvider);
    final overview = ref.watch(accountsOverviewProvider);
    final data = overview.value;

    final mayExpense = permissions.allows(
      P.accountsExpenseCreate,
      alsoRequire: data?.mayExpense,
    );
    final mayTransfer = permissions.allows(
      P.accountsTransferCreate,
      alsoRequire: data?.mayTransfer,
    );
    final mayCategories = permissions.allows(
      P.accountsCategoryManage,
      alsoRequire: data?.mayManageCategories,
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: ShellAppBar(
          title: Text(l10n.accounts),
          actions: [
            if (data != null && mayTransfer && data.accounts.length > 1)
              IconButton(
                tooltip: l10n.transfer,
                icon: const Icon(Icons.swap_horiz),
                onPressed: () => TransferSheet.show(context, overview: data),
              ),
            if (data != null && mayCategories)
              IconButton(
                tooltip: l10n.expenseTypes,
                icon: const Icon(Icons.category_outlined),
                onPressed: () => CategoriesSheet.show(context),
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.overview),
              Tab(text: l10n.expensesLabel),
              Tab(text: l10n.transactions),
            ],
          ),
        ),
        floatingActionButton: data != null && mayExpense
            ? FloatingActionButton.extended(
                onPressed: () => ExpenseFormSheet.show(context, overview: data),
                icon: const Icon(Icons.remove_circle_outline),
                label: Text(l10n.recordExpense),
              )
            : null,
        body: AsyncView<AccountsOverview>(
          value: overview,
          onRetry: () => ref.invalidate(accountsOverviewProvider),
          builder: (context, data) => TabBarView(
            children: [
              _OverviewTab(overview: data, mayExpense: mayExpense),
              _ExpensesTab(overview: data),
              _TransactionsTab(overview: data),
            ],
          ),
        ),
      ),
    );
  }
}

/// Everything the accounts screen shows is one call, and the dashboard's
/// money figures are built from the same ledger — both go stale together.
void refreshMoney(WidgetRef ref) {
  ref.invalidate(accountsOverviewProvider);
  ref.invalidate(dashboardProvider);
}

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab({required this.overview, required this.mayExpense});

  final AccountsOverview overview;
  final bool mayExpense;

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  /// Tiles with a post in flight. A tile is one tap, and a second tap while
  /// the first is travelling would be a second cup of tea on the books.
  final Set<int> _posting = {};

  Future<void> _tapTile(ExpenseCategory tile) async {
    // Salary needs a name, and a type without an amount needs one typed:
    // neither can go up in one tap, so the form opens with the type chosen.
    if (!tile.oneTap) {
      await ExpenseFormSheet.show(
        context,
        overview: widget.overview,
        category: tile,
      );
      return;
    }
    if (_posting.contains(tile.id)) return;
    setState(() => _posting.add(tile.id));

    final l10n = AppL10n.of(context);
    final money = ref.read(moneyProvider);
    final messenger = ScaffoldMessenger.of(context);
    final mayUndo = ref
        .read(permissionsProvider)
        .allows(
          P.accountsExpenseDelete,
          alsoRequire: widget.overview.mayDeleteExpense,
        );
    final repository = ref.read(accountsRepositoryProvider);

    try {
      final created = await repository.quickExpense(tile.id);
      refreshMoney(ref);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            // The server's amount: the tile sent none.
            content: Text(
              l10n.expenseRecorded(tile.name, money.format(created.amount)),
            ),
            action: mayUndo && created.id > 0
                ? SnackBarAction(
                    label: l10n.undo,
                    onPressed: () async {
                      try {
                        await repository.deleteExpense(created.id);
                        if (mounted) refreshMoney(ref);
                      } catch (e) {
                        if (mounted) showApiError(context, e);
                      }
                    },
                  )
                : null,
          ),
        );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _posting.remove(tile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final permissions = ref.watch(permissionsProvider);
    final o = widget.overview;

    final mayManage = permissions.allows(
      P.accountsAccountManage,
      alsoRequire: o.mayManage,
    );

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(accountsOverviewProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.gutter, 0, Insets.gutter, 96),
        children: [
          ReportSection(
            title: l10n.balance,
            scope: ReportScope.store,
            child: FigureGrid([
              Figure(l10n.inAccounts, money.format(o.totalBalance)),
              Figure(l10n.spentToday, money.format(o.todayExpense)),
              Figure(l10n.spentThisMonth, money.format(o.monthExpense)),
              if (o.monthSalary > 0)
                Figure(l10n.salaryThisMonth, money.format(o.monthSalary)),
            ]),
          ),
          if (widget.mayExpense && o.quick.isNotEmpty)
            ReportSection(
              title: l10n.quickExpenses,
              child: Wrap(
                spacing: Insets.s8,
                runSpacing: Insets.s8,
                children: [
                  for (final tile in o.quick)
                    _QuickTile(
                      tile: tile,
                      busy: _posting.contains(tile.id),
                      onTap: () => _tapTile(tile),
                    ),
                ],
              ),
            ),
          ReportSection(
            title: l10n.accounts,
            child: RowsCard(
              children: [
                for (final a in o.accounts)
                  FigureRow(
                    label: a.name,
                    detail: accountTypeLabel(l10n, a.type),
                    value: money.format(a.balance),
                    tone: a.balance < 0 ? palette.danger : null,
                  ),
                if (mayManage)
                  ListTile(
                    leading: Icon(Icons.add, color: palette.accent),
                    title: Text(
                      l10n.addAccount,
                      style: text.bodyMedium?.copyWith(color: palette.accent),
                    ),
                    onTap: () => AccountFormSheet.show(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends ConsumerWidget {
  const _QuickTile({
    required this.tile,
    required this.busy,
    required this.onTap,
  });

  final ExpenseCategory tile;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final l10n = AppL10n.of(context);

    return SizedBox(
      width: 104,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.row),
          side: BorderSide(color: palette.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(Insets.s12),
            child: Column(
              children: [
                SizedBox(
                  height: 28,
                  child: busy
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(
                          tile.icon ?? '💸',
                          style: const TextStyle(fontSize: 22),
                        ),
                ),
                const SizedBox(height: Insets.s4),
                Text(
                  tile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium,
                ),
                Text(
                  tile.oneTap
                      ? money.format(tile.defaultAmount)
                      : (tile.isSalary ? l10n.salaryAsks : l10n.typeAmount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.overview});

  final AccountsOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    if (overview.expenses.isEmpty) {
      return EmptyState(icon: Icons.receipt_outlined, title: l10n.noExpenses);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(accountsOverviewProvider),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: overview.expenses.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: palette.hairline, indent: Insets.gutter),
        itemBuilder: (context, i) {
          final e = overview.expenses[i];
          return ListTile(
            leading: Text(e.icon ?? '💸', style: const TextStyle(fontSize: 22)),
            title: Text(
              e.isSalary && e.employeeName != null
                  ? '${e.category ?? l10n.expense} · ${e.employeeName}'
                  : (e.category ?? l10n.expense),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                AppDates.stamp(e.when, locale: locale),
                ?e.account,
                if (e.salaryMonth != null) l10n.forMonth(e.salaryMonth!),
                ?e.note,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
            trailing: Text(
              money.format(e.amount),
              style: text.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            onTap: () => ExpenseDetailSheet.show(
              context,
              expense: e,
              overview: overview,
            ),
          );
        },
      ),
    );
  }
}

class _TransactionsTab extends ConsumerWidget {
  const _TransactionsTab({required this.overview});

  final AccountsOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    if (overview.transactions.isEmpty) {
      return EmptyState(icon: Icons.swap_vert, title: l10n.noTransactions);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(accountsOverviewProvider),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: overview.transactions.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: palette.hairline, indent: Insets.gutter),
        itemBuilder: (context, i) {
          final t = overview.transactions[i];
          final out = t.isOut;
          return ListTile(
            leading: Icon(
              out ? Icons.arrow_upward : Icons.arrow_downward,
              color: out ? palette.danger : palette.positive,
            ),
            title: Text(
              t.note ?? transactionTypeLabel(l10n, t.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                AppDates.stamp(t.createdAt, locale: locale),
                ?t.account,
                if (t.note != null && t.type != null)
                  transactionTypeLabel(l10n, t.type),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
            trailing: Text(
              '${out ? '−' : '+'}${money.format(t.amount.abs())}',
              style: text.titleSmall?.copyWith(
                color: out ? palette.danger : palette.positive,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One expense, and the way to take it back.
class ExpenseDetailSheet extends ConsumerStatefulWidget {
  const ExpenseDetailSheet({
    required this.expense,
    required this.overview,
    super.key,
  });

  final Expense expense;
  final AccountsOverview overview;

  static Future<void> show(
    BuildContext context, {
    required Expense expense,
    required AccountsOverview overview,
  }) {
    final l10n = AppL10n.of(context);
    return showAppSheet<void>(
      context,
      title: expense.category ?? l10n.expense,
      builder: (_) => ExpenseDetailSheet(expense: expense, overview: overview),
    );
  }

  @override
  ConsumerState<ExpenseDetailSheet> createState() => _ExpenseDetailSheetState();
}

class _ExpenseDetailSheetState extends ConsumerState<ExpenseDetailSheet> {
  bool _busy = false;

  Future<void> _delete() async {
    final l10n = AppL10n.of(context);
    final money = ref.read(moneyProvider);
    final sure = await confirmSheet(
      context,
      title: l10n.deleteExpense,
      message: l10n.deleteExpenseBody(
        money.format(widget.expense.amount),
        widget.expense.account ?? l10n.account,
      ),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!sure || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(accountsRepositoryProvider)
          .deleteExpense(widget.expense.id);
      refreshMoney(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.expenseDeleted);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final permissions = ref.watch(permissionsProvider);
    final e = widget.expense;
    final mayDelete = permissions.allows(
      P.accountsExpenseDelete,
      alsoRequire: widget.overview.mayDeleteExpense,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: RowsCard(
              children: [
                FigureRow(label: l10n.amount, value: money.format(e.amount)),
                if (e.account != null)
                  FigureRow(label: l10n.paidFrom, value: e.account!),
                FigureRow(
                  label: l10n.dateLabel,
                  value: AppDates.day(e.when, locale: locale),
                ),
                if (e.employeeName != null)
                  FigureRow(label: l10n.employeeName, value: e.employeeName!),
                if (e.salaryMonth != null)
                  FigureRow(label: l10n.salaryMonth, value: e.salaryMonth!),
                if (e.userName != null)
                  FigureRow(label: l10n.recordedBy, value: e.userName!),
                if (e.note != null) FigureRow(label: l10n.note, value: e.note!),
              ],
            ),
          ),
          if (mayDelete)
            SheetAction(
              label: l10n.deleteExpense,
              icon: Icons.delete_outline,
              tone: palette.danger,
              busy: _busy,
              onPressed: _delete,
            ),
        ],
      ),
    );
  }
}

String accountTypeLabel(AppL10n l10n, String type) => switch (type) {
  'cash' => l10n.accountCash,
  'bank' => l10n.accountBank,
  'mfs' || 'mobile' => l10n.accountMfs,
  _ => type,
};

String transactionTypeLabel(AppL10n l10n, String? type) => switch (type) {
  'sale' => l10n.txnSale,
  'expense' => l10n.expense,
  'transfer' || 'transfer_in' || 'transfer_out' => l10n.transfer,
  'purchase' => l10n.purchase,
  'payment' || 'due_payment' => l10n.txnDuePayment,
  'refund' || 'return' => l10n.txnRefund,
  'opening' => l10n.openingBalance,
  null || '' => l10n.transactions,
  _ => type.replaceAll('_', ' '),
};
