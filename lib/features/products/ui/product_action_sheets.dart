import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../l10n/app_localizations.dart';
import '../data/product_models.dart';
import '../data/products_repository.dart';
import 'pricing_fields.dart';

/// `PATCH /products/{id}/prices`.
///
/// All three prices go together — the API takes the set, not one of them, and
/// checks the rule that spans them. A selling price under the cost is refused,
/// so the save button is off until it holds. It answers `changed: false` when
/// nothing actually moved, which is worth saying rather than claiming a save.
///
/// Opened only by someone who can see the cost: the set cannot be sent without
/// one, and a hidden cost read as blank would be written back as nothing.
class PriceSheet extends ConsumerStatefulWidget {
  const PriceSheet({required this.product, super.key});

  final Product product;

  static Future<void> show(BuildContext context, Product product) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).changePrices,
        builder: (_) => PriceSheet(product: product),
      );

  @override
  ConsumerState<PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends ConsumerState<PriceSheet> {
  late final _pricing = PricingDraft(
    purchasePrice: widget.product.purchasePrice,
    salePrice: widget.product.salePrice,
    wholesalePrice: widget.product.wholesalePrice,
    profitPercent: widget.product.profitPercent,
  );

  bool _busy = false;

  @override
  void dispose() {
    _pricing.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_pricing.isComplete) return;
    final l10n = AppL10n.of(context);

    setState(() => _busy = true);
    try {
      final changed = await ref
          .read(productsRepositoryProvider)
          .setPrices(
            widget.product.id,
            purchasePrice: _pricing.purchaseValue!,
            salePrice: _pricing.saleValue!,
            wholesalePrice: _pricing.wholesaleValue!,
            profitPercent: _pricing.profitValue,
          );
      ref.invalidate(productsListProvider);
      ref.invalidate(productHistoryProvider(widget.product.id));
      ref.invalidate(productStatsProvider);
      if (!mounted) return;

      Navigator.of(context).pop();
      showNote(context, changed ? l10n.pricesSaved : l10n.pricesUnchanged);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final money = ref.watch(moneyProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(Insets.gutter),
          child: PricingFields(
            draft: _pricing,
            money: money,
            mrp: widget.product.mrp,
            autofocusSale: true,
            onChanged: () => setState(() {}),
          ),
        ),
        SheetAction(
          label: l10n.save,
          icon: Icons.check,
          busy: _busy,
          onPressed: _pricing.isComplete ? _save : null,
        ),
      ],
    );
  }
}

/// `POST /products/{id}/adjust` — signed, never zero.
///
/// The sign is the whole meaning of the field, so the form is a plus/minus pair
/// and a magnitude rather than a box somebody has to remember to type a minus
/// into. `isDamage` files it as damage instead of a correction, which is a
/// different line in the stock history.
///
/// Adding is the default: goods turning up is what a shop adjusts most often.
/// The reason is picked from a list — the server's `adjustReasons` when it
/// sends them, the built-in [AdjustReason.defaults] otherwise — with "Other"
/// for anything the list does not cover.
class AdjustStockSheet extends ConsumerStatefulWidget {
  const AdjustStockSheet({required this.product, super.key});

  final Product product;

  static Future<void> show(BuildContext context, Product product) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).adjustStock,
        builder: (_) => AdjustStockSheet(product: product),
      );

  @override
  ConsumerState<AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends ConsumerState<AdjustStockSheet> {
  final _qty = TextEditingController();
  final _reason = TextEditingController();

  bool _isAdding = true;
  bool _isDamage = false;

  /// The chosen reason; null with [_other] false means none chosen yet.
  AdjustReason? _picked;
  bool _other = false;
  bool _busy = false;

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  num get _signed {
    final magnitude = AmountField.read(_qty) ?? 0;
    return _isAdding ? magnitude : -magnitude;
  }

  /// What travels as `reason`: the picked reason as the person read it, or
  /// what they typed under "Other".
  String get _reasonText {
    if (_other) return _reason.text.trim();
    final locale = Localizations.localeOf(context).languageCode;
    return _picked?.labelFor(locale) ?? '';
  }

  void _pick(AdjustReason? reason, {bool other = false}) => setState(() {
    _picked = reason;
    _other = other;
    if (reason != null && !_isAdding) _isDamage = reason.isDamage;
  });

  Future<void> _save() async {
    if (_busy) return;
    final qty = _signed;
    final reason = _reasonText;
    if (qty == 0 || reason.isEmpty) return;

    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    try {
      await ref
          .read(productsRepositoryProvider)
          .adjust(
            widget.product.id,
            qty: qty,
            reason: reason,
            isDamage: _isDamage,
          );
      ref.invalidate(productsListProvider);
      ref.invalidate(productHistoryProvider(widget.product.id));
      ref.invalidate(productStatsProvider);
      if (!mounted) return;

      Navigator.of(context).pop();
      showNote(context, l10n.adjustDone);
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
    final locale = Localizations.localeOf(context).languageCode;
    final stock = widget.product.stock;
    final after = stock == null ? null : stock + _signed;

    final served = ref.watch(productLookupsProvider).value?.adjustReasons;
    final reasons = (served == null || served.isEmpty
            ? AdjustReason.defaults
            : served)
        .where((r) => r.fits(adding: _isAdding))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(Insets.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.add),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.remove),
                    label: Text(l10n.remove),
                  ),
                ],
                selected: {_isAdding},
                onSelectionChanged: (values) => setState(() {
                  _isAdding = values.first;
                  // Putting stock back is never damage.
                  if (_isAdding) _isDamage = false;
                  // A reason for the other direction no longer fits.
                  if (_picked != null && !_picked!.fits(adding: _isAdding)) {
                    _picked = null;
                  }
                  if (!_isAdding && _picked != null) {
                    _isDamage = _picked!.isDamage;
                  }
                }),
              ),
              const SizedBox(height: Insets.s16),
              AmountField(
                controller: _qty,
                label: l10n.adjustQtyLabel,
                autofocus: true,
                helperText: after == null
                    ? l10n.adjustHelp
                    : l10n.balanceAfter(after.toStringAsFixed(0)),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Insets.s16),
              DropdownButtonFormField<int>(
                // Rebuilt when the direction flips, so a cleared choice shows.
                key: ValueKey('reason-$_isAdding-${_picked?.label}-$_other'),
                initialValue: _other
                    ? -1
                    : (_picked == null ? null : reasons.indexOf(_picked!)),
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.adjustReasonLabel),
                hint: Text(l10n.adjustReasonHint),
                items: [
                  for (var i = 0; i < reasons.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        reasons[i].labelFor(locale),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  DropdownMenuItem(
                    value: -1,
                    child: Text(l10n.adjustReasonOther),
                  ),
                ],
                onChanged: (i) {
                  if (i == null) return;
                  i < 0 ? _pick(null, other: true) : _pick(reasons[i]);
                },
              ),
              if (_other) ...[
                const SizedBox(height: Insets.s12),
                TextField(
                  controller: _reason,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.adjustReasonTyped,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              if (!_isAdding) ...[
                const SizedBox(height: Insets.s8),
                CheckboxListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isDamage,
                  onChanged: (value) =>
                      setState(() => _isDamage = value ?? false),
                  title: Text(l10n.adjustIsDamage),
                ),
              ],
              if (after != null && after < 0) ...[
                const SizedBox(height: Insets.s8),
                Text(
                  l10n.outOfStock,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: palette.danger),
                ),
              ],
            ],
          ),
        ),
        SheetAction(
          label: l10n.adjustStock,
          icon: Icons.check,
          busy: _busy,
          // Zero is a refusal from the server, so it is a disabled button here.
          onPressed: _signed == 0 || _reasonText.isEmpty ? null : _save,
        ),
      ],
    );
  }
}
