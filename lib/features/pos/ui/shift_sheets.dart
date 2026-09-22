import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../l10n/app_localizations.dart';
import '../data/pos_models.dart';
import '../data/pos_repository.dart';

/// Opening the cash drawer.
///
/// A sale with no open drawer still goes through — it is simply counted in no
/// drawer — so this is an invitation, never a gate. `422 shift_open` comes back
/// if one is already open, and the server's own sentence is what gets shown.
class OpenShiftSheet extends ConsumerStatefulWidget {
  const OpenShiftSheet({super.key});

  static Future<bool> show(BuildContext context) async =>
      await showAppSheet<bool>(
        context,
        title: AppL10n.of(context).openDrawer,
        builder: (_) => const OpenShiftSheet(),
      ) ??
      false;

  @override
  ConsumerState<OpenShiftSheet> createState() => _OpenShiftSheetState();
}

class _OpenShiftSheetState extends ConsumerState<OpenShiftSheet> {
  final _cash = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final amount = AmountField.read(_cash) ?? 0;
    setState(() => _busy = true);
    try {
      await ref.read(posRepositoryProvider).openShift(amount);
      if (!mounted) return;
      // The till reads `shift` from lookups, so refetching is all the screen
      // needs to know the drawer is open.
      ref.invalidate(posLookupsProvider);
      showNote(context, AppL10n.of(context).drawerOpened);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final money = ref.watch(moneyProvider);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: AmountField(
              controller: _cash,
              label: l10n.openingCash,
              prefix: money.sign,
              autofocus: true,
              onSubmitted: (_) => _open(),
            ),
          ),
          SheetAction(
            label: l10n.openDrawer,
            icon: Icons.lock_open_outlined,
            busy: _busy,
            onPressed: _open,
          ),
        ],
      ),
    );
  }
}

/// Closing the drawer, and the count that comes back.
///
/// The interesting half is after the call: `expected`, `counted` and
/// `difference` are the server's reckoning, and a short drawer is a thing a
/// person has to be told plainly rather than shown as a negative number.
class CloseShiftSheet extends ConsumerStatefulWidget {
  const CloseShiftSheet({required this.shift, super.key});

  final PosShift shift;

  static Future<void> show(BuildContext context, PosShift shift) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).closeDrawer,
        builder: (_) => CloseShiftSheet(shift: shift),
      );

  @override
  ConsumerState<CloseShiftSheet> createState() => _CloseShiftSheetState();
}

class _CloseShiftSheetState extends ConsumerState<CloseShiftSheet> {
  final _counted = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  ShiftClosing? _result;

  @override
  void dispose() {
    _counted.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final amount = AmountField.read(_counted);
    if (amount == null) return;

    setState(() => _busy = true);
    try {
      final closing = await ref.read(posRepositoryProvider).closeShift(
            amount,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(posLookupsProvider);
      setState(() => _result = closing);
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
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final closing = _result;

    if (closing != null) {
      final difference = closing.difference;
      final (message, tone) = difference == 0
          ? (l10n.balanced, palette.positive)
          : difference < 0
              ? (l10n.shortBy(money.format(-difference)), palette.danger)
              : (l10n.overBy(money.format(difference)), palette.warning);

      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Insets.s24),
              child: Column(
                children: [
                  Text(
                    message,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: tone),
                  ),
                  const SizedBox(height: Insets.s24),
                  _Row(l10n.expectedCash, money.format(closing.expected)),
                  _Row(l10n.countedLabel, money.format(closing.counted)),
                  Divider(color: palette.hairline, height: Insets.s24),
                  _Row(
                    l10n.difference,
                    money.format(closing.difference),
                    tone: tone,
                  ),
                ],
              ),
            ),
            SheetAction(
              label: l10n.done,
              icon: Icons.check,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.openedAt(
                    AppDates.stamp(widget.shift.openedAt, locale: locale),
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.muted),
                ),
                const SizedBox(height: Insets.s4),
                _Row(l10n.openingCash, money.format(widget.shift.openingCash)),
                const SizedBox(height: Insets.s24),
                AmountField(
                  controller: _counted,
                  label: l10n.countedCash,
                  prefix: money.sign,
                  autofocus: true,
                ),
                const SizedBox(height: Insets.s16),
                TextField(
                  controller: _note,
                  decoration: InputDecoration(labelText: l10n.closingNote),
                ),
              ],
            ),
          ),
          SheetAction(
            label: l10n.closeDrawer,
            icon: Icons.lock_outline,
            busy: _busy,
            onPressed: _close,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.s4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(
            value,
            style: text.titleSmall?.copyWith(
              color: tone,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
