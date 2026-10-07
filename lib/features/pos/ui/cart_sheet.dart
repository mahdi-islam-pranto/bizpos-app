import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/pos_models.dart';
import '../state/cart.dart';
import 'customer_picker_sheet.dart';
import 'payment_sheet.dart';

/// The cart, before paying.
///
/// Price and discount controls appear **only** with `pos.sale.change_price` and
/// `pos.sale.give_discount`. This is not decoration: without the permission the
/// server silently ignores those fields, so offering them would let a cashier
/// type a discount, watch it land in the cart, and then find it missing from
/// the receipt with no error anywhere.
class CartSheet extends ConsumerWidget {
  const CartSheet({required this.lookups, super.key});

  final PosLookups lookups;

  static Future<void> show(BuildContext context, PosLookups lookups) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).cart,
        builder: (_) => CartSheet(lookups: lookups),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final cart = ref.watch(cartProvider);
    final controller = ref.read(cartProvider.notifier);
    final permissions = ref.watch(permissionsProvider);

    final mayDiscount = permissions.has(P.posSaleGiveDiscount);
    final mayChangePrice = permissions.has(P.posSaleChangePrice);

    if (cart.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Insets.s32),
        child: EmptyState(
          title: l10n.cartEmpty,
          body: l10n.cartEmptyBody,
          icon: Icons.shopping_cart_outlined,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: Insets.s8),
            children: [
              for (final line in cart.lines)
                _CartRow(
                  line: line,
                  money: money,
                  mayEdit: mayDiscount || mayChangePrice,
                  onQty: (qty) => controller.setQty(line.key, qty),
                  onRemove: () => controller.remove(line.key),
                  onEdit: () => _editLine(
                    context,
                    ref,
                    line,
                    mayChangePrice: mayChangePrice,
                    mayDiscount: mayDiscount,
                  ),
                ),
              const SizedBox(height: Insets.s8),
              Divider(color: palette.hairline, height: 1),
              _CustomerRow(lookups: lookups),
              Divider(color: palette.hairline, height: 1),
              Padding(
                padding: const EdgeInsets.all(Insets.gutter),
                child: Column(
                  children: [
                    _TotalRow(
                      label: l10n.subtotal,
                      value: money.format(cart.linesTotal.toDouble()),
                    ),
                    if (mayDiscount) ...[
                      const SizedBox(height: Insets.s8),
                      _DiscountRow(cart: cart, money: money),
                    ],
                    const SizedBox(height: Insets.s12),
                    _TotalRow(
                      label: l10n.estimatedTotal,
                      value: money.format(cart.estimatedTotal.toDouble()),
                      strong: true,
                    ),
                    if (cart.belowCost) ...[
                      const SizedBox(height: Insets.s12),
                      BelowCostNotice(cart: cart),
                    ],
                    const SizedBox(height: Insets.s4),
                    // Said plainly, because the number above is the app's own
                    // arithmetic and the receipt's is the server's.
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        l10n.estimatedNote,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: palette.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(color: palette.hairline, height: 1),
        SheetAction(
          label:
              '${l10n.charge}  ${money.format(cart.estimatedTotal.toDouble())}',
          icon: Icons.point_of_sale,
          // The server refuses a sale below cost. Taking the money first and
          // being refused after is the one order a counter cannot afford.
          onPressed: cart.belowCost
              ? null
              : () async {
                  Navigator.of(context).pop();
                  await PaymentSheet.show(context, lookups: lookups);
                },
        ),
      ],
    );
  }

  Future<void> _editLine(
    BuildContext context,
    WidgetRef ref,
    CartLine line, {
    required bool mayChangePrice,
    required bool mayDiscount,
  }) => showAppSheet<void>(
    context,
    title: AppL10n.of(context).editLine(line.item.name),
    builder: (_) => _EditLineSheet(
      line: line,
      mayChangePrice: mayChangePrice,
      mayDiscount: mayDiscount,
    ),
  );
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.line,
    required this.money,
    required this.mayEdit,
    required this.onQty,
    required this.onRemove,
    required this.onEdit,
  });

  final CartLine line;
  final Money money;
  final bool mayEdit;
  final ValueChanged<num> onQty;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    // A line can go in one tap (or a swipe), without stepping its quantity
    // down to zero first.
    return Dismissible(
      key: ValueKey(line.key),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: palette.danger,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
        child: Icon(Icons.delete_outline, color: palette.surface),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: Insets.gutter,
          end: Insets.s4,
          top: Insets.s8,
          bottom: Insets.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: mayEdit ? onEdit : null,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                line.item.name,
                                style: text.bodyLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (line.item.isPackage) ...[
                              const SizedBox(width: Insets.s8),
                              StatusChip(
                                label: l10n.packageBadge,
                                tone: palette.accent,
                              ),
                            ],
                          ],
                        ),
                        if (line.item.stock != null)
                          Text(
                            _stockLabel(l10n, line.item),
                            style: text.labelSmall?.copyWith(
                              color: line.atStock
                                  ? palette.warning
                                  : palette.muted,
                            ),
                          ),
                        const SizedBox(height: Insets.s4),
                        Row(
                          children: [
                            Text(
                              money.format(line.effectivePrice),
                              style: text.bodySmall?.copyWith(
                                color: palette.muted,
                                // A changed price is worth seeing at a glance.
                                fontWeight: line.unitPrice != null
                                    ? FontWeight.w600
                                    : null,
                              ),
                            ),
                            if (line.item.unit != null)
                              Text(
                                ' / ${line.item.unit}',
                                style: text.bodySmall?.copyWith(
                                  color: palette.muted,
                                ),
                              ),
                            if (line.lineDiscount != null &&
                                line.lineDiscount! > 0) ...[
                              const SizedBox(width: Insets.s8),
                              StatusChip(
                                label: '−${money.format(line.lineDiscount)}',
                                tone: palette.accent,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Insets.s8),
                QtyStepper(
                  qty: line.qty,
                  max: line.item.stock,
                  capAtMax: true,
                  onChanged: onQty,
                  compact: true,
                  onTapQty: () async {
                    final picked = await QtyPickerSheet.show(
                      context,
                      current: line.qty,
                      stock: line.item.stock,
                      unit: line.item.unit,
                    );
                    if (picked != null) onQty(picked);
                  },
                ),
                SizedBox(
                  width: 76,
                  child: Text(
                    money.format(line.subtotal.toDouble()),
                    textAlign: TextAlign.end,
                    style: text.titleSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  tooltip: l10n.removeLine,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 20, color: palette.danger),
                ),
              ],
            ),
            if (line.overStock)
              Padding(
                padding: const EdgeInsets.only(top: Insets.s4),
                child: Text(
                  l10n.overStockWarning(
                    (line.item.stock ?? 0).toStringAsFixed(0),
                  ),
                  style: text.labelSmall?.copyWith(color: palette.warning),
                ),
              ),
            if (line.belowCost)
              Padding(
                padding: const EdgeInsets.only(top: Insets.s4),
                child: Text(
                  l10n.lineBelowCostShort,
                  style: text.labelSmall?.copyWith(color: palette.danger),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerRow extends ConsumerWidget {
  const _CustomerRow({required this.lookups});

  final PosLookups lookups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final cart = ref.watch(cartProvider);
    final customer = cart.customer;

    return ListTile(
      leading: Icon(
        cart.hasNamedCustomer ? Icons.person : Icons.person_outline,
        color: cart.hasNamedCustomer ? palette.accent : palette.muted,
      ),
      title: Text(cart.hasNamedCustomer ? customer!.name : l10n.walkInCustomer),
      // The khata is one figure: what they owed walking in sits beside the
      // cart, because the next question is whether they are paying it.
      subtitle: cart.hasNamedCustomer
          ? Text(
              (customer!.due ?? 0) > 0
                  ? '${customer.phone ?? l10n.noPhone} · '
                        '${l10n.previousDueLabel} ${ref.watch(moneyProvider).format(customer.due)}'
                  : customer.phone ?? l10n.noPhone,
              style: (customer.due ?? 0) > 0
                  ? TextStyle(color: palette.warning)
                  : null,
            )
          : Text(l10n.chooseCustomer),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await CustomerPickerSheet.show(
          context,
          lookups: lookups,
          selected: customer,
        );
        if (picked == null) return;
        // The walk-in entry means "nobody in particular", which is the same as
        // no customer as far as credit and points are concerned.
        ref
            .read(cartProvider.notifier)
            .setCustomer(picked.isWalkIn ? null : picked);
      },
    );
  }
}

class _DiscountRow extends ConsumerWidget {
  const _DiscountRow({required this.cart, required this.money});

  final Cart cart;
  final Money money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.orderDiscount,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        // A rate, because the till sends one: ten percent off stays ten
        // percent off when another item goes in the basket.
        TextButton(
          onPressed: () async {
            // How far the rate can go before the bill drops under what its
            // goods cost — known only when every line's cost is.
            final maxRate = cart.maxOrderDiscountPercent;
            final maxOff = maxRate == null
                ? null
                : Exact.paisa((cart.linesTotal * maxRate).shift(-2));
            final rate = await _askAmount(
              context,
              title: l10n.orderDiscountPercent,
              initial: cart.orderDiscountPercent,
              suffix: '%',
              max: maxRate?.toDouble(),
              helperText: maxRate == null
                  ? null
                  : maxRate <= Decimal.zero
                  ? l10n.noDiscountRoom
                  : l10n.maxBillDiscount(
                      _rate(maxRate.toDouble()),
                      money.format(maxOff!.toDouble()),
                    ),
              overMaxText: maxRate == null
                  ? null
                  : l10n.billDiscountTooHigh(_rate(maxRate.toDouble())),
            );
            ref.read(cartProvider.notifier).setOrderDiscountPercent(rate);
          },
          child: Text(
            (cart.orderDiscountPercent ?? 0) <= 0
                ? l10n.add
                : '${_rate(cart.orderDiscountPercent!)}%  '
                      '−${money.format(cart.orderDiscountAmount.toDouble())}',
            style: TextStyle(color: palette.accent),
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = strong ? text.titleLarge : text.bodyMedium;

    return Row(
      children: [
        Expanded(child: Text(label, style: strong ? text.titleMedium : style)),
        Text(
          value,
          style: style?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Unit price and line discount for one line.
class _EditLineSheet extends ConsumerStatefulWidget {
  const _EditLineSheet({
    required this.line,
    required this.mayChangePrice,
    required this.mayDiscount,
  });

  final CartLine line;
  final bool mayChangePrice;
  final bool mayDiscount;

  @override
  ConsumerState<_EditLineSheet> createState() => _EditLineSheetState();
}

class _EditLineSheetState extends ConsumerState<_EditLineSheet> {
  late final TextEditingController _price = TextEditingController(
    text: widget.line.unitPrice == null
        ? ''
        : widget.line.unitPrice!.toString(),
  );
  late final TextEditingController _discount = TextEditingController(
    text: widget.line.lineDiscount == null
        ? ''
        : widget.line.lineDiscount!.toString(),
  );

  @override
  void dispose() {
    _price.dispose();
    _discount.dispose();
    super.dispose();
  }

  void _apply() {
    final controller = ref.read(cartProvider.notifier);
    if (widget.mayChangePrice) {
      controller.setUnitPrice(widget.line.key, AmountField.read(_price));
    }
    if (widget.mayDiscount) {
      controller.setLineDiscount(widget.line.key, AmountField.read(_discount));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final money = ref.watch(moneyProvider);
    final line = widget.line;

    // What one unit cost the shop, beside what it sells for, so the cashier
    // can see how much room there is to give. Null without
    // `inventory.product.view_cost`, and for a bundle, whose cost is judged
    // across its products — then only the selling price shows.
    final cost = line.knownCost == null ? null : line.item.purchasePrice;
    final typedPrice = widget.mayChangePrice ? AmountField.read(_price) : null;
    final price = widget.mayChangePrice
        ? typedPrice ?? line.item.salePrice
        : line.effectivePrice;
    final priceBelowCost = cost != null && typedPrice != null && price < cost;
    final maxOff = line.maxLineDiscount(price: price);
    final discount = widget.mayDiscount ? AmountField.read(_discount) : null;
    final discountTooHigh =
        maxOff != null && discount != null && Exact.of(discount) > maxOff;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              children: [
                _PriceFacts(
                  salePrice: line.item.salePrice,
                  cost: cost,
                  money: money,
                ),
                const SizedBox(height: Insets.s16),
                if (widget.mayChangePrice)
                  AmountField(
                    controller: _price,
                    label: l10n.unitPrice,
                    prefix: money.sign,
                    helperText: money.format(line.item.salePrice),
                    errorText: priceBelowCost
                        ? l10n.unitPriceBelowCost(money.format(cost))
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                if (widget.mayChangePrice && widget.mayDiscount)
                  const SizedBox(height: Insets.s16),
                if (widget.mayDiscount)
                  AmountField(
                    controller: _discount,
                    label: l10n.lineDiscount,
                    prefix: money.sign,
                    helperText: maxOff == null
                        ? null
                        : l10n.maxLineDiscount(
                            money.format(maxOff.toDouble()),
                          ),
                    errorText: discountTooHigh
                        ? l10n.lineDiscountTooHigh(
                            money.format(maxOff.toDouble()),
                          )
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                const SizedBox(height: Insets.s16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(cartProvider.notifier).remove(widget.line.key);
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: context.palette.danger,
                    ),
                    label: Text(
                      l10n.removeLine,
                      style: TextStyle(color: context.palette.danger),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SheetAction(
            label: l10n.apply,
            icon: Icons.check,
            // The server refuses a line under its cost; better said here.
            onPressed: priceBelowCost || discountTooHigh ? null : _apply,
          ),
        ],
      ),
    );
  }
}

/// Selling price and, when the role may see it, cost — side by side.
class _PriceFacts extends StatelessWidget {
  const _PriceFacts({
    required this.salePrice,
    required this.cost,
    required this.money,
  });

  final num salePrice;
  final num? cost;
  final Money money;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    Widget fact(String label, num value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall?.copyWith(color: palette.muted)),
          const SizedBox(height: Insets.s4),
          Text(
            money.format(value),
            style: text.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.row),
      ),
      child: Row(
        children: [
          fact(l10n.sellingPriceLabel, salePrice),
          if (cost != null) fact(l10n.costLabel, cost!),
        ],
      ),
    );
  }
}

/// A one-field money prompt. Returns null when the field is left empty, which
/// is how a discount is removed rather than set to zero.
///
/// With [max], a figure past it shows [overMaxText] and cannot be applied.
Future<num?> _askAmount(
  BuildContext context, {
  required String title,
  num? initial,
  String? suffix,
  num? max,
  String? helperText,
  String? overMaxText,
}) => showAppSheet<num?>(
  context,
  title: title,
  builder: (_) => _AmountPrompt(
    title: title,
    initial: initial,
    suffix: suffix,
    max: max,
    helperText: helperText,
    overMaxText: overMaxText,
  ),
);

/// The prompt owns its controller, so the controller dies with the sheet.
///
/// It used to be created outside and disposed the moment the sheet's future
/// completed — but that future completes when `pop` is called, while the sheet
/// is still animating out with its text field attached. Disposing under a live
/// field tore the overlay down mid-frame (`_dependents.isEmpty`), and Apply
/// showed a red screen instead of a discount.
class _AmountPrompt extends StatefulWidget {
  const _AmountPrompt({
    required this.title,
    this.initial,
    this.suffix,
    this.max,
    this.helperText,
    this.overMaxText,
  });

  final String title;
  final num? initial;
  final String? suffix;
  final num? max;
  final String? helperText;
  final String? overMaxText;

  @override
  State<_AmountPrompt> createState() => _AmountPromptState();
}

class _AmountPromptState extends State<_AmountPrompt> {
  late final _controller = TextEditingController(
    text: widget.initial == null || widget.initial == 0
        ? ''
        : widget.initial.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _overMax {
    final max = widget.max;
    final value = AmountField.read(_controller);
    return max != null && value != null && value > max;
  }

  void _submit() {
    if (_overMax) return;
    // Keyboard down first, so the sheet closes without a focused field.
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(AmountField.read(_controller));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Insets.gutter),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AmountField(
          controller: _controller,
          label: widget.title,
          prefix: widget.suffix,
          autofocus: true,
          helperText: widget.helperText,
          errorText: _overMax ? widget.overMaxText : null,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: Insets.s24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _overMax ? null : _submit,
            child: Text(AppL10n.of(context).apply),
          ),
        ),
      ],
    ),
  );
}

/// Quick quantities for a line, plus any figure typed by hand.
///
/// Stepping `+` thirty times is how a counter loses a queue. The common
/// round numbers are one tap each; anything else (`7`, `2.5` kg) goes in the
/// box underneath.
class QtyPickerSheet extends StatefulWidget {
  const QtyPickerSheet({
    required this.current,
    this.stock,
    this.unit,
    super.key,
  });

  final num current;
  final num? stock;
  final String? unit;

  static const presets = <num>[1, 2, 3, 5, 10, 20, 30, 50];

  static Future<num?> show(
    BuildContext context, {
    required num current,
    num? stock,
    String? unit,
  }) => showAppSheet<num>(
    context,
    title: AppL10n.of(context).qtyPickerTitle,
    builder: (_) => QtyPickerSheet(current: current, stock: stock, unit: unit),
  );

  @override
  State<QtyPickerSheet> createState() => _QtyPickerSheetState();
}

class _QtyPickerSheetState extends State<QtyPickerSheet> {
  // Owned here so it dies with the sheet, not when the sheet's future
  // completes — see [_AmountPrompt].
  late final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(num? qty) {
    if (qty == null || qty <= 0) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(qty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final stock = widget.stock;
    const perRow = 4;
    const presets = QtyPickerSheet.presets;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Insets.gutter),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stock != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.s12),
                child: Text(
                  l10n.onShelf(_rate(stock)),
                  style: text.bodySmall?.copyWith(color: palette.muted),
                ),
              ),
            for (var start = 0; start < presets.length; start += perRow) ...[
              if (start > 0) const SizedBox(height: Insets.s8),
              Row(
                children: [
                  for (var i = start; i < start + perRow; i++) ...[
                    if (i > start) const SizedBox(width: Insets.s8),
                    Expanded(
                      child: i < presets.length
                          ? _PresetButton(
                              qty: presets[i],
                              selected: presets[i] == widget.current,
                              overStock: stock != null &&
                                  presets[i] > stock &&
                                  presets[i] != widget.current,
                              onTap: () => _pick(presets[i]),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: Insets.s16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,3}'),
                      ),
                    ],
                    onSubmitted: (value) => _pick(num.tryParse(value.trim())),
                    decoration: InputDecoration(
                      labelText: l10n.qtyCustom,
                      hintText: _rate(widget.current),
                      suffixText: widget.unit,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: Insets.s8),
                FilledButton(
                  onPressed: () => _pick(num.tryParse(_controller.text.trim())),
                  child: Text(l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.qty,
    required this.selected,
    required this.overStock,
    required this.onTap,
  });

  final num qty;
  final bool selected;
  final bool overStock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = Text(
      _rate(qty),
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    );

    if (selected) return FilledButton(onPressed: onTap, child: label);
    // More than the branch has is not on offer: the server would refuse it.
    return OutlinedButton(
      onPressed: overStock ? null : onTap,
      style: overStock
          ? OutlinedButton.styleFrom(
              disabledForegroundColor: palette.muted,
              side: BorderSide(color: palette.hairline),
            )
          : null,
      child: label,
    );
  }
}

/// "12 in stock" for a product, "3 can be made" for a bundle.
String _stockLabel(AppL10n l10n, SellableItem item) {
  final stock = item.stock!;
  if (stock <= 0) return l10n.outOfStock;
  return item.isPackage
      ? l10n.buildable(_rate(stock))
      : l10n.inStock(_rate(stock));
}

String _rate(num value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

/// Why the pay button is off. The messages name no figures: a cashier may sell
/// without being allowed to see what anything cost.
class BelowCostNotice extends StatelessWidget {
  const BelowCostNotice({required this.cart, super.key});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.block, size: 16, color: palette.danger),
        const SizedBox(width: Insets.s8),
        Expanded(
          child: Text(
            cart.hasBelowCostLine ? l10n.lineBelowCost : l10n.discountBelowCost,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.danger),
          ),
        ),
      ],
    );
  }
}
