import 'package:flutter/material.dart';
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
            padding: const EdgeInsets.symmetric(vertical: Insets.s8),
            children: [
              for (final line in cart.lines)
                _CartRow(
                  line: line,
                  money: money,
                  mayEdit: mayDiscount || mayChangePrice,
                  onQty: (qty) => controller.setQty(line.key, qty),
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
                    const SizedBox(height: Insets.s4),
                    // Said plainly, because the number above is the app's own
                    // arithmetic and the receipt's is the server's.
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        l10n.estimatedNote,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
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
          label: '${l10n.charge}  ${money.format(cart.estimatedTotal.toDouble())}',
          icon: Icons.point_of_sale,
          onPressed: () async {
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
  }) =>
      showAppSheet<void>(
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
    required this.onEdit,
  });

  final CartLine line;
  final Money money;
  final bool mayEdit;
  final ValueChanged<num> onQty;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.gutter,
        vertical: Insets.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: text.bodySmall
                                  ?.copyWith(color: palette.muted),
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
                onChanged: onQty,
                compact: true,
              ),
              SizedBox(
                width: 84,
                child: Text(
                  money.format(line.subtotal.toDouble()),
                  textAlign: TextAlign.end,
                  style: text.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
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
        ],
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
      title: Text(
        cart.hasNamedCustomer ? customer!.name : l10n.walkInCustomer,
      ),
      subtitle: cart.hasNamedCustomer
          ? Text(customer!.phone ?? l10n.noPhone)
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
        TextButton(
          onPressed: () async {
            final amount = await _askAmount(
              context,
              title: l10n.orderDiscount,
              initial: cart.orderDiscount,
            );
            ref.read(cartProvider.notifier).setOrderDiscount(amount);
          },
          child: Text(
            cart.orderDiscount == null || cart.orderDiscount == 0
                ? l10n.add
                : '−${money.format(cart.orderDiscount)}',
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

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              children: [
                if (widget.mayChangePrice)
                  AmountField(
                    controller: _price,
                    label: l10n.unitPrice,
                    prefix: money.sign,
                    helperText: money.format(widget.line.item.salePrice),
                  ),
                if (widget.mayChangePrice && widget.mayDiscount)
                  const SizedBox(height: Insets.s16),
                if (widget.mayDiscount)
                  AmountField(
                    controller: _discount,
                    label: l10n.lineDiscount,
                    prefix: money.sign,
                  ),
                const SizedBox(height: Insets.s16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      ref
                          .read(cartProvider.notifier)
                          .remove(widget.line.key);
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
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}

/// A one-field money prompt. Returns null when the field is left empty, which
/// is how a discount is removed rather than set to zero.
Future<num?> _askAmount(
  BuildContext context, {
  required String title,
  num? initial,
}) async {
  final controller = TextEditingController(
    text: initial == null || initial == 0 ? '' : initial.toString(),
  );

  final result = await showAppSheet<num?>(
    context,
    title: title,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(Insets.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmountField(
            controller: controller,
            label: title,
            autofocus: true,
            onSubmitted: (_) => Navigator.of(sheetContext)
                .pop(AmountField.read(controller)),
          ),
          const SizedBox(height: Insets.s24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(sheetContext)
                  .pop(AmountField.read(controller)),
              child: Text(AppL10n.of(sheetContext).apply),
            ),
          ),
        ],
      ),
    ),
  );

  controller.dispose();
  return result;
}
