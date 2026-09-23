import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../l10n/app_localizations.dart';
import '../../products/data/products_repository.dart';
import '../../products/ui/pricing_fields.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';

/// `POST /catalog/{id}/adopt` — this shop's prices on a catalogue product.
///
/// The catalogue's defaults fill the form in so the shopkeeper only corrects
/// them, MRP included. Opening stock shows **1**, which is what the server
/// assumes when it is left out: adopting is the shop saying it already carries
/// the thing. Selling below cost is refused here as everywhere.
class AdoptSheet extends ConsumerStatefulWidget {
  const AdoptSheet({required this.entry, super.key});

  final CatalogEntry entry;

  static Future<void> show(BuildContext context, CatalogEntry entry) =>
      showAppSheet<void>(
        context,
        title: entry.name,
        subtitle: AppL10n.of(context).addToStore,
        builder: (_) => AdoptSheet(entry: entry),
      );

  @override
  ConsumerState<AdoptSheet> createState() => _AdoptSheetState();
}

class _AdoptSheetState extends ConsumerState<AdoptSheet> {
  late final _pricing = PricingDraft(
    purchasePrice: widget.entry.defaultPurchasePrice,
    salePrice: widget.entry.defaultSalePrice,
  );
  late final _mrp = TextEditingController(text: _plain(widget.entry.defaultMrp));
  final _opening = TextEditingController(text: '1');
  final _minimum = TextEditingController();
  final _localName = TextEditingController();
  bool _busy = false;

  static String _plain(num? value) {
    if (value == null || value == 0) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _pricing.dispose();
    _mrp.dispose();
    _opening.dispose();
    _minimum.dispose();
    _localName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_pricing.isComplete) return;
    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    final localName = _localName.text.trim();
    try {
      final result = await ref.read(catalogRepositoryProvider).adopt(
            widget.entry.id,
            AdoptDraft(
              purchasePrice: _pricing.purchaseValue!,
              salePrice: _pricing.saleValue!,
              wholesalePrice: _pricing.wholesaleValue,
              profitPercent: _pricing.profitValue,
              mrp: AmountField.read(_mrp),
              localName: localName.isEmpty ? null : localName,
              openingStock: AmountField.read(_opening) ?? 1,
              minimumStock: AmountField.read(_minimum),
            ),
          );
      ref.invalidate(catalogListProvider);
      ref.invalidate(productsListProvider);
      ref.invalidate(productStatsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(
        context,
        result.created
            ? l10n.adoptedProduct(widget.entry.name)
            : l10n.alreadyInStoreNote,
      );
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
    final entry = widget.entry;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Insets.gutter),
            children: [
              if (entry.brand != null || entry.genericName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.s16),
                  child: Text(
                    [?entry.brand, ?entry.genericName].join(' · '),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: palette.muted),
                  ),
                ),
              PricingFields(
                draft: _pricing,
                money: money,
                mrp: AmountField.read(_mrp),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: Insets.s16),
              Row(
                children: [
                  Expanded(
                    child: AmountField(
                      controller: _mrp,
                      label: l10n.mrpLabel,
                      prefix: money.sign,
                      helperText: l10n.mrpHelp,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: Insets.s12),
                  Expanded(
                    child: AmountField(
                      controller: _opening,
                      label: l10n.openingStockLabel,
                      helperText: l10n.adoptOpeningHelp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.s16),
              Row(
                children: [
                  Expanded(
                    child: AmountField(
                      controller: _minimum,
                      label: l10n.minimumStockLabel,
                    ),
                  ),
                  const SizedBox(width: Insets.s12),
                  Expanded(
                    child: TextField(
                      controller: _localName,
                      decoration: InputDecoration(
                        labelText: l10n.localNameLabel,
                        helperText: l10n.localNameHelp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SheetAction(
          label: l10n.addToStore,
          icon: Icons.add_business_outlined,
          busy: _busy,
          onPressed: _pricing.isComplete ? _save : null,
        ),
      ],
    );
  }
}
