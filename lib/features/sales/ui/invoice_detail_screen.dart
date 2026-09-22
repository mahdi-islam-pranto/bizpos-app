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
import '../data/sale_models.dart';
import '../data/sales_repository.dart';
import 'invoice_actions.dart';
import 'sale_status_chips.dart';

/// One invoice: the receipt, and the three things that can still happen to it.
///
/// The actions are each `permission && (meta.may* ?? true)`. `mayVoid` is the
/// one that carries real information beyond the permission — the server sets it
/// true only for a **completed** invoice, so a returned or already-cancelled
/// one hides the button even from an owner.
class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({required this.saleId, super.key});

  final int saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final detail = ref.watch(saleDetailProvider(saleId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoice),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/invoices'),
        ),
        actions: [
          PermissionGate(
            perm: P.posSalePrint,
            child: IconButton(
              tooltip: l10n.printReceipt,
              icon: const Icon(Icons.print_outlined),
              // Bluetooth printing is the last phase; saying so is kinder than
              // a button that appears to do nothing.
              onPressed: () => showNote(context, l10n.printingSoon),
            ),
          ),
        ],
      ),
      body: AsyncView<SaleDetailResult>(
        value: detail,
        onRetry: () => ref.invalidate(saleDetailProvider(saleId)),
        builder: (context, result) => _Detail(result: result),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.result});

  final SaleDetailResult result;

  Future<void> _after(WidgetRef ref, bool changed) async {
    if (!changed) return;
    // Both the invoice and the list it came from have moved: a return changes
    // status and stock, a collection changes the due, a void changes both plus
    // every total in the summary strip.
    ref.invalidate(saleDetailProvider(result.sale.id));
    ref.invalidate(salesListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final permissions = ref.watch(permissionsProvider);
    final sale = result.sale;

    final mayCollect = permissions.allows(
          P.salesPaymentCollect,
          alsoRequire: result.mayCollect,
        ) &&
        sale.due > 0 &&
        !sale.status.isCancelled;

    final mayReturn = permissions.allows(
          P.salesReturnCreate,
          alsoRequire: result.mayReturn,
        ) &&
        !sale.status.isCancelled;

    final mayVoid = permissions.allows(
      P.posSaleVoid,
      alsoRequire: result.mayVoid,
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Insets.gutter),
            children: [
              _ReceiptHead(sale: sale, locale: locale),
              const SizedBox(height: Insets.s16),

              if (sale.status.isCancelled)
                Container(
                  margin: const EdgeInsets.only(bottom: Insets.s16),
                  padding: const EdgeInsets.all(Insets.s12),
                  decoration: BoxDecoration(
                    color: palette.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(Radii.row),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 18, color: palette.danger),
                      const SizedBox(width: Insets.s8),
                      Expanded(
                        child: Text(
                          l10n.statusVoid,
                          style: text.titleSmall
                              ?.copyWith(color: palette.danger),
                        ),
                      ),
                    ],
                  ),
                ),

              SectionHeader(l10n.items),
              AppCard(
                children: [
                  for (final item in sale.items)
                    _ItemRow(item: item, money: money),
                ],
              ),

              SectionHeader(l10n.totalCharged),
              AppCard(
                padding: const EdgeInsets.all(Insets.s12),
                children: [
                  _TotalLine(l10n.subtotal, money.format(sale.subtotal)),
                  if (sale.discount > 0)
                    _TotalLine(
                      l10n.discount,
                      '−${money.format(sale.discount)}',
                      tone: palette.accent,
                    ),
                  if (sale.vat > 0)
                    _TotalLine(l10n.vat, money.format(sale.vat)),
                  Divider(color: palette.hairline, height: Insets.s24),
                  _TotalLine(
                    l10n.grandTotal,
                    money.format(sale.total),
                    strong: true,
                  ),
                  _TotalLine(l10n.paidLabel, money.format(sale.paid)),
                  if (sale.due > 0)
                    _TotalLine(
                      l10n.dueLabel,
                      money.format(sale.due),
                      tone: palette.warning,
                    ),
                ],
              ),

              if (sale.payments.isNotEmpty) ...[
                SectionHeader(l10n.payments),
                AppCard(
                  children: [
                    for (final payment in sale.payments)
                      ListTile(
                        dense: true,
                        title: Text(payment.method.toUpperCase()),
                        subtitle: payment.account == null &&
                                payment.reference == null
                            ? null
                            : Text(
                                [payment.account, payment.reference]
                                    .whereType<String>()
                                    .join(' · '),
                              ),
                        trailing: Text(money.format(payment.amount)),
                      ),
                  ],
                ),
              ],

              if ((sale.note ?? '').isNotEmpty) ...[
                SectionHeader(l10n.noteOnSale),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.s4),
                  child: Text(sale.note!, style: text.bodyMedium),
                ),
              ],

              if (mayVoid) ...[
                const SizedBox(height: Insets.s32),
                Center(
                  child: TextButton.icon(
                    onPressed: () async => _after(
                      ref,
                      await VoidSaleSheet.show(context, sale),
                    ),
                    icon: Icon(Icons.block, color: palette.danger),
                    label: Text(
                      l10n.voidInvoice,
                      style: TextStyle(color: palette.danger),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: Insets.s32),
            ],
          ),
        ),

        if (mayCollect || mayReturn)
          Material(
            color: palette.surface,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.hairline)),
                ),
                padding: const EdgeInsets.all(Insets.gutter),
                child: Row(
                  children: [
                    if (mayReturn)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async => _after(
                            ref,
                            await ReturnSheet.show(context, sale),
                          ),
                          icon: const Icon(Icons.undo),
                          label: Text(l10n.acceptReturn),
                        ),
                      ),
                    if (mayReturn && mayCollect)
                      const SizedBox(width: Insets.s12),
                    if (mayCollect)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async => _after(
                            ref,
                            await CollectPaymentSheet.show(context, sale),
                          ),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(l10n.collectDue),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The head of the receipt: who sold what to whom, and when.
class _ReceiptHead extends StatelessWidget {
  const _ReceiptHead({required this.sale, required this.locale});

  final SaleDetail sale;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
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
                child: Text(sale.store.name, style: text.titleMedium),
              ),
              SaleStatusChip(sale.status),
            ],
          ),
          if (sale.branch.name.isNotEmpty)
            Text(
              [sale.branch.name, sale.branch.address, sale.branch.phone]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
          Divider(color: palette.hairline, height: Insets.s24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sale.invoiceNo, style: text.titleSmall),
                    Text(
                      AppDates.stamp(sale.saleDate, locale: locale),
                      style: text.bodySmall?.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
              PaymentStatusChip(sale.paymentStatus),
            ],
          ),
          const SizedBox(height: Insets.s12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: palette.muted),
              const SizedBox(width: Insets.s8),
              Expanded(
                child: Text(
                  sale.hasCustomer
                      ? [sale.customerName, sale.customerPhone]
                          .whereType<String>()
                          .join(' · ')
                      : l10n.walkInCustomer,
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
          if ((sale.seller ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Insets.s4),
              child: Row(
                children: [
                  Icon(Icons.badge_outlined, size: 16, color: palette.muted),
                  const SizedBox(width: Insets.s8),
                  Text(
                    l10n.soldBy(sale.seller!),
                    style: text.bodySmall?.copyWith(color: palette.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.money});

  final SaleItem item;
  final Money money;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return ListTile(
      dense: true,
      title: Text(item.name),
      subtitle: Text(
        '${item.qty.toStringAsFixed(item.qty == item.qty.roundToDouble() ? 0 : 2)}'
        '${item.unit == null ? '' : ' ${item.unit}'}'
        ' × ${money.format(item.unitPrice)}'
        '${(item.discount ?? 0) > 0 ? '  −${money.format(item.discount)}' : ''}',
        style: text.bodySmall?.copyWith(color: palette.muted),
      ),
      trailing: Text(
        money.format(item.total),
        style: text.titleSmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine(this.label, this.value, {this.tone, this.strong = false});

  final String label;
  final String value;
  final Color? tone;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.s4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong ? text.titleMedium : text.bodyMedium,
            ),
          ),
          Text(
            value,
            style: (strong ? text.titleLarge : text.bodyLarge)?.copyWith(
              color: tone,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
