import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../data/package_models.dart';
import '../data/packages_repository.dart';
import 'package_form_sheet.dart';

/// Bundles: several products sold at one price.
///
/// Viewing is `inventory.package.view` (a cashier has it, to know what the
/// till can sell); every change is `inventory.package.manage` **and** the
/// list's own `meta.mayManage`.
class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final page = ref.watch(packagesProvider(_query));
    final mayManage = ref.watch(permissionsProvider).allows(
          P.inventoryPackageManage,
          alsoRequire: page.value?.mayManage,
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.packagesTitle)),
      floatingActionButton: mayManage
          ? FloatingActionButton.extended(
              onPressed: () => PackageFormSheet.show(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.newPackage),
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
              hint: l10n.packagesSearchHint,
              onChanged: _onChanged,
              onSubmitted: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: AsyncView<PackagePage>(
              value: page,
              onRetry: () => ref.invalidate(packagesProvider(_query)),
              builder: (context, data) {
                if (data.packages.isEmpty) {
                  return EmptyState(
                    icon: Icons.widgets_outlined,
                    title: _query.isEmpty
                        ? l10n.packagesEmpty
                        : l10n.productsNoResults,
                    body: _query.isEmpty && mayManage
                        ? l10n.packagesEmptyBody
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(packagesProvider(_query)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Insets.gutter,
                      Insets.s8,
                      Insets.gutter,
                      96,
                    ),
                    itemCount: data.packages.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Insets.s12),
                    itemBuilder: (context, i) => _PackageCard(
                      package: data.packages[i],
                      mayManage: mayManage,
                    ),
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

class _PackageCard extends ConsumerStatefulWidget {
  const _PackageCard({required this.package, required this.mayManage});

  final Package package;
  final bool mayManage;

  @override
  ConsumerState<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends ConsumerState<_PackageCard> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    try {
      final now = await ref
          .read(packagesRepositoryProvider)
          .setActive(widget.package.id, value);
      ref.invalidate(packagesProvider);
      if (!mounted) return;
      // Switched on is not the same as on sale: say which it became.
      showNote(context, availabilityLabel(l10n, now));
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppL10n.of(context);
    final sure = await confirmSheet(
      context,
      title: l10n.deletePackage,
      message: l10n.deletePackageBody(widget.package.name),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!sure || !mounted) return;
    try {
      await ref.read(packagesRepositoryProvider).delete(widget.package.id);
      ref.invalidate(packagesProvider);
      if (mounted) showNote(context, l10n.packageDeleted);
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
    final package = widget.package;

    final window = [
      if (package.startsAt != null)
        l10n.fromDate(AppDates.day(package.startsAt, locale: locale)),
      if (package.endsAt != null)
        l10n.untilDate(AppDates.day(package.endsAt, locale: locale)),
    ].join(' · ');

    return AppCard(
      children: [
        InkWell(
          onTap: widget.mayManage
              ? () => PackageFormSheet.show(context, package: package)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(Insets.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(package.name, style: text.titleMedium),
                    ),
                    Text(
                      money.format(package.price),
                      style: text.titleMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.s8),
                Wrap(
                  spacing: Insets.s8,
                  runSpacing: Insets.s4,
                  children: [
                    AvailabilityChip(package.availability),
                    if ((package.saving ?? 0) > 0)
                      StatusChip(
                        label: l10n.packageSaves(money.format(package.saving)),
                        tone: palette.positive,
                      ),
                    if (package.buildable != null)
                      StatusChip(
                        label: l10n.packageBuildable(
                          package.buildable!.toStringAsFixed(0),
                        ),
                        tone: package.buildable! <= 0
                            ? palette.danger
                            : palette.muted,
                      ),
                  ],
                ),
                const SizedBox(height: Insets.s8),
                Text(
                  [
                    for (final item in package.items)
                      '${_qty(item.qty)} × ${item.name}',
                  ].join('\n'),
                  style: text.bodySmall?.copyWith(color: palette.muted),
                ),
                if (window.isNotEmpty) ...[
                  const SizedBox(height: Insets.s4),
                  Text(
                    window,
                    style: text.labelSmall?.copyWith(color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.mayManage) ...[
          Divider(height: 1, color: palette.hairline),
          Row(
            children: [
              Expanded(
                child: SwitchListTile.adaptive(
                  dense: true,
                  value: package.isActive,
                  onChanged: _busy ? null : _toggle,
                  title: Text(l10n.packageOnSale),
                ),
              ),
              IconButton(
                tooltip: l10n.deletePackage,
                icon: Icon(Icons.delete_outline, color: palette.danger),
                onPressed: _delete,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String _qty(num value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

String availabilityLabel(AppL10n l10n, PackageAvailability value) =>
    switch (value) {
      PackageAvailability.live => l10n.availabilityLive,
      PackageAvailability.scheduled => l10n.availabilityScheduled,
      PackageAvailability.expired => l10n.availabilityExpired,
      PackageAvailability.inactive => l10n.availabilityInactive,
    };

class AvailabilityChip extends StatelessWidget {
  const AvailabilityChip(this.value, {super.key});

  final PackageAvailability value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = switch (value) {
      PackageAvailability.live => palette.positive,
      PackageAvailability.scheduled => palette.accent,
      PackageAvailability.expired => palette.warning,
      PackageAvailability.inactive => palette.muted,
    };
    return StatusChip(label: availabilityLabel(AppL10n.of(context), value), tone: tone);
  }
}
