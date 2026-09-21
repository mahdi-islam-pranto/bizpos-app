import 'dart:collection';

/// The permissions `GET /me` returned, as a set.
///
/// Hiding a button in the app is only a courtesy — the server refuses anyway —
/// but it is the difference between an app that fits the person's job and one
/// full of dead ends.
class PermissionSet {
  PermissionSet(Iterable<String> permissions, {this.isSuperAdmin = false})
      : _permissions = UnmodifiableSetView(permissions.toSet());

  const PermissionSet.empty()
      : _permissions = const <String>{},
        isSuperAdmin = false;

  final Set<String> _permissions;

  /// A super admin holds everything in every store, plus the `admin.*` calls.
  final bool isSuperAdmin;

  Set<String> get all => _permissions;

  int get length => _permissions.length;

  bool has(String permission) =>
      isSuperAdmin || _permissions.contains(permission);

  bool hasAny(Iterable<String> permissions) =>
      isSuperAdmin || permissions.any(_permissions.contains);

  bool hasAll(Iterable<String> permissions) =>
      isSuperAdmin || permissions.every(_permissions.contains);

  /// Combines a permission with a list response's `may*` flag.
  ///
  /// The flag can only *remove* an affordance, never grant one — and an absent
  /// flag means the endpoint said nothing, so the permission alone decides.
  bool allows(String permission, {bool? alsoRequire}) =>
      has(permission) && (alsoRequire ?? true);

  @override
  String toString() => 'PermissionSet(${_permissions.length} permissions'
      '${isSuperAdmin ? ', super admin' : ''})';
}
