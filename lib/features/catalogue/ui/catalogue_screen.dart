import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import 'adopt_sheet.dart';
import 'suggest_sheet.dart';

/// The shared catalogue, always of this store's own store type.
///
/// Three views of one list: everything, what this shop already stocks, and
/// what it does not — "Not in my store" is the list to shop from. Adding one
/// is `catalog.product.import`; when nothing fits, `catalog.product.suggest`
/// opens the suggestion form with what was searched for.
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
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
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(catalogListProvider.notifier).loadMore();
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 320),
      () => ref.read(catalogFilterProvider.notifier).setText(value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final filter = ref.watch(catalogFilterProvider);
    final list = ref.watch(catalogListProvider);
    final meta = list.value?.meta;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.catalogueTitle)),
      floatingActionButton: PermissionGate(
        perm: P.catalogProductSuggest,
        child: FloatingActionButton.extended(
          onPressed: () =>
              SuggestSheet.show(context, initialName: filter.text),
          icon: const Icon(Icons.add_box_outlined),
          label: Text(l10n.suggestProduct),
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
              hint: l10n.catalogueSearchHint,
              onChanged: _onQueryChanged,
              onSubmitted: (v) =>
                  ref.read(catalogFilterProvider.notifier).setText(v.trim()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
            child: Row(
              children: [
                for (final scope in CatalogScope.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.s8),
                    child: ChoiceChip(
                      selected: filter.scope == scope,
                      onSelected: (_) => ref
                          .read(catalogFilterProvider.notifier)
                          .setScope(scope),
                      label: Text(switch (scope) {
                        CatalogScope.all => l10n.catalogueAll,
                        // Both counts ignore `q`, so they stay put while the
                        // person types.
                        CatalogScope.mine => l10n.catalogueMine(
                            '${meta?.intValue('mineCount') ?? '–'}',
                          ),
                        CatalogScope.missing => l10n.catalogueMissing(
                            '${meta?.intValue('missingCount') ?? '–'}',
                          ),
                      }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Insets.s8),
          Expanded(
            child: AsyncView<Paged<CatalogEntry>>(
              value: list,
              onRetry: () => ref.invalidate(catalogListProvider),
              builder: (context, page) {
                if (page.items.isEmpty) {
                  return MessageState(
                    icon: Icons.menu_book_outlined,
                    title: filter.scope == CatalogScope.missing &&
                            (filter.text ?? '').isEmpty
                        ? l10n.catalogueNothingMissing
                        : l10n.catalogueNoResults,
                    body: l10n.catalogueNoResultsBody,
                    action: PermissionGate(
                      perm: P.catalogProductSuggest,
                      child: OutlinedButton.icon(
                        onPressed: () => SuggestSheet.show(
                          context,
                          initialName: filter.text,
                        ),
                        icon: const Icon(Icons.add_box_outlined),
                        label: Text(l10n.suggestProduct),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(catalogListProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: page.items.length + 1,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: palette.hairline,
                      indent: Insets.gutter,
                    ),
                    itemBuilder: (context, i) {
                      if (i >= page.items.length) {
                        return _Footer(page: page);
                      }
                      return _EntryRow(entry: page.items[i]);
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

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry});

  final CatalogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final mayImport = ref.watch(permissionsProvider).has(P.catalogProductImport);

    return ListTile(
      onTap: !entry.isInStore && mayImport
          ? () => AdoptSheet.show(context, entry)
          : null,
      title: Text(entry.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [?entry.brand, ?entry.genericName].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
          if (entry.isInStore || entry.pending) ...[
            const SizedBox(height: Insets.s4),
            Wrap(
              spacing: Insets.s8,
              children: [
                if (entry.isInStore)
                  StatusChip(
                    label: l10n.inMyStore,
                    tone: palette.positive,
                    icon: Icons.check,
                  ),
                // Put up by a shop, not vouched for by the platform yet.
                if (entry.pending)
                  StatusChip(label: l10n.pendingBadge, tone: palette.warning),
              ],
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (entry.defaultSalePrice != null)
            Text(
              money.format(entry.defaultSalePrice),
              style: text.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          if (!entry.isInStore && mayImport)
            Text(
              l10n.addToStore,
              style: text.labelSmall?.copyWith(color: palette.accent),
            ),
        ],
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.page});

  final Paged<CatalogEntry> page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final busy = ref.watch(catalogListProvider.notifier).isLoadingMore;

    return Padding(
      padding: const EdgeInsets.all(Insets.s24),
      child: Center(
        child: Column(
          children: [
            Text(
              l10n.showingOf('${page.items.length}', '${page.total}'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.palette.muted),
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
                TextButton(
                  onPressed: () =>
                      ref.read(catalogListProvider.notifier).loadMore(),
                  child: Text(l10n.loadMore),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
