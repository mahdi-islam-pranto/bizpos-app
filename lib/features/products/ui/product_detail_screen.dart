import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/product_models.dart';
import '../data/products_repository.dart';
import 'product_action_sheets.dart';
import 'pricing_fields.dart';
import 'product_form_sheet.dart';

/// One product: what it is, what it costs, and everything that has happened to
/// it.
///
/// There is no `GET /products/{id}` — the detail is read out of the list the
/// row was tapped from, and only the history has an endpoint of its own. That
/// is why every action here invalidates the list: the list *is* the record.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final product = ref.watch(productProvider(productId));

    if (product == null) {
      // The list has not been loaded, or the id belongs to another store —
      // where it is not forbidden, it simply does not exist.
      return Scaffold(
        appBar: AppBar(title: Text(l10n.productsTitle)),
        body: MessageState(
          icon: Icons.inventory_2_outlined,
          title: l10n.productsNoResults,
          body: l10n.productsNoResultsBody,
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(productsListProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (!product.isDeleted)
            PermissionGate(
              perm: P.inventoryProductUpdate,
              child: IconButton(
                tooltip: l10n.editProduct,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => ProductFormSheet.showEdit(context, product),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.gutter),
        children: [
          if (product.isDeleted) _DeletedBanner(product: product),
          _Identity(product: product),
          const SizedBox(height: Insets.s16),
          _Prices(product: product),
          const SizedBox(height: Insets.s16),
          _StockCard(product: product),
          _History(productId: productId),
          if (!product.isDeleted) ...[
            const SizedBox(height: Insets.s32),
            PermissionGate(
              perm: P.inventoryProductUpdate,
              child: Center(child: _SellingToggle(product: product)),
            ),
            PermissionGate(
              perm: P.inventoryProductDelete,
              child: Center(child: _DeleteButton(product: product)),
            ),
          ],
          const SizedBox(height: Insets.s32),
        ],
      ),
      bottomNavigationBar: _Actions(product: product),
    );
  }
}

class _DeletedBanner extends ConsumerWidget {
  const _DeletedBanner({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    return Container(
      margin: const EdgeInsets.only(bottom: Insets.s16),
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.row),
      ),
      child: Row(
        children: [
          Icon(Icons.delete_outline, size: 18, color: palette.danger),
          const SizedBox(width: Insets.s8),
          Expanded(
            child: Text(
              l10n.deletedOn(AppDates.day(product.deletedAt, locale: locale)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          PermissionGate(
            perm: P.inventoryProductDelete,
            child: _RestoreButton(product: product),
          ),
        ],
      ),
    );
  }
}

class _RestoreButton extends ConsumerStatefulWidget {
  const _RestoreButton({required this.product});

  final Product product;

  @override
  ConsumerState<_RestoreButton> createState() => _RestoreButtonState();
}

class _RestoreButtonState extends ConsumerState<_RestoreButton> {
  bool _busy = false;

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    try {
      await ref.read(productsRepositoryProvider).restore(widget.product.id);
      ref.invalidate(productsListProvider);
      ref.invalidate(productStatsProvider);
      if (mounted) showNote(context, l10n.restoreProductDone(widget.product.name));
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: _busy ? null : _restore,
        child: Text(AppL10n.of(context).restoreProduct),
      );
}

/// `PATCH /products/{id}` with `isActive` and nothing else.
///
/// A line the shop has stopped carrying is not a mistake to delete: it keeps
/// its stock and every invoice it was on, and only leaves the till. Sent on its
/// own, because a price beside it would bring the all-three-prices rule down on
/// a request that has no business naming a price.
class _SellingToggle extends ConsumerStatefulWidget {
  const _SellingToggle({required this.product});

  final Product product;

  @override
  ConsumerState<_SellingToggle> createState() => _SellingToggleState();
}

class _SellingToggleState extends ConsumerState<_SellingToggle> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    final l10n = AppL10n.of(context);
    final nowActive = !widget.product.isActive;

    setState(() => _busy = true);
    try {
      await ref
          .read(productsRepositoryProvider)
          .update(widget.product.id, isActive: nowActive);
      ref.invalidate(productsListProvider);
      ref.invalidate(productStatsProvider);
      if (mounted) {
        showNote(context, nowActive ? l10n.productResumed : l10n.productStopped);
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final active = widget.product.isActive;

    return Column(
      children: [
        TextButton.icon(
          onPressed: _busy ? null : _toggle,
          icon: Icon(active ? Icons.pause_circle_outline : Icons.play_circle_outline),
          label: Text(active ? l10n.stopSelling : l10n.resumeSelling),
        ),
        if (active)
          Text(
            l10n.stoppedSellingNote,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: context.palette.muted),
          ),
        const SizedBox(height: Insets.s16),
      ],
    );
  }
}

class _DeleteButton extends ConsumerStatefulWidget {
  const _DeleteButton({required this.product});

  final Product product;

  @override
  ConsumerState<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends ConsumerState<_DeleteButton> {
  bool _busy = false;

  /// Soft, and reversible — but it writes off whatever is on the shelf, and the
  /// figure it writes off is the part nobody expects. So the confirmation says
  /// what will happen and the note afterwards says what did.
  Future<void> _delete() async {
    if (_busy) return;
    final l10n = AppL10n.of(context);

    final ahead = await confirmSheet(
      context,
      title: l10n.deleteProduct,
      message: l10n.deleteProductBody,
      confirmLabel: l10n.deleteProduct,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ahead || !mounted) return;

    setState(() => _busy = true);
    try {
      final outcome =
          await ref.read(productsRepositoryProvider).softDelete(widget.product.id);
      ref.invalidate(productsListProvider);
      ref.invalidate(productStatsProvider);
      if (!mounted) return;
      showNote(
        context,
        l10n.deleteProductDone(outcome.stockWritten.toStringAsFixed(0)),
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return TextButton.icon(
      onPressed: _busy ? null : _delete,
      icon: Icon(Icons.delete_outline, color: palette.danger),
      label: Text(
        l10n.deleteProduct,
        style: TextStyle(color: palette.danger),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AppCard(
      padding: const EdgeInsets.all(Insets.gutter),
      children: [
        _Line(label: l10n.brandLabel, value: product.brand),
        _Line(label: l10n.categoryLabel, value: product.category),
        _Line(label: l10n.unitLabel, value: product.unit),
        _Line(label: l10n.barcodeLabel, value: product.barcode),
        _Line(label: l10n.skuLabel, value: product.sku),
        if (product.vatPercent > 0)
          _Line(
            label: l10n.vatLabel,
            value: '${product.vatPercent}%',
          ),
        if (product.trackBatch)
          _Line(label: l10n.trackBatchLabel, value: l10n.yes),
      ],
    );
  }
}

class _Prices extends ConsumerWidget {
  const _Prices({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);

    return AppCard(
      padding: const EdgeInsets.all(Insets.gutter),
      children: [
        _Line(label: l10n.saleLabel, value: money.format(product.salePrice)),
        // Every cost line is absent rather than zero for a role without
        // `inventory.product.view_cost`, so a cashier sees a price list and no
        // hint that the shop paid nothing for anything.
        if (product.purchasePrice != null)
          _Line(
            label: l10n.costLabel,
            value: money.format(product.purchasePrice),
          ),
        if (product.wholesalePrice != null)
          _Line(
            label: l10n.wholesaleLabel,
            value: money.format(product.wholesalePrice),
          ),
        if (product.mrp != null && product.mrp! > 0)
          _Line(label: l10n.mrpLabel, value: money.format(product.mrp)),
        if (markupLabel(product) != null)
          _Line(label: l10n.markupLabel, value: markupLabel(product)),
        if (product.margin != null)
          _Line(
            label: l10n.marginLabel,
            value: money.format(product.margin),
            tone: product.margin! < 0 ? palette.danger : palette.positive,
          ),
        if (product.purchasePrice == null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.s8),
            child: Text(
              l10n.costHidden,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: palette.muted),
            ),
          ),
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final stock = product.stock;

    // Null is a role without `inventory.stock.view`. Showing "0 on the shelf"
    // would be a lie about the shop rather than a gap in this person's access.
    if (stock == null) return const SizedBox.shrink();

    final tone = product.isOut
        ? palette.danger
        : product.isLow
            ? palette.warning
            : palette.positive;

    return AppCard(
      padding: const EdgeInsets.all(Insets.gutter),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.onShelf(stock.toStringAsFixed(0)),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: tone),
              ),
            ),
            if (product.minimumStock != null)
              StatusChip(
                label:
                    '${l10n.minimumStockLabel} ${product.minimumStock!.toStringAsFixed(0)}',
                tone: palette.muted,
              ),
          ],
        ),
      ],
    );
  }
}

/// The two histories, side by side under their own headings.
class _History extends ConsumerWidget {
  const _History({required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final history = ref.watch(productHistoryProvider(productId));

    return PermissionGate(
      perm: P.inventoryStockView,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(l10n.stockHistory),
          AsyncView<ProductHistory>(
            value: history,
            loading: const Padding(
              padding: EdgeInsets.all(Insets.s24),
              child: Center(child: CircularProgressIndicator()),
            ),
            onRetry: () => ref.invalidate(productHistoryProvider(productId)),
            builder: (context, data) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data.movements.isEmpty)
                  _Quiet(l10n.noMovements)
                else
                  AppCard(
                    children: [
                      for (final movement in data.movements)
                        _MovementRow(movement: movement),
                    ],
                  ),
                SectionHeader(l10n.priceHistory),
                if (data.prices.isEmpty)
                  _Quiet(l10n.noPrices)
                else
                  AppCard(
                    children: [
                      for (final price in data.prices)
                        _PriceRow(price: price),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends ConsumerWidget {
  const _MovementRow({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    // A type the API adds later reads as itself rather than as nothing.
    final label = switch (movement.type) {
      'opening' => l10n.movementOpening,
      'purchase' => l10n.movementPurchase,
      'sale' => l10n.movementSale,
      'return' => l10n.movementReturn,
      'adjustment' => l10n.movementAdjustment,
      'damage' => l10n.movementDamage,
      'transfer' => l10n.movementTransfer,
      final other => other,
    };

    final inward = movement.delta >= 0;

    return ListTile(
      dense: true,
      leading: Icon(
        inward ? Icons.south_west : Icons.north_east,
        size: 18,
        color: inward ? palette.positive : palette.danger,
      ),
      title: Text(label, style: text.bodyMedium),
      subtitle: Text(
        [
          AppDates.stamp(movement.movedAt, locale: locale),
          ?movement.user,
          ?movement.note,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: text.labelSmall?.copyWith(color: palette.muted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${inward ? '+' : '−'}${movement.delta.abs().toStringAsFixed(0)}',
            style: text.titleSmall?.copyWith(
              color: inward ? palette.positive : palette.danger,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            l10n.balanceAfter(movement.balanceAfter.toStringAsFixed(0)),
            style: text.labelSmall?.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends ConsumerWidget {
  const _PriceRow({required this.price});

  final PriceChange price;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    return ListTile(
      dense: true,
      title: Text(money.format(price.salePrice), style: text.bodyMedium),
      subtitle: Text(
        [
          AppDates.day(price.effectiveFrom, locale: locale),
          if (price.purchasePrice != null)
            '${l10n.costLabel} ${money.format(price.purchasePrice)}',
          if (price.profitPercent != null) '+${price.profitPercent}%',
        ].join(' · '),
        style: text.labelSmall?.copyWith(color: palette.muted),
      ),
      trailing: price.isCurrent
          ? StatusChip(label: l10n.currentPrice, tone: palette.accent)
          : null,
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.s16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: context.palette.muted),
        ),
      );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.tone});

  final String label;
  final String? value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.s4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
          ),
          Text(
            value!,
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

/// Change prices and adjust stock — the two things a stock keeper opens a
/// product to do. Each behind its own permission, and neither offered on a
/// product that has been deleted.
class _Actions extends ConsumerWidget {
  const _Actions({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final permissions = ref.watch(permissionsProvider);

    // The price set cannot be sent without the cost, and a role that may not
    // see the cost would write back a blank one.
    final mayPrice = permissions.has(P.inventoryProductUpdate) &&
        permissions.has(P.inventoryProductViewCost) &&
        !product.isDeleted;
    final mayAdjust =
        permissions.has(P.inventoryAdjustCreate) && !product.isDeleted;

    if (!mayPrice && !mayAdjust) return const SizedBox.shrink();

    return Material(
      color: palette.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.hairline)),
          ),
          padding: const EdgeInsets.all(Insets.gutter),
          child: Row(
            children: [
              if (mayPrice)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => PriceSheet.show(context, product),
                    icon: const Icon(Icons.sell_outlined),
                    label: Text(l10n.changePrices),
                  ),
                ),
              if (mayPrice && mayAdjust) const SizedBox(width: Insets.s12),
              if (mayAdjust)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => AdjustStockSheet.show(context, product),
                    icon: const Icon(Icons.tune),
                    label: Text(l10n.adjustStock),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
