import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../sales/ui/sale_status_chips.dart';
import '../../sales/data/sale_models.dart' show PaymentStatus;
import '../data/purchase_models.dart';
import '../data/purchases_repository.dart';
import 'photo_picking.dart';
import 'supplier_sheets.dart';

/// Goods in: the latest 50 bills, what is still owed on them, and the door to
/// a new one.
///
/// Reading is `purchase.bill.view` (an accountant or auditor has it too);
/// writing a bill is `purchase.bill.create` **and** `meta.mayCreate`.
class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
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
    final permissions = ref.watch(permissionsProvider);
    final page = ref.watch(purchasesProvider(_query));
    final data = page.value;

    final mayCreate = permissions.allows(
      P.purchaseBillCreate,
      alsoRequire: data?.mayCreate,
    );
    final mayManageSuppliers = permissions.allows(
      P.purchaseSupplierManage,
      alsoRequire: data?.mayManageSuppliers,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchaseTitle),
        actions: [
          if (data != null)
            IconButton(
              tooltip: l10n.suppliers,
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () => SupplierListSheet.show(
                context,
                suppliers: data.suppliers,
                mayManage: mayManageSuppliers,
              ),
            ),
        ],
      ),
      floatingActionButton: mayCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/purchase/new'),
              icon: const Icon(Icons.local_shipping_outlined),
              label: Text(l10n.goodsIn),
            )
          : null,
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
              hint: l10n.purchaseSearchHint,
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 320), () {
                  if (mounted) setState(() => _query = v.trim());
                });
              },
              onSubmitted: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: AsyncView<PurchasePage>(
              value: page,
              onRetry: () => ref.invalidate(purchasesProvider(_query)),
              builder: (context, data) {
                if (data.rows.isEmpty) {
                  return EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: l10n.purchasesEmpty,
                    body: mayCreate ? l10n.purchasesEmptyBody : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(purchasesProvider(_query)),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: data.rows.length + 1,
                    separatorBuilder: (_, i) => i == 0
                        ? const SizedBox.shrink()
                        : Divider(
                            height: 1,
                            color: palette.hairline,
                            indent: Insets.gutter,
                          ),
                    itemBuilder: (context, i) {
                      if (i == 0) return _Summary(page: data);
                      final row = data.rows[i - 1];
                      return _PurchaseRowTile(
                        row: row,
                        onTap: () => PurchaseDetailSheet.show(
                          context,
                          row: row,
                          page: data,
                          query: _query,
                        ),
                      );
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

class _Summary extends ConsumerWidget {
  const _Summary({required this.page});

  final PurchasePage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);

    Widget stat(String label, String value, {Color? tone}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelSmall?.copyWith(color: palette.muted)),
              Text(
                value,
                style: text.titleMedium?.copyWith(
                  color: tone,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        Insets.gutter,
        Insets.s4,
        Insets.gutter,
        Insets.s8,
      ),
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        children: [
          stat(l10n.billsCount(page.count), money.format(page.total)),
          stat(
            l10n.owedToSuppliers,
            money.format(page.due),
            tone: page.due > 0 ? palette.warning : null,
          ),
        ],
      ),
    );
  }
}

class _PurchaseRowTile extends ConsumerWidget {
  const _PurchaseRowTile({required this.row, required this.onTap});

  final PurchaseRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    return ListTile(
      onTap: onTap,
      title: Row(
        children: [
          Flexible(
            child: Text(
              row.supplier ?? l10n.noSupplier,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (row.photos.isNotEmpty) ...[
            const SizedBox(width: Insets.s8),
            Icon(Icons.photo_outlined, size: 16, color: palette.muted),
          ],
        ],
      ),
      subtitle: Text(
        [
          row.refNo,
          AppDates.day(row.purchaseDate, locale: locale),
          l10n.itemsCount(row.itemCount),
        ].where((s) => s.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodySmall?.copyWith(color: palette.muted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            money.format(row.total),
            style: text.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: Insets.s4),
          if (row.due > 0)
            StatusChip(
              label: '${l10n.dueLabel} ${money.format(row.due)}',
              tone: palette.warning,
            )
          else
            PaymentStatusChip(PaymentStatus.parse(row.paymentStatus)),
        ],
      ),
    );
  }
}

/// One bill: its figures and its photos.
///
/// There is no `GET /purchases/{id}`, so the sheet is fed from the row it was
/// opened from, and a photo change refreshes the list.
class PurchaseDetailSheet extends ConsumerStatefulWidget {
  const PurchaseDetailSheet({
    required this.row,
    required this.page,
    required this.query,
    super.key,
  });

  final PurchaseRow row;
  final PurchasePage page;
  final String query;

  static Future<void> show(
    BuildContext context, {
    required PurchaseRow row,
    required PurchasePage page,
    required String query,
  }) =>
      showAppSheet<void>(
        context,
        title: row.supplier ?? row.refNo,
        subtitle: row.refNo,
        builder: (_) => PurchaseDetailSheet(row: row, page: page, query: query),
      );

  @override
  ConsumerState<PurchaseDetailSheet> createState() =>
      _PurchaseDetailSheetState();
}

class _PurchaseDetailSheetState extends ConsumerState<PurchaseDetailSheet> {
  late List<PurchasePhoto> _photos = [...widget.row.photos];
  bool _busy = false;

  Future<void> _addPhotos() async {
    final room = widget.page.maxPhotos - _photos.length;
    if (room <= 0) return;
    final files = await pickBillPhotos(context, limit: room);
    if (files.isEmpty || !mounted) return;

    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    try {
      final result = await ref
          .read(purchasesRepositoryProvider)
          .uploadPhotos(widget.row.id, files);
      ref.invalidate(purchasesProvider);
      if (!mounted) return;
      setState(() => _photos = [..._photos, ...result.photos]);
      showNote(context, l10n.photosUploaded(result.accepted));
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePhoto(PurchasePhoto photo) async {
    final l10n = AppL10n.of(context);
    final sure = await confirmSheet(
      context,
      title: l10n.deletePhoto,
      message: l10n.deletePhotoBody,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!sure || !mounted) return;
    try {
      await ref
          .read(purchasesRepositoryProvider)
          .deletePhoto(widget.row.id, photo.id);
      ref.invalidate(purchasesProvider);
      if (mounted) setState(() => _photos.remove(photo));
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final permissions = ref.watch(permissionsProvider);
    final row = widget.row;

    final mayAdd = permissions.allows(
      P.purchaseBillCreate,
      alsoRequire: widget.page.mayCreate,
    );
    final mayRemove = permissions.allows(
      P.purchaseBillUpdate,
      alsoRequire: widget.page.mayEditBill,
    );

    Widget line(String label, String value, {Color? tone, bool strong = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Insets.s4),
          child: Row(
            children: [
              Expanded(child: Text(label, style: text.bodyMedium)),
              Text(
                value,
                style: (strong ? text.titleMedium : text.bodyMedium)?.copyWith(
                  color: tone,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Insets.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            [
              AppDates.stamp(row.purchaseDate, locale: locale),
              ?row.branch,
              l10n.itemsCount(row.itemCount),
            ].join(' · '),
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: Insets.s12),
          if (row.subtotal != null)
            line(l10n.subtotal, money.format(row.subtotal)),
          if ((row.discount ?? 0) > 0)
            line(
              row.discountPercent == null
                  ? l10n.discount
                  : '${l10n.discount} (${row.discountPercent}%)',
              '−${money.format(row.discount)}',
              tone: palette.accent,
            ),
          line(l10n.grandTotal, money.format(row.total), strong: true),
          line(l10n.paidLabel, money.format(row.paid)),
          if (row.due > 0)
            line(l10n.owedToSupplier, money.format(row.due), tone: palette.warning),
          if ((row.note ?? '').isNotEmpty) ...[
            const SizedBox(height: Insets.s8),
            Text(row.note!, style: text.bodySmall),
          ],
          SectionHeader(
            l10n.billPhotos(_photos.length, widget.page.maxPhotos),
            trailing: mayAdd && _photos.length < widget.page.maxPhotos
                ? TextButton.icon(
                    onPressed: _busy ? null : _addPhotos,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(l10n.add),
                  )
                : null,
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_photos.isEmpty)
            Text(
              l10n.noBillPhotos,
              style: text.bodySmall?.copyWith(color: palette.muted),
            )
          else
            Wrap(
              spacing: Insets.s8,
              runSpacing: Insets.s8,
              children: [
                for (final photo in _photos)
                  BillPhotoThumb(
                    url: photo.url,
                    onOpen: () => showBillPhoto(context, photo.url),
                    onRemove: mayRemove ? () => _deletePhoto(photo) : null,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
