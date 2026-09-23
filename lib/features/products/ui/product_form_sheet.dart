import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../l10n/app_localizations.dart';
import '../data/product_models.dart';
import '../data/products_repository.dart';
import 'pricing_fields.dart';

/// What a new product came back as — enough for the till to find it again.
typedef CreatedProduct = ({int id, String name, String? barcode});

/// Add a product, or edit the one already on the shelf.
///
/// Two shapes of the same form. A new product carries its prices and an
/// opening stock; an edit carries the details only, because prices go through
/// [PriceSheet] (`PATCH /products/{id}/prices`, which files the old price in
/// history) and stock through an adjustment. `PATCH /products/{id}` would take
/// the prices as well, but only as a complete set — one door for them keeps
/// that rule in one place.
class ProductFormSheet extends ConsumerStatefulWidget {
  const ProductFormSheet({
    this.product,
    this.initialName,
    this.initialBarcode,
    super.key,
  });

  /// Null means a new product.
  final Product? product;

  /// What the till was searching for when nothing came back: a scanned
  /// barcode, or the name the cashier typed.
  final String? initialName;
  final String? initialBarcode;

  static Future<CreatedProduct?> showNew(
    BuildContext context, {
    String? initialName,
    String? initialBarcode,
  }) =>
      showAppSheet<CreatedProduct>(
        context,
        title: AppL10n.of(context).addProduct,
        builder: (_) => ProductFormSheet(
          initialName: initialName,
          initialBarcode: initialBarcode,
        ),
      );

  static Future<void> showEdit(BuildContext context, Product product) =>
      showAppSheet<void>(
        context,
        title: product.name,
        builder: (_) => ProductFormSheet(product: product),
      );

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _form = GlobalKey<FormState>();

  late final _name = TextEditingController(
    text: widget.product?.name ?? widget.initialName ?? '',
  );
  late final _brand = TextEditingController(text: widget.product?.brand ?? '');
  late final _sku = TextEditingController(text: widget.product?.sku ?? '');
  late final _barcode = TextEditingController(
    text: widget.product?.barcode ?? widget.initialBarcode ?? '',
  );
  late final _unit = TextEditingController(text: widget.product?.unit ?? 'pc');
  final _generic = TextEditingController();

  late final _mrp = TextEditingController(text: _plain(widget.product?.mrp));
  late final _vat =
      TextEditingController(text: _plain(widget.product?.vatPercent));
  late final _minimum =
      TextEditingController(text: _plain(widget.product?.minimumStock));

  final _pricing = PricingDraft();

  /// Zero, spelled out. It is the API's own default for a typed-in product
  /// now, but a quantity nobody typed is a quantity nobody counted, so the form
  /// always sends the figure it shows.
  final _opening = TextEditingController(text: '0');

  late bool _trackBatch = widget.product?.trackBatch ?? false;
  bool _busy = false;

  bool get _isNew => widget.product == null;

  static String _plain(num? value) {
    if (value == null || value == 0) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _brand,
      _sku,
      _barcode,
      _unit,
      _generic,
      _mrp,
      _vat,
      _minimum,
      _opening,
    ]) {
      c.dispose();
    }
    _pricing.dispose();
    super.dispose();
  }

  String? _text(TextEditingController c) {
    final value = c.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    if (_busy) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    // Selling below cost is refused by the server everywhere a price is set;
    // the button is already disabled, this is the belt to that brace.
    if (_isNew && !_pricing.isComplete) return;

    setState(() => _busy = true);
    final repository = ref.read(productsRepositoryProvider);
    final l10n = AppL10n.of(context);

    try {
      CreatedProduct? created;
      if (_isNew) {
        final id = await repository.create(
          name: _name.text.trim(),
          purchasePrice: _pricing.purchaseValue!,
          salePrice: _pricing.saleValue!,
          genericName: _text(_generic),
          brand: _text(_brand),
          sku: _text(_sku),
          barcode: _text(_barcode),
          unit: _text(_unit),
          wholesalePrice: _pricing.wholesaleValue,
          profitPercent: _pricing.profitValue,
          mrp: AmountField.read(_mrp),
          vatPercent: AmountField.read(_vat),
          minimumStock: AmountField.read(_minimum),
          openingStock: AmountField.read(_opening) ?? 0,
          trackBatch: _trackBatch,
        );
        created = (
          id: id,
          name: _name.text.trim(),
          barcode: _text(_barcode),
        );
      } else {
        await repository.update(
          widget.product!.id,
          name: _name.text.trim(),
          brand: _text(_brand),
          sku: _text(_sku),
          barcode: _text(_barcode),
          unit: _text(_unit),
          mrp: AmountField.read(_mrp),
          vatPercent: AmountField.read(_vat),
          minimumStock: AmountField.read(_minimum),
          trackBatch: _trackBatch,
        );
      }

      // There is no `GET /products/{id}`, so the list *is* the record: refetch
      // it rather than patching a local copy that the next page would contradict.
      ref.invalidate(productsListProvider);
      ref.invalidate(productStatsProvider);
      // A company or unit typed here for the first time is now one of the shop's.
      ref.invalidate(productLookupsProvider);
      if (!mounted) return;

      Navigator.of(context).pop(created);
      showNote(
        context,
        _isNew ? l10n.productAdded(_name.text.trim()) : l10n.productSaved,
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
    final money = ref.watch(moneyProvider);
    final lookups = ref.watch(productLookupsProvider).value;

    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(Insets.gutter),
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: _isNew,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.productNameLabel,
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.requiredField
                      : null,
                ),
                const SizedBox(height: Insets.s16),

                if (_isNew) ...[
                  TextFormField(
                    controller: _generic,
                    decoration: InputDecoration(
                      labelText: l10n.genericNameLabel,
                    ),
                  ),
                  const SizedBox(height: Insets.s16),
                ],

                Row(
                  children: [
                    Expanded(
                      child: SuggestingField(
                        controller: _brand,
                        label: l10n.brandLabel,
                        options: lookups?.brands ?? const [],
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    SizedBox(
                      width: 112,
                      child: SuggestingField(
                        controller: _unit,
                        label: l10n.unitLabel,
                        options: [
                          for (final unit in lookups?.units ?? const [])
                            unit.short,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.s16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcode,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: l10n.barcodeLabel),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Expanded(
                      child: TextFormField(
                        controller: _sku,
                        decoration: InputDecoration(labelText: l10n.skuLabel),
                      ),
                    ),
                  ],
                ),

                // Prices only on the way in. Afterwards they belong to the
                // price sheet, which files the old one in the history.
                if (_isNew) ...[
                  const SizedBox(height: Insets.s24),
                  PricingFields(
                    draft: _pricing,
                    money: money,
                    mrp: AmountField.read(_mrp),
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: Insets.s16),
                  AmountField(
                    controller: _opening,
                    label: l10n.openingStockLabel,
                  ),
                ],

                const SizedBox(height: Insets.s16),
                Row(
                  children: [
                    Expanded(
                      child: AmountField(
                        controller: _mrp,
                        label: l10n.mrpLabel,
                        prefix: money.sign,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Expanded(
                      child: AmountField(
                        controller: _minimum,
                        label: l10n.minimumStockLabel,
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    SizedBox(
                      width: 88,
                      child: AmountField(
                        controller: _vat,
                        label: l10n.vatLabel,
                        prefix: '%',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: Insets.s8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _trackBatch,
                  onChanged: (value) => setState(() => _trackBatch = value),
                  title: Text(l10n.trackBatchLabel),
                ),
              ],
            ),
          ),
          SheetAction(
            label: l10n.save,
            icon: Icons.check,
            busy: _busy,
            onPressed: _isNew && !_pricing.isComplete ? null : _save,
          ),
        ],
      ),
    );
  }
}

/// A free-text box that offers what the shop already uses. Anything typed is
/// still accepted: a company nobody has saved yet simply works.
class SuggestingField extends StatefulWidget {
  const SuggestingField({
    required this.controller,
    required this.label,
    required this.options,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final List<String> options;

  @override
  State<SuggestingField> createState() => _SuggestingFieldState();
}

class _SuggestingFieldState extends State<SuggestingField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawAutocomplete<String>(
        textEditingController: widget.controller,
        focusNode: _focus,
        optionsBuilder: (value) {
          final typed = value.text.trim().toLowerCase();
          if (typed.isEmpty) return widget.options.take(8);
          return widget.options
              .where((o) => o.toLowerCase().contains(typed))
              .take(8);
        },
        fieldViewBuilder: (context, controller, focus, onSubmit) =>
            TextFormField(
          controller: controller,
          focusNode: focus,
          decoration: InputDecoration(labelText: widget.label),
          onFieldSubmitted: (_) => onSubmit(),
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(Radii.row),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      dense: true,
                      title: Text(option),
                      onTap: () => onSelected(option),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
