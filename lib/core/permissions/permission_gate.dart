import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controller.dart';
import 'permission_set.dart';

/// Screens that reach for [PermissionGate] almost always want `ref.watch` on
/// the set too, so the two travel together rather than making every widget
/// import the session layer to ask what someone may do.
export '../session/session_controller.dart' show permissionsProvider;

/// Shows [child] only if the person holds [perm].
///
/// [alsoRequire] takes a list response's `may*` flag. The flag can only take an
/// affordance away, never grant one, and **null means the endpoint said nothing**
/// — so the permission alone decides. Passing `false` for an absent flag is the
/// bug this parameter exists to prevent.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    required this.perm,
    required this.child,
    this.alsoRequire,
    this.fallback,
    super.key,
  });

  final String perm;
  final Widget child;
  final bool? alsoRequire;

  /// Usually nothing. A locked row is sometimes kinder than a missing one.
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    return permissions.allows(perm, alsoRequire: alsoRequire)
        ? child
        : (fallback ?? const SizedBox.shrink());
  }
}

/// `ref.can(...)` for logic, where a widget wrapper would read worse.
extension PermissionChecks on WidgetRef {
  PermissionSet get permissions => read(permissionsProvider);

  bool can(String perm) => read(permissionsProvider).has(perm);

  bool canAny(List<String> perms) => read(permissionsProvider).hasAny(perms);
}
