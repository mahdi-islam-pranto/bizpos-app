import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../l10n/app_localizations.dart';
import '../data/pos_models.dart';
import '../data/pos_repository.dart';
import '../state/cart.dart';
import 'cart_sheet.dart' show BelowCostNotice;
import 'checkout_done_sheet.dart';
import 'customer_picker_sheet.dart';

/// Taking the money.
///
/// Three API rules shape this whole screen, and getting any of them wrong is a
/// `422` in front of a waiting customer:
///
/// * **`credit` and `points` are not payment methods.** A due is made by paying
///   *less* than the total; points go in `redeemPoints`. Neither ever appears
///   in the method list.
/// * **A due needs a named customer**, and a walk-in customer may never have
///   one. The store can also switch credit off entirely (`allowCredit`).
/// * **The total the server returns is the sale.** Everything shown here is the
///   app's own estimate, so the amount fields start from it but the receipt
///   comes from the checkout response.
///
/// And one habit of the shop: **the khata is one figure.** A customer who owes
/// 500 and buys 300 is asked for 800. "Collect previous due" sends
/// `collectPrevious: true` and tenders against both; the server fills this bill
/// first and walks the older debts oldest first. Without it, the same
/// over-tender is change. Either way the tender is sent as typed — the server
/// splits it, not the app.
class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({required this.lookups, super.key});

  final PosLookups lookups;

  static Future<void> show(
    BuildContext context, {
    required PosLookups lookups,
  }) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).payment,
        dismissible: true,
        builder: (_) => PaymentSheet(lookups: lookups),
      );

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final List<_PaymentDraft> _drafts = [];
  bool _busy = false;

  /// Asking for the old debt along with today's goods.
  bool _collectPrevious = false;

  @override
  void initState() {
    super.initState();
    // One payment, for the whole bill, in the default account: the ordinary
    // sale. Splitting is a deliberate extra tap, not the default shape.
    final cart = ref.read(cartProvider);
    final account = widget.lookups.defaultAccount;
    _drafts.add(
      _PaymentDraft(
        account: account,
        method: account == null
            ? PayMethod.cash
            : PayMethod.forAccount(account),
        amount: cart.estimatedTotal.toDouble(),
      ),
    );
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  num get _paid => _drafts.fold<num>(0, (sum, d) => sum + (d.value ?? 0));

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final cart = ref.watch(cartProvider);
    final permissions = ref.watch(permissionsProvider);
    final loyalty = widget.lookups.loyalty;

    final total = cart.estimatedTotal.toDouble();
    final pointsOff = loyalty.worthOf(cart.redeemPoints);
    final payable = (total - pointsOff).clamp(0, double.infinity);

    final previousDue =
        cart.hasNamedCustomer ? (cart.customer!.due ?? 0) : 0;
    final collecting = _collectPrevious && previousDue > 0;
    final target = payable + (collecting ? previousDue : 0);
    final remaining = target - _paid;

    // A new due only exists when this bill itself is short. Paying the bill
    // and part of the old debt leaves the rest of the old debt where it was,
    // which is not a new credit sale.
    final leavesDue = payable - _paid > 0.001;
    final stillOwed = remaining > 0.001 ? remaining : 0;
    final change = remaining < -0.001 ? -remaining : 0;

    final creditBlocked = leavesDue &&
        (!widget.lookups.allowCredit || !cart.hasNamedCustomer);
    final creditReason = !widget.lookups.allowCredit
        ? l10n.creditOff
        : (cart.customer?.isWalkIn ?? true)
            ? l10n.walkInNoCredit
            : l10n.dueNeedsCustomer;

    final mayRedeem = permissions.has(P.posSaleRedeemPoints) &&
        loyalty.enabled &&
        loyalty.mayRedeem;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Insets.gutter),
            children: [
              _Summary(
                total: total,
                pointsOff: pointsOff,
                money: money,
              ),
              const SizedBox(height: Insets.s16),

              if (previousDue > 0)
                _PreviousDueRow(
                  due: previousDue,
                  money: money,
                  value: _collectPrevious,
                  onChanged: (value) => setState(() {
                    _collectPrevious = value;
                    // The ordinary case is one payment for everything asked
                    // for, so the single draft follows the figure.
                    if (_drafts.length == 1) {
                      final newTarget = payable + (value ? previousDue : 0);
                      _drafts.first.amount.text =
                          _PaymentDraft._trim(newTarget);
                    }
                  }),
                ),

              if (mayRedeem)
                _RedeemRow(
                  lookups: widget.lookups,
                  total: total,
                  onChanged: () => setState(() {}),
                ),

              const SizedBox(height: Insets.s8),
              for (var i = 0; i < _drafts.length; i++)
                _PaymentCard(
                  draft: _drafts[i],
                  accounts: widget.lookups.accounts,
                  money: money,
                  canRemove: _drafts.length > 1,
                  onChanged: () => setState(() {}),
                  onRemove: () => setState(() {
                    _drafts.removeAt(i).dispose();
                  }),
                ),

              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _drafts.add(
                      _PaymentDraft(
                        account: widget.lookups.defaultAccount,
                        method: PayMethod.cash,
                        // A split's second leg starts at what is left, which is
                        // nearly always the intended figure.
                        amount: remaining > 0 ? remaining : 0,
                      ),
                    );
                  }),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addPayment),
                ),
              ),

              const SizedBox(height: Insets.s8),
              if (change > 0)
                _Line(
                  label: l10n.changeDue,
                  value: money.format(change),
                  tone: palette.positive,
                ),
              if (stillOwed > 0)
                _Line(
                  label: l10n.remainingDue,
                  value: money.format(stillOwed),
                  tone: creditBlocked ? palette.danger : palette.warning,
                ),
              if (creditBlocked)
                Padding(
                  padding: const EdgeInsets.only(top: Insets.s8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: palette.danger,
                      ),
                      const SizedBox(width: Insets.s8),
                      Expanded(
                        child: Text(
                          creditReason,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: palette.danger),
                        ),
                      ),
                      if (widget.lookups.allowCredit)
                        TextButton(
                          onPressed: _pickCustomer,
                          child: Text(l10n.customer),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Divider(color: palette.hairline, height: 1),
        if (cart.belowCost)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.gutter,
              Insets.s12,
              Insets.gutter,
              0,
            ),
            child: BelowCostNotice(cart: cart),
          ),
        SheetAction(
          label: '${l10n.completeSale}  ${money.format(target)}',
          icon: Icons.check_circle_outline,
          busy: _busy,
          onPressed: creditBlocked || cart.belowCost ? null : _checkout,
        ),
      ],
    );
  }

  Future<void> _pickCustomer() async {
    final picked = await CustomerPickerSheet.show(
      context,
      lookups: widget.lookups,
      selected: ref.read(cartProvider).customer,
    );
    if (picked == null) return;
    ref
        .read(cartProvider.notifier)
        .setCustomer(picked.isWalkIn ? null : picked);
    if (mounted) setState(() {});
  }

  /// One shot. [_busy] latches before the await and the button is disabled
  /// while it holds, because there is no idempotency key: a second
  /// `POST /pos/checkout` is a second sale, not a retry.
  Future<void> _checkout() async {
    if (_busy) return;
    setState(() => _busy = true);

    final cart = ref.read(cartProvider);
    final permissions = ref.read(permissionsProvider);
    final mayChangePrice = permissions.has(P.posSaleChangePrice);
    final mayDiscount = permissions.has(P.posSaleGiveDiscount);

    // The body is built by the cart itself, not here: which permission-gated
    // fields travel is a rule about the API, and it is under test there.
    final body = cart.toCheckoutBody(
      mayChangePrice: mayChangePrice,
      mayDiscount: mayDiscount,
      collectPrevious:
          _collectPrevious && (cart.customer?.due ?? 0) > 0,
      payments: [
        for (final draft in _drafts)
          if ((draft.value ?? 0) > 0)
            CartPayment(
              method: draft.method,
              amount: draft.value!,
              accountId: draft.account?.id,
              reference: draft.reference.text.trim(),
            ),
      ],
    );

    try {
      final result =
          await ref.read(posRepositoryProvider).checkout(body);
      if (!mounted) return;

      ref.read(cartProvider.notifier).clear();
      // The drawer figure and the held list both move with a sale.
      ref.invalidate(posLookupsProvider);

      Navigator.of(context).pop();
      await CheckoutDoneSheet.show(context, result: result);
    } catch (e) {
      // The sale did not happen. The cart is untouched, so the cashier can fix
      // whatever the server objected to and try again.
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// One payment being entered. Holds its own controller so typing does not
/// rebuild the list from scratch.
class _PaymentDraft {
  _PaymentDraft({
    required this.account,
    required this.method,
    required num amount,
  }) : amount = TextEditingController(
          text: amount <= 0 ? '' : _trim(amount),
        );

  PosAccount? account;
  PayMethod method;
  final TextEditingController amount;
  final TextEditingController reference = TextEditingController();

  num? get value => num.tryParse(amount.text.trim());

  void dispose() {
    amount.dispose();
    reference.dispose();
  }

  static String _trim(num value) => (value * 100).round() % 100 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.draft,
    required this.accounts,
    required this.money,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final _PaymentDraft draft;
  final List<PosAccount> accounts;
  final Money money;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  String _methodLabel(AppL10n l10n, PayMethod method) => switch (method) {
        PayMethod.cash => l10n.payMethodCash,
        PayMethod.card => l10n.payMethodCard,
        PayMethod.bkash => l10n.payMethodBkash,
        PayMethod.nagad => l10n.payMethodNagad,
        PayMethod.rocket => l10n.payMethodRocket,
        PayMethod.bank => l10n.payMethodBank,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: Insets.s12),
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final method in PayMethod.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.s8),
                    child: ChoiceChip(
                      label: Text(_methodLabel(l10n, method)),
                      selected: draft.method == method,
                      onSelected: (_) {
                        draft.method = method;
                        onChanged();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Insets.s12),
          Row(
            children: [
              Expanded(
                child: AmountField(
                  controller: draft.amount,
                  label: l10n.amountReceived,
                  prefix: money.sign,
                  onChanged: (_) => onChanged(),
                ),
              ),
              if (canRemove)
                IconButton(
                  icon: Icon(Icons.close, color: palette.muted),
                  onPressed: onRemove,
                ),
            ],
          ),
          if (accounts.isNotEmpty) ...[
            const SizedBox(height: Insets.s12),
            // Sending `accountId` is what puts the money in that account's
            // balance; without it the sale is recorded but the drawer is not.
            DropdownButtonFormField<int>(
              initialValue: draft.account?.id,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.account,
                isDense: true,
              ),
              items: [
                for (final account in accounts)
                  DropdownMenuItem(
                    value: account.id,
                    child: Text(account.name),
                  ),
              ],
              onChanged: (id) {
                draft.account = accounts.firstWhere((a) => a.id == id);
                onChanged();
              },
            ),
          ],
          if (draft.method != PayMethod.cash) ...[
            const SizedBox(height: Insets.s12),
            TextField(
              controller: draft.reference,
              decoration: InputDecoration(
                labelText: l10n.reference,
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The customer's old debt, and whether it is being asked for now.
class _PreviousDueRow extends StatelessWidget {
  const _PreviousDueRow({
    required this.due,
    required this.money,
    required this.value,
    required this.onChanged,
  });

  final num due;
  final Money money;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: Insets.s12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: palette.hairline),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        title: Text(l10n.collectPreviousDue),
        subtitle: Text(
          '${l10n.previousDueLabel} ${money.format(due)}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: palette.warning),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.total,
    required this.pointsOff,
    required this.money,
  });

  final num total;
  final num pointsOff;
  final Money money;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Column(
      children: [
        _Line(label: l10n.estimatedTotal, value: money.format(total), strong: true),
        if (pointsOff > 0)
          _Line(
            label: l10n.redeemPoints,
            value: '−${money.format(pointsOff)}',
            tone: palette.accent,
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.tone,
    this.strong = false,
  });

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

/// Redeeming loyalty points.
///
/// The server caps what is actually redeemed by a minimum, a maximum
/// percentage of the bill and the balance — so the figure shown here is a
/// request, and the success sheet reports what was really taken.
class _RedeemRow extends ConsumerWidget {
  const _RedeemRow({
    required this.lookups,
    required this.total,
    required this.onChanged,
  });

  final PosLookups lookups;
  final num total;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final cart = ref.watch(cartProvider);
    final loyalty = lookups.loyalty;

    // Points belong to a person. Without one there is nothing to redeem, and
    // sending any would be a `422`.
    if (!cart.hasNamedCustomer) return const SizedBox.shrink();

    final balance = cart.customer?.loyaltyPoints;
    if (balance == null || balance < loyalty.minRedeem) {
      return const SizedBox.shrink();
    }

    final cap = loyalty.capFor(total, balance);

    return Container(
      margin: const EdgeInsets.only(bottom: Insets.s12),
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(Radii.row),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_outlined, size: 18, color: palette.accent),
              const SizedBox(width: Insets.s8),
              Expanded(
                child: Text(
                  l10n.redeemPointsHelp(
                    balance.toStringAsFixed(0),
                    money.format(loyalty.worthOf(balance)),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.s8),
          Row(
            children: [
              Expanded(
                child: Text(
                  cart.redeemPoints > 0
                      ? l10n.pointsBalance(
                          cart.redeemPoints.toStringAsFixed(0),
                        )
                      : l10n.redeemPoints,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (cart.redeemPoints > 0)
                TextButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).setRedeemPoints(0);
                    onChanged();
                  },
                  child: Text(l10n.remove),
                ),
              FilledButton.tonal(
                onPressed: cap <= 0
                    ? null
                    : () {
                        ref.read(cartProvider.notifier).setRedeemPoints(cap);
                        onChanged();
                      },
                child: Text(l10n.redeemMax),
              ),
            ],
          ),
          Text(
            l10n.redeemCapNote,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}
