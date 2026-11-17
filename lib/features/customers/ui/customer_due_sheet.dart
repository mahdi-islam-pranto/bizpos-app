import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../l10n/app_localizations.dart';
import '../../pos/data/pos_models.dart';
import '../data/customer_models.dart';
import '../data/customers_repository.dart';

/// Which half of the due sheet is showing.
enum CustomerDueTab { collect, add }

/// Money moving against a customer's whole balance.
///
/// Two actions share one sheet because they are two answers to the same
/// question — "this person's due" — and an owner correcting one while looking
/// at the other should not have to close and reopen:
///
/// * **Collect due** takes money (and, with the permission, writes a discount
///   off) against everything owed, oldest first. It is not tied to an invoice:
///   the previous due and every invoice are settled in one go.
/// * **Add due** puts more on the balance with no invoice behind it, which is
///   how a debt carried over from the old notebook gets written down.
///
/// The server is authoritative on all three figures; the sheet's own summary is
/// only a preview so the person can see where the money is going before they
/// tap.
class CustomerDueSheet extends ConsumerStatefulWidget {
  const CustomerDueSheet({
    required this.customer,
    required this.mayCollect,
    required this.mayAddDue,
    required this.mayGiveDiscount,
    this.initial = CustomerDueTab.collect,
    super.key,
  });

  final Customer customer;

  /// `sales.payment.collect`.
  final bool mayCollect;

  /// `customers.credit.manage`.
  final bool mayAddDue;

  /// `pos.sale.give_discount`; without it a collection cannot carry a discount.
  final bool mayGiveDiscount;

  final CustomerDueTab initial;

  static Future<bool> show(
    BuildContext context,
    Customer customer, {
    required bool mayCollect,
    required bool mayAddDue,
    required bool mayGiveDiscount,
    CustomerDueTab initial = CustomerDueTab.collect,
  }) async =>
      await showAppSheet<bool>(
        context,
        title: customer.name,
        builder: (_) => CustomerDueSheet(
          customer: customer,
          mayCollect: mayCollect,
          mayAddDue: mayAddDue,
          mayGiveDiscount: mayGiveDiscount,
          initial: initial,
        ),
      ) ??
      false;

  @override
  ConsumerState<CustomerDueSheet> createState() => _CustomerDueSheetState();
}

class _CustomerDueSheetState extends ConsumerState<CustomerDueSheet> {
  late final TextEditingController _collectAmount;
  late final TextEditingController _addAmount;
  final _discount = TextEditingController();
  final _reason = TextEditingController();
  final _remark = TextEditingController();

  late CustomerDueTab _tab;
  int? _accountId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _collectAmount = TextEditingController(
      // The common case is collecting the lot, so the field starts there.
      text: ref.read(moneyProvider).plain(widget.customer.due),
    );
    _addAmount = TextEditingController();
    _tab = widget.initial;
    if (_tab == CustomerDueTab.collect && !widget.mayCollect) {
      _tab = CustomerDueTab.add;
    }
    if (_tab == CustomerDueTab.add && !widget.mayAddDue) {
      _tab = CustomerDueTab.collect;
    }
  }

  @override
  void dispose() {
    _collectAmount.dispose();
    _addAmount.dispose();
    _discount.dispose();
    _reason.dispose();
    _remark.dispose();
    super.dispose();
  }

  num get _collectValue => AmountField.read(_collectAmount) ?? 0;
  num get _addValue => AmountField.read(_addAmount) ?? 0;
  num get _discountValue =>
      widget.mayGiveDiscount ? (AmountField.read(_discount) ?? 0) : 0;

  bool get _discountOn => _discountValue > 0;

  /// What would be left after this collection. Never below zero: the sheet
  /// refuses an over-collection before it can show a negative remainder.
  num get _stillOwed {
    final left = widget.customer.due - _collectValue - _discountValue;
    return left < 0 ? 0 : left;
  }

  String get _reasonText => _reason.text.trim();
  String get _remarkText => _remark.text.trim();

  bool get _overCollecting =>
      _collectValue + _discountValue > widget.customer.due + 0.005;

  bool get _canSubmit {
    if (_busy) return false;
    if (_tab == CustomerDueTab.collect) {
      final total = _collectValue + _discountValue;
      if (!widget.mayCollect || total <= 0 || _overCollecting) return false;
      if (_discountOn && _reasonText.length < 3) return false;
      return true;
    }
    return widget.mayAddDue &&
        _addValue > 0 &&
        _remarkText.length >= 3 &&
        _remarkText.length <= 200;
  }

  PosAccount? _account(List<PosAccount> accounts) {
    if (accounts.isEmpty) return null;
    final id = _accountId;
    if (id != null) {
      for (final account in accounts) {
        if (account.id == id) return account;
      }
    }
    for (final account in accounts) {
      if (account.isDefault) return account;
    }
    return accounts.first;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final l10n = AppL10n.of(context);
    final money = ref.read(moneyProvider);

    setState(() => _busy = true);
    try {
      if (_tab == CustomerDueTab.collect) {
        final accounts =
            ref.read(customerAccountsProvider).value ?? const <PosAccount>[];
        final account = _account(accounts);
        final discount = _discountOn ? _discountValue : null;
        final result = await ref
            .read(customersRepositoryProvider)
            .collect(
              widget.customer.id,
              amount: _collectValue,
              discount: discount,
              discountReason: discount == null ? null : _reasonText,
              accountId: account?.id,
              method: account == null
                  ? null
                  : PayMethod.forAccount(account).wire,
            );
        _refresh();
        if (!mounted) return;

        showNote(
          context,
          discount == null
              ? l10n.dueCollected(
                  money.format(result.collected),
                  money.format(result.outstanding),
                )
              : l10n.dueCollectedDiscounted(
                  money.format(result.collected),
                  money.format(result.discounted),
                  money.format(result.outstanding),
                ),
        );
      } else {
        final result = await ref
            .read(customersRepositoryProvider)
            .addDue(
              widget.customer.id,
              amount: _addValue,
              remark: _remarkText,
            );
        _refresh();
        if (!mounted) return;

        showNote(
          context,
          l10n.dueAddDone(
            money.format(result.added),
            money.format(result.outstanding),
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The list and the ledger both moved; every other customer's row did not.
  void _refresh() {
    ref.invalidate(customersProvider);
    ref.invalidate(customerLedgerProvider(widget.customer.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final accounts =
        ref.watch(customerAccountsProvider).value ?? const <PosAccount>[];
    final selectedAccount = _account(accounts);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.mayCollect && widget.mayAddDue) ...[
                  SegmentedButton<CustomerDueTab>(
                    segments: [
                      ButtonSegment(
                        value: CustomerDueTab.collect,
                        label: Text(l10n.collectDue),
                      ),
                      ButtonSegment(
                        value: CustomerDueTab.add,
                        label: Text(l10n.addDue),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (values) =>
                        setState(() => _tab = values.first),
                  ),
                  const SizedBox(height: Insets.s16),
                ],
                _TotalOwed(amount: widget.customer.due, money: money),
                const SizedBox(height: Insets.s16),
                if (_tab == CustomerDueTab.collect) ...[
                  AmountField(
                    controller: _collectAmount,
                    label: l10n.amountReceived,
                    prefix: money.sign,
                    autofocus: true,
                    errorText: _overCollecting
                        ? l10n.dueOverCollection
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (widget.mayGiveDiscount) ...[
                    const SizedBox(height: Insets.s12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AmountField(
                            controller: _discount,
                            label: l10n.discount,
                            prefix: money.sign,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: Insets.s12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _reason,
                            decoration: InputDecoration(
                              labelText: l10n.discountReason,
                              hintText: l10n.discountReasonHint,
                              helperText: l10n.discountReasonHelp,
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (accounts.isNotEmpty) ...[
                    const SizedBox(height: Insets.s12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedAccount?.id,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.toAccount,
                        isDense: true,
                      ),
                      items: [
                        for (final account in accounts)
                          DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ),
                      ],
                      onChanged: (id) => setState(() => _accountId = id),
                    ),
                  ],
                  const SizedBox(height: Insets.s16),
                  Row(
                    children: [
                      Expanded(
                        child: _Figure(
                          label: l10n.received,
                          value: money.format(_collectValue),
                          tone: palette.positive,
                        ),
                      ),
                      if (widget.mayGiveDiscount) ...[
                        const SizedBox(width: Insets.s8),
                        Expanded(
                          child: _Figure(
                            label: l10n.discount,
                            value: money.format(_discountValue),
                            tone: palette.accent,
                          ),
                        ),
                      ],
                      const SizedBox(width: Insets.s8),
                      Expanded(
                        child: _Figure(
                          label: l10n.stillOwed,
                          value: money.format(_stillOwed),
                          tone: _stillOwed > 0
                              ? palette.warning
                              : palette.muted,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  AmountField(
                    controller: _addAmount,
                    label: l10n.amountToAdd,
                    prefix: money.sign,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: Insets.s12),
                  TextField(
                    controller: _remark,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: l10n.addDueRemark,
                      hintText: l10n.addDueRemarkHint,
                      helperText: l10n.addDueRemarkHelp,
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: Insets.s8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.newTotalOwed,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        money.format(widget.customer.due + _addValue),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: palette.warning,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SheetAction(
            label: _tab == CustomerDueTab.collect
                ? l10n.collectDue
                : l10n.addDue,
            busy: _busy,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}

/// The whole balance, stated once at the top so every figure below has a
/// reference point.
class _TotalOwed extends StatelessWidget {
  const _TotalOwed({required this.amount, required this.money});

  final num amount;
  final Money money;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.s12,
        vertical: Insets.s16,
      ),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: palette.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            AppL10n.of(context).totalOwed.toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: palette.warning,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Insets.s4),
          Text(
            money.format(amount),
            style: text.headlineSmall?.copyWith(
              color: palette.warning,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the three preview figures under the form.
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.s4,
        vertical: Insets.s8,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: Insets.s4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(
              color: tone ?? palette.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
