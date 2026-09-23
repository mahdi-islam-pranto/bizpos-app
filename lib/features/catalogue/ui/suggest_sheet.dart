import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../l10n/app_localizations.dart';
import '../../products/data/products_repository.dart';
import '../../products/ui/pricing_fields.dart';
import '../../products/ui/product_form_sheet.dart' show SuggestingField;
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import 'adopt_sheet.dart';

/// `POST /catalog/suggestions` — a product the catalogue does not have yet.
///
/// While the name is typed, `GET /catalog/check` says whether it is really
/// new: `exists` means adopt that one instead, `variant` / `other_brand` /
/// `similar` are worth a look, `new` is new. An exact duplicate still answers
/// `409 already_in_catalog`, and the person may send it anyway — the resend
/// carries `confirmedNew: true`.
///
/// Someone who may also review suggestions endorses their own on the spot, so
/// the product is on sale at once; anyone else's waits in the owner's queue.
class SuggestSheet extends ConsumerStatefulWidget {
  const SuggestSheet({this.initialName, super.key});

  final String? initialName;

  static Future<void> show(BuildContext context, {String? initialName}) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).suggestProduct,
        builder: (_) => SuggestSheet(initialName: initialName),
      );

  @override
  ConsumerState<SuggestSheet> createState() => _SuggestSheetState();
}

class _SuggestSheetState extends ConsumerState<SuggestSheet> {
  late final _name = TextEditingController(text: widget.initialName ?? '');
  final _generic = TextEditingController();
  final _brand = TextEditingController();
  final _unit = TextEditingController(text: 'pc');
  final _barcode = TextEditingController();
  final _mrp = TextEditingController();
  final _opening = TextEditingController(text: '1');
  final _reason = TextEditingController();
  final _pricing = PricingDraft();

  Timer? _debounce;
  CatalogCheck? _check;
  bool _checking = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initialName ?? '').trim().length >= 3) _scheduleCheck();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      _name,
      _generic,
      _brand,
      _unit,
      _barcode,
      _mrp,
      _opening,
      _reason,
    ]) {
      c.dispose();
    }
    _pricing.dispose();
    super.dispose();
  }

  String? _text(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  void _scheduleCheck() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _runCheck);
  }

  Future<void> _runCheck() async {
    final name = _name.text.trim();
    if (name.length < 3) {
      if (mounted) setState(() => _check = null);
      return;
    }
    setState(() => _checking = true);
    try {
      final check = await ref.read(catalogRepositoryProvider).check(
            name: name,
            brand: _text(_brand),
            barcode: _text(_barcode),
          );
      // Only the answer to what is in the box now is worth showing.
      if (mounted && _name.text.trim() == name) setState(() => _check = check);
    } catch (_) {
      // The check is advice. Sending still works without it.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  bool get _canSend => _name.text.trim().isNotEmpty && _pricing.isComplete;

  SuggestionDraft get _draft => SuggestionDraft(
        name: _name.text.trim(),
        purchasePrice: _pricing.purchaseValue!,
        salePrice: _pricing.saleValue!,
        genericName: _text(_generic),
        brand: _text(_brand),
        barcode: _text(_barcode),
        unit: _text(_unit),
        profitPercent: _pricing.profitValue,
        mrp: AmountField.read(_mrp),
        openingStock: AmountField.read(_opening) ?? 1,
        reason: _text(_reason),
      );

  Future<void> _send({bool confirmedNew = false}) async {
    if (_busy || !_canSend) return;
    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    final repository = ref.read(catalogRepositoryProvider);
    try {
      final result = await repository.suggest(
        _draft,
        confirmedNew: confirmedNew,
      );
      ref.invalidate(catalogListProvider);
      ref.invalidate(suggestionQueueProvider);
      if (result.endorsed) {
        ref.invalidate(productsListProvider);
        ref.invalidate(productStatsProvider);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(
        context,
        result.endorsed ? l10n.suggestionEndorsed : l10n.suggestionSent,
      );
    } on ConflictException catch (e) {
      // An exact duplicate. Say which, and let the person decide.
      if (!mounted) return;
      setState(() => _busy = false);
      final matchName = e.match?['name']?.toString();
      final ahead = await confirmSheet(
        context,
        title: l10n.alreadyInCatalogue,
        message: matchName == null
            ? e.message
            : l10n.alreadyInCatalogueBody(matchName),
        confirmLabel: l10n.sendAnyway,
        cancelLabel: l10n.cancel,
      );
      if (ahead && mounted) await _send(confirmedNew: true);
      return;
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _adoptInstead(CatalogMatch match) {
    // This sheet's context goes with it; the navigator's own stays.
    final navigator = Navigator.of(context);
    navigator.pop();
    AdoptSheet.show(navigator.context, CatalogEntry.fromMatch(match));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final money = ref.watch(moneyProvider);
    final lookups = ref.watch(catalogLookupsProvider).value;

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
                autofocus: (widget.initialName ?? '').isEmpty,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.productNameLabel,
                  helperText: l10n.suggestNameHelp,
                  suffixIcon: _checking
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: (_) {
                  setState(() {});
                  _scheduleCheck();
                },
              ),
              if (_check != null) ...[
                const SizedBox(height: Insets.s12),
                _CheckPanel(
                  check: _check!,
                  onAdopt: ref
                          .watch(permissionsProvider)
                          .has(P.catalogProductImport)
                      ? _adoptInstead
                      : null,
                ),
              ],
              const SizedBox(height: Insets.s16),
              TextField(
                controller: _generic,
                decoration: InputDecoration(labelText: l10n.genericNameLabel),
              ),
              const SizedBox(height: Insets.s16),
              Row(
                children: [
                  Expanded(
                    child: SuggestingField(
                      controller: _brand,
                      label: l10n.brandLabel,
                      options: lookups?.brands ?? const [],
                    ),
                  ),
                  const SizedBox(width: Insets.s12),
                  SizedBox(
                    width: 112,
                    child: SuggestingField(
                      controller: _unit,
                      label: l10n.unitLabel,
                      options: [
                        for (final unit in lookups?.units ?? const [])
                          unit.short,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.s16),
              TextField(
                controller: _barcode,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.barcodeLabel),
              ),
              const SizedBox(height: Insets.s24),
              PricingFields(
                draft: _pricing,
                money: money,
                mrp: AmountField.read(_mrp),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: Insets.s16),
              Row(
                children: [
                  Expanded(
                    child: AmountField(
                      controller: _mrp,
                      label: l10n.mrpLabel,
                      prefix: money.sign,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: Insets.s12),
                  Expanded(
                    child: AmountField(
                      controller: _opening,
                      label: l10n.openingStockLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.s16),
              TextField(
                controller: _reason,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.suggestReason,
                  helperText: l10n.suggestReasonHelp,
                ),
              ),
            ],
          ),
        ),
        SheetAction(
          label: l10n.sendSuggestion,
          icon: Icons.send_outlined,
          busy: _busy,
          onPressed: _canSend ? () => _send() : null,
        ),
      ],
    );
  }
}

/// The verdict of `/catalog/check`, with the matches that earned it.
class _CheckPanel extends ConsumerWidget {
  const _CheckPanel({required this.check, this.onAdopt});

  final CatalogCheck check;
  final void Function(CatalogMatch)? onAdopt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    final (message, tone, icon) = switch (check.verdict) {
      CheckVerdict.exists => (
          l10n.verdictExists,
          palette.danger,
          Icons.content_copy_outlined,
        ),
      CheckVerdict.variant => (
          l10n.verdictVariant,
          palette.warning,
          Icons.tune,
        ),
      CheckVerdict.otherBrand => (
          l10n.verdictOtherBrand,
          palette.warning,
          Icons.business_outlined,
        ),
      CheckVerdict.similar => (
          l10n.verdictSimilar,
          palette.warning,
          Icons.search,
        ),
      CheckVerdict.isNew => (
          l10n.verdictNew,
          palette.positive,
          Icons.check_circle_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tone),
              const SizedBox(width: Insets.s8),
              Expanded(child: Text(message, style: text.bodySmall)),
            ],
          ),
          if (check.alreadyInStore != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.s4),
              child: Text(
                l10n.alreadyInStoreNote,
                style: text.labelSmall?.copyWith(color: palette.danger),
              ),
            ),
          for (final match in check.matches.take(3)) ...[
            const SizedBox(height: Insets.s8),
            Text(match.name, style: text.bodyMedium),
            if (match.reasonFor(locale) != null)
              Text(
                match.reasonFor(locale)!,
                style: text.labelSmall?.copyWith(color: palette.muted),
              ),
            if (onAdopt != null && check.alreadyInStore == null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => onAdopt!(match),
                  child: Text(l10n.adoptThisInstead),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
