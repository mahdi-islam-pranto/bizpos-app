import '../../../core/format/dates.dart';
import '../../../core/network/envelope.dart';
import '../../reports/data/report_models.dart';

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

Map<String, dynamic>? _obj(Object? v) => v is Map<String, dynamic> ? v : null;

/// The rows of a section that may arrive as a bare list or as an object
/// carrying the list under one of a few names. The doc names the sections'
/// contents, not every key, so the parser accepts either rather than showing
/// an empty section over a key it did not expect.
List<Map<String, dynamic>> _rows(Object? raw, [List<String> keys = const []]) {
  if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
  if (raw is Map<String, dynamic>) {
    for (final key in [...keys, 'rows', 'items', 'latest', 'recent', 'data']) {
      final v = raw[key];
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    }
  }
  return const [];
}

/// "How were these paid" as a list of tallies, whether the server sends
/// `[{method, total}]` or `{cash: 1200, bkash: 300}`.
List<Tally> _tallies(Object? raw) {
  if (raw is List) {
    return raw.whereType<Map<String, dynamic>>().map(Tally.fromJson).toList();
  }
  if (raw is Map<String, dynamic>) {
    final nested = raw['byMethod'] ?? raw['rows'] ?? raw['methods'];
    if (nested != null) return _tallies(nested);
    return [
      for (final e in raw.entries)
        if (e.value is num) Tally(label: e.key, total: e.value as num),
    ];
  }
  return const [];
}

/// The windows `GET /dashboard?range=` takes. A custom one needs `from` and
/// `to`, and is trimmed to 62 days by the server.
enum DashboardRange {
  today('today'),
  yesterday('yesterday'),
  d7('7d'),
  d15('15d'),
  m1('1m'),
  m2('2m'),
  custom('custom');

  const DashboardRange(this.key);

  final String key;
}

/// What the dashboard is asked for — a value type, so the provider keyed on
/// it refetches exactly when the window changes.
class DashboardQuery {
  const DashboardQuery(this.range, {this.from, this.to});

  final DashboardRange range;
  final DateTime? from;
  final DateTime? to;

  /// The longest window the server will answer for.
  static const maxDays = 62;

  Map<String, dynamic> toQuery() => {
    'range': range.key,
    if (range == DashboardRange.custom && from != null)
      'from': AppDates.bucket(from!),
    if (range == DashboardRange.custom && to != null)
      'to': AppDates.bucket(to!),
  };

  @override
  bool operator ==(Object other) =>
      other is DashboardQuery &&
      other.range == range &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(range, from, to);
}

class DashboardWindow {
  const DashboardWindow({this.from, this.to, this.capped = false});

  final DateTime? from;
  final DateTime? to;

  /// A custom window longer than 62 days was cut short.
  final bool capped;

  factory DashboardWindow.fromJson(Map<String, dynamic>? json) =>
      DashboardWindow(
        from: parseBucket(json?['from']),
        to: parseBucket(json?['to']),
        capped: _bool(json?['capped']),
      );
}

/// The figures across the top. The two profits are null without
/// `report.profit.view` — not zero, which would read as a bad week.
class Headline {
  const Headline({
    required this.revenue,
    required this.invoices,
    required this.averageSale,
    required this.discountGiven,
    required this.dueRaised,
    required this.returned,
    required this.expenses,
    this.grossProfit,
    this.netProfit,
  });

  final num revenue;
  final int invoices;
  final num averageSale;
  final num discountGiven;
  final num dueRaised;
  final num returned;
  final num expenses;
  final num? grossProfit;
  final num? netProfit;

  factory Headline.fromJson(Map<String, dynamic> json) => Headline(
    revenue: _num(json['revenue']),
    invoices: _int(json['invoices']),
    averageSale: _num(json['averageSale']),
    discountGiven: _num(json['discountGiven']),
    dueRaised: _num(json['dueRaised']),
    returned: _num(json['returned']),
    expenses: _num(json['expenses']),
    grossProfit: _numOrNull(json['grossProfit']),
    netProfit: _numOrNull(json['netProfit']),
  );
}

/// Where the money is standing **now**, whatever the window.
class Capital {
  const Capital({
    required this.stock,
    required this.receivable,
    required this.inAccounts,
    required this.invested,
    required this.payable,
    required this.net,
    required this.accounts,
  });

  final num stock;
  final num receivable;
  final num inAccounts;
  final num invested;
  final num payable;
  final num net;
  final List<Tally> accounts;

  factory Capital.fromJson(Map<String, dynamic> json) => Capital(
    stock: _num(json['stock']),
    receivable: _num(json['receivable']),
    inAccounts: _num(json['inAccounts']),
    invested: _num(json['invested']),
    payable: _num(json['payable']),
    net: _num(json['net']),
    accounts: _rows(json['accounts'])
        .map(
          (a) => Tally(
            label: _str(a['name']),
            total: _num(a['balance'] ?? a['total']),
          ),
        )
        .toList(),
  );
}

class DashboardDay {
  const DashboardDay({
    required this.date,
    required this.sales,
    required this.invoices,
    required this.expenses,
  });

  final DateTime? date;
  final num sales;
  final int invoices;
  final num expenses;

  factory DashboardDay.fromJson(Map<String, dynamic> json) => DashboardDay(
    date: parseBucket(json['date']),
    sales: _num(json['sales'] ?? json['total']),
    invoices: _int(json['invoices'] ?? json['count']),
    expenses: _num(json['expenses']),
  );
}

/// Money that **arrived** in the window, whatever it settled. Not the same
/// question as `payments`, which is how the window's own bills were paid.
class Collections {
  const Collections({
    required this.total,
    required this.onSales,
    required this.onDues,
    required this.onPreviousDue,
    required this.byMethod,
  });

  final num total;
  final num onSales;
  final num onDues;
  final num onPreviousDue;
  final List<Tally> byMethod;

  factory Collections.fromJson(Map<String, dynamic> json) => Collections(
    total: _num(json['total']),
    onSales: _num(json['onSales']),
    onDues: _num(json['onDues']),
    onPreviousDue: _num(json['onPreviousDue']),
    byMethod: _tallies(json['byMethod']),
  );
}

/// `rising`, `new`, `steady`, `falling` or `stopped`.
class Mover {
  const Mover({
    required this.name,
    required this.qty,
    required this.wasQty,
    required this.revenue,
    required this.wasRevenue,
    this.id,
    this.changePercent,
    this.verdict,
    this.perDay,
    this.onHand,
    this.daysCover,
  });

  final int? id;
  final String name;
  final num qty;
  final num wasQty;
  final num revenue;
  final num wasRevenue;

  /// Null when there is nothing earlier to compare with — new, not
  /// infinitely up.
  final num? changePercent;
  final String? verdict;
  final num? perDay;
  final num? onHand;

  /// Days until the shelf is empty at this rate.
  final num? daysCover;

  factory Mover.fromJson(Map<String, dynamic> json) => Mover(
    id: _intOrNull(json['id'] ?? json['storeProductId']),
    name: _str(json['name']),
    qty: _num(json['qty']),
    wasQty: _num(json['wasQty']),
    revenue: _num(json['revenue']),
    wasRevenue: _num(json['wasRevenue']),
    changePercent: _numOrNull(json['changePercent']),
    verdict: _strOrNull(json['verdict']),
    perDay: _numOrNull(json['perDay']),
    onHand: _numOrNull(json['onHand']),
    daysCover: _numOrNull(json['daysCover']),
  );
}

class Movers {
  const Movers({
    required this.rising,
    required this.falling,
    this.restock,
    this.previous,
  });

  final List<Mover> rising;
  final List<Mover> falling;

  /// Null without stock permission — the one list with a deadline on it.
  final List<Mover>? restock;
  final DashboardWindow? previous;

  factory Movers.fromJson(Map<String, dynamic> json) => Movers(
    rising: _rows(json['rising']).map(Mover.fromJson).toList(),
    falling: _rows(json['falling']).map(Mover.fromJson).toList(),
    restock: json['restock'] == null
        ? null
        : _rows(json['restock']).map(Mover.fromJson).toList(),
    previous: _obj(json['previous']) == null
        ? null
        : DashboardWindow.fromJson(_obj(json['previous'])),
  );
}

class StaffRow {
  const StaffRow({
    required this.name,
    required this.invoices,
    required this.revenue,
    required this.discount,
    required this.dueRaised,
    required this.averageSale,
    this.profit,
  });

  final String name;
  final int invoices;
  final num revenue;
  final num discount;
  final num dueRaised;
  final num averageSale;
  final num? profit;

  factory StaffRow.fromJson(Map<String, dynamic> json) => StaffRow(
    name: _str(json['name']),
    invoices: _int(json['invoices']),
    revenue: _num(json['revenue']),
    discount: _num(json['discount']),
    dueRaised: _num(json['dueRaised']),
    averageSale: _num(json['averageSale']),
    profit: _numOrNull(json['profit']),
  );
}

/// A party and what is owed — a customer to the shop, or the shop to a
/// supplier.
class OwedRow {
  const OwedRow({required this.name, required this.due, this.id, this.phone});

  final int? id;
  final String name;
  final String? phone;
  final num due;

  factory OwedRow.fromJson(Map<String, dynamic> json) => OwedRow(
    id: _intOrNull(json['id']),
    name: _str(json['name']),
    phone: _strOrNull(json['phone']),
    due: _num(json['due'] ?? json['total']),
  );
}

class DuesSection {
  const DuesSection({
    required this.receivableTotal,
    required this.payableTotal,
    required this.customers,
    required this.suppliers,
  });

  final num receivableTotal;
  final num payableTotal;
  final List<OwedRow> customers;
  final List<OwedRow> suppliers;

  factory DuesSection.fromJson(Map<String, dynamic> json) => DuesSection(
    receivableTotal: _num(json['receivableTotal']),
    payableTotal: _num(json['payableTotal']),
    customers: _rows(json['customers']).map(OwedRow.fromJson).toList(),
    suppliers: _rows(json['suppliers']).map(OwedRow.fromJson).toList(),
  );
}

class ExpensesSection {
  const ExpensesSection({required this.total, required this.byCategory});

  final num total;
  final List<Tally> byCategory;

  factory ExpensesSection.fromJson(Map<String, dynamic> json) =>
      ExpensesSection(
        total: _num(json['total']),
        byCategory: _rows(json['byCategory'])
            .map(
              (c) => Tally(
                label: _str(c['name'] ?? c['category'] ?? c['label']),
                total: _num(c['total'] ?? c['amount']),
                count: _intOrNull(c['count']),
              ),
            )
            .toList(),
      );
}

class PurchasesSection {
  const PurchasesSection({
    required this.total,
    required this.due,
    required this.count,
  });

  final num total;
  final num due;
  final int count;

  factory PurchasesSection.fromJson(Map<String, dynamic> json) =>
      PurchasesSection(
        total: _num(json['total']),
        due: _num(json['due']),
        count: _int(json['count']),
      );
}

class StockSection {
  const StockSection({
    required this.value,
    required this.units,
    required this.outOfStock,
    required this.low,
    required this.expiring,
  });

  final num? value;
  final num units;
  final int outOfStock;
  final List<StockLine> low;
  final List<StockLine> expiring;

  factory StockSection.fromJson(Map<String, dynamic> json) => StockSection(
    value: _numOrNull(json['value']),
    units: _num(json['units']),
    outOfStock: _int(json['outOfStock']),
    low: _rows(json['low']).map(StockLine.fromJson).toList(),
    expiring: _rows(json['expiring']).map(StockLine.fromJson).toList(),
  );
}

/// A cash drawer as the dashboard lists it.
class ShiftRow {
  const ShiftRow({
    required this.openingCash,
    this.id,
    this.userName,
    this.openedAt,
    this.closedAt,
    this.expected,
    this.counted,
    this.difference,
    this.sold,
  });

  final int? id;
  final String? userName;
  final DateTime? openedAt;

  /// Null while the drawer is still open.
  final DateTime? closedAt;
  final num openingCash;
  final num? expected;
  final num? counted;

  /// Counted minus expected: negative is short.
  final num? difference;
  final num? sold;

  factory ShiftRow.fromJson(Map<String, dynamic> json) => ShiftRow(
    id: _intOrNull(json['id']),
    userName: _strOrNull(json['userName'] ?? json['user'] ?? json['name']),
    openedAt: AppDates.parse(json['openedAt']),
    closedAt: AppDates.parse(json['closedAt']),
    openingCash: _num(json['openingCash']),
    expected: _numOrNull(json['expected']),
    counted: _numOrNull(json['counted']),
    difference: _numOrNull(json['difference']),
    sold: _numOrNull(json['sold']),
  );
}

/// `GET /dashboard` — the owner's whole screen in one call.
///
/// **A section the caller may not see is null, not missing**, so every field
/// here is nullable and the screen says "you do not have this" for a null one
/// instead of drawing a shorter dashboard that looks complete.
class Dashboard {
  const Dashboard({
    required this.window,
    required this.meta,
    this.headline,
    this.capital,
    this.daily,
    this.payments,
    this.collections,
    this.topProducts,
    this.movers,
    this.staff,
    this.dues,
    this.expenses,
    this.purchases,
    this.stock,
    this.shifts,
  });

  final DashboardWindow window;
  final Meta meta;
  final Headline? headline;
  final Capital? capital;
  final List<DashboardDay>? daily;
  final List<Tally>? payments;
  final Collections? collections;
  final List<TopProduct>? topProducts;
  final Movers? movers;
  final List<StaffRow>? staff;
  final DuesSection? dues;
  final ExpensesSection? expenses;
  final PurchasesSection? purchases;
  final StockSection? stock;
  final List<ShiftRow>? shifts;

  bool? get mayProfit => meta.flag('mayProfit');
  bool? get mayStock => meta.flag('mayStock');
  bool? get mayDues => meta.flag('mayDues');
  bool? get mayMoney => meta.flag('mayMoney');
  bool? get mayInvoices => meta.flag('mayInvoices');
  bool? get mayPurchase => meta.flag('mayPurchase');

  factory Dashboard.fromJson(Map<String, dynamic> json, Meta meta) {
    T? section<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = _obj(json[key]);
      return raw == null ? null : parse(raw);
    }

    List<T>? list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        json[key] == null ? null : _rows(json[key]).map(parse).toList();

    return Dashboard(
      window: DashboardWindow.fromJson(_obj(json['range'])),
      meta: meta,
      headline: section('headline', Headline.fromJson),
      capital: section('capital', Capital.fromJson),
      daily: list('daily', DashboardDay.fromJson),
      payments: json['payments'] == null ? null : _tallies(json['payments']),
      collections: section('collections', Collections.fromJson),
      topProducts: list('topProducts', TopProduct.fromJson),
      movers: section('movers', Movers.fromJson),
      staff: list('staff', StaffRow.fromJson),
      dues: section('dues', DuesSection.fromJson),
      expenses: section('expenses', ExpensesSection.fromJson),
      purchases: section('purchases', PurchasesSection.fromJson),
      stock: section('stock', StockSection.fromJson),
      shifts: list('shifts', ShiftRow.fromJson),
    );
  }
}
