import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/pos_models.dart';

/// What the server said happened.
///
/// Every number here comes from the checkout response, never from the cart:
/// the total may include VAT the app did not compute, and `pointsRedeemed` is
/// capped server-side, so it is routinely smaller than what was asked for. A
/// cashier reading the requested figure and the customer reading the receipt
/// would be looking at two different sales.
class CheckoutDoneSheet extends ConsumerWidget {
  const CheckoutDoneSheet({required this.result, super.key});

  final CheckoutResult result;

  static Future<void> show(
    BuildContext context, {
    required CheckoutResult result,
  }) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).saleComplete,
        builder: (_) => CheckoutDoneSheet(result: result),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);

    final (statusLabel, statusTone) = switch (result.paymentStatus) {
      'paid' => (l10n.statusPaid, palette.positive),
      'partial' => (l10n.statusPartial, palette.warning),
      _ => (l10n.statusUnpaid, palette.danger),
    };

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.s24),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: palette.positive,
                ),
                const SizedBox(height: Insets.s12),
                Text(
                  money.format(result.total),
                  style: text.displaySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: Insets.s4),
                Text(
                  l10n.invoiceNumber(result.invoiceNo),
                  style: text.bodyMedium?.copyWith(color: palette.muted),
                ),
                const SizedBox(height: Insets.s16),
                Wrap(
                  spacing: Insets.s8,
                  runSpacing: Insets.s8,
                  alignment: WrapAlignment.center,
                  children: [
                    _Pill(
                      label: '${l10n.paidLabel} ${money.format(result.paid)}',
                      tone: statusTone,
                      title: statusLabel,
                    ),
                    if (result.due > 0)
                      _Pill(
                        label: money.format(result.due),
                        tone: palette.warning,
                        title: l10n.dueLabel,
                      ),
                    if ((result.pointsRedeemed ?? 0) > 0)
                      _Pill(
                        label: l10n.pointsRedeemed(
                          result.pointsRedeemed!.toStringAsFixed(0),
                        ),
                        tone: palette.accent,
                        title: l10n.points,
                      ),
                    if ((result.pointsEarned ?? 0) > 0)
                      _Pill(
                        label: l10n.pointsEarned(
                          result.pointsEarned!.toStringAsFixed(0),
                        ),
                        tone: palette.accent,
                        title: l10n.points,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // The receipt screen is the invoice detail: it already has the
                  // store, branch, items, payments and totals a receipt needs.
                  context.go('/invoices/${result.saleId}');
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(l10n.viewReceipt),
              ),
            ),
          ),
          SheetAction(
            label: l10n.newSale,
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.tone,
    required this.title,
  });

  final String label;
  final String title;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.s12,
        vertical: Insets.s8,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.row),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: text.labelSmall?.copyWith(color: tone, letterSpacing: 0.6),
          ),
          Text(label, style: text.bodyMedium?.copyWith(color: tone)),
        ],
      ),
    );
  }
}
