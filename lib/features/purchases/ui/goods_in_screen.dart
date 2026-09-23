import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../pos/data/pos_models.dart' show PosAccount;
import '../../products/data/products_repository.dart';
import '../data/purchase_models.dart';
import '../data/purchases_repository.dart';
import 'photo_picking.dart';

/// `POST /purchases` — goods in.
///
/// The order of the form is the order of the job: who it came from, what came,
/// what it cost, what was paid. Stock rises when it is saved and whatever was
/// not paid is owed to the supplier.
///
/// Photos of the paper bill are picked here but uploaded **after** the bill is
/// saved: the bill is stock and money, and a dropped upload must not cost the
/// shop that. A failed upload says so and offers again; the bill stands.
class GoodsInScreen extends ConsumerStatefulWidget {
  const GoodsInScreen({super.key});

  @override
  ConsumerState<GoodsInScreen> createState() => _GoodsInScreenState();
}

class _GoodsInScreenState extends ConsumerState<GoodsInScreen> {
  final _party = TextEditingController();
  final _partyFocus = FocusNode();
  final _discount = TextEditingController();
  final _paid = TextEditingController();
  final _note = TextEditingController();

  Supplier? _supplier;
  final List<PurchaseLine> _lines = [];
  final List<PhotoFile> _photos = [];
  PosAccount? _account;

  /// Until the person types a paid figure, it follows the total — paying the
  /// whole bill is the ordinary case.
  bool _paidTouched = false;
  bool _busy = false;

  @override
  void dispose() {
    _party.dispose();
    _partyFocus.dispose();
    _discount.dispose();
    _paid.dispose();
    _note.dispose();
    super.dispose();
  }

  String? get _newPartyName {
    if (_supplier != null) return null;
    final typed = _party.text.trim();
    return typed.isEmpty ? null : typed;
  }

  PurchaseDraft _draft() => PurchaseDraft(
        lines: _lines,
        supplierId: _supplier?.id,
        supplierName: _newPartyName,
        discountPercent: AmountField.read(_discount),
        paidAmount: _paidTouched
            ? (AmountField.read(_paid) ?? 0)
            : _draftTotal().toDouble(),
        accountId: _account?.id,
        note: _note.text.trim(),
      );

  /// The total with no paid figure in it, so [_draft] can default to it.
  num _draftTotal() => PurchaseDraft(
        lines: _lines,
        discountPercent: AmountField.read(_discount),
      ).total.toDouble();

  Future<void> _addLine() async {
    final product = await _PurchaseProductPicker.show(context);
    if (product == null || !mounted) return;
    final line = await _LineSheet.show(
      context,
      line: PurchaseLine(
        product: product,
        qty: 1,
        unitCost: product.purchasePrice ?? 0,
      ),
      isNew: true,
    );
    if (line == null || !mounted) return;
    setState(() => _lines.add(line));
  }

  Future<void> _editLine(int index) async {
    final line = await _LineSheet.show(context, line: _lines[index]);
    if (!mounted) return;
    setState(() {
      if (line == null) return;
      if (line.qty <= 0) {
        _lines.removeAt(index);
      } else {
        _lines[index] = line;
      }
    });
  }

  Future<void> _addPhotos(int maxPhotos) async {
    final room = maxPhotos - _photos.length;
    if (room <= 0) return;
    final files = await pickBillPhotos(context, limit: room);
    if (files.isEmpty || !mounted) return;
    setState(() => _photos.addAll(files));
  }

  Future<void> _save({required bool mayCreateParty}) async {
    if (_busy) return;
    final l10n = AppL10n.of(context);
    final draft = _draft();
    if (!draft.hasParty || _lines.isEmpty) return;
    if (_supplier == null && !mayCreateParty) {
      showNote(context, l10n.pickSupplierFromList);
      return;
    }

    setState(() => _busy = true);
    final repository = ref.read(purchasesRepositoryProvider);
    try {
      final created = await repository.create(draft);
      ref.invalidate(purchasesProvider);
      ref.invalidate(productsListProvider);
      ref.invalidate(productStatsProvider);

      if (_photos.isNotEmpty) {
        await _uploadWithRetry(repository, created.id);
      }
      if (!mounted) return;
      showNote(context, l10n.purchaseSaved(created.refNo));
      context.go('/purchase');
    } on ValidationException catch (e) {
      if (mounted) showApiError(context, e);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The bill already exists; only the photos are at stake here.
  Future<void> _uploadWithRetry(PurchasesRepository repository, int id) async {
    while (mounted) {
      try {
        await repository.uploadPhotos(id, _photos);
        ref.invalidate(purchasesProvider);
        return;
      } catch (e) {
        if (!mounted) return;
        final l10n = AppL10n.of(context);
        final again = await confirmSheet(
          context,
          title: l10n.photoUploadFailed,
          message: l10n.photoUploadFailedBody(
            e is ApiException ? e.message : l10n.genericError,
          ),
          confirmLabel: l10n.retry,
          cancelLabel: l10n.skipPhotos,
        );
        if (!again) return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final permissions = ref.watch(permissionsProvider);
    final page = ref.watch(purchasesProvider('')).value;
    final accounts = ref.watch(purchaseAccountsProvider).value ?? const [];

    if (!permissions.has(P.purchaseBillCreate)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.goodsIn)),
        body: MessageState(
          icon: Icons.lock_outline,
          title: l10n.notAllowedTitle,
        ),
      );
    }

    final mayCreateParty = permissions.allows(
      P.purchaseSupplierManage,
      alsoRequire: page?.mayManageSuppliers,
    );
    final maxPhotos = page?.maxPhotos ?? 5;

    _account ??= accounts.isEmpty
        ? null
        : accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);

    final draft = _draft();
    final total = draft.total.toDouble();
    final paid = draft.paidAmount ?? 0;
    final owed = total - paid;
    final ready = draft.hasParty &&
        _lines.isNotEmpty &&
        (_supplier != null || mayCreateParty) &&
        paid >= 0 &&
        paid <= total + 0.001;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/purchase')),
        title: Text(l10n.goodsIn),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.gutter),
        children: [
          SectionHeader(l10n.supplier),
          _PartyField(
            controller: _party,
            focusNode: _partyFocus,
            selected: _supplier,
            onSelected: (s) => setState(() => _supplier = s),
            onTyped: () => setState(() {
              // Typing over a picked party un-picks it.
              if (_supplier != null && _party.text != _supplier!.name) {
                _supplier = null;
              }
            }),
          ),
          if (_newPartyName != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.s4),
              child: Text(
                mayCreateParty
                    ? l10n.newSupplierNote(_newPartyName!)
                    : l10n.pickSupplierFromList,
                style: text.labelSmall?.copyWith(
                  color: mayCreateParty ? palette.accent : palette.danger,
                ),
              ),
            ),

          SectionHeader(
            l10n.itemsReceived,
            trailing: TextButton.icon(
              onPressed: _addLine,
              icon: const Icon(Icons.add),
              label: Text(l10n.add),
            ),
          ),
          if (_lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Insets.s12),
              child: Text(
                l10n.noItemsReceived,
                style: text.bodySmall?.copyWith(color: palette.muted),
              ),
            )
          else
            AppCard(
              children: [
                for (var i = 0; i < _lines.length; i++)
                  ListTile(
                    dense: true,
                    onTap: () => _editLine(i),
                    title: Text(_lines[i].product.name),
                    subtitle: Text(
                      [
                        '${_qty(_lines[i].qty)} × ${money.format(_lines[i].unitCost)}',
                        if ((_lines[i].batchNo ?? '').isNotEmpty)
                          l10n.batchShort(_lines[i].batchNo!),
                        if (_lines[i].expiryDate != null)
                          l10n.expiresShort(AppDates.day(_lines[i].expiryDate)),
                      ].join(' · '),
                      style: text.labelSmall?.copyWith(color: palette.muted),
                    ),
                    trailing: Text(
                      money.format(_lines[i].lineTotal.toDouble()),
                      style: text.titleSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),

          SectionHeader(l10n.payment),
          _Line(l10n.subtotal, money.format(draft.subtotal.toDouble())),
          Row(
            children: [
              Expanded(
                child: Text(l10n.billDiscountPercent, style: text.bodyMedium),
              ),
              SizedBox(
                width: 110,
                child: AmountField(
                  controller: _discount,
                  label: '%',
                  prefix: '%',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (draft.discountAmount.toDouble() > 0)
            _Line(
              l10n.discount,
              '−${money.format(draft.discountAmount.toDouble())}',
              tone: palette.accent,
            ),
          _Line(l10n.grandTotal, money.format(total), strong: true),
          const SizedBox(height: Insets.s12),
          AmountField(
            controller: _paid,
            label: l10n.paidToSupplier,
            prefix: money.sign,
            helperText: _paidTouched ? null : l10n.paidFollowsTotal,
            errorText: paid > total + 0.001 ? l10n.paidOverTotal : null,
            onChanged: (_) => setState(() => _paidTouched = true),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _paidTouched = false;
                  _paid.clear();
                }),
                child: Text(l10n.payInFull),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _paidTouched = true;
                  _paid.text = '0';
                }),
                child: Text(l10n.payNothing),
              ),
            ],
          ),
          if (owed > 0.001)
            _Line(
              l10n.owedToSupplier,
              money.format(owed),
              tone: palette.warning,
            ),
          if (accounts.isNotEmpty && paid > 0) ...[
            const SizedBox(height: Insets.s8),
            DropdownButtonFormField<int>(
              initialValue: _account?.id,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.paidFrom),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (id) => setState(
                () => _account = accounts.firstWhere((a) => a.id == id),
              ),
            ),
          ],
          const SizedBox(height: Insets.s16),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              labelText: l10n.purchaseNote,
              hintText: l10n.purchaseNoteHint,
            ),
          ),

          SectionHeader(
            l10n.billPhotos(_photos.length, maxPhotos),
            trailing: _photos.length < maxPhotos
                ? TextButton.icon(
                    onPressed: () => _addPhotos(maxPhotos),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(l10n.add),
                  )
                : null,
          ),
          if (_photos.isEmpty)
            Text(
              l10n.billPhotosHelp,
              style: text.bodySmall?.copyWith(color: palette.muted),
            )
          else
            Wrap(
              spacing: Insets.s8,
              runSpacing: Insets.s8,
              children: [
                for (final photo in _photos)
                  BillPhotoThumb(
                    bytes: Uint8List.fromList(photo.bytes),
                    onRemove: () => setState(() => _photos.remove(photo)),
                  ),
              ],
            ),
          const SizedBox(height: 96),
        ],
      ),
      bottomNavigationBar: SheetAction(
        label: '${l10n.saveBill}  ${money.format(total)}',
        icon: Icons.inventory_outlined,
        busy: _busy,
        onPressed: ready
            ? () => _save(mayCreateParty: mayCreateParty)
            : null,
      ),
    );
  }
}

String _qty(num value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.tone, this.strong = false});

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
            child: Text(label, style: strong ? text.titleMedium : text.bodyMedium),
          ),
          Text(
            value,
            style: (strong ? text.titleLarge : text.bodyMedium)?.copyWith(
              color: tone,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The party box: `GET /suppliers/search` while typing, and a name that is
/// not on the list is a new party saved with the bill.
class _PartyField extends ConsumerWidget {
  const _PartyField({
    required this.controller,
    required this.focusNode,
    required this.selected,
    required this.onSelected,
    required this.onTyped,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Supplier? selected;
  final ValueChanged<Supplier> onSelected;
  final VoidCallback onTyped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return RawAutocomplete<Supplier>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (s) => s.name,
      optionsBuilder: (value) async {
        final q = value.text.trim();
        if (q.isEmpty || (selected != null && q == selected!.name)) {
          return const <Supplier>[];
        }
        try {
          return await ref.read(purchasesRepositoryProvider).searchSuppliers(q);
        } catch (_) {
          return const <Supplier>[];
        }
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
        controller: controller,
        focusNode: focus,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l10n.supplierSearch,
          prefixIcon: const Icon(Icons.storefront_outlined),
          suffixIcon: selected != null
              ? Icon(Icons.check_circle, color: palette.positive)
              : null,
        ),
        onChanged: (_) => onTyped(),
        onSubmitted: (_) => onSubmit(),
      ),
      optionsViewBuilder: (context, onSelect, options) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(Radii.row),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final s in options)
                  ListTile(
                    dense: true,
                    title: Text(s.name),
                    subtitle: Text([?s.company, ?s.phone].join(' · ')),
                    onTap: () => onSelect(s),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `GET /purchases/products?q=`.
class _PurchaseProductPicker extends ConsumerStatefulWidget {
  const _PurchaseProductPicker();

  static Future<PurchaseProduct?> show(BuildContext context) =>
      showAppSheet<PurchaseProduct>(
        context,
        title: AppL10n.of(context).pickProduct,
        builder: (_) => const _PurchaseProductPicker(),
      );

  @override
  ConsumerState<_PurchaseProductPicker> createState() =>
      _PurchaseProductPickerState();
}

class _PurchaseProductPickerState
    extends ConsumerState<_PurchaseProductPicker> {
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
    final results = ref.watch(purchaseProductsProvider(_query));

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
            child: AsyncView<List<PurchaseProduct>>(
              value: results,
              onRetry: () => ref.invalidate(purchaseProductsProvider(_query)),
              builder: (context, items) => items.isEmpty
                  ? MessageState(
                      icon: Icons.search_off,
                      title: l10n.productsNoResults,
                      // Not on the shelf yet: it comes from the catalogue
                      // first, then goods can come in against it.
                      body: l10n.purchaseAddFromCatalogue,
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: item.trackBatch
                              ? Text(
                                  l10n.tracksBatches,
                                  style: TextStyle(color: palette.muted),
                                )
                              : null,
                          trailing: item.purchasePrice == null
                              ? null
                              : Text(money.format(item.purchasePrice)),
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

/// Quantity, unit cost, and batch and expiry for a batch-tracked product.
/// Returns the line, a line with qty 0 to remove it, or null to leave it.
class _LineSheet extends ConsumerStatefulWidget {
  const _LineSheet({required this.line, required this.isNew});

  final PurchaseLine line;
  final bool isNew;

  static Future<PurchaseLine?> show(
    BuildContext context, {
    required PurchaseLine line,
    bool isNew = false,
  }) =>
      showAppSheet<PurchaseLine>(
        context,
        title: line.product.name,
        builder: (_) => _LineSheet(line: line, isNew: isNew),
      );

  @override
  ConsumerState<_LineSheet> createState() => _LineSheetState();
}

class _LineSheetState extends ConsumerState<_LineSheet> {
  late final _qty = TextEditingController(text: _plain(widget.line.qty));
  late final _cost = TextEditingController(
    text: widget.line.unitCost == 0 ? '' : _plain(widget.line.unitCost),
  );
  late final _batch = TextEditingController(text: widget.line.batchNo ?? '');
  late DateTime? _expiry = widget.line.expiryDate;

  static String _plain(num value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    _batch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final money = ref.watch(moneyProvider);
    final qty = AmountField.read(_qty) ?? 0;
    final cost = AmountField.read(_cost);
    final ready = qty > 0 && cost != null && cost > 0;
    final tracks = widget.line.product.trackBatch;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(Insets.gutter),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AmountField(
                      controller: _qty,
                      label: l10n.quantityReceived,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: Insets.s12),
                  Expanded(
                    child: AmountField(
                      controller: _cost,
                      label: l10n.unitCost,
                      prefix: money.sign,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              if (tracks) ...[
                const SizedBox(height: Insets.s16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _batch,
                        decoration: InputDecoration(labelText: l10n.batchNo),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _expiry ?? DateTime(now.year + 1, now.month),
                            firstDate: now,
                            lastDate: DateTime(now.year + 10),
                          );
                          if (picked != null) setState(() => _expiry = picked);
                        },
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text(
                          _expiry == null
                              ? l10n.expiryDate
                              : AppDates.day(_expiry),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (ready) ...[
                const SizedBox(height: Insets.s12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(money.format(qty * cost)),
                ),
              ],
              if (!widget.isNew)
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(
                    widget.line.copyWith(qty: 0),
                  ),
                  icon: Icon(Icons.delete_outline, color: context.palette.danger),
                  label: Text(
                    l10n.removeLine,
                    style: TextStyle(color: context.palette.danger),
                  ),
                ),
            ],
          ),
        ),
        SheetAction(
          label: widget.isNew ? l10n.add : l10n.apply,
          icon: Icons.check,
          onPressed: ready
              ? () => Navigator.of(context).pop(
                    PurchaseLine(
                      product: widget.line.product,
                      qty: qty,
                      unitCost: cost,
                      batchNo: tracks ? _batch.text.trim() : null,
                      expiryDate: tracks ? _expiry : null,
                    ),
                  )
              : null,
        ),
      ],
    );
  }
}
