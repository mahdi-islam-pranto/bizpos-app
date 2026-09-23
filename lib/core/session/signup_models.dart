/// The shapes behind a shop signing itself up and an account opening a second
/// shop — `docs/MOBILE-API-NEW.md` section 2.
library;

int _int(Object? v) => switch (v) {
      final int x => x,
      final num x => x.toInt(),
      final String x => int.tryParse(x) ?? 0,
      _ => 0,
    };

int? _intOrNull(Object? v) => v == null ? null : _int(v);

String _str(Object? v) => v?.toString() ?? '';

String? _strOrNull(Object? v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

bool _bool(Object? v) => v == true || v == 1 || v == 'true';

List<T> _listOf<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(parse).toList();
}

/// A kind of shop. It decides which shared catalogue the shop reads, so it is
/// the one choice on the form that matters on the first day.
class StoreType {
  const StoreType({required this.id, required this.name, required this.slug});

  final int id;
  final String name;
  final String slug;

  factory StoreType.fromJson(Map<String, dynamic> json) => StoreType(
        id: _int(json['id']),
        name: _str(json['name']),
        slug: _str(json['slug']),
      );
}

/// `GET /public/store-types` — what the sign-up form needs, before anyone has
/// an account to sign in with.
class SignupOptions {
  const SignupOptions({required this.storeTypes, required this.trialDays});

  final List<StoreType> storeTypes;

  /// How long a self-signed-up shop runs before an admin has to extend it.
  final int trialDays;

  factory SignupOptions.fromJson(Map<String, dynamic> json) => SignupOptions(
        storeTypes: _listOf(json['storeTypes'], StoreType.fromJson),
        trialDays: _int(json['trialDays']),
      );
}

/// What `POST /auth/register` answers: a **working** token, so the app goes
/// straight into the new shop. A sign-up that ends at a login screen is one
/// half the people abandon.
class RegisterResult {
  const RegisterResult({
    required this.token,
    required this.storeName,
    this.expiresAt,
    this.trialEndsAt,
    this.trialDaysLeft,
  });

  final String token;
  final DateTime? expiresAt;
  final String storeName;
  final DateTime? trialEndsAt;
  final int? trialDaysLeft;

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    final store = json['store'] is Map<String, dynamic>
        ? json['store'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return RegisterResult(
      token: _str(json['token']),
      expiresAt: DateTime.tryParse(_str(json['expiresAt'])),
      storeName: _str(store['name']),
      trialEndsAt: DateTime.tryParse(_str(store['trialEndsAt'])),
      trialDaysLeft: _intOrNull(store['trialDaysLeft']),
    );
  }
}

/// One shop this account may work in, from `GET /stores`.
class OwnedStore {
  const OwnedStore({
    required this.id,
    required this.name,
    required this.isOwner,
    required this.isCurrent,
    this.storeType,
    this.trialDaysLeft,
  });

  final int id;
  final String name;
  final String? storeType;
  final bool isOwner;
  final bool isCurrent;
  final int? trialDaysLeft;

  factory OwnedStore.fromJson(Map<String, dynamic> json) => OwnedStore(
        id: _int(json['id']),
        name: _str(json['name']),
        storeType: _strOrNull(json['storeType']),
        isOwner: _bool(json['isOwner']),
        isCurrent: _bool(json['isCurrent']),
        trialDaysLeft: _intOrNull(json['trialDaysLeft']),
      );
}

/// `GET /stores`. A shop the platform has closed is not in [stores];
/// [lockedName] is there so the screen can say why the list is shorter than
/// the person remembers.
class StoreList {
  const StoreList({required this.stores, this.lockedName});

  final List<OwnedStore> stores;
  final String? lockedName;
}
