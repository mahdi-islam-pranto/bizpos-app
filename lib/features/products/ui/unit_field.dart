import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/product_models.dart';

/// The Unit box on the product form: a dropdown of every unit
/// `GET /products/lookups` offers, common ones first.
///
/// It writes the unit's `short` into [controller], which is what `unit`
/// sends. A word that is not on the list can still be typed in the picker's
/// search box and used — the server makes an unknown unit this store's own.
class UnitField extends StatelessWidget {
  const UnitField({
    required this.controller,
    required this.label,
    required this.units,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final List<ProductUnit> units;

  Future<void> _pick(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await UnitPickerSheet.show(
      context,
      units: units,
      selected: controller.text.trim(),
    );
    if (picked != null) controller.text = picked;
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    readOnly: true,
    onTap: () => _pick(context),
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: const Icon(Icons.arrow_drop_down),
    ),
  );
}

/// Every unit, searchable, with the reader's own language beside the short
/// form the product will carry.
class UnitPickerSheet extends ConsumerStatefulWidget {
  const UnitPickerSheet({required this.units, this.selected, super.key});

  final List<ProductUnit> units;
  final String? selected;

  static Future<String?> show(
    BuildContext context, {
    required List<ProductUnit> units,
    String? selected,
  }) => showAppSheet<String>(
    context,
    title: AppL10n.of(context).chooseUnit,
    builder: (_) => UnitPickerSheet(units: units, selected: selected),
  );

  @override
  ConsumerState<UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends ConsumerState<UnitPickerSheet> {
  // Owned here so it dies with the sheet, not when the sheet's future
  // completes (see `_AmountPrompt` in the cart sheet).
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _choose(String unit) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(unit);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    final typed = _search.text.trim();
    final needle = typed.toLowerCase();
    final shown = needle.isEmpty
        ? widget.units
        : widget.units
              .where(
                (u) =>
                    u.short.toLowerCase().contains(needle) ||
                    u.label.toLowerCase().contains(needle) ||
                    (u.labelBn ?? '').contains(typed),
              )
              .toList();
    final exact = widget.units.any((u) => u.short.toLowerCase() == needle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.gutter,
            0,
            Insets.gutter,
            Insets.s8,
          ),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (shown.length == 1) {
                _choose(shown.single.short);
              } else if (typed.isNotEmpty) {
                _choose(typed);
              }
            },
            decoration: InputDecoration(
              hintText: l10n.unitSearchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: Insets.s16),
            children: [
              // A unit nobody has saved yet is still a unit.
              if (typed.isNotEmpty && !exact)
                ListTile(
                  leading: Icon(Icons.add, color: palette.accent),
                  title: Text(
                    l10n.useNewUnit(typed),
                    style: TextStyle(color: palette.accent),
                  ),
                  onTap: () => _choose(typed),
                ),
              for (final unit in shown)
                ListTile(
                  title: Text(unit.labelFor(locale)),
                  subtitle: Text(unit.short),
                  selected: unit.short == widget.selected,
                  trailing: unit.short == widget.selected
                      ? Icon(Icons.check, color: palette.accent)
                      : null,
                  onTap: () => _choose(unit.short),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
