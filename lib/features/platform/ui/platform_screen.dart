import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/shell_nav.dart';
import '../../../core/format/money.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../team/ui/team_screen.dart' show humanizeKey;
import '../data/platform_models.dart';
import '../data/platform_repository.dart';
import 'admin_catalogue_tab.dart';
import 'platform_sheets.dart';

/// The platform, for its own staff: every shop, the suggestions shops put up
/// for the shared catalogue, and the catalogue itself.
///
/// Gated on `admin.store.view`; each tab and button carries its own
/// `admin.*` permission.
class PlatformScreen extends ConsumerStatefulWidget {
  const PlatformScreen({super.key});

  @override
  ConsumerState<PlatformScreen> createState() => _PlatformScreenState();
}

enum _PlatformTab { stores, suggestions, catalogue }

class _PlatformScreenState extends ConsumerState<PlatformScreen>
    with TickerProviderStateMixin {
  TabController? _controller;
  List<_PlatformTab> _tabs = const [];

  void _ensureTabs(List<_PlatformTab> tabs) {
    if (_controller != null && _tabs.length == tabs.length) return;
    _controller?.dispose();
    _tabs = tabs;
    _controller = TabController(length: tabs.length, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final permissions = ref.watch(permissionsProvider);
    final overview = ref.watch(platformOverviewProvider);
    final data = overview.value;

    _ensureTabs([
      _PlatformTab.stores,
      if (permissions.has(P.adminSuggestionReview)) _PlatformTab.suggestions,
      if (permissions.has(P.adminCatalogManage)) _PlatformTab.catalogue,
    ]);
    final controller = _controller!;
    final current = _tabs[controller.index.clamp(0, _tabs.length - 1)];

    final fab = switch (current) {
      _PlatformTab.stores
          when data != null && permissions.has(P.adminStoreCreate) =>
        FloatingActionButton.extended(
          onPressed: () => NewStoreSheet.show(context, overview: data),
          icon: const Icon(Icons.add_business_outlined),
          label: Text(l10n.newStore),
        ),
      _PlatformTab.catalogue => FloatingActionButton.extended(
        onPressed: () => CatalogEntrySheet.show(
          context,
          storeTypes: data?.storeTypes ?? const [],
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCatalogEntry),
      ),
      _ => null,
    };

    return Scaffold(
      appBar: ShellAppBar(
        title: Text(l10n.platform),
        bottom: _tabs.length < 2
            ? null
            : TabBar(
                controller: controller,
                tabs: [
                  for (final t in _tabs)
                    Tab(
                      text: switch (t) {
                        _PlatformTab.stores => l10n.platformStores,
                        _PlatformTab.suggestions => l10n.platformSuggestions(
                          data?.suggestions.length ?? 0,
                        ),
                        _PlatformTab.catalogue => l10n.platformCatalogue,
                      },
                    ),
                ],
              ),
      ),
      floatingActionButton: fab,
      body: TabBarView(
        controller: controller,
        children: [
          for (final t in _tabs)
            switch (t) {
              _PlatformTab.stores => const _StoresTab(),
              _PlatformTab.suggestions => const _SuggestionsTab(),
              _PlatformTab.catalogue => AdminCatalogueTab(
                storeTypes: data?.storeTypes ?? const [],
              ),
            },
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stores

enum _StoreFilter { all, active, endingSoon, locked }

class _StoresTab extends ConsumerStatefulWidget {
  const _StoresTab();

  @override
  ConsumerState<_StoresTab> createState() => _StoresTabState();
}

class _StoresTabState extends ConsumerState<_StoresTab> {
  final _search = TextEditingController();
  String _query = '';
  _StoreFilter _filter = _StoreFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _passes(AdminStore s) => switch (_filter) {
    _StoreFilter.all => true,
    _StoreFilter.active => !s.locked && !s.isSuspended,
    _StoreFilter.endingSoon =>
      !s.locked && s.trialDaysLeft != null && s.trialDaysLeft! <= 7,
    _StoreFilter.locked => s.locked || s.isSuspended,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final overview = ref.watch(platformOverviewProvider);

    return AsyncView<PlatformOverview>(
      value: overview,
      onRetry: () => ref.invalidate(platformOverviewProvider),
      builder: (context, data) {
        final stores = data.stores
            .where((s) => s.matches(_query) && _passes(s))
            .toList();
        final ending = data.stores
            .where(
              (s) =>
                  !s.locked && s.trialDaysLeft != null && s.trialDaysLeft! <= 7,
            )
            .length;
        final locked = data.stores
            .where((s) => s.locked || s.isSuspended)
            .length;

        return RefreshIndicator(
          onRefresh: () => ref.refresh(platformOverviewProvider.future),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (data.totals.isNotEmpty) _Totals(totals: data.totals),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.gutter,
                  Insets.s12,
                  Insets.gutter,
                  Insets.s8,
                ),
                child: SearchField(
                  controller: _search,
                  hint: l10n.storeSearchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
                child: Row(
                  children: [
                    for (final f in _StoreFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: Insets.s8),
                        child: ChoiceChip(
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          label: Text(switch (f) {
                            _StoreFilter.all => l10n.allStoresCount(
                              data.stores.length,
                            ),
                            _StoreFilter.active => l10n.activeBadge,
                            _StoreFilter.endingSoon => l10n.trialEndingCount(
                              ending,
                            ),
                            _StoreFilter.locked => l10n.lockedCount(locked),
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Insets.s8),
              if (stores.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Insets.s32),
                  child: MessageState(
                    icon: Icons.storefront_outlined,
                    title: l10n.noStoresMatch,
                  ),
                )
              else
                for (var i = 0; i < stores.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: palette.hairline,
                      indent: Insets.gutter,
                    ),
                  _StoreRow(store: stores[i], overview: data),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.totals});

  final Map<String, num> totals;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          Insets.gutter,
          Insets.s12,
          Insets.gutter,
          0,
        ),
        children: [
          for (final e in totals.entries)
            Container(
              margin: const EdgeInsets.only(right: Insets.s8),
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.s12,
                vertical: Insets.s8,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(Radii.row),
                border: Border.all(color: palette.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    plainNumber(e.value),
                    style: text.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    humanizeKey(e.key),
                    style: text.labelSmall?.copyWith(color: palette.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String plainNumber(num v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

class _StoreRow extends ConsumerWidget {
  const _StoreRow({required this.store, required this.overview});

  final AdminStore store;
  final PlatformOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final here = ref.watch(meProvider)?.store?.id == store.id;
    final type =
        store.storeTypeName ?? overview.storeTypeName(store.storeTypeId);

    return ListTile(
      onTap: () =>
          StoreAdminSheet.show(context, store: store, overview: overview),
      title: Row(
        children: [
          Flexible(
            child: Text(
              store.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (here) ...[
            const SizedBox(width: Insets.s8),
            Icon(Icons.location_on, size: 16, color: palette.accent),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [?type, ?(store.ownerName ?? store.phone)].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: Insets.s4),
          StoreBadges(store: store),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

/// Status, trial clock and database state — the three things that decide
/// whether a shop can open in the morning.
class StoreBadges extends StatelessWidget {
  const StoreBadges({required this.store, super.key});

  final AdminStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final days = store.trialDaysLeft;

    return Wrap(
      spacing: Insets.s8,
      runSpacing: Insets.s4,
      children: [
        if (store.isSuspended)
          StatusChip(
            label: l10n.suspendedBadge,
            tone: palette.danger,
            icon: Icons.block,
          )
        else if (store.locked)
          StatusChip(
            label: l10n.lockedBadge,
            tone: palette.danger,
            icon: Icons.lock_outline,
          )
        else
          StatusChip(label: l10n.activeBadge, tone: palette.positive),
        if (store.hasTrial && days != null)
          StatusChip(
            label: days <= 0 ? l10n.trialOver : l10n.daysLeft('$days'),
            tone: days <= 3 ? palette.danger : palette.warning,
            icon: Icons.hourglass_bottom,
          ),
        if (store.dbName != null && !store.dbReady)
          StatusChip(
            label: l10n.dbNotReady,
            tone: palette.danger,
            icon: Icons.storage,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Suggestions

class _SuggestionsTab extends ConsumerWidget {
  const _SuggestionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final overview = ref.watch(platformOverviewProvider);

    return AsyncView<PlatformOverview>(
      value: overview,
      onRetry: () => ref.invalidate(platformOverviewProvider),
      builder: (context, data) {
        if (data.suggestions.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(platformOverviewProvider.future),
            child: ListView(
              children: [
                const SizedBox(height: Insets.s32),
                MessageState(
                  icon: Icons.inbox_outlined,
                  title: l10n.platformSuggestionsEmpty,
                  body: l10n.platformSuggestionsEmptyBody,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(platformOverviewProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(Insets.gutter),
            itemCount: data.suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: Insets.s12),
            // Keyed, so a card's in-flight state never passes to the next
            // suggestion when a reviewed one leaves the list.
            itemBuilder: (context, i) => _SuggestionCard(
              key: ValueKey(data.suggestions[i].id),
              suggestion: data.suggestions[i],
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionCard extends ConsumerStatefulWidget {
  const _SuggestionCard({required this.suggestion, super.key});

  final AdminSuggestion suggestion;

  @override
  ConsumerState<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<_SuggestionCard> {
  bool _busy = false;

  Future<void> _review({required bool approve}) async {
    final l10n = AppL10n.of(context);
    String? note;
    if (!approve) {
      note = await askNote(context, title: l10n.rejectReason);
      if (note == null || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(platformRepositoryProvider)
          .reviewSuggestion(widget.suggestion.id, approve: approve, note: note);
      ref.invalidate(platformOverviewProvider);
      // An approval is a new catalogue entry; a pending one leaves the list.
      ref.invalidate(adminCatalogProvider);
      if (!mounted) return;
      showNote(
        context,
        !approve
            ? l10n.platformSuggestionRejected
            : created
            ? l10n.platformSuggestionAdded
            : l10n.platformSuggestionMatched,
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
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final s = widget.suggestion;
    final details = [?s.brand, ?s.genericName, ?s.unit].join(' · ');
    final from = [?s.storeName, ?s.suggestedBy].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(Insets.gutter),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(s.name, style: text.titleSmall)),
            if (s.storeType != null)
              StatusChip(label: s.storeType!, tone: palette.accent),
          ],
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: Insets.s4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              details,
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
          ),
        ],
        if (s.salePrice != null || s.mrp != null || s.barcode != null) ...[
          const SizedBox(height: Insets.s4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              [
                if (s.salePrice != null)
                  '${l10n.saleLabel} ${money.format(s.salePrice)}',
                if (s.mrp != null) '${l10n.mrpLabel} ${money.format(s.mrp)}',
                ?s.barcode,
              ].join(' · '),
              style: text.bodySmall,
            ),
          ),
        ],
        if (from.isNotEmpty) ...[
          const SizedBox(height: Insets.s4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.suggestedFrom(from),
              style: text.labelSmall?.copyWith(color: palette.muted),
            ),
          ),
        ],
        const SizedBox(height: Insets.s12),
        if (_busy)
          const LinearProgressIndicator()
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _review(approve: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.danger,
                  ),
                  child: Text(l10n.reject),
                ),
              ),
              const SizedBox(width: Insets.s12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _review(approve: true),
                  child: Text(l10n.approve),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
