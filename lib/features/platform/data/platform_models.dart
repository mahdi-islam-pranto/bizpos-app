import '../../../core/format/dates.dart';
import '../../../core/network/envelope.dart';

int _int(Object? v) => switch (v) {
  final int x => x,
  final num x => x.toInt(),
  final String x => int.tryParse(x) ?? 0,
  _ => 0,
};

int? _intOrNull(Object? v) => v == null ? null : _int(v);

num? _numOrNull(Object? v) => switch (v) {
  final num x => x,
  final String x => num.tryParse(x),
  _ => null,
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

/// A name, or `{name}`.
String? _nameOf(Object? v) => switch (v) {
  final Map<String, dynamic> m => _strOrNull(m['name']),
  _ => _strOrNull(v),
};

/// A store type or a plan: an id and a name.
class Choice {
  const Choice({required this.id, required this.name});

  final int id;
  final String name;

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
    id: _int(json['id']),
    name: _strOrNull(json['name']) ?? _str(json['label']),
  );
}

/// One shop on the platform, as `GET /admin/overview` lists it.
class AdminStore {
  const AdminStore({
    required this.id,
    required this.name,
    required this.status,
    this.slug,
    this.storeTypeId,
    this.storeTypeName,
    this.planId,
    this.planName,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.currency,
    this.timezone,
    this.ownerName,
    this.ownerEmail,
    this.trialEndsAt,
    this.trialDaysLeft,
    this.locked = false,
    this.dbName,
    this.dbReady = false,
    this.dbMigratedAt,
    this.createdAt,
    this.counts = const {},
  });

  final int id;
  final String name;

  /// `active` or `suspended`.
  final String status;
  final String? slug;
  final int? storeTypeId;
  final String? storeTypeName;
  final int? planId;
  final String? planName;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? currency;
  final String? timezone;
  final String? ownerName;
  final String? ownerEmail;

  /// Null when the shop has no clock on it (it pays, or predates trials).
  final DateTime? trialEndsAt;
  final int? trialDaysLeft;

  /// Nobody can sign in: suspended, or the trial ran out.
  final bool locked;

  final String? dbName;
  final bool dbReady;

  /// Null with a [dbName] is the normal state before the shop is moved.
  final DateTime? dbMigratedAt;
  final DateTime? createdAt;

  /// Members, branches, products, sales — whatever counts the row carries.
  final Map<String, int> counts;

  bool get isSuspended => status == 'suspended';
  bool get hasTrial => trialEndsAt != null;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      name,
      slug,
      phone,
      email,
      ownerName,
      ownerEmail,
      city,
    ].whereType<String>().any((v) => v.toLowerCase().contains(q));
  }

  factory AdminStore.fromJson(Map<String, dynamic> json) {
    final counts = <String, int>{};
    final nested = json['counts'];
    if (nested is Map) {
      nested.forEach((k, v) {
        if (v is num) counts[k.toString()] = v.toInt();
      });
    }
    // `membersCount`, `products_count`, ... at the top level.
    json.forEach((k, v) {
      final key = k.toString();
      if (v is! num) return;
      final lower = key.toLowerCase();
      if (lower.endsWith('count') && lower != 'count') {
        final name = key
            .substring(0, key.length - 5)
            .replaceAll(RegExp(r'_$'), '');
        counts.putIfAbsent(name, () => v.toInt());
      }
    });
    final owner = json['owner'];
    return AdminStore(
      id: _int(json['id']),
      name: _str(json['name']),
      status: _strOrNull(json['status']) ?? 'active',
      slug: _strOrNull(json['slug']),
      storeTypeId: _intOrNull(json['storeTypeId']),
      storeTypeName:
          _strOrNull(json['storeTypeName']) ?? _nameOf(json['storeType']),
      planId: _intOrNull(json['planId']),
      planName: _strOrNull(json['planName']) ?? _nameOf(json['plan']),
      phone: _strOrNull(json['phone']),
      email: _strOrNull(json['email']),
      address: _strOrNull(json['address']),
      city: _strOrNull(json['city']),
      currency: _strOrNull(json['currency']),
      timezone: _strOrNull(json['timezone']),
      ownerName:
          _strOrNull(json['ownerName']) ??
          (owner is Map ? _strOrNull(owner['name']) : null),
      ownerEmail:
          _strOrNull(json['ownerEmail']) ??
          (owner is Map ? _strOrNull(owner['email']) : null),
      trialEndsAt: AppDates.parse(json['trialEndsAt']),
      trialDaysLeft: _intOrNull(json['trialDaysLeft']),
      locked: _bool(json['locked']),
      dbName: _strOrNull(json['dbName']),
      dbReady: _bool(json['dbReady']),
      dbMigratedAt: AppDates.parse(json['dbMigratedAt']),
      createdAt: AppDates.parse(json['createdAt']),
      counts: counts,
    );
  }
}

/// A product a shop put up for the shared catalogue.
class AdminSuggestion {
  const AdminSuggestion({
    required this.id,
    required this.name,
    this.genericName,
    this.brand,
    this.unit,
    this.barcode,
    this.storeName,
    this.storeType,
    this.suggestedBy,
    this.salePrice,
    this.mrp,
    this.status,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? genericName;
  final String? brand;
  final String? unit;
  final String? barcode;
  final String? storeName;
  final String? storeType;
  final String? suggestedBy;
  final num? salePrice;
  final num? mrp;
  final String? status;
  final DateTime? createdAt;

  factory AdminSuggestion.fromJson(Map<String, dynamic> json) =>
      AdminSuggestion(
        id: _int(json['id']),
        name: _str(json['name']),
        genericName: _strOrNull(json['genericName'] ?? json['generic_name']),
        brand: _nameOf(json['brand']),
        unit: _nameOf(json['unit']),
        barcode: _strOrNull(json['barcode']),
        storeName: _strOrNull(json['storeName']) ?? _nameOf(json['store']),
        storeType:
            _strOrNull(json['storeTypeName']) ?? _nameOf(json['storeType']),
        suggestedBy: _strOrNull(json['suggestedBy']) ?? _nameOf(json['user']),
        salePrice: _numOrNull(json['salePrice']),
        mrp: _numOrNull(json['mrp']),
        status: _strOrNull(json['status']),
        createdAt: AppDates.parse(json['createdAt']),
      );
}

/// `GET /admin/overview`.
class PlatformOverview {
  const PlatformOverview({
    required this.stores,
    required this.storeTypes,
    required this.plans,
    required this.suggestions,
    required this.totals,
  });

  final List<AdminStore> stores;
  final List<Choice> storeTypes;
  final List<Choice> plans;
  final List<AdminSuggestion> suggestions;

  /// Platform-wide figures, keyed as the server names them.
  final Map<String, num> totals;

  String? storeTypeName(int? id) {
    for (final t in storeTypes) {
      if (t.id == id) return t.name;
    }
    return null;
  }

  String? planName(int? id) {
    for (final p in plans) {
      if (p.id == id) return p.name;
    }
    return null;
  }

  factory PlatformOverview.fromJson(Map<String, dynamic> json) {
    final totals = <String, num>{};
    final raw = json['totals'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is num) totals[k.toString()] = v;
      });
    }
    return PlatformOverview(
      stores: _listOf(json['stores'], AdminStore.fromJson),
      storeTypes: _listOf(json['storeTypes'], Choice.fromJson),
      plans: _listOf(json['plans'], Choice.fromJson),
      suggestions: _listOf(json['suggestions'], AdminSuggestion.fromJson),
      totals: totals,
    );
  }
}

/// `POST /admin/stores`. `phone` is required at every door a shop comes in by.
class NewStoreDraft {
  const NewStoreDraft({
    required this.name,
    required this.storeTypeId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPassword,
    required this.phone,
    this.planId,
    this.address,
    this.branchName,
  });

  final String name;
  final int storeTypeId;
  final String ownerName;
  final String ownerEmail;
  final String ownerPassword;
  final String phone;
  final int? planId;
  final String? address;
  final String? branchName;

  Map<String, dynamic> toBody() {
    final a = address?.trim();
    final b = branchName?.trim();
    return {
      'name': name.trim(),
      'storeTypeId': storeTypeId,
      'ownerName': ownerName.trim(),
      'ownerEmail': ownerEmail.trim(),
      'ownerPassword': ownerPassword,
      'phone': phone.trim(),
      'planId': ?planId,
      if (a != null && a.isNotEmpty) 'address': a,
      if (b != null && b.isNotEmpty) 'branchName': b,
    };
  }
}

/// What creating a shop did — including whether its own database was made.
class StoreCreated {
  const StoreCreated({
    required this.storeId,
    this.ownerEmail,
    this.reusedExistingAccount = false,
    this.dbName,
    this.dbCreated = false,
    this.dbMigrated = false,
    this.dbProblem,
    this.dbDetail,
  });

  final int storeId;
  final String? ownerEmail;
  final bool reusedExistingAccount;
  final String? dbName;
  final bool dbCreated;
  final bool dbMigrated;

  /// Set when the database step failed; the shop itself still exists.
  final String? dbProblem;
  final String? dbDetail;

  bool get dbOk => dbProblem == null && dbCreated && dbMigrated;

  factory StoreCreated.fromJson(Map<String, dynamic> json) => StoreCreated(
    storeId: _int(json['storeId']),
    ownerEmail: _strOrNull(json['ownerEmail']),
    reusedExistingAccount: _bool(json['reusedExistingAccount']),
    dbName: _strOrNull(json['dbName']),
    dbCreated: _bool(json['dbCreated']),
    dbMigrated: _bool(json['dbMigrated']),
    dbProblem: _strOrNull(json['dbProblem']),
    dbDetail: _strOrNull(json['dbDetail']),
  );
}

/// `PATCH /admin/stores/{id}`: only what changed travels. The slug, the
/// database name and the trial are not editable here.
class StoreEdit {
  const StoreEdit({
    this.name,
    this.storeTypeId,
    this.planId,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.currency,
    this.timezone,
  });

  final String? name;
  final int? storeTypeId;
  final int? planId;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? currency;
  final String? timezone;

  /// The fields of [after] that differ from [before].
  factory StoreEdit.diff(AdminStore before, StoreEdit after) {
    String? changed(String? was, String? now) {
      final n = now?.trim() ?? '';
      return n == (was ?? '') ? null : n;
    }

    return StoreEdit(
      name: changed(before.name, after.name),
      storeTypeId: after.storeTypeId == before.storeTypeId
          ? null
          : after.storeTypeId,
      planId: after.planId == before.planId ? null : after.planId,
      phone: changed(before.phone, after.phone),
      email: changed(before.email, after.email),
      address: changed(before.address, after.address),
      city: changed(before.city, after.city),
      currency: changed(before.currency, after.currency),
      timezone: changed(before.timezone, after.timezone),
    );
  }

  Map<String, dynamic> toBody() => {
    'name': ?name,
    'storeTypeId': ?storeTypeId,
    'planId': ?planId,
    'phone': ?phone,
    'email': ?email,
    'address': ?address,
    'city': ?city,
    'currency': ?currency,
    'timezone': ?timezone,
  };

  bool get isEmpty => toBody().isEmpty;
}

class StoreUpdated {
  const StoreUpdated({required this.id, this.storeTypeChanged = false});

  final int id;

  /// The shop now reads another kind's shared catalogue.
  final bool storeTypeChanged;

  factory StoreUpdated.fromJson(Map<String, dynamic> json) => StoreUpdated(
    id: _int(json['id']),
    storeTypeChanged: _bool(json['storeTypeChanged']),
  );
}

/// What `POST /admin/stores/{id}/extend` left the shop as.
class TrialState {
  const TrialState({
    required this.id,
    required this.status,
    this.trialEndsAt,
    this.trialDaysLeft,
    this.locked = false,
  });

  final int id;
  final String status;
  final DateTime? trialEndsAt;
  final int? trialDaysLeft;
  final bool locked;

  factory TrialState.fromJson(Map<String, dynamic> json) => TrialState(
    id: _int(json['id']),
    status: _strOrNull(json['status']) ?? 'active',
    trialEndsAt: AppDates.parse(json['trialEndsAt']),
    trialDaysLeft: _intOrNull(json['trialDaysLeft']),
    locked: _bool(json['locked']),
  );
}

/// An entry in the shared catalogue, as the platform manages it.
class AdminCatalogEntry {
  const AdminCatalogEntry({
    required this.id,
    required this.name,
    this.genericName,
    this.brand,
    this.unit,
    this.category,
    this.categoryId,
    this.storeType,
    this.storeTypeId,
    this.sku,
    this.barcode,
    this.description,
    this.purchasePrice,
    this.salePrice,
    this.mrp,
    this.vatPercent,
    this.status = 'approved',
    this.inStores = 0,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String? genericName;
  final String? brand;
  final String? unit;
  final String? category;
  final int? categoryId;
  final String? storeType;
  final int? storeTypeId;
  final String? sku;
  final String? barcode;
  final String? description;
  final num? purchasePrice;
  final num? salePrice;
  final num? mrp;
  final num? vatPercent;

  /// `draft`, `pending`, `approved` or `rejected`.
  final String status;

  /// How many shops have it on their shelf — worth a look before renaming it.
  final int inStores;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory AdminCatalogEntry.fromJson(Map<String, dynamic> json) =>
      AdminCatalogEntry(
        id: _int(json['id']),
        name: _str(json['name']),
        genericName: _strOrNull(json['genericName']),
        brand: _nameOf(json['brand']),
        unit: _nameOf(json['unit']),
        category: _nameOf(json['category']),
        categoryId: _intOrNull(json['categoryId']),
        storeType: _nameOf(json['storeType']),
        storeTypeId: _intOrNull(json['storeTypeId']),
        sku: _strOrNull(json['sku']),
        barcode: _strOrNull(json['barcode']),
        description: _strOrNull(json['description']),
        purchasePrice: _numOrNull(json['purchasePrice']),
        salePrice: _numOrNull(json['salePrice']),
        mrp: _numOrNull(json['mrp']),
        vatPercent: _numOrNull(json['vatPercent']),
        status: _strOrNull(json['status']) ?? 'approved',
        inStores: _int(json['inStores']),
        deletedAt: AppDates.parse(json['deletedAt']),
      );
}

/// `POST/PATCH /admin/catalog`.
class CatalogEntryDraft {
  const CatalogEntryDraft({
    required this.storeTypeId,
    required this.name,
    this.genericName,
    this.brand,
    this.unit,
    this.categoryId,
    this.sku,
    this.barcode,
    this.description,
    this.purchasePrice,
    this.salePrice,
    this.mrp,
    this.vatPercent,
    this.status,
  });

  final int storeTypeId;
  final String name;
  final String? genericName;
  final String? brand;
  final String? unit;
  final int? categoryId;
  final String? sku;
  final String? barcode;
  final String? description;
  final num? purchasePrice;
  final num? salePrice;
  final num? mrp;
  final num? vatPercent;
  final String? status;

  /// Every field the form shows travels, empty ones as null, so an edit can
  /// clear a barcode as well as set one.
  Map<String, dynamic> toBody() {
    String? t(String? v) {
      final s = v?.trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return {
      'storeTypeId': storeTypeId,
      'name': name.trim(),
      'genericName': t(genericName),
      'brand': t(brand),
      'unit': t(unit),
      'categoryId': categoryId,
      'sku': t(sku),
      'barcode': t(barcode),
      'description': t(description),
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'mrp': mrp,
      'vatPercent': vatPercent,
      'status': ?status,
    };
  }
}

/// `GET /admin/catalog/lookups?storeType=` — the shared lists, never a shop's.
class AdminCatalogLookups {
  const AdminCatalogLookups({
    this.brands = const [],
    this.units = const [],
    this.categories = const [],
  });

  final List<String> brands;

  /// `{short, label}`: `pcs` / `Pieces`.
  final List<({String short, String label})> units;
  final List<Choice> categories;

  factory AdminCatalogLookups.fromJson(Map<String, dynamic> json) {
    final brands = json['brands'];
    final units = json['units'];
    return AdminCatalogLookups(
      brands: [
        if (brands is List)
          for (final b in brands)
            if (_nameOf(b) != null) _nameOf(b)!,
      ],
      units: [
        if (units is List)
          for (final u in units)
            if (u is Map)
              (
                short: _str(u['short']),
                label: _strOrNull(u['label']) ?? _str(u['short']),
              )
            else if (u != null)
              (short: _str(u), label: _str(u)),
      ],
      categories: _listOf(json['categories'], Choice.fromJson),
    );
  }
}

/// What the platform catalogue list is filtered by.
class AdminCatalogFilter {
  const AdminCatalogFilter({
    this.q,
    this.storeTypeId,
    this.status,
    this.trashed = false,
  });

  final String? q;
  final int? storeTypeId;
  final String? status;
  final bool trashed;

  AdminCatalogFilter copyWith({
    String? q,
    int? storeTypeId,
    String? status,
    bool? trashed,
    bool clearStoreType = false,
    bool clearStatus = false,
  }) => AdminCatalogFilter(
    q: q ?? this.q,
    storeTypeId: clearStoreType ? null : (storeTypeId ?? this.storeTypeId),
    status: clearStatus ? null : (status ?? this.status),
    trashed: trashed ?? this.trashed,
  );

  Map<String, dynamic> toQuery() => {
    if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
    'storeType': ?storeTypeId,
    'status': ?status,
    if (trashed) 'trashed': 1,
  };

  @override
  bool operator ==(Object other) =>
      other is AdminCatalogFilter &&
      other.q == q &&
      other.storeTypeId == storeTypeId &&
      other.status == status &&
      other.trashed == trashed;

  @override
  int get hashCode => Object.hash(q, storeTypeId, status, trashed);
}

/// The catalogue page's own counts and the store types to filter by.
class AdminCatalogMeta {
  const AdminCatalogMeta(this.meta);

  final Meta meta;

  int get trashedCount => meta.intValue('trashedCount') ?? 0;
  int get pendingCount => meta.intValue('pendingCount') ?? 0;
  List<Choice> get storeTypes =>
      meta.listValue('storeTypes').map(Choice.fromJson).toList();
}
