import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paged.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/platform_models.dart';
import '../data/platform_repository.dart';

const _statuses = ['approved', 'pending', 'draft', 'rejected'];

String statusLabel(AppL10n l10n, String status) => switch (status) {
  'approved' => l10n.catalogStatusApproved,
  'pending' => l10n.catalogStatusPending,
  'draft' => l10n.catalogStatusDraft,
  'rejected' => l10n.catalogStatusRejected,
  _ => status,
};

/// The shared catalogue every shop of a kind is offered — `GET /admin/catalog`.
///
/// An edit here never touches a shop's own product name or price; deleting is
/// soft, and shops that already sell an entry keep it.
class AdminCatalogueTab extends ConsumerStatefulWidget {
  const AdminCatalogueTab({required this.storeTypes, super.key});

  /// From the overview, until the catalogue's own `meta.storeTypes` arrives.
  final List<Choice> storeTypes;

  @override
  ConsumerState<AdminCatalogueTab> createState() => _AdminCatalogueTabState();
}

class _AdminCatalogueTabState extends ConsumerState<AdminCatalogueTab> {
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
      ref.read(adminCatalogProvider.notifier).loadMore();
    }
  }

  void _setFilter(AdminCatalogFilter filter) =>
      ref.read(adminCatalogFilterProvider.notifier).set(filter);

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final filter = ref.watch(adminCatalogFilterProvider);
    final list = ref.watch(adminCatalogProvider);
    final meta = list.value == null ? null : AdminCatalogMeta(list.value!.meta);
    final types = (meta?.storeTypes.isNotEmpty ?? false)
        ? meta!.storeTypes
        : widget.storeTypes;
    String typeName(int? id) =>
        types.where((t) => t.id == id).firstOrNull?.name ?? l10n.allTypes;

    return Column(
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
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 320),
                () => _setFilter(filter.copyWith(q: v.trim())),
              );
            },
            onSubmitted: (v) => _setFilter(filter.copyWith(q: v.trim())),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
          child: Row(
            children: [
              _MenuChip<int>(
                icon: Icons.category_outlined,
                label: typeName(filter.storeTypeId),
                selected: filter.storeTypeId,
                allLabel: l10n.allTypes,
                options: {for (final t in types) t.id: t.name},
                onSelected: (id) => _setFilter(
                  id == null
                      ? filter.copyWith(clearStoreType: true)
                      : filter.copyWith(storeTypeId: id),
                ),
              ),
              const SizedBox(width: Insets.s8),
              _MenuChip<String>(
                icon: Icons.flag_outlined,
                label: filter.status == null
                    ? l10n.allStatuses
                    : statusLabel(l10n, filter.status!),
                selected: filter.status,
                allLabel: l10n.allStatuses,
                options: {
                  for (final s in _statuses)
                    s: s == 'pending' && (meta?.pendingCount ?? 0) > 0
                        ? '${statusLabel(l10n, s)} (${meta!.pendingCount})'
                        : statusLabel(l10n, s),
                },
                onSelected: (s) => _setFilter(
                  s == null
                      ? filter.copyWith(clearStatus: true)
                      : filter.copyWith(status: s),
                ),
              ),
              const SizedBox(width: Insets.s8),
              FilterChip(
                selected: filter.trashed,
                onSelected: (v) => _setFilter(filter.copyWith(trashed: v)),
                avatar: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.deletedCount(meta?.trashedCount ?? 0)),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.s8),
        Expanded(
          child: AsyncView<Paged<AdminCatalogEntry>>(
            value: list,
            onRetry: () => ref.invalidate(adminCatalogProvider),
            builder: (context, page) {
              if (page.items.isEmpty) {
                return MessageState(
                  icon: Icons.menu_book_outlined,
                  title: l10n.catalogueNoResults,
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(adminCatalogProvider.notifier).refresh(),
                child: ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: page.items.length + 1,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: palette.hairline,
                    indent: Insets.gutter,
                  ),
                  itemBuilder: (context, i) => i >= page.items.length
                      ? _Footer(page: page)
                      : _EntryRow(entry: page.items[i], storeTypes: types),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.allLabel,
    required this.options,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final T? selected;
  final String allLabel;
  final Map<T, String> options;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<Object>(
    onSelected: (v) => onSelected(v is _All ? null : v as T),
    itemBuilder: (_) => [
      CheckedPopupMenuItem<Object>(
        value: const _All(),
        checked: selected == null,
        child: Text(allLabel),
      ),
      for (final e in options.entries)
        CheckedPopupMenuItem<Object>(
          value: e.key as Object,
          checked: selected == e.key,
          child: Text(e.value),
        ),
    ],
    child: Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: selected == null
          ? null
          : context.palette.accent.withValues(alpha: 0.12),
    ),
  );
}

class _All {
  const _All();
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry, required this.storeTypes});

  final AdminCatalogEntry entry;
  final List<Choice> storeTypes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final type =
        entry.storeType ??
        storeTypes.where((t) => t.id == entry.storeTypeId).firstOrNull?.name;
    final details = [?entry.brand, ?entry.genericName, ?entry.unit].join(' · ');

    return ListTile(
      onTap: () =>
          CatalogEntrySheet.show(context, storeTypes: storeTypes, entry: entry),
      title: Text(
        entry.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: entry.isDeleted
            ? TextStyle(
                color: palette.muted,
                decoration: TextDecoration.lineThrough,
              )
            : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.isNotEmpty)
            Text(
              details,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
          const SizedBox(height: Insets.s4),
          Wrap(
            spacing: Insets.s8,
            runSpacing: Insets.s4,
            children: [
              if (type != null) StatusChip(label: type, tone: palette.muted),
              if (entry.isDeleted)
                StatusChip(label: l10n.deletedBadge, tone: palette.danger)
              else if (entry.status != 'approved')
                StatusChip(
                  label: statusLabel(l10n, entry.status),
                  tone: entry.status == 'rejected'
                      ? palette.danger
                      : palette.warning,
                ),
              if (entry.inStores > 0)
                StatusChip(
                  label: l10n.inStoresCount(entry.inStores),
                  tone: palette.accent,
                  icon: Icons.storefront_outlined,
                ),
            ],
          ),
        ],
      ),
      trailing: entry.salePrice == null
          ? null
          : Text(
              money.format(entry.salePrice),
              style: text.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.page});

  final Paged<AdminCatalogEntry> page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final busy = ref.watch(adminCatalogProvider.notifier).isLoadingMore;

    return Padding(
      padding: const EdgeInsets.all(Insets.s24),
      child: Center(
        child: Column(
          children: [
            Text(
              l10n.showingOf('${page.items.length}', '${page.total}'),
              style: Theme.of(context).textTheme.bodySmall
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
                      ref.read(adminCatalogProvider.notifier).loadMore(),
                  child: Text(l10n.loadMore),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One entry

/// Adds or corrects a shared catalogue entry. In edit mode it also deletes
/// (soft) or, for a deleted one, restores.
class CatalogEntrySheet extends ConsumerStatefulWidget {
  const CatalogEntrySheet({required this.storeTypes, this.entry, super.key});

  final List<Choice> storeTypes;

  /// Null to add one.
  final AdminCatalogEntry? entry;

  static Future<void> show(
    BuildContext context, {
    required List<Choice> storeTypes,
    AdminCatalogEntry? entry,
  }) => showAppSheet<void>(
    context,
    title: entry == null
        ? AppL10n.of(context).newCatalogEntry
        : AppL10n.of(context).editCatalogEntry,
    subtitle: entry == null
        ? null
        : AppL10n.of(context).inStoresCount(entry.inStores),
    builder: (_) => CatalogEntrySheet(storeTypes: storeTypes, entry: entry),
  );

  @override
  ConsumerState<CatalogEntrySheet> createState() => _CatalogEntrySheetState();
}

class _CatalogEntrySheetState extends ConsumerState<CatalogEntrySheet> {
  final _form = GlobalKey<FormState>();
  late final AdminCatalogEntry? _e = widget.entry;
  late final _name = TextEditingController(text: _e?.name);
  late final _generic = TextEditingController(text: _e?.genericName);
  late final _brand = TextEditingController(text: _e?.brand);
  late final _sku = TextEditingController(text: _e?.sku);
  late final _barcode = TextEditingController(text: _e?.barcode);
  late final _description = TextEditingController(text: _e?.description);
  late final _cost = TextEditingController(text: _num(_e?.purchasePrice));
  late final _sale = TextEditingController(text: _num(_e?.salePrice));
  late final _mrp = TextEditingController(text: _num(_e?.mrp));
  late final _vat = TextEditingController(text: _num(_e?.vatPercent));
  late int? _storeTypeId =
      _e?.storeTypeId ??
      ref.read(adminCatalogFilterProvider).storeTypeId ??
      (widget.storeTypes.length == 1 ? widget.storeTypes.first.id : null);
  late String? _unit = _e?.unit;
  late int? _categoryId = _e?.categoryId;
  late String _status = _e?.status ?? 'approved';
  bool _busy = false;
  Map<String, List<String>> _fieldErrors = const {};

  static String? _num(num? v) => v?.toString();

  @override
  void dispose() {
    for (final c in [
      _name,
      _generic,
      _brand,
      _sku,
      _barcode,
      _description,
      _cost,
      _sale,
      _mrp,
      _vat,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _server(String field) {
    final messages = _fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _fieldErrors = const {});
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    final draft = CatalogEntryDraft(
      storeTypeId: _storeTypeId!,
      name: _name.text,
      genericName: _generic.text,
      brand: _brand.text,
      unit: _unit,
      categoryId: _categoryId,
      sku: _sku.text,
      barcode: _barcode.text,
      description: _description.text,
      purchasePrice: AmountField.read(_cost),
      salePrice: AmountField.read(_sale),
      mrp: AmountField.read(_mrp),
      vatPercent: AmountField.read(_vat),
      status: _status,
    );
    final repository = ref.read(platformRepositoryProvider);
    try {
      if (_e == null) {
        await repository.createEntry(draft);
      } else {
        await repository.updateEntry(_e.id, draft);
      }
      ref.invalidate(adminCatalogProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.catalogEntrySaved);
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _fieldErrors = e.fields);
        _form.currentState!.validate();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppL10n.of(context);
    final e = _e!;
    final ok = await confirmSheet(
      context,
      title: l10n.deleteCatalogEntryTitle(e.name),
      message: e.inStores > 0
          ? '${l10n.deleteCatalogEntryBody} ${l10n.inStoresCount(e.inStores)}.'
          : l10n.deleteCatalogEntryBody,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final affected = await ref
          .read(platformRepositoryProvider)
          .deleteEntry(e.id);
      ref.invalidate(adminCatalogProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.catalogEntryDeleted(affected));
    } catch (err) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, err);
      }
    }
  }

  Future<void> _restore() async {
    final l10n = AppL10n.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(platformRepositoryProvider).restoreEntry(_e!.id);
      ref.invalidate(adminCatalogProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.catalogEntryRestored);
    } catch (err) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, err);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final lookups = _storeTypeId == null
        ? null
        : ref.watch(adminCatalogLookupsProvider(_storeTypeId)).value;
    final units = [
      ...?lookups?.units,
      // Keep what the entry has even if the list no longer offers it.
      if (_unit != null &&
          !(lookups?.units.any((u) => u.short == _unit) ?? false))
        (short: _unit!, label: _unit!),
    ];
    final categories = lookups?.categories ?? const <Choice>[];

    if (_e?.isDeleted ?? false) {
      return Padding(
        padding: const EdgeInsets.all(Insets.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.catalogEntryIsDeleted),
            const SizedBox(height: Insets.s16),
            FilledButton.icon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore),
              label: Text(l10n.catalogRestore),
            ),
          ],
        ),
      );
    }

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
                if ((_e?.inStores ?? 0) > 0) ...[
                  Text(
                    l10n.catalogEditNote(_e!.inStores),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.warning),
                  ),
                  const SizedBox(height: Insets.s12),
                ],
                DropdownButtonFormField<int>(
                  initialValue:
                      widget.storeTypes.any((t) => t.id == _storeTypeId)
                      ? _storeTypeId
                      : null,
                  decoration: InputDecoration(labelText: l10n.storeTypeLabel),
                  items: [
                    for (final t in widget.storeTypes)
                      DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: (v) => setState(() {
                    _storeTypeId = v;
                    // Categories belong to a kind of shop.
                    _categoryId = null;
                  }),
                  validator: (v) =>
                      v == null ? l10n.requiredField : _server('storeTypeId'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.productNameLabel),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.requiredField
                      : _server('name'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _generic,
                  decoration: InputDecoration(labelText: l10n.genericNameLabel),
                  validator: (_) => _server('genericName'),
                ),
                const SizedBox(height: Insets.s12),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _brand.text),
                  optionsBuilder: (value) {
                    final q = value.text.trim().toLowerCase();
                    if (q.isEmpty) return const Iterable<String>.empty();
                    return (lookups?.brands ?? const <String>[])
                        .where((b) => b.toLowerCase().contains(q))
                        .take(8);
                  },
                  onSelected: (v) => _brand.text = v,
                  fieldViewBuilder: (context, controller, focus, submit) =>
                      TextFormField(
                        controller: controller,
                        focusNode: focus,
                        onChanged: (v) => _brand.text = v,
                        decoration: InputDecoration(labelText: l10n.brandLabel),
                        validator: (_) => _server('brand'),
                      ),
                ),
                const SizedBox(height: Insets.s12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _unit,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l10n.unitLabel),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('—')),
                          for (final u in units)
                            DropdownMenuItem(
                              value: u.short,
                              child: Text(
                                u.label == u.short
                                    ? u.short
                                    : '${u.label} (${u.short})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _unit = v),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: categories.any((c) => c.id == _categoryId)
                            ? _categoryId
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.categoryLabel,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('—')),
                          for (final c in categories)
                            DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.s12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sku,
                        decoration: InputDecoration(labelText: l10n.skuLabel),
                        validator: (_) => _server('sku'),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Expanded(
                      child: TextFormField(
                        controller: _barcode,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.barcodeLabel,
                        ),
                        validator: (_) => _server('barcode'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.s12),
                Row(
                  children: [
                    Expanded(
                      child: AmountField(
                        controller: _cost,
                        label: l10n.costLabel,
                        prefix: '${money.sign} ',
                        errorText: _server('purchasePrice'),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Expanded(
                      child: AmountField(
                        controller: _sale,
                        label: l10n.saleLabel,
                        prefix: '${money.sign} ',
                        errorText: _server('salePrice'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.s12),
                Row(
                  children: [
                    Expanded(
                      child: AmountField(
                        controller: _mrp,
                        label: l10n.mrpLabel,
                        prefix: '${money.sign} ',
                        errorText: _server('mrp'),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Expanded(
                      child: AmountField(
                        controller: _vat,
                        label: '${l10n.vatLabel} %',
                        errorText: _server('vatPercent'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.s12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(labelText: l10n.catalogStatus),
                  items: [
                    for (final s in {..._statuses, _status})
                      DropdownMenuItem(
                        value: s,
                        child: Text(statusLabel(l10n, s)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l10n.description),
                  validator: (_) => _server('description'),
                ),
                if (_e != null) ...[
                  const SizedBox(height: Insets.s16),
                  TextButton.icon(
                    onPressed: _busy ? null : _delete,
                    icon: Icon(Icons.delete_outline, color: palette.danger),
                    label: Text(
                      l10n.delete,
                      style: TextStyle(color: palette.danger),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SheetAction(
            label: l10n.save,
            icon: Icons.check,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
