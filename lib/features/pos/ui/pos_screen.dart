import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/shell_nav.dart';
import '../../../core/format/money.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../products/ui/product_form_sheet.dart';
import '../data/pos_models.dart';
import '../data/pos_repository.dart';
import '../state/cart.dart';
import '../state/invoice_edit.dart';
import 'cart_sheet.dart';
import 'holds_sheet.dart';
import 'payment_sheet.dart';
import 'scanner_sheet.dart';
import 'shift_sheets.dart';

/// The till.
///
/// Laid out for one thumb: search at the top under the finger that just
/// scanned, results filling the middle, and a cart bar pinned to the bottom
/// that grows into the charge button. Nothing important lives behind a menu,
/// because a queue does not wait for a menu.
///
/// It is also where an invoice is corrected ([invoiceEditProvider]): the same
/// till, with a banner naming the invoice, the invoice's own units counted as
/// back on the shelf, and no holds or packages — an edit takes product lines
/// only.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  Timer? _debounce;

  /// The product that just went in, shown inside the cart bar for a moment.
  ///
  /// Not a snack bar: the outer shell's scaffold floats one straight over the
  /// cart bar, which is exactly the thing a cashier reaches for next. The bar
  /// saying "Napa added" where the item count usually is confirms the tap and
  /// covers nothing.
  String? _justAdded;
  Timer? _justAddedTimer;

  /// What the list is showing. Held here and handed to [posSearchProvider],
  /// which owns the fetching — so a store or branch switch, or the `/me`
  /// refresh that bumps the scope epoch at start-up, re-runs the search instead
  /// of cancelling it and leaving the counter with an empty list it cannot
  /// retry.
  PosQuery _query = const PosQuery();

  @override
  void dispose() {
    _debounce?.cancel();
    _justAddedTimer?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 280),
      () => _setQuery(_query.withText(value.trim())),
    );
  }

  void _setQuery(PosQuery next) {
    if (next == _query) return;
    if (mounted) setState(() => _query = next);
  }

  /// A scan is a search whose first result is the answer.
  ///
  /// `GET /pos/search` puts an exact barcode match at `data[0]`, so a scanned
  /// code goes straight into the cart; anything else falls back to showing the
  /// list, which is what happens with a smudged label or an unknown code.
  Future<void> _scan() async {
    final code = await ScannerSheet.show(context);
    if (code == null || !mounted) return;

    _debounce?.cancel();
    _search.text = code;
    // Bundles never carry the barcode that was scanned, so a scan always lands
    // in the product list.
    _setQuery(PosQuery(text: code));

    final List<SellableItem> found;
    try {
      found = await ref.read(posSearchProvider(PosQuery(text: code)).future);
    } catch (_) {
      // The list below is showing the same failure with its own retry; a second
      // complaint here would only cover it up.
      return;
    }
    if (!mounted) return;

    final exact = found.isNotEmpty && found.first.barcode == code
        ? found.first
        : null;
    if (exact == null) return;
    final editing = ref.read(invoiceEditProvider);

    _addToCart(editing?.withSold(exact) ?? exact);
    // Cleared so the next scan starts from nothing rather than from the last
    // code still sitting in the box.
    _search.clear();
    _setQuery(const PosQuery());
  }

  /// `POST /products` from the till, then `/pos/search` again so the new
  /// product reaches the cart in exactly the shape every other one does.
  ///
  /// What was searched for fills the form in: a string of digits is a barcode
  /// that was scanned, anything else is a name.
  Future<void> _newProduct() async {
    final typed = _query.text.trim();
    final looksLikeBarcode = RegExp(r'^\d{6,}$').hasMatch(typed);
    final created = await ProductFormSheet.showNew(
      context,
      initialName: looksLikeBarcode ? null : typed,
      initialBarcode: looksLikeBarcode ? typed : null,
    );
    if (created == null || !mounted) return;

    final lookFor = created.barcode ?? created.name;
    ref.invalidate(posSearchProvider);
    try {
      final found = await ref.read(
        posSearchProvider(PosQuery(text: lookFor)).future,
      );
      if (!mounted) return;
      for (final item in found) {
        if (item.id == created.id) {
          _addToCart(item);
          _search.clear();
          _setQuery(const PosQuery());
          return;
        }
      }
    } catch (_) {
      // The product exists; the list below will show it on the next search.
    }
  }

  void _addToCart(SellableItem item) {
    final l10n = AppL10n.of(context);
    final money = ref.read(moneyProvider);
    // Priced over the MRP on the shelf: the server will not sell it at that
    // price. Someone who may change prices can still take it and bring the
    // line down; anyone else is told why it will not go in.
    final aboveMrp = item.priceAboveMrp;
    if (aboveMrp && !ref.read(permissionsProvider).has(P.posSaleChangePrice)) {
      _alertAboveMrp(
        l10n.cannotSellAboveMrp(
          item.name,
          money.format(item.salePrice),
          money.format(item.mrp),
        ),
      );
      return;
    }
    // Out of stock, or every last one already in the cart. Said out loud,
    // because a scan that silently does nothing reads as a broken scanner.
    if (!ref.read(cartProvider.notifier).add(item)) {
      showNote(context, l10n.noStockLeft(item.name));
      return;
    }
    if (aboveMrp) {
      _alertAboveMrp(
        l10n.lowerToMrp(
          item.name,
          money.format(item.salePrice),
          money.format(item.mrp),
        ),
      );
      return;
    }
    _justAddedTimer?.cancel();
    setState(() => _justAdded = item.name);
    _justAddedTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _justAdded = null);
    });
  }

  /// A dialog rather than a note: a price over the MRP is a refusal, and it
  /// must not slip by under the cashier's thumb.
  void _alertAboveMrp(String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.price_change_outlined, color: context.palette.danger),
      title: Text(AppL10n.of(context).aboveMrpTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppL10n.of(context).ok),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final lookups = ref.watch(posLookupsProvider);
    final cart = ref.watch(cartProvider);
    final editing = ref.watch(invoiceEditProvider);
    // An edit takes product lines only, so the till stays on products.
    final query = editing != null && _query.packages
        ? _query.withPackages(false)
        : _query;
    final results = ref.watch(posSearchProvider(query));

    return Scaffold(
      appBar: ShellAppBar(
        title: Text(editing == null ? l10n.posTitle : l10n.editInvoice),
        actions: [
          lookups.maybeWhen(
            data: (data) => _ShiftButton(lookups: data),
            orElse: () => const SizedBox.shrink(),
          ),
          if (editing == null)
            PermissionGate(
              perm: P.posSaleHold,
              child: lookups.maybeWhen(
                data: (data) => _HoldsButton(held: data.held),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
      body: AsyncView<PosLookups>(
        value: lookups,
        onRetry: () => ref.invalidate(posLookupsProvider),
        builder: (context, data) => Column(
          children: [
            if (editing != null)
              _EditingBanner(edit: editing)
            else if (!data.hasOpenShift)
              _DrawerClosedBanner(lookups: data),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.gutter,
                Insets.s12,
                Insets.gutter,
                Insets.s8,
              ),
              child: SearchField(
                controller: _search,
                focusNode: _searchFocus,
                hint: l10n.posSearchHint,
                onChanged: _onQueryChanged,
                onSubmitted: (value) {
                  _debounce?.cancel();
                  _setQuery(_query.withText(value.trim()));
                },
                trailing: IconButton(
                  tooltip: l10n.posScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scan,
                ),
              ),
            ),
            if (editing == null)
              PermissionGate(
                perm: P.inventoryPackageView,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.gutter,
                  ),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(l10n.posTabProducts),
                        selected: !_query.packages,
                        onSelected: (_) =>
                            _setQuery(_query.withPackages(false)),
                      ),
                      const SizedBox(width: Insets.s8),
                      ChoiceChip(
                        label: Text(l10n.posTabPackages),
                        selected: _query.packages,
                        onSelected: (_) => _setQuery(_query.withPackages(true)),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: AsyncView<List<SellableItem>>(
                value: editing == null
                    ? results
                    : results.whenData(
                        (items) => [for (final i in items) editing.withSold(i)],
                      ),
                onRetry: () => ref.invalidate(posSearchProvider(query)),
                builder: (context, items) => items.isEmpty
                    ? MessageState(
                        title: query.text.isEmpty
                            ? l10n.posStartTitle
                            : l10n.posNoResults,
                        body: query.text.isEmpty
                            ? l10n.posStartBody
                            : l10n.posNoResultsBody,
                        icon: Icons.qr_code_scanner,
                        // Nothing on the shelf by that name: write it down
                        // here, with the customer still waiting, rather than
                        // send the cashier to another screen.
                        action: query.text.isEmpty || query.packages
                            ? null
                            : PermissionGate(
                                perm: P.inventoryProductCreate,
                                child: OutlinedButton.icon(
                                  onPressed: _newProduct,
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.newProduct),
                                ),
                              ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          vertical: Insets.s8,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: Insets.gutter),
                        itemBuilder: (context, i) => _ProductRow(
                          item: items[i],
                          inCart: cart.lineFor(items[i])?.qty,
                          onTap: () => _addToCart(items[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: lookups.maybeWhen(
        data: (data) => _CartBar(lookups: data, justAdded: _justAdded),
        orElse: () => null,
      ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({
    required this.item,
    required this.inCart,
    required this.onTap,
  });

  final SellableItem item;
  final num? inCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);

    final stock = item.stock;
    final (stockLabel, stockTone) = switch (stock) {
      null => (null, palette.muted),
      final s when s <= 0 => (l10n.outOfStock, palette.danger),
      _ when item.isLow => (l10n.lowStock, palette.warning),
      final s => (
        item.isPackage
            ? l10n.buildable(s.toStringAsFixed(0))
            : l10n.inStock(s.toStringAsFixed(0)),
        palette.muted,
      ),
    };

    final off = item.mrpDiscountPercent;
    final offLabel = item.priceAboveMrp
        ? l10n.aboveMrpTag
        : off == null
        ? null
        : l10n.mrpOff(_percent(off));

    return ListTile(
      onTap: onTap,
      // Nothing on the shelf, nothing to sell: greyed out and untappable.
      enabled: stock == null || stock > 0,
      title: Row(
        children: [
          Flexible(
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.isPackage) ...[
            const SizedBox(width: Insets.s8),
            StatusChip(label: l10n.packageBadge, tone: palette.accent),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          if (stockLabel != null)
            Text(stockLabel, style: text.bodySmall?.copyWith(color: stockTone)),
          // How far under the printed price it sells — or, in red, that it is
          // priced over it and will not sell as it stands.
          if (offLabel != null) ...[
            if (stockLabel != null) Text(' · ', style: text.bodySmall),
            Text(
              offLabel,
              style: text.labelSmall?.copyWith(
                color: item.priceAboveMrp ? palette.danger : palette.positive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (item.brand != null) ...[
            if (stockLabel != null || offLabel != null)
              Text(' · ', style: text.bodySmall),
            Flexible(
              child: Text(
                item.brand!,
                style: text.bodySmall?.copyWith(color: palette.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            money.format(item.salePrice),
            style: text.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (inCart != null && inCart! > 0)
            Padding(
              padding: const EdgeInsets.only(top: Insets.s4),
              child: StatusChip(
                label: '×${inCart!.toStringAsFixed(0)}',
                tone: palette.accent,
                icon: Icons.shopping_cart_outlined,
              ),
            ),
        ],
      ),
    );
  }
}

/// 17.57 reads as "17.6", 20 as "20".
String _percent(num value) {
  final tenths = (value * 10).round() / 10;
  return tenths == tenths.roundToDouble()
      ? tenths.toStringAsFixed(0)
      : tenths.toStringAsFixed(1);
}

/// The cart bar: a running count on the left, the charge button on the right.
///
/// Tapping the count opens the cart to change things; tapping charge goes
/// straight to payment, which is the path a busy counter takes ninety times out
/// of a hundred.
class _CartBar extends ConsumerWidget {
  const _CartBar({required this.lookups, this.justAdded});

  final PosLookups lookups;

  /// Shown in place of the item count for a moment after a tap.
  final String? justAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final cart = ref.watch(cartProvider);
    final editing = ref.watch(invoiceEditProvider) != null;

    if (cart.isEmpty) return const SizedBox.shrink();

    return Material(
      color: palette.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.hairline)),
          ),
          padding: const EdgeInsets.all(Insets.s12),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.row),
                  onTap: () => CartSheet.show(context, lookups),
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.s8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: justAdded == null
                              ? Text(
                                  l10n.cartItems(cart.lineCount),
                                  key: const ValueKey('count'),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: palette.muted),
                                )
                              : Row(
                                  key: ValueKey(justAdded),
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: palette.positive,
                                    ),
                                    const SizedBox(width: Insets.s4),
                                    Flexible(
                                      child: Text(
                                        l10n.addedToCart(justAdded!),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(color: palette.positive),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        Text(
                          money.format(cart.estimatedTotal.toDouble()),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Holding an invoice half-edited has no meaning: it is either
              // saved or left as it was.
              if (!editing)
                PermissionGate(
                  perm: P.posSaleHold,
                  child: IconButton(
                    tooltip: l10n.holdCart,
                    icon: const Icon(Icons.pause_circle_outline),
                    onPressed: () => HoldCartSheet.show(context),
                  ),
                ),
              const SizedBox(width: Insets.s8),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => PaymentSheet.show(context, lookups: lookups),
                  icon: Icon(
                    editing ? Icons.save_outlined : Icons.point_of_sale,
                  ),
                  label: Text(editing ? l10n.saveChanges : l10n.charge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which invoice the till is correcting, and the way out without saving.
class _EditingBanner extends ConsumerWidget {
  const _EditingBanner({required this.edit});

  final InvoiceEdit edit;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppL10n.of(context);
    final ok = await confirmSheet(
      context,
      title: l10n.discardEditTitle,
      message: l10n.discardEditBody(edit.invoiceNo),
      confirmLabel: l10n.discard,
      cancelLabel: l10n.keepEditing,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    ref.read(invoiceEditProvider.notifier).end();
    context.go('/invoices/${edit.saleId}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Material(
      color: palette.accentSoft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Insets.gutter,
          Insets.s8,
          Insets.s8,
          Insets.s8,
        ),
        child: Row(
          children: [
            Icon(Icons.edit_note, size: 20, color: palette.accent),
            const SizedBox(width: Insets.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.editingInvoice(edit.invoiceNo),
                    style: text.titleSmall?.copyWith(color: palette.accent),
                  ),
                  Text(l10n.editingInvoiceBody, style: text.bodySmall),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _cancel(context, ref),
              child: Text(l10n.cancelEdit),
            ),
          ],
        ),
      ),
    );
  }
}

/// Says the drawer is shut without getting in the way.
///
/// A sale with no open shift is allowed — it is just not counted in any
/// drawer — so this is a line of text with a button, not a blocking screen.
class _DrawerClosedBanner extends ConsumerWidget {
  const _DrawerClosedBanner({required this.lookups});

  final PosLookups lookups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    if (!ref.watch(permissionsProvider).has(P.posShiftManage)) {
      return const SizedBox.shrink();
    }

    return Material(
      color: palette.warning.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Insets.gutter,
          Insets.s8,
          Insets.s8,
          Insets.s8,
        ),
        child: Row(
          children: [
            Icon(Icons.savings_outlined, size: 18, color: palette.warning),
            const SizedBox(width: Insets.s8),
            Expanded(
              child: Text(
                l10n.drawerClosedBody,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () => OpenShiftSheet.show(context),
              child: Text(l10n.openDrawer),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftButton extends ConsumerWidget {
  const _ShiftButton({required this.lookups});

  final PosLookups lookups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final shift = lookups.shift;

    return PermissionGate(
      perm: P.posShiftManage,
      child: IconButton(
        tooltip: shift == null ? l10n.openDrawer : l10n.closeDrawer,
        icon: Icon(
          shift == null ? Icons.lock_outline : Icons.lock_open_outlined,
          color: shift == null ? null : palette.positive,
        ),
        onPressed: () => shift == null
            ? OpenShiftSheet.show(context)
            : CloseShiftSheet.show(context, shift),
      ),
    );
  }
}

class _HoldsButton extends StatelessWidget {
  const _HoldsButton({required this.held});

  final List<HeldCart> held;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return IconButton(
      tooltip: l10n.heldCarts,
      onPressed: () => HeldCartsSheet.show(context, held),
      icon: Badge.count(
        count: held.length,
        isLabelVisible: held.isNotEmpty,
        child: const Icon(Icons.pause_circle_outline),
      ),
    );
  }
}
