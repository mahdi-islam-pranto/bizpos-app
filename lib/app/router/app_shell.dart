import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/me.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'app_router.dart';
import 'screen_gates.dart';
import 'shell_nav.dart';

/// The frame every in-session screen sits in.
///
/// The bar and the sidebar are built from the permission list, so each role
/// gets its own app out of one build: a cashier opens on Sell, an accountant
/// sees no Sell tab at all.
///
/// The bottom bar holds the first four screens plus Products; the sidebar
/// lists every screen this person may open, so the rest live there.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  /// Five icons is the most that stays tappable one-handed.
  static const int maxTabs = 5;

  /// The first four screens in gate order, then Products when this person may
  /// see it and it is not already among them — else the fifth screen.
  static List<ScreenGate> tabsFor(List<ScreenGate> available) {
    final tabs = available.take(maxTabs - 1).toList();
    final products = available.where(
      (gate) => gate.screen == AppScreen.products,
    );
    if (products.isNotEmpty && !tabs.contains(products.first)) {
      tabs.add(products.first);
    } else if (available.length >= maxTabs) {
      tabs.add(available[maxTabs - 1]);
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final permissions = ref.watch(permissionsProvider);
    final session = ref.watch(sessionControllerProvider).value;
    final available = screensFor(permissions);
    final tabs = tabsFor(available);

    // A detail page lights its parent's tab: /invoices/12 is still Invoices.
    final location = GoRouterState.of(context).matchedLocation;
    final current = gateForPath(location);
    final index = current == null ? -1 : tabs.indexOf(current);

    return ShellBackHandler(
      child: Scaffold(
        key: shellScaffoldKey,
        drawer: _AppDrawer(available: available, location: location),
        body: Column(
          children: [
            if (session is SessionActive && session.me.impersonating)
              _Banner(
                text: l10n.supportMode,
                background: palette.warning,
                foreground: palette.surface,
              ),
            // A self-signed-up shop stops at the end of its trial, and sign-in
            // is refused from then on. Saying so on the last day is the
            // difference between a phone call to the platform and a locked
            // door at opening.
            if (session is SessionActive &&
                (session.me.store?.trialEndingSoon ?? false))
              _Banner(
                text: session.me.store!.trialDaysLeft! <= 0
                    ? l10n.trialEndsToday
                    : l10n.trialDaysLeft(session.me.store!.trialDaysLeft!),
                icon: Icons.hourglass_bottom,
                background: palette.danger,
                foreground: palette.surface,
              ),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: tabs.length < 2
            ? null
            : _TabBar(tabs: tabs, index: index),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tabs, required this.index});

  final List<ScreenGate> tabs;

  /// -1 on a sidebar screen, Profile or Not-allowed: no tab is current.
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final bar = NavigationBar(
      // The bar insists on a selection. With none current it is drawn all
      // unselected by the theme below rather than lighting the wrong tab.
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (i) => ShellNav.open(context, tabs[i].path),
      destinations: [
        for (final gate in tabs)
          NavigationDestination(icon: Icon(gate.icon), label: gate.label(l10n)),
      ],
    );
    if (index >= 0) return bar;

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return NavigationBarTheme(
      data: NavigationBarTheme.of(context).copyWith(
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: muted)),
        labelTextStyle: WidgetStatePropertyAll(
          (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
            color: muted,
          ),
        ),
      ),
      child: bar,
    );
  }
}

/// The sidebar: who and where on top, then every screen this person may open,
/// then their own account.
class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.available, required this.location});

  final List<ScreenGate> available;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final session = ref.watch(sessionControllerProvider).value;
    final me = session is SessionActive ? session.me : null;
    final current = gateForPath(location);

    void go(String path) {
      Navigator.of(context).pop();
      ShellNav.open(context, path);
    }

    return Drawer(
      backgroundColor: palette.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (me != null) _DrawerHeader(me: me),
          _SectionLabel(l10n.menu),
          for (final gate in available)
            _DrawerItem(
              icon: gate.icon,
              label: gate.label(l10n),
              selected: gate == current,
              onTap: () => go(gate.path),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Insets.s24,
              vertical: Insets.s8,
            ),
            child: Divider(height: 1),
          ),
          _SectionLabel(l10n.account),
          _DrawerItem(
            icon: Icons.person_outline,
            label: l10n.profile,
            selected: location == Routes.profile,
            onTap: () => go(Routes.profile),
          ),
          _DrawerItem(
            icon: Icons.logout,
            label: l10n.signOut,
            tone: palette.danger,
            onTap: () {
              Navigator.of(context).pop();
              ref.read(sessionControllerProvider.notifier).signOut();
            },
          ),
          SizedBox(height: Insets.s16 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.me});

  final Me me;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final name = me.user.name.trim();
    final role = me.user.isSuperAdmin
        ? 'Super admin'
        : me.role?.labelFor(locale);
    final where = [
      if (me.store != null) me.store!.name,
      if (me.branch != null) me.branch!.name,
    ].join(' · ');
    final soft = palette.onAccent.withValues(alpha: 0.18);

    return Container(
      color: palette.accent,
      padding: EdgeInsets.fromLTRB(
        Insets.s24,
        MediaQuery.paddingOf(context).top + Insets.s24,
        Insets.s24,
        Insets.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: soft,
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: text.titleLarge?.copyWith(color: palette.onAccent),
            ),
          ),
          const SizedBox(height: Insets.s12),
          Text(
            name,
            style: text.titleMedium?.copyWith(color: palette.onAccent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (where.isNotEmpty) ...[
            const SizedBox(height: Insets.s4),
            Text(
              where,
              style: text.bodySmall?.copyWith(
                color: palette.onAccent.withValues(alpha: 0.85),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (role != null && role.isNotEmpty) ...[
            const SizedBox(height: Insets.s8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.s8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                role,
                style: text.labelSmall?.copyWith(color: palette.onAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Insets.s24,
      Insets.s16,
      Insets.s24,
      Insets.s8,
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: context.palette.muted),
    ),
  );
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.tone,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = tone ?? (selected ? palette.accent : palette.text);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.s12, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: palette.accentSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.background,
    required this.foreground,
    this.icon = Icons.shield_outlined,
  });

  final String text;
  final IconData icon;
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
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: Insets.s8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
