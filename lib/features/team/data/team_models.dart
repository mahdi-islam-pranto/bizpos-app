import '../../../core/format/dates.dart';
import '../../../core/network/envelope.dart';

int _int(Object? v) => switch (v) {
  final int x => x,
  final num x => x.toInt(),
  final String x => int.tryParse(x) ?? 0,
  _ => 0,
};

int? _intOrNull(Object? v) => v == null ? null : _int(v);

num _num(Object? v) => switch (v) {
  final num x => x,
  final String x => num.tryParse(x) ?? 0,
  _ => 0,
};

String _str(Object? v) => v?.toString() ?? '';

String? _strOrNull(Object? v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

bool _bool(Object? v) => v == true || v == 1 || v == 'true' || v == '1';

List<T> _listOf<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(parse).toList();
}

Map<String, dynamic> _map(Object? v) =>
    v is Map<String, dynamic> ? v : const {};

/// The first of [keys] that [json] has a value for. `GET /settings` is the web
/// workspace's own payload, and its `settings{}` keys are not promised to be
/// camelCase the way the mobile endpoints are.
Object? _either(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}

/// A member's row in this store — `storeUserId` in the API.
///
/// **Suspending takes this; changing a role takes the user's own id.** The two
/// sit side by side on every member row, and passing one for the other
/// suspends or re-roles somebody else. Separate types make that a compile
/// error rather than a support call.
extension type const StoreUserId(int value) {}

/// A person's account id — the user `id` in the API. See [StoreUserId].
extension type const UserId(int value) {}

class TeamMember {
  const TeamMember({
    required this.storeUserId,
    required this.userId,
    required this.name,
    required this.status,
    this.email,
    this.phone,
    this.roleName,
    this.lastLoginAt,
  });

  final StoreUserId storeUserId;
  final UserId userId;
  final String name;

  /// `active` or `suspended`.
  final String status;
  final String? email;
  final String? phone;
  final String? roleName;
  final DateTime? lastLoginAt;

  bool get isActive => status != 'suspended';

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    storeUserId: StoreUserId(_int(json['storeUserId'])),
    userId: UserId(_int(json['id'])),
    name: _str(json['name']),
    status: _strOrNull(json['status']) ?? 'active',
    email: _strOrNull(json['email']),
    phone: _strOrNull(json['phone']),
    roleName: _strOrNull(json['roleName']),
    lastLoginAt: AppDates.parse(json['lastLoginAt']),
  );
}

class TeamRole {
  const TeamRole({
    required this.id,
    required this.name,
    required this.label,
    this.labelBn,
    this.isLocked = false,
  });

  final int id;

  /// The key: `manager`, `cashier`, ...
  final String name;
  final String label;
  final String? labelBn;
  final bool isLocked;

  String labelFor(String locale) =>
      locale == 'bn' && labelBn != null ? labelBn! : label;

  /// Whether a member's `roleName` names this role. The member row carries the
  /// role by name only, and the server has sent both the key and the label.
  bool matches(String? roleName) {
    if (roleName == null) return false;
    final r = roleName.toLowerCase();
    return r == name.toLowerCase() ||
        r == label.toLowerCase() ||
        r == labelBn?.toLowerCase();
  }

  factory TeamRole.fromJson(Map<String, dynamic> json) {
    final name = _str(json['name']);
    return TeamRole(
      id: _int(json['id']),
      name: name,
      label: _strOrNull(json['label']) ?? name,
      labelBn: _strOrNull(json['label_bn'] ?? json['labelBn']),
      isLocked: _bool(json['isLocked'] ?? json['is_locked']),
    );
  }
}

/// `GET /settings/roles/{id}`: what a role may do.
class RoleDetail {
  const RoleDetail({
    required this.id,
    required this.name,
    required this.label,
    required this.permissions,
    this.isLocked = false,
  });

  final int id;
  final String name;
  final String label;
  final bool isLocked;
  final List<String> permissions;

  /// `pos.sale.create` → `pos`. The matrix in section 3 of the doc groups the
  /// same way.
  Map<String, List<String>> get byModule {
    final groups = <String, List<String>>{};
    for (final p in permissions) {
      final module = p.contains('.') ? p.substring(0, p.indexOf('.')) : p;
      groups.putIfAbsent(module, () => []).add(p);
    }
    return groups;
  }

  factory RoleDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['permissions'];
    return RoleDetail(
      id: _int(json['id']),
      name: _str(json['name']),
      label: _strOrNull(json['label']) ?? _str(json['name']),
      isLocked: _bool(json['isLocked']),
      permissions: [
        if (raw is List)
          for (final p in raw)
            // A plain key, or `{name: key}` from an older build.
            if (p is String)
              p
            else if (p is Map && p['name'] != null)
              p['name'].toString(),
      ],
    );
  }
}

class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.code,
    this.phone,
    this.address,
    this.isDefault = false,
  });

  final int id;
  final String name;
  final String code;
  final String? phone;
  final String? address;
  final bool isDefault;

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
    id: _int(json['id']),
    name: _str(json['name']),
    code: _str(json['code']),
    phone: _strOrNull(json['phone']),
    address: _strOrNull(json['address']),
    isDefault: _bool(_either(json, const ['isDefault', 'is_default'])),
  );
}

/// The loyalty programme. Snake_case keys both ways, as in `/pos/lookups`.
class LoyaltySettings {
  const LoyaltySettings({
    this.enabled = false,
    this.earnPer = 100,
    this.earnPoints = 1,
    this.valuePer = 1,
    this.minRedeem = 0,
    this.maxRedeemPct = 100,
    this.round = 'down',
  });

  final bool enabled;

  /// Spend this much…
  final num earnPer;

  /// …to earn this many points.
  final num earnPoints;

  /// What one point is worth in money.
  final num valuePer;
  final num minRedeem;
  final num maxRedeemPct;

  /// How a fractional point is settled: `down`, `nearest` or `up`.
  final String round;

  factory LoyaltySettings.fromJson(Map<String, dynamic> json) =>
      LoyaltySettings(
        enabled: _bool(json['loyalty_enabled']),
        earnPer: _num(json['loyalty_earn_per'] ?? 100),
        earnPoints: _num(json['loyalty_earn_points'] ?? 1),
        valuePer: _num(json['loyalty_value_per'] ?? 1),
        minRedeem: _num(json['loyalty_min_redeem']),
        maxRedeemPct: _num(json['loyalty_max_redeem_pct'] ?? 100),
        round: _strOrNull(json['loyalty_round']) ?? 'down',
      );

  Map<String, dynamic> toJson() => {
    'loyalty_enabled': enabled,
    'loyalty_earn_per': earnPer,
    'loyalty_earn_points': earnPoints,
    'loyalty_value_per': valuePer,
    'loyalty_min_redeem': minRedeem,
    'loyalty_max_redeem_pct': maxRedeemPct,
    'loyalty_round': round,
  };
}

/// The shop's own details and the few switches the till obeys.
class StoreProfile {
  const StoreProfile({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.currency,
    this.vatMode = 'exclusive',
    this.receiptPaper = '80mm',
    this.invoicePrefix,
    this.allowCreditSale = true,
  });

  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? currency;

  /// `inclusive` or `exclusive`.
  final String vatMode;

  /// `58mm`, `80mm` or `A4` — what the receipt printer is.
  final String receiptPaper;
  final String? invoicePrefix;
  final bool allowCreditSale;

  /// [store] is the store row, [settings] the key/value `settings{}` beside
  /// it. A detail may live in either, so each is read from both.
  factory StoreProfile.fromJson(
    Map<String, dynamic> store,
    Map<String, dynamic> settings,
  ) {
    Object? pick(List<String> keys) =>
        _either(store, keys) ?? _either(settings, keys);
    final credit = pick(const [
      'allowCreditSale',
      'allow_credit_sale',
      'allowCredit',
    ]);
    final vat = _strOrNull(pick(const ['vatMode', 'vat_mode']));
    return StoreProfile(
      name: _str(store['name']),
      phone: _strOrNull(pick(const ['phone'])),
      email: _strOrNull(pick(const ['email'])),
      address: _strOrNull(pick(const ['address'])),
      city: _strOrNull(pick(const ['city'])),
      currency: _strOrNull(pick(const ['currency'])),
      vatMode:
          vat ??
          (_bool(pick(const ['vatInclusive', 'vat_inclusive']))
              ? 'inclusive'
              : 'exclusive'),
      receiptPaper:
          _strOrNull(pick(const ['receiptPaper', 'receipt_paper'])) ?? '80mm',
      invoicePrefix: _strOrNull(
        pick(const ['invoicePrefix', 'invoice_prefix']),
      ),
      // Absent means the server's default, which allows it.
      allowCreditSale: credit == null || _bool(credit),
    );
  }
}

/// One line of "who changed what".
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.event,
    this.subjectType,
    this.subjectId,
    this.subjectLabel,
    this.changes = const [],
    this.createdAt,
    this.userName,
    this.ip,
  });

  final int id;

  /// `created`, `updated`, `deleted`, ...
  final String event;
  final String? subjectType;
  final int? subjectId;
  final String? subjectLabel;
  final List<ActivityChange> changes;
  final DateTime? createdAt;
  final String? userName;
  final String? ip;

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return ActivityEntry(
      id: _int(json['id']),
      event: _str(json['event']),
      subjectType: _strOrNull(json['subjectType']),
      subjectId: _intOrNull(json['subjectId']),
      subjectLabel: _strOrNull(json['subjectLabel']),
      changes: _listOf(json['changes'], ActivityChange.fromJson),
      createdAt: AppDates.parse(json['createdAt']),
      // A name, or `{id, name}`.
      userName: user is Map ? _strOrNull(user['name']) : _strOrNull(user),
      ip: _strOrNull(json['ip']),
    );
  }
}

class ActivityChange {
  const ActivityChange({required this.field, this.from, this.to});

  final String field;
  final String? from;
  final String? to;

  factory ActivityChange.fromJson(Map<String, dynamic> json) => ActivityChange(
    field: _str(json['field']),
    from: _strOrNull(json['from']),
    to: _strOrNull(json['to']),
  );
}

/// `GET /settings/activity`: up to 200 rows and the filters the server offers.
class ActivityLog {
  const ActivityLog({
    required this.entries,
    this.subjects = const [],
    this.events = const [],
    this.days = 30,
  });

  final List<ActivityEntry> entries;

  /// What `subject=` accepts — `StoreProduct`, `Sale`, ...
  final List<String> subjects;
  final List<String> events;
  final int days;

  factory ActivityLog.from(List<ActivityEntry> entries, Meta meta) {
    List<String> names(Object? raw) => [
      if (raw is List)
        for (final v in raw)
          // A plain name, or `{value, label}` for a select box.
          if (v is Map) _str(v['value'] ?? v['name'] ?? v['key']) else _str(v),
    ].where((s) => s.isNotEmpty).toList();
    return ActivityLog(
      entries: entries,
      subjects: names(meta.raw['subjects']),
      events: names(meta.raw['events']),
      days: meta.intValue('days') ?? 30,
    );
  }
}

/// What the activity log is asked for. A value type, so the provider keyed on
/// it refetches when — and only when — a filter actually changes.
class ActivityQuery {
  const ActivityQuery({this.days = 7, this.subject, this.q});

  final int days;
  final String? subject;
  final String? q;

  ActivityQuery copyWith({
    int? days,
    String? subject,
    String? q,
    bool clearSubject = false,
  }) => ActivityQuery(
    days: days ?? this.days,
    subject: clearSubject ? null : (subject ?? this.subject),
    q: q ?? this.q,
  );

  Map<String, dynamic> toQuery() => {
    'days': days,
    if (subject != null) 'subject': subject,
    if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is ActivityQuery &&
      other.days == days &&
      other.subject == subject &&
      other.q == q;

  @override
  int get hashCode => Object.hash(days, subject, q);
}

/// Everything `GET /settings` returns, and what it says this person may do.
class SettingsOverview {
  const SettingsOverview({
    required this.store,
    required this.branches,
    required this.members,
    required this.roles,
    required this.loyalty,
    this.activity = const [],
    this.mayUpdateStore,
    this.mayManageBranch,
    this.mayManageUser,
    this.mayManageRole,
    this.maySeeActivity,
  });

  final StoreProfile store;
  final List<Branch> branches;
  final List<TeamMember> members;
  final List<TeamRole> roles;
  final LoyaltySettings loyalty;

  /// Empty without `settings.activity.view` — not "nothing happened".
  final List<ActivityEntry> activity;

  // Tri-state, read as `permission && (flag ?? true)`.
  final bool? mayUpdateStore;
  final bool? mayManageBranch;
  final bool? mayManageUser;
  final bool? mayManageRole;
  final bool? maySeeActivity;

  TeamRole? roleOf(TeamMember member) {
    for (final role in roles) {
      if (role.matches(member.roleName)) return role;
    }
    return null;
  }

  factory SettingsOverview.fromJson(Map<String, dynamic> json, Meta meta) {
    final settings = _map(json['settings']);
    // Loyalty arrives on its own, or folded into `settings{}`.
    final loyalty = json['loyalty'] is Map<String, dynamic>
        ? json['loyalty'] as Map<String, dynamic>
        : settings;
    return SettingsOverview(
      store: StoreProfile.fromJson(_map(json['store']), settings),
      branches: _listOf(json['branches'], Branch.fromJson),
      members: _listOf(json['members'], TeamMember.fromJson),
      roles: _listOf(json['roles'], TeamRole.fromJson),
      loyalty: LoyaltySettings.fromJson(loyalty),
      activity: _listOf(json['activity'], ActivityEntry.fromJson),
      mayUpdateStore: meta.flag('mayUpdateStore'),
      mayManageBranch: meta.flag('mayManageBranch'),
      mayManageUser: meta.flag('mayManageUser'),
      mayManageRole: meta.flag('mayManageRole'),
      maySeeActivity: meta.flag('maySeeActivity'),
    );
  }
}

/// `PATCH /settings/store`. `name` is required on every call, so a loyalty
/// change sends the shop's name along with it.
class StoreDraft {
  const StoreDraft({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.vatMode,
    this.receiptPaper,
    this.invoicePrefix,
    this.allowCreditSale,
    this.loyalty,
  });

  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? vatMode;
  final String? receiptPaper;
  final String? invoicePrefix;
  final bool? allowCreditSale;
  final LoyaltySettings? loyalty;

  /// Only the loyalty block, with the name the endpoint insists on.
  factory StoreDraft.loyaltyOnly(String name, LoyaltySettings loyalty) =>
      StoreDraft(name: name, loyalty: loyalty);

  Map<String, dynamic> toBody() {
    String? t(String? v) => v?.trim();
    return {
      'name': name.trim(),
      'phone': ?t(phone),
      'email': ?t(email),
      'address': ?t(address),
      'city': ?t(city),
      'vatMode': ?vatMode,
      'receiptPaper': ?receiptPaper,
      'invoicePrefix': ?t(invoicePrefix),
      'allowCreditSale': ?allowCreditSale,
      'loyalty': ?loyalty?.toJson(),
    };
  }
}

class BranchDraft {
  const BranchDraft({
    required this.name,
    required this.code,
    this.phone,
    this.address,
  });

  final String name;
  final String code;
  final String? phone;
  final String? address;

  Map<String, dynamic> toBody() {
    final p = phone?.trim();
    final a = address?.trim();
    return {
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      if (p != null && p.isNotEmpty) 'phone': p,
      if (a != null && a.isNotEmpty) 'address': a,
    };
  }
}

class MemberDraft {
  const MemberDraft({
    required this.name,
    required this.email,
    required this.password,
    required this.roleId,
    this.branchId,
  });

  final String name;
  final String email;
  final String password;
  final int roleId;
  final int? branchId;

  Map<String, dynamic> toBody() => {
    'name': name.trim(),
    'email': email.trim(),
    'password': password,
    'roleId': roleId,
    'branchId': ?branchId,
  };
}

class MemberAdded {
  const MemberAdded({required this.userId, this.reusedExistingAccount = false});

  final UserId userId;

  /// The email already had an account: that person joins with their own
  /// password, and the one typed here was not used.
  final bool reusedExistingAccount;

  factory MemberAdded.fromJson(Map<String, dynamic> json) => MemberAdded(
    userId: UserId(_int(json['userId'])),
    reusedExistingAccount: _bool(json['reusedExistingAccount']),
  );
}
