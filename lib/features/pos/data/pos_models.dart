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

/// Kept nullable on purpose. The same endpoint returns **less** to a weaker
/// role: a cashier's `purchasePrice` arrives as `null`, not as zero, and
/// `loyaltyPoints` is `null` without `customers.points.view`. Collapsing those
/// to 0 would show a cashier a cost of nothing rather than no cost at all.
num? _numOrNull(Object? v) => v == null ? null : _num(v);

String _str(Object? v) => v?.toString() ?? '';

String? _strOrNull(Object? v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

bool _bool(Object? v) => v == true || v == 1 || v == 'true';

/// A payment account from `lookups.accounts` — Cash Drawer, bKash, a bank.
///
/// Sending `accountId` with a payment is what makes the money land in that
/// account's balance, so the app always picks one.
class PosAccount {
  const PosAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.isDefault,
  });

  final int id;
  final String name;

  /// `cash`, `bank`, `mobile`, ... Used to guess a sensible payment method.
  final String type;
  final bool isDefault;

  factory PosAccount.fromJson(Map<String, dynamic> json) => PosAccount(
        id: _int(json['id']),
        name: _str(json['name']),
        type: _str(json['type']),
        isDefault: _bool(json['isDefault']),
      );
}

/// A customer as the POS knows one — from `lookups.customers` or
/// `GET /customers/search`.
class PosCustomer {
  const PosCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.isWalkIn = false,
    this.creditLimit,
    this.loyaltyPoints,
    this.due,
  });

  final int id;
  final String name;
  final String? phone;

  /// Walk-in customers cannot buy on credit — the server refuses, and so does
  /// the checkout button.
  final bool isWalkIn;

  final num? creditLimit;

  /// Null without `customers.points.view`. Not zero: unknown.
  final num? loyaltyPoints;
  final num? due;

  factory PosCustomer.fromJson(Map<String, dynamic> json) => PosCustomer(
        id: _int(json['id']),
        name: _str(json['name']),
        phone: _strOrNull(json['phone']),
        isWalkIn: _bool(json['isWalkIn']),
        creditLimit: _numOrNull(json['creditLimit']),
        loyaltyPoints: _numOrNull(json['loyaltyPoints']),
        due: _numOrNull(json['due']),
      );
}

/// A cart somebody put aside. The server does not read `cart`; it stores the
/// JSON and gives it back.
class HeldCart {
  const HeldCart({required this.id, required this.label, this.createdAt});

  final int id;
  final String label;
  final DateTime? createdAt;

  factory HeldCart.fromJson(Map<String, dynamic> json) => HeldCart(
        id: _int(json['id']),
        label: _str(json['label']),
        createdAt: AppDates.parse(json['createdAt']),
      );
}

/// An open cash drawer. `lookups.shift` is null when none is open — and a sale
/// still goes through without one, it is simply counted in no drawer.
class PosShift {
  const PosShift({
    required this.id,
    required this.openingCash,
    this.openedAt,
  });

  final int id;
  final num openingCash;
  final DateTime? openedAt;

  factory PosShift.fromJson(Map<String, dynamic> json) => PosShift(
        id: _int(json['id']),
        openingCash: _num(json['openingCash']),
        openedAt: AppDates.parse(json['openedAt']),
      );
}

/// What `POST /pos/shift/close` answers with.
class ShiftClosing {
  const ShiftClosing({
    required this.expected,
    required this.counted,
    required this.difference,
  });

  final num expected;
  final num counted;

  /// Negative is short, positive is over. Shown as the server computed it.
  final num difference;

  factory ShiftClosing.fromJson(Map<String, dynamic> json) => ShiftClosing(
        expected: _num(json['expected']),
        counted: _num(json['counted']),
        difference: _num(json['difference']),
      );
}

/// One day of a drawer's takings.
class ShiftDay {
  const ShiftDay({
    required this.invoices,
    required this.sold,
    required this.cash,
    required this.digital,
    required this.dueGiven,
    required this.collected,
    this.date,
  });

  /// `YYYY-MM-DD`, or null on the totals row.
  final String? date;
  final int invoices;
  final num sold;

  /// Taken at this counter, by how it was paid. Points are left out: nothing
  /// was handed over for them.
  final num cash;
  final num digital;

  /// Put on the khata — what went out unpaid.
  final num dueGiven;

  /// Money that arrived after its bill rather than with it: dues collected,
  /// counted by when the money came in, not by which shift wrote the bill.
  final num collected;

  factory ShiftDay.fromJson(Map<String, dynamic> json) => ShiftDay(
        date: _strOrNull(json['date']),
        invoices: _int(json['invoices']),
        sold: _num(json['sold']),
        cash: _num(json['cash']),
        digital: _num(json['digital']),
        dueGiven: _num(json['dueGiven']),
        collected: _num(json['collected']),
      );
}

/// `GET /pos/shift/report` — the drawer's report, a day at a time.
///
/// A shift is not a day: a drawer opened on Monday and never closed holds a
/// week, so the window is the shift and the rows are days, newest first. With
/// no drawer open it answers for today with [shiftId] null, which is still
/// worth showing to a cashier about to open one.
class ShiftReport {
  const ShiftReport({
    required this.openingCash,
    required this.cashTaken,
    required this.expected,
    required this.days,
    required this.totals,
    this.shiftId,
    this.openedAt,
  });

  final int? shiftId;
  final DateTime? openedAt;
  final num openingCash;
  final num cashTaken;

  /// `openingCash + cashTaken` — the same arithmetic, from the same query, as
  /// `POST /pos/shift/close`, so the two cannot disagree. Cash paid *out* of
  /// the drawer as an expense is not taken off it.
  final num expected;
  final List<ShiftDay> days;
  final ShiftDay totals;

  factory ShiftReport.fromJson(Map<String, dynamic> json) {
    final shift = json['shift'];
    return ShiftReport(
      shiftId: shift is Map<String, dynamic> ? _intOrNull(shift['id']) : null,
      openedAt:
          shift is Map<String, dynamic> ? AppDates.parse(shift['openedAt']) : null,
      openingCash: _num(json['openingCash']),
      cashTaken: _num(json['cashTaken']),
      expected: _num(json['expected']),
      days: _listOf(json['days'], ShiftDay.fromJson),
      totals: ShiftDay.fromJson(
        json['totals'] is Map<String, dynamic>
            ? json['totals'] as Map<String, dynamic>
            : const {},
      ),
    );
  }
}

/// The store's loyalty settings, straight out of `lookups.loyalty`.
///
/// These keys are snake_case in the response — one of the few places besides
/// `/me` where that happens — so they are read literally rather than through a
/// convention.
class LoyaltyConfig {
  const LoyaltyConfig({
    required this.enabled,
    required this.earnPer,
    required this.earnPoints,
    required this.valuePer,
    required this.minRedeem,
    required this.maxRedeemPct,
    required this.round,
    required this.mayRedeem,
  });

  const LoyaltyConfig.off()
      : enabled = false,
        earnPer = 0,
        earnPoints = 0,
        valuePer = 0,
        minRedeem = 0,
        maxRedeemPct = 0,
        round = 'down',
        mayRedeem = false;

  final bool enabled;
  final num earnPer;
  final num earnPoints;

  /// What one point is worth in money.
  final num valuePer;
  final num minRedeem;
  final num maxRedeemPct;
  final String round;

  /// The endpoint's own say on redeeming, on top of `pos.sale.redeem_points`.
  final bool mayRedeem;

  factory LoyaltyConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LoyaltyConfig.off();
    return LoyaltyConfig(
      enabled: _bool(json['loyalty_enabled']),
      earnPer: _num(json['loyalty_earn_per']),
      earnPoints: _num(json['loyalty_earn_points']),
      valuePer: _num(json['loyalty_value_per']),
      minRedeem: _num(json['loyalty_min_redeem']),
      maxRedeemPct: _num(json['loyalty_max_redeem_pct']),
      round: _str(json['loyalty_round']),
      mayRedeem: _bool(json['mayRedeem']),
    );
  }

  /// What redeeming [points] is worth off the bill. The server caps the real
  /// figure; this is only what the sheet shows while the person is deciding.
  num worthOf(num points) => points * valuePer;

  /// The most that may be redeemed against a bill of [total], by both rules.
  num capFor(num total, num balance) {
    if (!enabled || valuePer <= 0) return 0;
    final byPercent = (total * maxRedeemPct / 100) / valuePer;
    final cap = balance < byPercent ? balance : byPercent;
    return cap < 0 ? 0 : cap.floorToDouble();
  }
}

/// Everything `GET /pos/lookups` hands the till when it opens.
class PosLookups {
  const PosLookups({
    required this.accounts,
    required this.customers,
    required this.held,
    required this.shift,
    required this.vatInclusive,
    required this.allowCredit,
    required this.loyalty,
  });

  final List<PosAccount> accounts;

  /// The first 200. Beyond that the counter searches.
  final List<PosCustomer> customers;
  final List<HeldCart> held;

  /// Null when no drawer is open.
  final PosShift? shift;

  final bool vatInclusive;

  /// False turns the whole idea of leaving a due off for this store.
  final bool allowCredit;

  final LoyaltyConfig loyalty;

  bool get hasOpenShift => shift != null;

  PosAccount? get defaultAccount {
    if (accounts.isEmpty) return null;
    return accounts.firstWhere(
      (a) => a.isDefault,
      orElse: () => accounts.first,
    );
  }

  /// The walk-in customer, which every store has. Selling to nobody in
  /// particular means selling to this one.
  PosCustomer? get walkIn {
    for (final c in customers) {
      if (c.isWalkIn) return c;
    }
    return null;
  }

  factory PosLookups.fromJson(Map<String, dynamic> json) => PosLookups(
        accounts: _listOf(json['accounts'], PosAccount.fromJson),
        customers: _listOf(json['customers'], PosCustomer.fromJson),
        held: _listOf(json['held'], HeldCart.fromJson),
        shift: json['shift'] is Map<String, dynamic>
            ? PosShift.fromJson(json['shift'] as Map<String, dynamic>)
            : null,
        vatInclusive: _bool(json['vatInclusive']),
        allowCredit: _bool(json['allowCredit']),
        loyalty: LoyaltyConfig.fromJson(
          json['loyalty'] as Map<String, dynamic>?,
        ),
      );
}

/// A sellable line: either a store product or a package.
///
/// One type for both, because a cart line does not care which it is — only
/// `checkout` does, and it sends either `storeProductId` or `packageId`.
class SellableItem {
  const SellableItem({
    required this.id,
    required this.name,
    required this.salePrice,
    required this.isPackage,
    this.barcode,
    this.unit,
    this.brand,
    this.vatPercent = 0,
    this.stock,
    this.purchasePrice,
    this.minimumStock,
    this.trackBatch = false,
  });

  final int id;
  final String name;
  final num salePrice;

  /// Decides which key checkout sends, and which badge the row wears.
  final bool isPackage;

  final String? barcode;
  final String? unit;
  final String? brand;
  final num vatPercent;

  /// This branch's stock, or for a package how many can be built from it.
  final num? stock;

  /// Null without `inventory.product.view_cost`. A cashier never sees it.
  final num? purchasePrice;

  final num? minimumStock;
  final bool trackBatch;

  bool get isLow =>
      stock != null && minimumStock != null && stock! <= minimumStock!;

  factory SellableItem.fromProduct(Map<String, dynamic> json) => SellableItem(
        id: _int(json['id']),
        name: _str(json['name']),
        salePrice: _num(json['salePrice']),
        isPackage: false,
        barcode: _strOrNull(json['barcode']),
        unit: _strOrNull(json['unit']),
        brand: _strOrNull(json['brand']),
        vatPercent: _num(json['vatPercent']),
        stock: _numOrNull(json['stock']),
        purchasePrice: _numOrNull(json['purchasePrice']),
        minimumStock: _numOrNull(json['minimumStock']),
        trackBatch: _bool(json['trackBatch']),
      );

  /// A sellable package. `buildable` is how many can be made from this
  /// branch's stock, which is exactly the meaning `stock` carries for a
  /// product, so it lands in the same field.
  factory SellableItem.fromPackage(Map<String, dynamic> json) => SellableItem(
        id: _int(json['id']),
        name: _str(json['name']),
        salePrice: _num(json['price']),
        isPackage: true,
        barcode: _strOrNull(json['barcode']),
        unit: null,
        brand: null,
        vatPercent: _num(json['vatPercent']),
        stock: _numOrNull(json['buildable']),
      );
}

/// What `POST /pos/checkout` answers with — and the only totals worth showing.
///
/// The server works out prices, VAT and totals. The app's own running subtotal
/// is a preview; **this** is the sale.
class CheckoutResult {
  const CheckoutResult({
    required this.saleId,
    required this.invoiceNo,
    required this.total,
    required this.paid,
    required this.due,
    required this.paymentStatus,
    this.pointsEarned,
    this.pointsRedeemed,
    this.previousDue,
    this.outstanding,
  });

  final int saleId;
  final String invoiceNo;
  final num total;
  final num paid;
  final num due;

  /// `paid`, `partial` or `unpaid`.
  final String paymentStatus;

  /// Server-capped — often less than the app asked to redeem, which is why the
  /// success sheet shows it rather than the requested figure.
  final num? pointsEarned;
  final num? pointsRedeemed;

  /// What the customer owed before this bill — a record, not a charge.
  final num? previousDue;

  /// Everything they owe now that this bill and any payment have both landed.
  /// It is what the next bill will print as its previous due.
  final num? outstanding;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) => CheckoutResult(
        saleId: _int(json['saleId']),
        invoiceNo: _str(json['invoiceNo']),
        total: _num(json['total']),
        paid: _num(json['paid']),
        due: _num(json['due']),
        paymentStatus: _str(json['paymentStatus']),
        pointsEarned: _numOrNull(json['pointsEarned']),
        pointsRedeemed: _numOrNull(json['pointsRedeemed']),
        previousDue: _numOrNull(json['previousDue']),
        outstanding: _numOrNull(json['outstanding']),
      );
}

/// The result of `POST /customers/quick`, which answers `200` with
/// `created: false` when the phone already belongs to somebody.
class QuickCustomer {
  const QuickCustomer({
    required this.id,
    required this.name,
    required this.created,
    this.phone,
  });

  final int id;
  final String name;
  final String? phone;

  /// False means this phone was already on file and that customer came back —
  /// not an error, and worth saying so rather than silently attaching a
  /// stranger's ledger to the sale.
  final bool created;

  factory QuickCustomer.fromJson(Map<String, dynamic> json) => QuickCustomer(
        id: _int(json['id']),
        name: _str(json['name']),
        phone: _strOrNull(json['phone']),
        created: _bool(json['created']),
      );

  PosCustomer toCustomer() =>
      PosCustomer(id: id, name: name, phone: phone);
}

/// The six methods the API accepts.
///
/// `credit` and `points` are deliberately absent: a due is made by paying
/// *less*, and points go in `redeemPoints`. Sending either as a method is a
/// `422`.
enum PayMethod {
  cash('cash'),
  card('card'),
  bkash('bkash'),
  nagad('nagad'),
  rocket('rocket'),
  bank('bank');

  const PayMethod(this.wire);

  final String wire;

  static PayMethod fromWire(String value) => PayMethod.values.firstWhere(
        (m) => m.wire == value,
        orElse: () => PayMethod.cash,
      );

  /// A guess from the account's own type, so picking "bKash" as the account
  /// does not then need the method picked again.
  static PayMethod forAccount(PosAccount account) {
    final name = account.name.toLowerCase();
    for (final m in [
      PayMethod.bkash,
      PayMethod.nagad,
      PayMethod.rocket,
    ]) {
      if (name.contains(m.wire)) return m;
    }
    return switch (account.type.toLowerCase()) {
      'cash' => PayMethod.cash,
      'bank' => PayMethod.bank,
      'card' => PayMethod.card,
      _ => PayMethod.cash,
    };
  }
}

List<T> _listOf<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(parse).toList();
}

/// Shared by the models above so each file does not grow its own copy.
int? parseIdOrNull(Object? v) => _intOrNull(v);
