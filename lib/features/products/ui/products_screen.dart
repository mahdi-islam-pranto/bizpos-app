import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/network/paged.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/product_models.dart';
import '../data/products_repository.dart';
import 'product_form_sheet.dart';

/// The shelves.
///
/// Genuinely paginated, unlike customers — so this one really does scroll into
/// the next page rather than showing a "narrow your search" footer. The header
/// carries the two numbers a stock keeper opens the app for: how much is low
/// and what the stock is worth.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    // A screen's worth of runway, so the next page is usually there before the
    // list reaches the bottom.
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(productsListProvider.notifier).loadMore();
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 320),
      () => ref.read(productFilterProvider.notifier).setText(value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final filter = ref.watch(productFilterProvider);
    final products = ref.watch(productsListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.productsTitle)),
      floatingActionButton: PermissionGate(
        perm: P.inventoryProductCreate,
        // Adding to the deleted list would be a strange thing to offer.
        child: filter.trashed
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                onPressed: () => ProductFormSheet.showNew(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addProduct),
              ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.gutter,
              Insets.s12,
              Insets.gutter,
              Insets.s8,
            ),
            child: SearchField(
              controller: _search,
              hint: l10n.productsSearchHint,
              onChanged: _onQueryChanged,
              onSubmitted: (value) => ref
                  .read(productFilterProvider.notifier)
                  .setText(value.trim()),
            ),
          ),
          _Filters(filter: filter),
          Expanded(
            child: AsyncView<Paged<Product>>(
              value: products,
              onRetry: () => ref.invalidate(productsListProvider),
              builder: (context, page) {
                if (page.items.isEmpty) return _Empty(filter: filter);

                // One extra row for the footer, which is either the next-page
                // spinner or the total.
                final rows = page.items.length + 1;

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(productsListProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: rows,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: palette.hairline,
                      indent: Insets.gutter,
                    ),
                    itemBuilder: (context, i) {
                      if (i >= page.items.length) {
                        return _Footer(
                          page: page,
                          onMore: () => ref
                              .read(productsListProvider.notifier)
                              .loadMore(),
                        );
                      }
                      return _ProductRow(product: page.items[i]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Low stock and the deleted list, plus the two figures from
/// `GET /products/stats`.
///
/// The stats are their own provider so a slow or forbidden stats call cannot
/// keep the list off the screen — the row simply is not there.
class _Filters extends ConsumerWidget {
  const _Filters({required this.filter});

  final ProductFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final controller = ref.read(productFilterProvider.notifier);
    final stats = ref.watch(productStatsProvider).value;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
        children: [
          FilterChip(
            label: Text(
              stats == null
                  ? l10n.productsLowOnly
                  : l10n.lowStockCount(stats.lowCount),
            ),
            avatar: Icon(
              Icons.trending_down,
              size: 18,
              color: filter.lowOnly ? null : palette.warning,
            ),
            selected: filter.lowOnly,
            onSelected: controller.setLowOnly,
          ),
          const SizedBox(width: Insets.s8),
          FilterChip(
            label: Text(
              stats == null || stats.expiringCount == 0
                  ? l10n.productsLive
                  : l10n.expiringCount(stats.expiringCount),
            ),
            selected: !filter.trashed,
            onSelected: (_) => controller.setTrashed(false),
          ),
          const SizedBox(width: Insets.s8),
          // `trashed=1` is a different list, not a narrowing of this one, so it
          // gets its own chip rather than sitting beside "low stock".
          PermissionGate(
            perm: P.inventoryProductDelete,
            child: FilterChip(
              label: Text(l10n.productsTrashed),
              avatar: const Icon(Icons.delete_outline, size: 18),
              selected: filter.trashed,
              onSelected: controller.setTrashed,
            ),
          ),
          // Only with the cost permission: `stockValue` arrives whatever the
          // role, and `canSeeCost` is what says whether it means anything.
          if (stats != null && stats.canSeeCost && stats.stockValue != null) ...[
            const SizedBox(width: Insets.s12),
            Center(
              child: Text(
                '${l10n.stockValue}: ${money.format(stats.stockValue)}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: palette.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filter});

  final ProductFilter filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    if (filter.trashed) {
      return EmptyState(
        title: l10n.productsNoneTrashed,
        body: l10n.productsNoneTrashedBody,
        icon: Icons.delete_outline,
      );
    }
    if (!filter.isPlain) {
      return EmptyState(
        title: l10n.productsNoResults,
        body: l10n.productsNoResultsBody,
        icon: Icons.search_off,
      );
    }
    return EmptyState(
      title: l10n.productsNone,
      body: l10n.productsNoneBody,
      icon: Icons.inventory_2_outlined,
    );
  }
}

/// The end of the list: how far through it we are, and the way to the rest.
///
/// A spinner shows only while a page is genuinely in flight. Showing one
/// whenever there is more would spin for ever on a first page too short to
/// scroll, which is exactly the case where somebody needs the button.
class _Footer extends ConsumerWidget {
  const _Footer({required this.page, required this.onMore});

  final Paged<Product> page;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final busy = ref.watch(productsListProvider.notifier).isLoadingMore;

    return Padding(
      padding: const EdgeInsets.all(Insets.s24),
      child: Center(
        child: Column(
          children: [
            Text(
              l10n.showingOf(
                page.items.length.toString(),
                page.total.toString(),
              ),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: palette.muted),
            ),
            if (page.hasMore) ...[
              const SizedBox(height: Insets.s12),
              if (busy)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(onPressed: onMore, child: Text(l10n.loadMore)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);

    final stock = product.stock;
    final (stockLabel, stockTone) = switch (stock) {
      // Null is a role without `inventory.stock.view`, not an empty shelf.
      null => (null, palette.muted),
      final s when s <= 0 => (l10n.outOfStock, palette.danger),
      _ when product.isLow => (l10n.lowStock, palette.warning),
      final s => (l10n.onShelf(s.toStringAsFixed(0)), palette.muted),
    };

    return ListTile(
      onTap: () => context.go('/products/${product.id}'),
      title: Row(
        children: [
          Flexible(
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              // Stopped, not deleted: still here, no longer at the till. The
              // workspace strikes it through, and so does this.
              style: product.isActive || product.isDeleted
                  ? null
                  : TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: palette.muted,
                    ),
            ),
          ),
          if (product.isDeleted) ...[
            const SizedBox(width: Insets.s8),
            StatusChip(label: l10n.deletedBadge, tone: palette.danger),
          ] else if (!product.isActive) ...[
            const SizedBox(width: Insets.s8),
            StatusChip(label: l10n.inactiveBadge, tone: palette.muted),
          ],
        ],
      ),
      subtitle: Text(
        [
          ?stockLabel,
          ?product.brand,
          ?product.unit,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodySmall?.copyWith(color: stockTone),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            money.format(product.salePrice),
            style: text.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          // Null cost is "not told". A cashier sees the sale price alone.
          ?switch (product.purchasePrice) {
            null => null,
            final cost => Text(
                '${l10n.costLabel} ${money.format(cost)}',
                style: text.labelSmall?.copyWith(color: palette.muted),
              ),
          },
        ],
      ),
    );
  }
}
