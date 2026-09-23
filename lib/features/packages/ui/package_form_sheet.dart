import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/package_models.dart';
import '../data/packages_repository.dart';

/// `POST /packages` and `PATCH /packages/{id}`.
///
/// The items travel as the whole list on every save — an edit replaces them —
/// so the form holds the full list and never sends a delta.
class PackageFormSheet extends ConsumerStatefulWidget {
  const PackageFormSheet({this.package, super.key});

  /// Null for a new package.
  final Package? package;

  static Future<void> show(BuildContext context, {Package? package}) =>
      showAppSheet<void>(
        context,
        title: package == null
            ? AppL10n.of(context).newPackage
            : package.name,
        builder: (_) => PackageFormSheet(package: package),
      );

  @override
  ConsumerState<PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends ConsumerState<PackageFormSheet> {
  late final _name = TextEditingController(text: widget.package?.name ?? '');
  late final _price = TextEditingController(text: _plain(widget.package?.price));
  late final _description =
      TextEditingController(text: widget.package?.description ?? '');
  late final _barcode =
      TextEditingController(text: widget.package?.barcode ?? '');
  late final _vat = TextEditingController(
    text: (widget.package?.vatPercent ?? 0) == 0
        ? ''
        : _plain(widget.package!.vatPercent),
  );

  late final List<PackageItem> _items = [...?widget.package?.items];
  late DateTime? _startsAt = widget.package?.startsAt;
  late DateTime? _endsAt = widget.package?.endsAt;
  late bool _isActive = widget.package?.isActive ?? true;

  bool _busy = false;
  Map<String, List<String>> _fieldErrors = const {};

  static String _plain(num? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _barcode.dispose();
    _vat.dispose();
    super.dispose();
  }

  String? _text(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  num get _componentTotal =>
      _items.fold<num>(0, (sum, item) => sum + item.salePrice * item.qty);

  PackageDraft get _draft => PackageDraft(
        name: _name.text.trim(),
        price: AmountField.read(_price) ?? 0,
        items: _items,
        description: _text(_description),
        barcode: _text(_barcode),
        vatPercent: AmountField.read(_vat),
        startsAt: _startsAt,
        endsAt: _endsAt,
        isActive: _isActive,
      );

  bool get _canSave =>
      _name.text.trim().isNotEmpty &&
      (AmountField.read(_price) ?? 0) > 0 &&
      _items.isNotEmpty &&
      _draft.windowIsValid;

  Future<void> _addProduct() async {
    final picked = await _ProductPicker.show(context);
    if (picked == null || !mounted) return;
    setState(() {
      final at = _items.indexWhere((i) => i.storeProductId == picked.id);
      if (at >= 0) {
        final existing = _items[at];
        _items[at] = PackageItem(
          storeProductId: existing.storeProductId,
          name: existing.name,
          qty: existing.qty + 1,
          salePrice: existing.salePrice,
          unit: existing.unit,
        );
      } else {
        _items.add(
          PackageItem(
            storeProductId: picked.id,
            name: picked.name,
            qty: 1,
            salePrice: picked.salePrice,
            unit: picked.unit,
          ),
        );
      }
    });
  }

  void _setQty(int index, num qty) => setState(() {
        if (qty <= 0) {
          _items.removeAt(index);
          return;
        }
        final item = _items[index];
        _items[index] = PackageItem(
          storeProductId: item.storeProductId,
          name: item.name,
          qty: qty,
          salePrice: item.salePrice,
          unit: item.unit,
        );
      });

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = (start ? _startsAt : _endsAt) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() => start ? _startsAt = picked : _endsAt = picked);
  }

  Future<void> _save() async {
    if (_busy || !_canSave) return;
    setState(() {
      _busy = true;
      _fieldErrors = const {};
    });
    final repository = ref.read(packagesRepositoryProvider);
    final l10n = AppL10n.of(context);
    try {
      if (widget.package == null) {
        await repository.create(_draft);
      } else {
        await repository.update(widget.package!.id, _draft);
      }
      ref.invalidate(packagesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.packageSaved);
    } on ValidationException catch (e) {
      if (mounted) setState(() => _fieldErrors = e.fields);
      if (mounted) showApiError(context, e);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _error(String field) {
    final messages = _fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    final price = AmountField.read(_price) ?? 0;
    final components = _componentTotal;
    final saving = components - price;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Insets.gutter),
            children: [
              TextField(
                controller: _name,
                autofocus: widget.package == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.packageName,
                  errorText: _error('name'),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Insets.s16),
              Row(
                children: [
                  Expanded(
                    child: AmountField(
                      controller: _price,
                      label: l10n.packagePrice,
                      prefix: money.sign,
                      errorText: _error('price'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: Insets.s12),
                  SizedBox(
                    width: 96,
                    child: AmountField(
                      controller: _vat,
                      label: l10n.vatLabel,
                      prefix: '%',
                    ),
                  ),
                ],
              ),

              SectionHeader(
                l10n.packageItems,
                trailing: TextButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.add),
                ),
              ),
              if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.s12),
                  child: Text(
                    l10n.packageNeedsItems,
                    style: text.bodySmall?.copyWith(color: palette.muted),
                  ),
                )
              else
                AppCard(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      ListTile(
                        dense: true,
                        title: Text(_items[i].name),
                        subtitle: Text(
                          money.format(_items[i].salePrice),
                          style: text.labelSmall
                              ?.copyWith(color: palette.muted),
                        ),
                        trailing: QtyStepper(
                          qty: _items[i].qty,
                          min: 0,
                          compact: true,
                          onChanged: (qty) => _setQty(i, qty),
                        ),
                      ),
                  ],
                ),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: Insets.s8),
                _Line(l10n.packageComponents, money.format(components)),
                _Line(
                  saving >= 0 ? l10n.packageSaving : l10n.packageAboveItems,
                  money.format(saving.abs()),
                  tone: saving >= 0 ? palette.positive : palette.warning,
                ),
              ],

              const SizedBox(height: Insets.s16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(start: true),
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text(
                        _startsAt == null
                            ? l10n.packageStartsAny
                            : l10n.fromDate(
                                AppDates.day(_startsAt, locale: locale),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Insets.s8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(start: false),
                      icon: const Icon(Icons.event_busy_outlined, size: 18),
                      label: Text(
                        _endsAt == null
                            ? l10n.packageEndsNever
                            : l10n.untilDate(
                                AppDates.day(_endsAt, locale: locale),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_startsAt != null || _endsAt != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _startsAt = null;
                      _endsAt = null;
                    }),
                    child: Text(l10n.packageClearDates),
                  ),
                ),
              if (!_draft.windowIsValid)
                Text(
                  l10n.packageWindowInvalid,
                  style: text.bodySmall?.copyWith(color: palette.danger),
                ),
              const SizedBox(height: Insets.s8),
              TextField(
                controller: _description,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.description),
              ),
              const SizedBox(height: Insets.s16),
              TextField(
                controller: _barcode,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.barcodeLabel),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: Text(l10n.packageOnSale),
              ),
            ],
          ),
        ),
        SheetAction(
          label: l10n.save,
          icon: Icons.check,
          busy: _busy,
          onPressed: _canSave ? _save : null,
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.s4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodySmall)),
          Text(
            value,
            style: text.bodyMedium?.copyWith(
              color: tone,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// `GET /packages/products?q=` — a searchable list to pick one product from.
class _ProductPicker extends ConsumerStatefulWidget {
  const _ProductPicker();

  static Future<PackageProduct?> show(BuildContext context) =>
      showAppSheet<PackageProduct>(
        context,
        title: AppL10n.of(context).addToPackage,
        builder: (_) => const _ProductPicker(),
      );

  @override
  ConsumerState<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<_ProductPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final results = ref.watch(packageProductsProvider(_query));

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: SearchField(
              controller: _search,
              hint: l10n.productsSearchHint,
              autofocus: true,
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _query = v.trim());
                });
              },
            ),
          ),
          Expanded(
            child: AsyncView<List<PackageProduct>>(
              value: results,
              onRetry: () => ref.invalidate(packageProductsProvider(_query)),
              builder: (context, items) => items.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: l10n.productsNoResults,
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: item.stock == null
                              ? null
                              : Text(
                                  l10n.onShelf(item.stock!.toStringAsFixed(0)),
                                  style: TextStyle(color: palette.muted),
                                ),
                          trailing: Text(money.format(item.salePrice)),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
