import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../theme/tokens.dart';

/// The app's one bottom sheet.
///
/// Nearly every counter action is a sheet rather than a page: a cashier's thumb
/// is at the bottom of the phone, and a sheet keeps the cart visible behind the
/// thing being decided. Sheets are the only place this design uses elevation.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext context) builder,
  String? subtitle,
  bool isScrollControlled = true,
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: dismissible,
    enableDrag: dismissible,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
    ),
    builder: (sheetContext) => AppSheetFrame(
      title: title,
      subtitle: subtitle,
      dismissible: dismissible,
      child: builder(sheetContext),
    ),
  );
}

/// The chrome around a sheet's content: grabber, title, close, and the keyboard
/// inset so a field never hides under the on-screen keyboard.
class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({
    required this.title,
    required this.child,
    this.subtitle,
    this.dismissible = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      // The sheet grows with the keyboard rather than being covered by it.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Insets.s8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.hairline,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.gutter,
                Insets.s12,
                Insets.s8,
                Insets.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.titleMedium),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: Insets.s4),
                            child: Text(
                              subtitle!,
                              style: text.bodySmall
                                  ?.copyWith(color: palette.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (dismissible)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
            Divider(color: palette.hairline, height: 1),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// A yes/no sheet. [destructive] paints the confirm button in the danger
/// colour — used for discarding a held cart and for voiding an invoice, which
/// is the one action in the counter that cannot be taken back.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final palette = context.palette;

  final answer = await showAppSheet<bool>(
    context,
    title: title,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(Insets.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: Theme.of(sheetContext).textTheme.bodyMedium),
          const SizedBox(height: Insets.s24),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: palette.danger,
                    foregroundColor: palette.onAccent,
                  )
                : null,
            onPressed: () => Navigator.of(sheetContext).pop(true),
            child: Text(confirmLabel),
          ),
          const SizedBox(height: Insets.s8),
          TextButton(
            onPressed: () => Navigator.of(sheetContext).pop(false),
            child: Text(cancelLabel),
          ),
        ],
      ),
    ),
  );

  return answer ?? false;
}

/// The full-width button that sits at the bottom of a sheet, above the gesture
/// bar. Shows a spinner in place of its label while the call is in flight, so
/// nobody taps "Charge" twice — a retried `POST /pos/checkout` is a second sale.
class SheetAction extends StatelessWidget {
  const SheetAction({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    this.tone,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(Insets.gutter),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            style: tone == null
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: tone,
                    foregroundColor: palette.onAccent,
                  ),
            onPressed: busy ? null : onPressed,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (icon == null ? const SizedBox.shrink() : Icon(icon)),
            label: Text(label),
          ),
        ),
      ),
    );
  }
}
