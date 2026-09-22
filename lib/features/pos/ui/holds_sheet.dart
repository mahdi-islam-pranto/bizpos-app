import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/pos_models.dart';
import '../data/pos_repository.dart';
import '../state/cart.dart';

/// Putting a cart aside and picking it up again.
///
/// The server stores the `cart` JSON without reading it and hands the same
/// bytes back, so the shape is entirely the app's own — which is why
/// [Cart.fromHoldJson] is forgiving: a hold made by an older build should bring
/// back the lines it can rather than failing the resume.
class HoldCartSheet extends ConsumerStatefulWidget {
  const HoldCartSheet({super.key});

  static Future<bool> show(BuildContext context) async =>
      await showAppSheet<bool>(
        context,
        title: AppL10n.of(context).holdCart,
        builder: (_) => const HoldCartSheet(),
      ) ??
      false;

  @override
  ConsumerState<HoldCartSheet> createState() => _HoldCartSheetState();
}

class _HoldCartSheetState extends ConsumerState<HoldCartSheet> {
  final _label = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _hold() async {
    final label = _label.text.trim();
    if (label.isEmpty) return;

    setState(() => _busy = true);
    final cart = ref.read(cartProvider);
    try {
      await ref.read(posRepositoryProvider).hold(
            label: label,
            cart: cart.toHoldJson(),
          );
      if (!mounted) return;
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(posLookupsProvider);
      showNote(context, AppL10n.of(context).holdSaved(label));
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

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: TextField(
              controller: _label,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.holdLabel,
                hintText: l10n.holdLabelHint,
              ),
              onSubmitted: (_) => _hold(),
            ),
          ),
          SheetAction(
            label: l10n.holdCart,
            icon: Icons.pause_circle_outline,
            busy: _busy,
            onPressed: _hold,
          ),
        ],
      ),
    );
  }
}

/// The list of held carts, with resume and discard.
class HeldCartsSheet extends ConsumerStatefulWidget {
  const HeldCartsSheet({required this.held, super.key});

  final List<HeldCart> held;

  static Future<void> show(BuildContext context, List<HeldCart> held) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).heldCarts,
        subtitle: AppL10n.of(context).resumeOverwrites,
        builder: (_) => HeldCartsSheet(held: held),
      );

  @override
  ConsumerState<HeldCartsSheet> createState() => _HeldCartsSheetState();
}

class _HeldCartsSheetState extends ConsumerState<HeldCartsSheet> {
  int? _busyId;

  Future<void> _resume(HeldCart hold) async {
    setState(() => _busyId = hold.id);
    try {
      final json = await ref.read(posRepositoryProvider).resumeHold(hold.id);
      if (!mounted) return;
      // The hold is deleted server-side by this call, so the list must refetch
      // whether or not the cart parsed.
      ref.read(cartProvider.notifier).replace(Cart.fromHoldJson(json));
      ref.invalidate(posLookupsProvider);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _discard(HeldCart hold) async {
    final l10n = AppL10n.of(context);
    final sure = await confirmSheet(
      context,
      title: l10n.discard,
      message: l10n.discardHoldConfirm(hold.label),
      confirmLabel: l10n.discard,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!sure || !mounted) return;

    setState(() => _busyId = hold.id);
    try {
      await ref.read(posRepositoryProvider).discardHold(hold.id);
      if (!mounted) return;
      ref.invalidate(posLookupsProvider);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    if (widget.held.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Insets.s32),
        child: EmptyState(
          title: l10n.noHeldCarts,
          icon: Icons.pause_circle_outline,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: Insets.gutter),
      itemCount: widget.held.length,
      itemBuilder: (context, i) {
        final hold = widget.held[i];
        final busy = _busyId == hold.id;

        return ListTile(
          leading: Icon(Icons.pause_circle_outline, color: palette.muted),
          title: Text(hold.label),
          subtitle: Text(AppDates.stamp(hold.createdAt, locale: locale)),
          trailing: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.discard,
                      icon: Icon(Icons.delete_outline, color: palette.danger),
                      onPressed: () => _discard(hold),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _resume(hold),
                      child: Text(l10n.resume),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
