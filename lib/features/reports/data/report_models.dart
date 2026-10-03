import '../../../core/format/dates.dart';

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

num? _numOrNull(Object? v) => v == null ? null : _num(v);

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

/// A report bucket is `YYYY-MM-DD` with no time and no offset. Parsing it as
/// a moment and calling `toLocal()` moves a Dhaka day onto the one before it
/// on a UTC machine, so it is read as a calendar date and never converted.
DateTime? parseBucket(Object? v) {
  final s = v?.toString();
  if (s == null || s.length < 10) return null;
  final parts = s.substring(0, 10).split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// One day of `GET /reports/sales`.
class SalesDay {
  const SalesDay({
    required this.date,
    required this.total,
    required this.count,
  });

  final DateTime? date;
  final num total;
  final int count;

  factory SalesDay.fromJson(Map<String, dynamic> json) => SalesDay(
    date: parseBucket(json['date']),
    total: _num(json['total']),
    count: _int(json['count']),
  );
}

/// A best seller. [profit] is null for a role without `report.profit.view`.
class TopProduct {
  const TopProduct({
    required this.name,
    required this.qty,
    required this.revenue,
    this.id,
    this.profit,
  });

  final int? id;
  final String name;
  final num qty;
  final num revenue;
  final num? profit;

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
    id: _intOrNull(json['id']),
    name: _str(json['name']),
    qty: _num(json['qty']),
    revenue: _num(json['revenue']),
    profit: _numOrNull(json['profit']),
  );
}

/// A name, a sum and a count: `byUser`, and `byMethod` without the count.
class Tally {
  const Tally({required this.label, required this.total, this.count});

  final String label;
  final num total;
  final int? count;

  factory Tally.fromJson(Map<String, dynamic> json) => Tally(
    label: _str(json['name'] ?? json['method'] ?? json['label']),
    total: _num(json['total'] ?? json['amount']),
    count: _intOrNull(json['count']),
  );
}

/// `GET /reports/sales?days=` — **the current branch**.
class SalesReport {
  const SalesReport({
    required this.daily,
    required this.topProducts,
    required this.byUser,
    required this.byMethod,
    required this.showProfit,
  });

  final List<SalesDay> daily;
  final List<TopProduct> topProducts;
  final List<Tally> byUser;
  final List<Tally> byMethod;

  /// False without `report.profit.view`; then every `profit` is null.
  final bool showProfit;

  num get total => daily.fold<num>(0, (s, d) => s + d.total);
  int get count => daily.fold<int>(0, (s, d) => s + d.count);

  factory SalesReport.fromJson(Map<String, dynamic> json) => SalesReport(
    daily: _listOf(json['daily'], SalesDay.fromJson),
    topProducts: _listOf(json['topProducts'], TopProduct.fromJson),
    byUser: _listOf(json['byUser'], Tally.fromJson),
    byMethod: _listOf(json['byMethod'], Tally.fromJson),
    showProfit: _bool(json['showProfit']),
  );
}

/// `GET /reports/profit?days=`.
///
/// Mixed scope, and the screen says so: [revenue] and [cost] are for the
/// current branch, while [returnTotal] and [expenses] cover the whole store.
class ProfitReport {
  const ProfitReport({
    required this.revenue,
    required this.cost,
    required this.returnTotal,
    required this.grossProfit,
    required this.expenses,
    required this.netProfit,
    required this.margin,
  });

  final num revenue;
  final num cost;
  final num returnTotal;
  final num grossProfit;
  final num expenses;
  final num netProfit;

  /// A percentage.
  final num margin;

  factory ProfitReport.fromJson(Map<String, dynamic> json) => ProfitReport(
    revenue: _num(json['revenue']),
    cost: _num(json['cost']),
    returnTotal: _num(json['returnTotal']),
    grossProfit: _num(json['grossProfit']),
    expenses: _num(json['expenses']),
    netProfit: _num(json['netProfit']),
    margin: _num(json['margin']),
  );
}

/// A product row of the stock report, the dashboard's stock section and its
/// movers — every list that is "a product and how much of it".
class StockLine {
  const StockLine({
    required this.name,
    this.id,
    this.qty,
    this.minimum,
    this.expiresAt,
    this.lastSoldAt,
    this.value,
  });

  final int? id;
  final String name;
  final num? qty;
  final num? minimum;
  final DateTime? expiresAt;
  final DateTime? lastSoldAt;
  final num? value;

  factory StockLine.fromJson(Map<String, dynamic> json) => StockLine(
    id: _intOrNull(json['id'] ?? json['storeProductId']),
    name: _str(json['name']),
    qty: _numOrNull(
      json['quantity'] ?? json['qty'] ?? json['stock'] ?? json['onHand'],
    ),
    minimum: _numOrNull(
      json['minimum'] ?? json['alertQuantity'] ?? json['reorderLevel'],
    ),
    expiresAt: AppDates.parse(json['expiresAt'] ?? json['expiryDate']),
    lastSoldAt: AppDates.parse(json['lastSoldAt'] ?? json['lastSale']),
    value: _numOrNull(json['value'] ?? json['stockValue']),
  );
}

/// `GET /reports/stock` — the current branch.
class StockReport {
  const StockReport({
    required this.stockValue,
    required this.totalUnits,
    required this.low,
    required this.expiring,
    required this.dead,
  });

  /// At cost. Null when the server holds it back.
  final num? stockValue;
  final num totalUnits;
  final List<StockLine> low;
  final List<StockLine> expiring;

  /// Twenty products with no sale in 90 days: money sitting on a shelf.
  final List<StockLine> dead;

  factory StockReport.fromJson(Map<String, dynamic> json) => StockReport(
    stockValue: _numOrNull(json['stockValue']),
    totalUnits: _num(json['totalUnits']),
    low: _listOf(json['low'], StockLine.fromJson),
    expiring: _listOf(json['expiring'], StockLine.fromJson),
    dead: _listOf(json['dead'], StockLine.fromJson),
  );
}

/// A customer who owes the shop, from `GET /reports/dues` — the whole store.
class DueRow {
  const DueRow({
    required this.id,
    required this.name,
    required this.due,
    this.phone,
    this.creditLimit,
    this.ageDays,
  });

  final int id;
  final String name;
  final String? phone;
  final num due;
  final num? creditLimit;

  /// Days since the oldest unpaid bill.
  final int? ageDays;

  bool get overLimit =>
      creditLimit != null && creditLimit! > 0 && due > creditLimit!;

  factory DueRow.fromJson(Map<String, dynamic> json) => DueRow(
    id: _int(json['id']),
    name: _str(json['name']),
    phone: _strOrNull(json['phone']),
    due: _num(json['due']),
    creditLimit: _numOrNull(json['creditLimit']),
    ageDays: _intOrNull(json['ageDays']),
  );
}
