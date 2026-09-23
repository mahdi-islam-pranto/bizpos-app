import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../sales/data/sales_repository.dart';
import '../data/customer_models.dart';
import '../data/customers_repository.dart';
import 'customer_form_sheet.dart';

/// One customer: who they are, what they owe, and their points.
///
/// The ledger and the points panel each need their own permission, and each is
/// its own request — so a role that may see the customer but not the ledger
/// gets the page without a hole in it, rather than a 403 that kills the screen.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({required this.customerId, super.key});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final page = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customer),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/customers'),
        ),
      ),
      body: AsyncView<CustomerPage>(
        value: page,
        onRetry: () => ref.invalidate(customersProvider),
        builder: (context, data) {
          // The list is the only endpoint that returns a full customer object;
          // there is no `GET /customers/{id}`. A customer who is not in the
          // current window (or not in this store any more) is a dead link, and
          // saying so beats an empty page.
          final customer = data.customers
              .where((c) => c.id == customerId)
              .firstOrNull;

          if (customer == null) {
            return EmptyState(
              title: l10n.noCustomers,
              body: l10n.customerSearchListHint,
              icon: Icons.person_off_outlined,
            );
          }

          return _Detail(customer: customer, page: data);
        },
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.customer, required this.page});

  final Customer customer;
  final CustomerPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final permissions = ref.watch(permissionsProvider);

    final mayEdit = permissions.allows(
      P.customersCustomerUpdate,
      alsoRequire: page.mayEdit,
    );
    final maySeeLedger = permissions.allows(
      P.customersLedgerView,
      alsoRequire: page.maySeeLedger,
    );

    return ListView(
      padding: const EdgeInsets.all(Insets.gutter),
      children: [
        Container(
          padding: const EdgeInsets.all(Insets.gutter),
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: BorderRadius.circular(Radii.row),
            border: Border.all(color: palette.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(customer.name, style: text.titleLarge),
                  ),
                  if (mayEdit)
                    IconButton(
                      tooltip: l10n.editCustomer,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => CustomerFormSheet.show(
                        context,
                        customer: customer,
                        mayManageCredit: page.mayManageCredit,
                      ),
                    ),
                ],
              ),
              for (final (icon, value) in [
                (Icons.phone_outlined, customer.phone),
                (Icons.mail_outline, customer.email),
                (Icons.place_outlined, customer.address),
              ])
                if ((value ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.s4),
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: palette.muted),
                        const SizedBox(width: Insets.s8),
                        Expanded(
                          child: Text(value!, style: text.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: Insets.s16),
              Row(
                children: [
                  _Stat(
                    label: l10n.dueLabel,
                    value: money.format(customer.due),
                    tone: customer.due > 0 ? palette.warning : null,
                    // Part of it has no invoice behind it; whoever goes to
                    // collect it should know.
                    note: (customer.openingBalance ?? 0) > 0
                        ? '${l10n.openingBalance} ${money.format(customer.openingBalance)}'
                        : null,
                  ),
                  _Stat(
                    label: l10n.invoices,
                    value: customer.saleCount.toString(),
                  ),
                  if (customer.creditLimit != null)
                    _Stat(
                      label: l10n.creditLimit,
                      value: money.format(customer.creditLimit),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: Insets.s8),
        AppCard(
          children: [
            ListTile(
              leading: Icon(Icons.receipt_long_outlined, color: palette.muted),
              title: Text(l10n.viewInvoices),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // The invoice list searches on name or phone, so handing it the
                // phone is the closest thing the API has to "their invoices".
                ref
                    .read(salesQueryProvider.notifier)
                    .setText(customer.phone ?? customer.name);
                ref.read(salesQueryProvider.notifier).setDays(null);
                context.go('/invoices');
              },
            ),
          ],
        ),

        PermissionGate(
          perm: P.customersPointsView,
          child: _PointsPanel(customer: customer),
        ),

        if (maySeeLedger) _LedgerPanel(customer: customer),
        const SizedBox(height: Insets.s32),
      ],
    );
  }
}

class _PointsPanel extends ConsumerWidget {
  const _PointsPanel({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final points = ref.watch(customerPointsProvider(customer.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          l10n.pointsTitle,
          trailing: PermissionGate(
            perm: P.customersPointsAdjust,
            child: TextButton(
              onPressed: () => AdjustPointsSheet.show(context, customer),
              child: Text(l10n.adjustPoints),
            ),
          ),
        ),
        points.when(
          loading: () => const LinearProgressIndicator(),
          // A points panel that fails is not worth a full-screen error: the
          // rest of the customer is still useful.
          error: (error, _) => ErrorView(error: error),
          data: (account) => AppCard(
            padding: const EdgeInsets.all(Insets.gutter),
            children: [
              Row(
                children: [
                  Icon(Icons.stars_outlined, color: palette.accent),
                  const SizedBox(width: Insets.s12),
                  Expanded(
                    child: Text(
                      l10n.pointsBalance(account.balance.toStringAsFixed(0)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    l10n.pointsWorth(money.format(account.worth)),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: palette.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerPanel extends ConsumerWidget {
  const _LedgerPanel({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final ledger = ref.watch(customerLedgerProvider(customer.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.ledger),
        ledger.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => ErrorView(error: error),
          data: (entries) => entries.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(Insets.s24),
                  child: Text(
                    l10n.ledgerEmpty,
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: palette.muted),
                  ),
                )
              : AppCard(
                  children: [
                    for (final entry in entries)
                      ListTile(
                        dense: true,
                        title: Text(ledgerLabel(l10n, entry.refType)),
                        subtitle: Text(
                          [
                            AppDates.stamp(entry.date, locale: locale),
                            entry.note,
                          ].whereType<String>().where((s) => s.isNotEmpty).join(
                                ' · ',
                              ),
                          style: text.bodySmall
                              ?.copyWith(color: palette.muted),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              entry.debit > 0
                                  ? '+${money.format(entry.debit)}'
                                  : '−${money.format(entry.credit)}',
                              style: text.bodyMedium?.copyWith(
                                color: entry.debit > 0
                                    ? palette.warning
                                    : palette.positive,
                              ),
                            ),
                            Text(
                              money.format(entry.balance),
                              style: text.labelSmall
                                  ?.copyWith(color: palette.muted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.tone,
    this.note,
  });

  final String label;
  final String value;
  final Color? tone;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall?.copyWith(color: palette.muted)),
          Text(
            value,
            style: text.titleMedium?.copyWith(
              color: tone,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (note != null)
            Text(note!, style: text.labelSmall?.copyWith(color: palette.muted)),
        ],
      ),
    );
  }
}

/// A ledger row's kind in words. An unknown kind reads as itself, so a type the
/// API adds later is still something rather than nothing.
String ledgerLabel(AppL10n l10n, String refType) => switch (refType) {
      'sale' => l10n.ledgerSale,
      'payment' => l10n.ledgerPayment,
      'return' => l10n.ledgerReturn,
      'void' => l10n.ledgerVoid,
      'opening' => l10n.openingBalance,
      'opening_correction' => l10n.ledgerOpeningCorrection,
      _ => refType.replaceAll('_', ' ').toUpperCase(),
    };
