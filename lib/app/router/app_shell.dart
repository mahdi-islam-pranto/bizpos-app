import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/session_controller.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'app_router.dart';
import 'screen_gates.dart';

/// The frame every in-session screen sits in.
///
/// The bar is built from the permission list, so each role gets its own app out
/// of one build: a cashier opens on Sell, an owner on the dashboard, an
/// accountant sees no Sell tab at all.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  /// Four tabs plus More. Five icons is the most that stays tappable one-handed.
  static const int _visibleTabs = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final permissions = ref.watch(permissionsProvider);
    final session = ref.watch(sessionControllerProvider).value;
    final available = screensFor(permissions);

    final visible = available.take(_visibleTabs).toList();
    final overflow = available.skip(_visibleTabs).toList();

    final location = GoRouterState.of(context).matchedLocation;
    final index = visible.indexWhere((gate) => gate.path == location);

    return Scaffold(
      body: Column(
        children: [
          if (session is SessionActive && session.me.impersonating)
            _Banner(
              text: l10n.supportMode,
              background: palette.warning,
              foreground: palette.surface,
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: available.isEmpty
          ? null
          : NavigationBar(
              // -1 while on More, Profile or Not-allowed: no tab is current.
              selectedIndex: index < 0 ? visible.length : index,
              onDestinationSelected: (i) {
                if (i < visible.length) {
                  context.go(visible[i].path);
                } else {
                  _showMore(context, ref, overflow);
                }
              },
              destinations: [
                for (final gate in visible)
                  NavigationDestination(
                    icon: Icon(gate.icon),
                    label: gate.label(l10n),
                  ),
                NavigationDestination(
                  icon: const Icon(Icons.more_horiz),
                  label: l10n.more,
                ),
              ],
            ),
    );
  }

  void _showMore(BuildContext context, WidgetRef ref, List<ScreenGate> rest) {
    final l10n = AppL10n.of(context);

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: Insets.s16),
          children: [
            for (final gate in rest)
              ListTile(
                leading: Icon(gate.icon),
                title: Text(gate.label(l10n)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go(gate.path);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.profile),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go(Routes.profile);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.s16,
              vertical: Insets.s8,
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: foreground),
                const SizedBox(width: Insets.s8),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
