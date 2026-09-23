import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/network/paged.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/sale_models.dart';
import '../data/sales_repository.dart';
import 'sale_status_chips.dart';

/// The invoice list.
///
/// A cashier with only `sales.invoice.view` sees their own sales and nothing
/// else — the server decides that, not the app, so the list is the same widget
/// for every role. `meta.seeAll` is what tells us which of the two happened,
/// and it is worth saying out loud so nobody thinks the shop sold three things
/// today.
class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    // Fetch the next page before the bottom is reached, so scrolling does not
    // stall on a spinner.
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      ref.read(salesListProvider.notifier).loadMore();
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 320),
      () => ref.read(salesQueryProvider.notifier).setText(value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final sales = ref.watch(salesListProvider);
    final query = ref.watch(salesQueryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invoices)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.gutter,
              Insets.s12,
              Insets.gutter,
              Insets.s8,
            ),
            child: SearchField(
              controller: _search,
              hint: l10n.invoiceSearchHint,
              onChanged: _onQueryChanged,
              onSubmitted: (value) => ref
                  .read(salesQueryProvider.notifier)
                  .setText(value.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
            child: Row(
              children: [
                for (final (label, days) in [
                  (l10n.filterToday, 1),
                  (l10n.filterWeek, 7),
                  (l10n.filterAll, null),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.s8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: query.days == days,
                      onSelected: (_) =>
                          ref.read(salesQueryProvider.notifier).setDays(days),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<Paged<SaleListItem>>(
              value: sales,
              onRetry: () => ref.invalidate(salesListProvider),
              builder: (context, page) {
                final summary = SalesSummary.from(page.meta);
                // Tri-state: absent means the endpoint said nothing, so we do
                // not claim the list is narrowed when we were not told.
                final seeAll = page.meta.flag('seeAll');

                if (page.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(salesListProvider.notifier).refresh(),
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.5,
                          child: EmptyState(
                            title: l10n.noInvoices,
                            body: l10n.noInvoicesBody,
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    if (summary != null)
                      _SummaryStrip(summary: summary, ownOnly: seeAll == false),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () =>
                            ref.read(salesListProvider.notifier).refresh(),
                        child: ListView.separated(
                          controller: _scroll,
                          padding: const EdgeInsets.only(bottom: Insets.s24),
                          itemCount: page.items.length + (page.hasMore ? 1 : 0),
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: palette.hairline,
                            indent: Insets.gutter,
                          ),
                          itemBuilder: (context, i) {
                            if (i >= page.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(Insets.gutter),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _InvoiceRow(sale: page.items[i]);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends ConsumerWidget {
  const _SummaryStrip({required this.summary, required this.ownOnly});

  final SalesSummary summary;
  final bool ownOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        Insets.gutter,
        Insets.s12,
        Insets.gutter,
        Insets.s8,
      ),
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Stat(
                label: l10n.invoiceCount(summary.count.toString()),
                value: money.format(summary.total),
              ),
              Container(
                width: 1,
                height: 32,
                color: palette.hairline,
              ),
              _Stat(
                label: l10n.invoiceDue,
                value: money.format(summary.due),
                tone: summary.due > 0 ? palette.warning : null,
              ),
            ],
          ),
          if (ownOnly)
            Padding(
              padding: const EdgeInsets.only(top: Insets.s8),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: palette.muted),
                  const SizedBox(width: Insets.s4),
                  Text(
                    l10n.ownInvoicesOnly,
                    style: text.labelSmall?.copyWith(color: palette.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(color: palette.muted),
          ),
          Text(
            value,
            style: text.titleMedium?.copyWith(
              color: tone,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends ConsumerWidget {
  const _InvoiceRow({required this.sale});

  final SaleListItem sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    return ListTile(
      onTap: () => context.go('/invoices/${sale.id}'),
      title: Row(
        children: [
          Text(
            sale.invoiceNo,
            style: text.titleSmall?.copyWith(
              // A cancelled sale reads as cancelled at a glance, before anyone
              // gets as far as the chip.
              decoration: sale.status.isCancelled
                  ? TextDecoration.lineThrough
                  : null,
              color: sale.status.isCancelled ? palette.muted : null,
            ),
          ),
          const SizedBox(width: Insets.s8),
          SaleStatusChip(sale.status),
        ],
      ),
      subtitle: Text(
        [
          sale.customer ?? l10n.walkInCustomer,
          AppDates.stamp(sale.saleDate, locale: locale),
          l10n.itemsCount(sale.itemCount),
          ?discountLabel(sale, money),
        ].where((s) => s.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            money.format(sale.total),
            style: text.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: Insets.s4),
          if (sale.due > 0 && !sale.status.isCancelled)
            StatusChip(
              label: '${l10n.dueLabel} ${money.format(sale.due)}',
              tone: palette.warning,
            )
          else
            PaymentStatusChip(sale.paymentStatus),
        ],
      ),
    );
  }
}

/// The permission set the list screen itself needs. Kept beside the screen so
/// the route guard and the tab agree without either importing the other.
const invoicesGate = [P.salesInvoiceView, P.salesInvoiceViewAll];

/// The discount on a row, with its rate. The rate the cashier gave is shown
/// plainly; one worked out from the figures is marked "≈", because nobody set
/// it.
String? discountLabel(SaleListItem sale, Money money) {
  final off = sale.discount ?? 0;
  if (off <= 0) return null;
  final given = sale.discountPercent;
  final derived = sale.discountRate;
  final rate = given != null
      ? ' (${_rate(given)}%)'
      : derived != null && derived > 0
          ? ' (≈${_rate(derived)}%)'
          : '';
  return '−${money.format(off)}$rate';
}

String _rate(num value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
