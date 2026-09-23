import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fields.dart';
import '../../../l10n/app_localizations.dart';
import '../data/product_models.dart';

/// The price boxes of a product, as one set: cost, markup, selling price,
/// wholesale.
///
/// A shop prices by saying "cost plus five percent", so the markup box fills
/// the selling price in, and a new cost carries the selling price with it while
/// a rate is stated. Typing a selling price over it clears the rate, because the
/// price was then named rather than worked out — and a rate left standing
/// beside a hand-typed price would be a reason nobody gave.
///
/// Both travel: `salePrice` is the authority on the money, `profitPercent`
/// records why it is that price.
class PricingDraft {
  PricingDraft({
    num? purchasePrice,
    num? salePrice,
    num? wholesalePrice,
    num? profitPercent,
  })  : purchase = TextEditingController(text: _plain(purchasePrice)),
        sale = TextEditingController(text: _plain(salePrice)),
        wholesale = TextEditingController(text: _plain(wholesalePrice)),
        profit = TextEditingController(text: _plain(profitPercent));

  final TextEditingController purchase;
  final TextEditingController sale;
  final TextEditingController wholesale;
  final TextEditingController profit;

  num? get purchaseValue => AmountField.read(purchase);
  num? get saleValue => AmountField.read(sale);

  /// Blank means the selling price stands, which is what the web form does.
  num? get wholesaleValue => AmountField.read(wholesale) ?? saleValue;

  /// Null when no rate was stated. Not zero.
  num? get profitValue => AmountField.read(profit);

  bool get belowCost => isBelowCost(cost: purchaseValue, sale: saleValue);

  /// Ready to save: the two required prices are there and the one rule the
  /// shop does not bend on holds.
  bool get isComplete =>
      (purchaseValue ?? 0) > 0 && saleValue != null && !belowCost;

  void costChanged() => _reprice();

  void profitChanged() => _reprice();

  /// A price typed by hand. The stated rate no longer explains it.
  void saleChanged() => profit.clear();

  void _reprice() {
    final cost = purchaseValue;
    final rate = profitValue;
    if (cost == null || rate == null) return;
    sale.text = _plain(markupPrice(cost, rate));
  }

  void dispose() {
    purchase.dispose();
    sale.dispose();
    wholesale.dispose();
    profit.dispose();
  }

  static String _plain(num? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}

class PricingFields extends StatelessWidget {
  const PricingFields({
    required this.draft,
    required this.money,
    required this.onChanged,
    this.mrp,
    this.autofocusSale = false,
    super.key,
  });

  final PricingDraft draft;
  final Money money;

  /// Rebuilds the parent, whose save button depends on [PricingDraft.isComplete].
  final VoidCallback onChanged;

  /// The printed price, when the form has one. A selling price above it earns
  /// a warning and not a refusal — the pack may simply be old stock.
  final num? mrp;

  final bool autofocusSale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final sale = draft.saleValue;
    final overMrp = mrp != null && mrp! > 0 && sale != null && sale > mrp!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AmountField(
                controller: draft.purchase,
                label: l10n.costLabel,
                prefix: money.sign,
                onChanged: (_) {
                  draft.costChanged();
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: Insets.s12),
            SizedBox(
              width: 112,
              child: AmountField(
                controller: draft.profit,
                label: l10n.profitPercentLabel,
                prefix: '%',
                onChanged: (_) {
                  draft.profitChanged();
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.s16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AmountField(
                controller: draft.sale,
                label: l10n.saleLabel,
                prefix: money.sign,
                autofocus: autofocusSale,
                errorText: draft.belowCost ? l10n.saleBelowPurchase : null,
                onChanged: (_) {
                  draft.saleChanged();
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: Insets.s12),
            Expanded(
              child: AmountField(
                controller: draft.wholesale,
                label: l10n.wholesaleLabel,
                prefix: money.sign,
                helperText: l10n.wholesaleBlankHelp,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        if (overMrp)
          Padding(
            padding: const EdgeInsets.only(top: Insets.s4),
            child: Text(
              l10n.saleAboveMrp,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: palette.warning),
            ),
          ),
      ],
    );
  }
}

/// A markup as the product list and detail show it: the stated rate plainly,
/// a derived one marked as approximate.
String? markupLabel(Product product) {
  final stated = product.profitPercent;
  if (stated != null) return '${_rate(stated)}%';
  final derived = product.profitRate;
  if (derived != null) return '≈${_rate(derived)}%';
  return null;
}

String _rate(num value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
