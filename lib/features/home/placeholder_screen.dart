import 'package:flutter/material.dart';

import '../../app/router/screen_gates.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';

/// Stands in for a screen this person's role opens but that a later phase
/// builds.
///
/// It says so plainly, rather than looking broken. Phase 1 replaces Sell,
/// Invoices and Customers; the rest follow.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.gate, super.key});

  final ScreenGate gate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final label = gate.label(l10n);
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: MessageState(
        icon: gate.icon,
        title: l10n.comingSoonTitle,
        body: l10n.comingSoonBody(label),
        action: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.s12,
            vertical: Insets.s8,
          ),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            gate.anyOf.join(' · '),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: palette.accent),
          ),
        ),
      ),
    );
  }
}
