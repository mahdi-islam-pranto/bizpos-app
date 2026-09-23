import '../../../core/format/dates.dart';

int _int(Object? v) => switch (v) {
      final int x => x,
      final num x => x.toInt(),
      final String x => int.tryParse(x) ?? 0,
      _ => 0,
    };

num _num(Object? v) => switch (v) {
      final num x => x,
      final String x => num.tryParse(x) ?? 0,
      _ => 0,
    };

num? _numOrNull(Object? v) => v == null ? null : _num(v);

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

/// Whether a package can be sold right now, as the server reckons it.
///
/// Four states, because "on" is not the same as "on sale": a package switched
/// on whose window has not opened is `scheduled`, one whose window closed is
/// `expired`.
enum PackageAvailability {
  live,
  scheduled,
  expired,
  inactive;

  static PackageAvailability parse(String value) => switch (value) {
        'live' => live,
        'scheduled' => scheduled,
        'expired' => expired,
        _ => inactive,
      };
}

/// One product inside a bundle.
class PackageItem {
  const PackageItem({
    required this.storeProductId,
    required this.name,
    required this.qty,
    required this.salePrice,
    this.unit,
  });

  final int storeProductId;
  final String name;
  final num qty;

  /// The product's own price, which is what [Package.componentTotal] adds up.
  final num salePrice;
  final String? unit;

  factory PackageItem.fromJson(Map<String, dynamic> json) => PackageItem(
        storeProductId: _int(json['storeProductId']),
        name: _str(json['name']),
        qty: _num(json['qty']),
        salePrice: _num(json['salePrice']),
        unit: _strOrNull(json['unit']),
      );

  Map<String, dynamic> toBody() => {'storeProductId': storeProductId, 'qty': qty};
}

/// A bundle: several products sold together at one price.
class Package {
  const Package({
    required this.id,
    required this.name,
    required this.price,
    required this.isActive,
    required this.availability,
    required this.sellable,
    required this.items,
    this.description,
    this.barcode,
    this.vatPercent = 0,
    this.startsAt,
    this.endsAt,
    this.buildable,
    this.componentTotal,
    this.saving,
  });

  final int id;
  final String name;
  final num price;
  final bool isActive;
  final PackageAvailability availability;

  /// Live **and** buildable from this branch's stock.
  final bool sellable;
  final List<PackageItem> items;
  final String? description;
  final String? barcode;
  final num vatPercent;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// How many can be made from this branch's stock.
  final num? buildable;

  /// The items at their own prices, and what the bundle takes off that.
  final num? componentTotal;
  final num? saving;

  factory Package.fromJson(Map<String, dynamic> json) => Package(
        id: _int(json['id']),
        name: _str(json['name']),
        price: _num(json['price']),
        isActive: _bool(json['isActive']),
        availability: PackageAvailability.parse(_str(json['availability'])),
        sellable: _bool(json['sellable']),
        items: _listOf(json['items'], PackageItem.fromJson),
        description: _strOrNull(json['description']),
        barcode: _strOrNull(json['barcode']),
        vatPercent: _num(json['vatPercent']),
        startsAt: AppDates.parse(json['startsAt']),
        endsAt: AppDates.parse(json['endsAt']),
        buildable: _numOrNull(json['buildable']),
        componentTotal: _numOrNull(json['componentTotal']),
        saving: _numOrNull(json['saving']),
      );
}

/// A product the package form may put in a bundle, from
/// `GET /packages/products`.
class PackageProduct {
  const PackageProduct({
    required this.id,
    required this.name,
    required this.salePrice,
    this.unit,
    this.stock,
  });

  final int id;
  final String name;
  final num salePrice;
  final String? unit;
  final num? stock;

  factory PackageProduct.fromJson(Map<String, dynamic> json) => PackageProduct(
        id: _int(json['id']),
        name: _str(json['name']),
        salePrice: _num(json['salePrice']),
        unit: _strOrNull(json['unit']),
        stock: _numOrNull(json['stock']),
      );
}

/// The body of `POST /packages` and `PATCH /packages/{id}`.
///
/// On an edit the items are **replaced**, not merged, so the whole list always
/// travels.
class PackageDraft {
  const PackageDraft({
    required this.name,
    required this.price,
    required this.items,
    this.description,
    this.barcode,
    this.vatPercent,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
  });

  final String name;
  final num price;
  final List<PackageItem> items;
  final String? description;
  final String? barcode;
  final num? vatPercent;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;

  /// `endsAt` must come after `startsAt`; the server says so with a `422`,
  /// and the form says so first.
  bool get windowIsValid =>
      startsAt == null || endsAt == null || endsAt!.isAfter(startsAt!);

  Map<String, dynamic> toBody() => {
        'name': name,
        'price': price,
        'items': [for (final item in items) item.toBody()],
        'description': ?description,
        'barcode': ?barcode,
        'vatPercent': ?vatPercent,
        // Sent as plain dates: a window is days, and a time of day picked on a
        // phone in one zone should not move it in another.
        'startsAt': startsAt == null ? null : AppDates.bucket(startsAt!),
        'endsAt': endsAt == null ? null : AppDates.bucket(endsAt!),
        'isActive': isActive,
      };
}
