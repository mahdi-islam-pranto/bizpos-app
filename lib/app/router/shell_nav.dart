import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/permissions/permission_set.dart';
import '../../core/session/session_controller.dart';
import '../../l10n/app_localizations.dart';
import 'app_router.dart';
import 'screen_gates.dart';

/// The pages a person has walked through inside the shell, so Back goes back.
///
/// The shell navigates with `go`, which replaces the page instead of stacking
/// it, so the navigator itself has nothing to pop and the Android back button
/// used to close the app from any screen. This list is that missing stack.
///
/// The rule is Material's "start destination" one: a menu choice (bottom bar
/// or sidebar) starts the stack again from home, so Back from any top-level
/// screen lands on home; a detail opened from a screen goes on top of it.
class NavHistory {
  final List<String> _stack = [];

  /// The most a long session keeps; Back past that ends at home anyway.
  static const int _cap = 40;

  bool get canGoBack => _stack.length > 1;

  /// Called on every location change the router makes.
  void record(String location) {
    if (!_inShell(location)) {
      _stack.clear();
      return;
    }
    if (_stack.isNotEmpty && _stack.last == location) return;
    // Arriving at the page below the top is a pop (a pushed route such as
    // Devices closing), not a new visit.
    if (_stack.length > 1 && _stack[_stack.length - 2] == location) {
      _stack.removeLast();
      return;
    }
    _stack.add(location);
    if (_stack.length > _cap) _stack.removeAt(0);
  }

  /// A fresh start at [root] — for a menu choice, a store switch, a sign-in.
  void startFrom(String root) => _stack
    ..clear()
    ..add(root);

  /// Drops the current page and names the one before it, if any.
  String? popBack() {
    if (_stack.length < 2) return null;
    _stack.removeLast();
    return _stack.last;
  }

  static bool _inShell(String location) {
    final path = Uri.parse(location).path;
    return path != Routes.splash &&
        path != Routes.login &&
        path != Routes.register &&
        path != Routes.noStore;
  }
}

final navHistoryProvider = Provider<NavHistory>((ref) => NavHistory());

/// The shell's own scaffold, which owns the sidebar. Each screen has a
/// scaffold of its own nested inside, so `Scaffold.of` from a screen finds the
/// wrong one; the menu button opens the drawer through this key instead.
final GlobalKey<ScaffoldState> shellScaffoldKey = GlobalKey<ScaffoldState>();

/// How a screen sits in the navigation, which decides its app bar's leading.
enum NavPlace {
  /// The landing screen: nothing to go back to, so only the menu.
  home,

  /// A menu destination: back to home, and the menu.
  topLevel,

  /// A page opened from another one: back only.
  detail,
}

/// Navigation actions shared by the app bar, the bottom bar, the sidebar and
/// the system back button, so all four agree on where "back" is.
class ShellNav {
  const ShellNav._();

  static PermissionSet _permissions(BuildContext context) =>
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(permissionsProvider);

  static String home(BuildContext context) => homeFor(_permissions(context));

  static NavPlace placeOf(BuildContext context, String location) {
    if (location == home(context)) return NavPlace.home;
    if (location == Routes.profile ||
        location == Routes.notAllowed ||
        screenGates.any((gate) => gate.path == location)) {
      return NavPlace.topLevel;
    }
    return NavPlace.detail;
  }

  /// A menu choice: the stack starts again from home.
  static void open(BuildContext context, String path) {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(navHistoryProvider).startFrom(home(context));
    context.go(path);
  }

  /// One step back: the previous page, else the page this one belongs to,
  /// else home.
  static void back(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final location = router.state.matchedLocation;
    final previous = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(navHistoryProvider).popBack();
    router.go(previous ?? _parentOf(context, location));
  }

  /// `/invoices/12` belongs to `/invoices`, `/purchase/new` to `/purchase`;
  /// a top-level screen belongs to home.
  static String _parentOf(BuildContext context, String location) {
    final gate = gateForPath(location);
    if (gate != null && gate.path != location) return gate.path;
    return home(context);
  }

  static void openDrawer() => shellScaffoldKey.currentState?.openDrawer();
}

/// The app bar every in-shell screen uses: the same as [AppBar], with the
/// leading worked out from where the screen sits — the menu on home, back and
/// the menu on a top-level screen, back alone on a detail page.
class ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ShellAppBar({this.title, this.actions, this.bottom, super.key});

  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    // A screen pumped on its own (in a widget test) has no router to ask.
    if (GoRouter.maybeOf(context) == null) {
      return AppBar(title: title, actions: actions, bottom: bottom);
    }

    final place = ShellNav.placeOf(
      context,
      GoRouterState.of(context).matchedLocation,
    );
    final localizations = MaterialLocalizations.of(context);

    final backButton = IconButton(
      icon: const BackButtonIcon(),
      tooltip: localizations.backButtonTooltip,
      onPressed: () => ShellNav.back(context),
    );
    final menuButton = IconButton(
      icon: const Icon(Icons.menu),
      tooltip: localizations.openAppDrawerTooltip,
      onPressed: ShellNav.openDrawer,
    );

    return AppBar(
      title: title,
      actions: actions,
      bottom: bottom,
      automaticallyImplyLeading: false,
      titleSpacing: place == NavPlace.topLevel ? 0 : null,
      leadingWidth: place == NavPlace.topLevel ? 96 : null,
      leading: switch (place) {
        NavPlace.home => menuButton,
        NavPlace.topLevel => Row(children: [backButton, menuButton]),
        NavPlace.detail => backButton,
      },
    );
  }
}

/// Catches the system back button for the whole shell.
///
/// go_router asks the shell's navigator first (a sheet or a dialog on top
/// closes as usual) and then the route hosting the shell — this one — before
/// letting the app close. So Back walks [NavHistory], closes an open sidebar,
/// and on home asks for a second press before leaving.
class ShellBackHandler extends StatefulWidget {
  const ShellBackHandler({required this.child, super.key});

  final Widget child;

  @override
  State<ShellBackHandler> createState() => _ShellBackHandlerState();
}

class _ShellBackHandlerState extends State<ShellBackHandler> {
  DateTime? _lastPress;

  void _onBack() {
    final scaffold = shellScaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
      return;
    }

    final location = GoRouterState.of(context).matchedLocation;
    final history = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(navHistoryProvider);
    if (location != ShellNav.home(context) || history.canGoBack) {
      ShellNav.back(context);
      return;
    }

    // On home with nowhere further back: a till closed by one stray press is
    // a till somebody has to reopen mid-queue.
    final now = DateTime.now();
    if (_lastPress != null &&
        now.difference(_lastPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastPress = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(context).pressBackAgainToExit),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      _onBack();
    },
    child: widget.child,
  );
}
