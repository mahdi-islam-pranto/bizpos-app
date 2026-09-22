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
import '../../pos/data/pos_repository.dart';
import '../data/sale_models.dart';
import '../data/sales_repository.dart';

/// Collecting money against an outstanding invoice.
///
/// Paying more than is owed is `422 over_payment`, so the field is capped to
/// the due before it ever leaves — a refusal a person can avoid is better than
/// a refusal explained well.
class CollectPaymentSheet extends ConsumerStatefulWidget {
  const CollectPaymentSheet({required this.sale, super.key});

  final SaleDetail sale;

  static Future<bool> show(BuildContext context, SaleDetail sale) async =>
      await showAppSheet<bool>(
        context,
        title: AppL10n.of(context).collectTitle,
        subtitle: sale.invoiceNo,
        builder: (_) => CollectPaymentSheet(sale: sale),
      ) ??
      false;

  @override
  ConsumerState<CollectPaymentSheet> createState() =>
      _CollectPaymentSheetState();
}

class _CollectPaymentSheetState extends ConsumerState<CollectPaymentSheet> {
  late final TextEditingController _amount =
      TextEditingController(text: _plain(widget.sale.due));
  PayMethod _method = PayMethod.cash;
  int? _accountId;
  bool _busy = false;

  static String _plain(num value) => (value * 100).round() % 100 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    final amount = AmountField.read(_amount);
    if (amount == null || amount <= 0) return;

    setState(() => _busy = true);
    try {
      await ref.read(salesRepositoryProvider).collect(
            widget.sale.id,
            amount: amount,
            method: _method.wire,
            accountId: _accountId,
          );
      if (!mounted) return;
      final money = ref.read(moneyProvider);
      showNote(context, AppL10n.of(context).collected(money.format(amount)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
    final money = ref.watch(moneyProvider);
    // The account list belongs to the POS lookups; reusing it means the money
    // lands in the same accounts a sale would.
    final accounts = ref.watch(posLookupsProvider).value?.accounts ??
        const <PosAccount>[];

    final typed = AmountField.read(_amount) ?? 0;
    final overPaying = typed > widget.sale.due;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.outstanding,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      money.format(widget.sale.due),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: palette.warning,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.s24),
                AmountField(
                  controller: _amount,
                  label: l10n.collectAmount,
                  prefix: money.sign,
                  autofocus: true,
                  errorText: overPaying ? l10n.overPayment : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Insets.s8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => setState(
                      () => _amount.text = _plain(widget.sale.due),
                    ),
                    child: Text(l10n.collectAll),
                  ),
                ),
                const SizedBox(height: Insets.s8),
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
                            selected: _method == method,
                            onSelected: (_) =>
                                setState(() => _method = method),
                          ),
                        ),
                    ],
                  ),
                ),
                if (accounts.isNotEmpty) ...[
                  const SizedBox(height: Insets.s16),
                  DropdownButtonFormField<int>(
                    initialValue: _accountId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.account),
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
              ],
            ),
          ),
          SheetAction(
            label: l10n.collectDue,
            icon: Icons.payments_outlined,
            busy: _busy,
            onPressed: overPaying ? null : _collect,
          ),
        ],
      ),
    );
  }
}

/// Goods coming back, line by line.
///
/// The invoice stands — this is not a cancellation. `saleItemId` is the line's
/// own `id` from the detail response, and the server refuses a quantity larger
/// than what is left on that line with a message that names the figure.
class ReturnSheet extends ConsumerStatefulWidget {
  const ReturnSheet({required this.sale, super.key});

  final SaleDetail sale;

  static Future<bool> show(BuildContext context, SaleDetail sale) async =>
      await showAppSheet<bool>(
        context,
        title: AppL10n.of(context).returnTitle,
        subtitle: sale.invoiceNo,
        builder: (_) => ReturnSheet(sale: sale),
      ) ??
      false;

  @override
  ConsumerState<ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends ConsumerState<ReturnSheet> {
  final Map<int, num> _qty = {};
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _anySelected => _qty.values.any((q) => q > 0);

  Future<void> _submit() async {
    final items = [
      for (final entry in _qty.entries)
        if (entry.value > 0)
          {'saleItemId': entry.key, 'qty': entry.value},
    ];
    if (items.isEmpty) return;

    setState(() => _busy = true);
    try {
      final result = await ref.read(salesRepositoryProvider).createReturn(
            widget.sale.id,
            items: items,
            reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
          );
      if (!mounted) return;
      showNote(context, AppL10n.of(context).returnDone(result.returnNo));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Insets.gutter),
            children: [
              Text(
                l10n.returnBody,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: Insets.s16),
              for (final item in widget.sale.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.s8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name),
                            Text(
                              '${money.format(item.unitPrice)} · '
                              '${l10n.returnOf(item.qty.toStringAsFixed(0))}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: palette.muted),
                            ),
                          ],
                        ),
                      ),
                      QtyStepper(
                        qty: _qty[item.id] ?? 0,
                        min: 0,
                        max: item.qty,
                        compact: true,
                        onChanged: (value) => setState(() {
                          // Capped at what the line sold, so the obvious
                          // mistake never reaches the server.
                          _qty[item.id] =
                              value.clamp(0, item.qty);
                        }),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Insets.s16),
              TextField(
                controller: _reason,
                decoration: InputDecoration(
                  labelText: l10n.returnReason,
                  hintText: l10n.returnReasonHint,
                ),
              ),
            ],
          ),
        ),
        SheetAction(
          label: l10n.acceptReturn,
          icon: Icons.undo,
          busy: _busy,
          onPressed: _anySelected ? _submit : null,
        ),
      ],
    );
  }
}

/// Cancelling the sale outright.
///
/// This is the one counter action with no undo, so it spells out what it does
/// before asking for a reason. The reason is required (3–255 characters) and
/// the server refuses a second attempt, so the button latches while in flight.
class VoidSaleSheet extends ConsumerStatefulWidget {
  const VoidSaleSheet({required this.sale, super.key});

  final SaleDetail sale;

  static Future<bool> show(BuildContext context, SaleDetail sale) async =>
      await showAppSheet<bool>(
        context,
        title: AppL10n.of(context).voidTitle,
        subtitle: sale.invoiceNo,
        builder: (_) => VoidSaleSheet(sale: sale),
      ) ??
      false;

  @override
  ConsumerState<VoidSaleSheet> createState() => _VoidSaleSheetState();
}

class _VoidSaleSheetState extends ConsumerState<VoidSaleSheet> {
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _void() async {
    final reason = _reason.text.trim();
    if (reason.length < 3) return;

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(salesRepositoryProvider)
          .voidSale(widget.sale.id, reason: reason);
      if (!mounted) return;
      showNote(
        context,
        AppL10n.of(context).voidDone(
          result.invoiceNo,
          result.restored.toStringAsFixed(0),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final reason = _reason.text.trim();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(Insets.s12),
                  decoration: BoxDecoration(
                    color: palette.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(Radii.row),
                  ),
                  child: Text(
                    l10n.voidBody,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: Insets.s16),
                TextField(
                  controller: _reason,
                  autofocus: true,
                  maxLength: 255,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.voidReason,
                    hintText: l10n.voidReasonHint,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          SheetAction(
            label: l10n.voidConfirm,
            icon: Icons.block,
            tone: palette.danger,
            busy: _busy,
            onPressed: reason.length >= 3 ? _void : null,
          ),
        ],
      ),
    );
  }
}
