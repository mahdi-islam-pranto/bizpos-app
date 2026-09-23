import 'package:decimal/decimal.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';

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

/// Null is "not told", not zero.
///
/// `purchasePrice` arrives as `null` for anyone without
/// `inventory.product.view_cost`, and a cost of zero is a different claim to no
/// cost at all — one would have a stock keeper believing the shop paid nothing.
num? _numOrNull(Object? v) => v == null ? null : _num(v);

String _str(Object? v) => v?.toString() ?? '';

String? _strOrNull(Object? v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

bool _bool(Object? v) => v == true || v == 1 || v == 'true';

/// A product on this store's shelves, with this branch's stock.
///
/// One type for the live list and the trashed one: `deletedAt` is what tells
/// them apart, and a deleted product keeps every other field so the screen can
/// show what is about to come back.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.salePrice,
    this.barcode,
    this.sku,
    this.unit,
    this.brand,
    this.category,
    this.purchasePrice,
    this.wholesalePrice,
    this.mrp,
    this.profitPercent,
    this.profitRate,
    this.vatPercent = 0,
    this.minimumStock,
    this.stock,
    this.isActive = true,
    this.trackBatch = false,
    this.deletedAt,
    this.addedBy,
    this.changedBy,
  });

  final int id;
  final String name;
  final num salePrice;

  final String? barcode;
  final String? sku;
  final String? unit;
  final String? brand;
  final String? category;

  /// Null without `inventory.product.view_cost`.
  final num? purchasePrice;
  final num? wholesalePrice;

  /// What the box says it costs. The gap between this and [salePrice] is the
  /// saving a receipt boasts about.
  final num? mrp;

  /// The markup the shop **stated** on its cost ("cost plus five percent"), or
  /// null when the price was simply named. Null is not zero: it is the absence
  /// of a decision, and it is what every product priced before the field
  /// existed carries.
  final num? profitPercent;

  /// `(sale − cost) / cost × 100`, always worked out. Shown as approximate when
  /// [profitPercent] is null, because a derived figure is not a rate anybody
  /// set. Both are null without `inventory.product.view_cost` — a markup is a
  /// cost by another name.
  final num? profitRate;

  final num vatPercent;
  final num? minimumStock;

  /// This branch's stock. Null without `inventory.stock.view`.
  final num? stock;

  final bool isActive;
  final bool trackBatch;

  /// Set only on the `trashed=1` list. A soft delete: the product leaves every
  /// stock figure and the till, and `POST /products/{id}/restore` puts it back.
  final DateTime? deletedAt;

  final String? addedBy;
  final String? changedBy;

  bool get isDeleted => deletedAt != null;

  bool get isLow =>
      stock != null && minimumStock != null && stock! <= minimumStock!;

  bool get isOut => stock != null && stock! <= 0;

  /// What the shop makes on one, or null when the cost is hidden.
  num? get margin => purchasePrice == null ? null : salePrice - purchasePrice!;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: _int(json['id']),
        name: _str(json['name']),
        salePrice: _num(json['salePrice']),
        barcode: _strOrNull(json['barcode']),
        sku: _strOrNull(json['sku']),
        unit: _strOrNull(json['unit']),
        brand: _strOrNull(json['brand']),
        category: _strOrNull(json['category']),
        purchasePrice: _numOrNull(json['purchasePrice']),
        wholesalePrice: _numOrNull(json['wholesalePrice']),
        mrp: _numOrNull(json['mrp']),
        profitPercent: _numOrNull(json['profitPercent']),
        profitRate: _numOrNull(json['profitRate']),
        vatPercent: _num(json['vatPercent']),
        minimumStock: _numOrNull(json['minimumStock']),
        stock: _numOrNull(json['stock']),
        isActive: json['isActive'] == null || _bool(json['isActive']),
        trackBatch: _bool(json['trackBatch']),
        deletedAt: AppDates.parse(json['deletedAt']),
        addedBy: _strOrNull(json['addedBy']),
        changedBy: _strOrNull(json['changedBy']),
      );
}

/// One line of the `movements` in `GET /products/{id}/history`.
///
/// Every reason stock moved: an opening balance, a purchase, a sale, a return,
/// an adjustment, damage. `balanceAfter` is what was on the shelf once it had.
class StockMovement {
  const StockMovement({
    required this.id,
    required this.type,
    required this.qtyIn,
    required this.qtyOut,
    required this.balanceAfter,
    this.movedAt,
    this.note,
    this.user,
  });

  final int id;

  /// `opening`, `purchase`, `sale`, `return`, `adjustment`, `damage`, ...
  /// Shown through a known-types switch that falls back to the raw word, so a
  /// type the API adds later reads as itself rather than as nothing.
  final String type;

  final num qtyIn;
  final num qtyOut;
  final num balanceAfter;
  final DateTime? movedAt;
  final String? note;
  final String? user;

  /// Positive in, negative out.
  num get delta => qtyIn - qtyOut;

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
        id: _int(json['id']),
        type: _str(json['type']),
        qtyIn: _num(json['qtyIn']),
        qtyOut: _num(json['qtyOut']),
        balanceAfter: _num(json['balanceAfter']),
        movedAt: AppDates.parse(json['movedAt']),
        note: _strOrNull(json['note']),
        user: _strOrNull(json['user']),
      );
}

/// One row of the price history. `effectiveTo` is null on the current one.
class PriceChange {
  const PriceChange({
    required this.id,
    required this.salePrice,
    this.purchasePrice,
    this.wholesalePrice,
    this.profitPercent,
    this.effectiveFrom,
    this.effectiveTo,
  });

  final int id;
  final num salePrice;
  final num? purchasePrice;
  final num? wholesalePrice;

  /// The markup stated for this period, so the history answers "what were we
  /// making on this in Ramadan" as well as "what were we charging".
  final num? profitPercent;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  bool get isCurrent => effectiveTo == null;

  factory PriceChange.fromJson(Map<String, dynamic> json) => PriceChange(
        id: _int(json['id']),
        salePrice: _num(json['salePrice']),
        purchasePrice: _numOrNull(json['purchasePrice']),
        wholesalePrice: _numOrNull(json['wholesalePrice']),
        profitPercent: _numOrNull(json['profitPercent']),
        effectiveFrom: AppDates.parse(json['effectiveFrom']),
        effectiveTo: AppDates.parse(json['effectiveTo']),
      );
}

/// `GET /products/{id}/history` — the last 40 movements and 20 prices.
class ProductHistory {
  const ProductHistory({required this.movements, required this.prices});

  final List<StockMovement> movements;
  final List<PriceChange> prices;

  factory ProductHistory.fromJson(Map<String, dynamic> json) => ProductHistory(
        movements: _listOf(json['movements'], StockMovement.fromJson),
        prices: _listOf(json['prices'], PriceChange.fromJson),
      );
}

/// A name and a number, as the `low` and `expiring` lists in the stats give
/// them.
class StockAlert {
  const StockAlert({
    required this.id,
    required this.name,
    this.quantity,
    this.minimum,
    this.expiresAt,
  });

  final int id;
  final String name;
  final num? quantity;
  final num? minimum;
  final DateTime? expiresAt;

  factory StockAlert.fromJson(Map<String, dynamic> json) => StockAlert(
        id: _int(json['id']),
        name: _str(json['name']),
        quantity: _numOrNull(json['quantity']),
        minimum: _numOrNull(json['minimum']),
        expiresAt: AppDates.parse(json['expiresAt'] ?? json['expiryDate']),
      );
}

/// `GET /products/stats` — the top of the products screen.
class ProductStats {
  const ProductStats({
    required this.total,
    required this.active,
    required this.lowCount,
    required this.low,
    required this.expiringCount,
    required this.expiring,
    required this.canSeeCost,
    this.stockValue,
  });

  final int total;
  final int active;
  final int lowCount;
  final List<StockAlert> low;
  final int expiringCount;
  final List<StockAlert> expiring;

  /// False for a role without `inventory.product.view_cost`, and then
  /// [stockValue] is not worth showing whatever it holds.
  final bool canSeeCost;
  final num? stockValue;

  factory ProductStats.fromJson(Map<String, dynamic> json) => ProductStats(
        total: _int(json['total']),
        active: _int(json['active']),
        lowCount: _int(json['lowCount']),
        low: _listOf(json['low'], StockAlert.fromJson),
        expiringCount: _int(json['expiringCount']),
        expiring: _listOf(json['expiring'], StockAlert.fromJson),
        canSeeCost: _bool(json['canSeeCost']),
        stockValue: _numOrNull(json['stockValue']),
      );
}

/// `GET /products/lookups` — what the Company and Unit boxes offer, so neither
/// is blank paper. Both stay free text: a company nobody has saved yet simply
/// works, and an unknown unit becomes this store's own.
class ProductLookups {
  const ProductLookups({required this.brands, required this.units});

  final List<String> brands;
  final List<ProductUnit> units;

  factory ProductLookups.fromJson(Map<String, dynamic> json) => ProductLookups(
        brands: (json['brands'] is List)
            ? (json['brands'] as List).map((b) => b.toString()).toList()
            : const [],
        units: _listOf(json['units'], ProductUnit.fromJson),
      );
}

class ProductUnit {
  const ProductUnit({required this.short, required this.label, this.labelBn});

  /// What the request sends as `unit`.
  final String short;
  final String label;
  final String? labelBn;

  String labelFor(String locale) =>
      locale == 'bn' && (labelBn ?? '').isNotEmpty ? labelBn! : label;

  factory ProductUnit.fromJson(Map<String, dynamic> json) => ProductUnit(
        short: _str(json['short']),
        label: _str(json['label']),
        labelBn: _strOrNull(json['labelBn']),
      );
}

/// Cost plus [percent], to the paisa: a cost of 90 at 5% is 94.50.
///
/// Exact arithmetic, because this figure is sent as the selling price and a
/// stray `94.49999999` would be a different price.
num markupPrice(num cost, num percent) => Exact.paisa(
      (Exact.of(cost) * (Decimal.fromInt(100) + Exact.of(percent))).shift(-2),
    ).toDouble();

/// The rule the server does not bend on, anywhere a price is set: a selling
/// price under the cost is refused with a `422`. Checked on the form as well so
/// nobody has to press Save to find out.
bool isBelowCost({required num? cost, required num? sale}) =>
    cost != null && sale != null && sale < cost;

/// What a soft delete reports: how much was on the shelf when it went.
class DeleteOutcome {
  const DeleteOutcome({required this.stockWritten});

  final num stockWritten;

  factory DeleteOutcome.fromJson(Map<String, dynamic> json) =>
      DeleteOutcome(stockWritten: _num(json['stockWritten']));
}

List<T> _listOf<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(parse).toList();
}
