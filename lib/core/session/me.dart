import '../permissions/permission_set.dart';

/// Reads a value that the API spells one way in `/me` and another way in
/// `POST /auth/login`.
///
/// `/me` is the one response that answers in **snake_case** (`is_super_admin`,
/// `store_type_id`, `label_bn`) while the rest of the API is camelCase — see
/// `docs/MOBILE-API.md` section 2. Rather than trusting a convention that has an
/// exception, every key here is read explicitly, with the sibling spelling as a
/// fallback so the same model parses both responses.
Object? _either(Map<String, dynamic> json, String a, String b) =>
    json[a] ?? json[b];

int _int(Object? value) => switch (value) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

int? _intOrNull(Object? value) => value == null ? null : _int(value);

String _string(Object? value) => value?.toString() ?? '';

bool _bool(Object? value) => switch (value) {
      final bool v => v,
      1 => true,
      'true' => true,
      _ => false,
    };

/// The signed-in person.
class MeUser {
  const MeUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isSuperAdmin,
    this.locale,
    this.theme,
  });

  final int id;
  final String name;
  final String email;

  /// Platform staff. Holds everything in every store.
  final bool isSuperAdmin;

  /// `bn` or `en`, as saved on the account.
  final String? locale;

  /// `daylight`, `midnight`, `workspace`, `paper` or `contrast`.
  final String? theme;

  factory MeUser.fromJson(Map<String, dynamic> json) => MeUser(
        id: _int(json['id']),
        name: _string(json['name']),
        email: _string(json['email']),
        // `/me` says is_super_admin; `/auth/login` says isSuperAdmin.
        isSuperAdmin: _bool(_either(json, 'is_super_admin', 'isSuperAdmin')),
        locale: json['locale'] as String?,
        theme: json['theme'] as String?,
      );
}

/// The store this device is working in.
class MeStore {
  const MeStore({
    required this.id,
    required this.name,
    required this.slug,
    required this.currency,
    this.storeTypeId,
    this.storeTypeName,
  });

  final int id;
  final String name;
  final String slug;

  /// Usually `BDT`. Every amount in the API is a number in this currency.
  final String currency;

  final int? storeTypeId;
  final String? storeTypeName;

  factory MeStore.fromJson(Map<String, dynamic> json) => MeStore(
        id: _int(json['id']),
        name: _string(json['name']),
        slug: _string(json['slug']),
        currency: _string(json['currency']).isEmpty
            ? 'BDT'
            : _string(json['currency']),
        storeTypeId: _intOrNull(_either(json, 'store_type_id', 'storeTypeId')),
        storeTypeName:
            _either(json, 'store_type_name', 'storeTypeName') as String?,
      );
}

/// A branch. Stock, sales, shifts and most reports are per branch.
class MeBranch {
  const MeBranch({required this.id, required this.name, this.code});

  final int id;
  final String name;
  final String? code;

  factory MeBranch.fromJson(Map<String, dynamic> json) => MeBranch(
        id: _int(json['id']),
        name: _string(json['name']),
        code: json['code'] as String?,
      );
}

/// A store in the switcher.
class StoreRef {
  const StoreRef({required this.id, required this.name, this.slug});

  final int id;
  final String name;
  final String? slug;

  factory StoreRef.fromJson(Map<String, dynamic> json) => StoreRef(
        id: _int(json['id']),
        name: _string(json['name']),
        slug: json['slug'] as String?,
      );
}

/// The person's role. **Display only** — never branch on [name].
class MeRole {
  const MeRole({
    required this.id,
    required this.name,
    required this.label,
    this.labelBn,
  });

  final int id;

  /// `store_owner`, `manager`, `cashier`, ... Shown, never tested against.
  final String name;
  final String label;
  final String? labelBn;

  factory MeRole.fromJson(Map<String, dynamic> json) => MeRole(
        id: _int(json['id']),
        name: _string(json['name']),
        label: _string(json['label']),
        labelBn: _either(json, 'label_bn', 'labelBn') as String?,
      );

  /// The server already supplies both languages, so nothing is translated here.
  String labelFor(String locale) =>
      (locale == 'bn' && labelBn != null && labelBn!.isNotEmpty)
          ? labelBn!
          : label;
}

/// The whole answer to "who am I, where am I, what may I do".
class Me {
  Me({
    required this.user,
    required this.store,
    required this.branch,
    required this.stores,
    required this.branches,
    required this.role,
    required this.permissions,
    required this.impersonating,
  });

  final MeUser user;

  /// Null when the person belongs to no active store — a screen, not an error.
  final MeStore? store;
  final MeBranch? branch;

  final List<StoreRef> stores;
  final List<MeBranch> branches;
  final MeRole? role;
  final PermissionSet permissions;

  /// True while a super admin is inside someone else's store.
  final bool impersonating;

  bool get hasStore => store != null;
  bool get canSwitchStore => stores.length > 1;
  bool get canSwitchBranch => branches.length > 1;

  factory Me.fromJson(Map<String, dynamic> json) {
    final user = MeUser.fromJson(
      (json['user'] as Map<String, dynamic>?) ?? const {},
    );
    final store = json['store'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;
    final role = json['role'] as Map<String, dynamic>?;

    return Me(
      user: user,
      store: store == null ? null : MeStore.fromJson(store),
      branch: branch == null ? null : MeBranch.fromJson(branch),
      stores: _list(json['stores'], StoreRef.fromJson),
      branches: _list(json['branches'], MeBranch.fromJson),
      role: role == null ? null : MeRole.fromJson(role),
      permissions: PermissionSet(
        (json['permissions'] as List?)?.map(_string) ?? const <String>[],
        isSuperAdmin: user.isSuperAdmin,
      ),
      impersonating: _bool(json['impersonating']),
    );
  }

  Map<String, dynamic> toJson() => {
        'user': {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'is_super_admin': user.isSuperAdmin,
          'locale': user.locale,
          'theme': user.theme,
        },
        if (store != null)
          'store': {
            'id': store!.id,
            'name': store!.name,
            'slug': store!.slug,
            'currency': store!.currency,
            'store_type_id': store!.storeTypeId,
            'store_type_name': store!.storeTypeName,
          },
        if (branch != null)
          'branch': {
            'id': branch!.id,
            'name': branch!.name,
            'code': branch!.code,
          },
        'stores': [
          for (final s in stores) {'id': s.id, 'name': s.name, 'slug': s.slug},
        ],
        'branches': [
          for (final b in branches) {'id': b.id, 'name': b.name, 'code': b.code},
        ],
        if (role != null)
          'role': {
            'id': role!.id,
            'name': role!.name,
            'label': role!.label,
            'label_bn': role!.labelBn,
          },
        'permissions': permissions.all.toList(),
        'impersonating': impersonating,
      };

  static List<T> _list<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}

/// What `POST /auth/login` hands back.
class LoginResult {
  const LoginResult({
    required this.token,
    required this.user,
    this.expiresAt,
  });

  final String token;
  final MeUser user;

  /// Roughly 90 days out. One token is one device.
  final DateTime? expiresAt;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        token: _string(json['token']),
        user: MeUser.fromJson(
          (json['user'] as Map<String, dynamic>?) ?? const {},
        ),
        expiresAt: DateTime.tryParse(_string(json['expiresAt'])),
      );
}

/// A signed-in phone, from `GET /auth/devices`.
class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.name,
    required this.isCurrent,
    this.lastUsedAt,
    this.expiresAt,
  });

  final int id;
  final String name;
  final bool isCurrent;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
        id: _int(json['id']),
        name: _string(json['name']),
        isCurrent: _bool(json['current']),
        lastUsedAt: DateTime.tryParse(_string(json['lastUsedAt'])),
        expiresAt: DateTime.tryParse(_string(json['expiresAt'])),
      );
}
