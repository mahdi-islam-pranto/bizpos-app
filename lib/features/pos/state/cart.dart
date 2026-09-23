import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/session/session_controller.dart';
import '../data/pos_models.dart';

/// One line in the cart.
///
/// [unitPrice] and [lineDiscount] are held as overrides rather than as the
/// price. Without `pos.sale.change_price` or `pos.sale.give_discount` the
/// server **ignores** those fields, so the app must not pretend they took
/// effect — if the permission is missing they are never set, never sent, and
/// never shown.
class CartLine {
  const CartLine({
    required this.item,
    required this.qty,
    this.unitPrice,
    this.lineDiscount,
  });

  final SellableItem item;
  final num qty;

  /// Set only with `pos.sale.change_price`.
  final num? unitPrice;

  /// Set only with `pos.sale.give_discount`. Money off this line.
  final num? lineDiscount;

  /// What this line is charged at, as far as the app can tell.
  num get effectivePrice => unitPrice ?? item.salePrice;

  /// A preview only — the server computes the real figure, including VAT.
  Decimal get subtotal {
    final gross = Exact.of(effectivePrice) * Exact.of(qty);
    final off = Exact.of(lineDiscount ?? 0);
    final net = gross - off;
    return net < Decimal.zero ? Decimal.zero : net;
  }

  bool get overStock => item.stock != null && qty > item.stock!;

  /// What one unit goes out at once its own discount is off.
  Decimal get netUnitPrice {
    if (qty <= 0) return Decimal.zero;
    return (subtotal / Exact.of(qty)).toDecimal(scaleOnInfinitePrecision: 6);
  }

  /// The server refuses a line whose price, after its own discount, is under
  /// the product's cost. Only knowable when the cost came down with the item —
  /// which it does not for a cashier without `inventory.product.view_cost`, and
  /// never for a package, whose price is judged across its products.
  bool get belowCost {
    final cost = item.purchasePrice;
    if (cost == null || cost <= 0 || item.isPackage) return false;
    return netUnitPrice < Exact.of(cost);
  }

  /// This line's known cost, or null when the cost is hidden.
  Decimal? get knownCost {
    final cost = item.purchasePrice;
    if (cost == null || cost <= 0 || item.isPackage) return null;
    return Exact.of(cost) * Exact.of(qty);
  }

  /// Lines are identified by what they are, not by position: scanning the same
  /// barcode twice adds one to the line that already exists.
  String get key => '${item.isPackage ? 'pkg' : 'sp'}:${item.id}';

  CartLine copyWith({
    num? qty,
    num? unitPrice,
    num? lineDiscount,
    bool clearUnitPrice = false,
    bool clearDiscount = false,
  }) =>
      CartLine(
        item: item,
        qty: qty ?? this.qty,
        unitPrice: clearUnitPrice ? null : (unitPrice ?? this.unitPrice),
        lineDiscount: clearDiscount ? null : (lineDiscount ?? this.lineDiscount),
      );

  /// What `POST /pos/checkout` gets. Either `storeProductId` **or**
  /// `packageId`, never both.
  Map<String, dynamic> toCheckoutLine({
    required bool mayChangePrice,
    required bool mayDiscount,
  }) =>
      {
        if (item.isPackage) 'packageId': item.id else 'storeProductId': item.id,
        'qty': qty,
        if (mayChangePrice && unitPrice != null) 'unitPrice': unitPrice,
        if (mayDiscount && lineDiscount != null && lineDiscount! > 0)
          'discount': lineDiscount,
      };

  /// Held carts round-trip through the server untouched, so the app owns this
  /// shape completely.
  Map<String, dynamic> toHoldJson() => {
        'id': item.id,
        'isPackage': item.isPackage,
        'name': item.name,
        'salePrice': item.salePrice,
        'unit': item.unit,
        'barcode': item.barcode,
        'vatPercent': item.vatPercent,
        'stock': item.stock,
        'purchasePrice': item.purchasePrice,
        'qty': qty,
        'unitPrice': unitPrice,
        'lineDiscount': lineDiscount,
      };

  static CartLine? fromHoldJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = parseIdOrNull(raw['id']);
    if (id == null || id == 0) return null;
    return CartLine(
      item: SellableItem(
        id: id,
        name: raw['name']?.toString() ?? '',
        salePrice: (raw['salePrice'] as num?) ?? 0,
        isPackage: raw['isPackage'] == true,
        unit: raw['unit'] as String?,
        barcode: raw['barcode'] as String?,
        vatPercent: (raw['vatPercent'] as num?) ?? 0,
        stock: raw['stock'] as num?,
        purchasePrice: raw['purchasePrice'] as num?,
      ),
      qty: (raw['qty'] as num?) ?? 1,
      unitPrice: raw['unitPrice'] as num?,
      lineDiscount: raw['lineDiscount'] as num?,
    );
  }
}

/// A payment the cashier has entered. Several make a split payment.
class CartPayment {
  const CartPayment({
    required this.method,
    required this.amount,
    this.accountId,
    this.reference,
  });

  final PayMethod method;
  final num amount;

  /// From `lookups.accounts`, so the money lands in that account's balance.
  final int? accountId;

  /// A bKash transaction id, a card slip number.
  final String? reference;

  Map<String, dynamic> toJson() => {
        'method': method.wire,
        'amount': amount,
        if (accountId != null) 'accountId': accountId,
        if (reference != null && reference!.isNotEmpty) 'reference': reference,
      };
}

/// The whole till, as one immutable value.
class Cart {
  const Cart({
    this.lines = const [],
    this.customer,
    this.orderDiscountPercent,
    this.redeemPoints = 0,
    this.note,
  });

  final List<CartLine> lines;

  /// Null means the walk-in customer is implied. Anything left due, or any
  /// points at all, needs a named one.
  final PosCustomer? customer;

  /// Set only with `pos.sale.give_discount`. A **rate** off the whole bill,
  /// 0–100, and what the till sends as `orderDiscountPercent`: "ten percent
  /// off" survives the basket changing under it, a flat figure does not. The
  /// server works the taka out off the goods total after the line discounts,
  /// which is exactly what [orderDiscountAmount] previews.
  final num? orderDiscountPercent;

  final num redeemPoints;
  final String? note;

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;
  int get lineCount => lines.length;

  num get itemCount =>
      lines.fold<num>(0, (sum, line) => sum + line.qty);

  /// The running total the cashier watches while ringing items up.
  ///
  /// **Not the sale.** VAT, store rules and any server-side rounding are not in
  /// here; `POST /pos/checkout` returns the real total and that is the one the
  /// receipt shows. This exists so the number on screen while deciding is at
  /// least exact arithmetic rather than floating-point drift.
  Decimal get linesTotal =>
      Exact.sum(lines.map((line) => line.subtotal));

  /// The taka the bill rate comes to, off [linesTotal], to the paisa.
  Decimal get orderDiscountAmount {
    final rate = orderDiscountPercent ?? 0;
    if (rate <= 0) return Decimal.zero;
    return Exact.paisa((linesTotal * Exact.of(rate)).shift(-2));
  }

  Decimal get estimatedTotal {
    final afterOrder = linesTotal - orderDiscountAmount;
    return afterOrder < Decimal.zero ? Decimal.zero : afterOrder;
  }

  bool get hasOverStockLine => lines.any((line) => line.overStock);

  /// "Nothing goes out below what it cost." The server refuses the sale when a
  /// line is under its cost, or when the bill discount takes the whole basket
  /// under the cost of its goods — so the till disables its own pay button
  /// rather than take money and then be refused. Lines whose cost is hidden
  /// are left to the server; there is nothing here to compare them against.
  bool get hasBelowCostLine => lines.any((line) => line.belowCost);

  bool get discountBelowCost {
    if ((orderDiscountPercent ?? 0) <= 0) return false;
    final costs = [for (final line in lines) line.knownCost];
    // Only a basket whose every cost is known can be judged as a whole.
    if (costs.isEmpty || costs.any((c) => c == null)) return false;
    return estimatedTotal < Exact.sum(costs.whereType<Decimal>());
  }

  bool get belowCost => hasBelowCostLine || discountBelowCost;

  /// A named customer, not the walk-in one. Credit and points both need this.
  bool get hasNamedCustomer =>
      customer != null && !customer!.isWalkIn;

  CartLine? lineFor(SellableItem item) {
    final key = '${item.isPackage ? 'pkg' : 'sp'}:${item.id}';
    for (final line in lines) {
      if (line.key == key) return line;
    }
    return null;
  }

  Cart copyWith({
    List<CartLine>? lines,
    PosCustomer? customer,
    num? orderDiscountPercent,
    num? redeemPoints,
    String? note,
    bool clearCustomer = false,
    bool clearOrderDiscount = false,
  }) =>
      Cart(
        lines: lines ?? this.lines,
        customer: clearCustomer ? null : (customer ?? this.customer),
        orderDiscountPercent: clearOrderDiscount
            ? null
            : (orderDiscountPercent ?? this.orderDiscountPercent),
        redeemPoints: redeemPoints ?? this.redeemPoints,
        note: note ?? this.note,
      );

  /// The body of `POST /pos/checkout`.
  ///
  /// Every permission-sensitive field is decided here rather than in the sheet,
  /// because the rules are easy to state and easy to get wrong:
  ///
  /// * `unitPrice`, line `discount` and `orderDiscountPercent` are **silently
  ///   ignored** without `pos.sale.change_price` / `pos.sale.give_discount`. Sending them
  ///   anyway is not an error — it is worse, because the response comes back
  ///   without them and nothing says why.
  /// * `customerId` goes only for a **named** customer. The walk-in one means
  ///   nobody in particular, and it cannot hold a due or points.
  /// * Each line carries `storeProductId` **or** `packageId`, never both.
  /// * `credit` and `points` never appear as payment methods: a due is paying
  ///   less, and points go in `redeemPoints`. Nothing paid at all is
  ///   `payments: []` with a named customer — the whole bill onto the khata.
  /// * `collectPrevious` asks for the customer's old debt along with today's
  ///   goods: tender past this bill then settles older debts, oldest first,
  ///   where without it the same over-tender is change. It means nothing
  ///   without a named customer, so it never travels without one.
  Map<String, dynamic> toCheckoutBody({
    required bool mayChangePrice,
    required bool mayDiscount,
    required List<CartPayment> payments,
    bool collectPrevious = false,
  }) =>
      {
        if (hasNamedCustomer) 'customerId': customer!.id,
        'lines': [
          for (final line in lines)
            line.toCheckoutLine(
              mayChangePrice: mayChangePrice,
              mayDiscount: mayDiscount,
            ),
        ],
        'payments': [
          for (final payment in payments)
            if (payment.amount > 0) payment.toJson(),
        ],
        if (mayDiscount && (orderDiscountPercent ?? 0) > 0)
          'orderDiscountPercent': orderDiscountPercent,
        if (redeemPoints > 0) 'redeemPoints': redeemPoints,
        if (collectPrevious && hasNamedCustomer) 'collectPrevious': true,
        if ((note ?? '').isNotEmpty) 'note': note,
      };

  Map<String, dynamic> toHoldJson() => {
        'v': 2,
        'lines': [for (final line in lines) line.toHoldJson()],
        if (customer != null)
          'customer': {
            'id': customer!.id,
            'name': customer!.name,
            'phone': customer!.phone,
            'isWalkIn': customer!.isWalkIn,
          },
        'orderDiscountPercent': orderDiscountPercent,
        'redeemPoints': redeemPoints,
        'note': note,
      };

  /// Rebuilds a held cart. Anything unreadable is dropped rather than throwing:
  /// a hold from an older build of the app should still bring back the lines it
  /// can, not fail the resume outright.
  static Cart fromHoldJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    final lines = <CartLine>[];
    if (rawLines is List) {
      for (final raw in rawLines) {
        final line = CartLine.fromHoldJson(raw);
        if (line != null) lines.add(line);
      }
    }
    final rawCustomer = json['customer'];
    return Cart(
      lines: lines,
      customer: rawCustomer is Map<String, dynamic>
          ? PosCustomer.fromJson(rawCustomer)
          : null,
      orderDiscountPercent: _holdRate(json, lines),
      redeemPoints: (json['redeemPoints'] as num?) ?? 0,
      note: json['note'] as String?,
    );
  }
}

/// The bill rate a hold carries. A hold from before the till sent rates holds
/// a flat `orderDiscount` instead; it comes back as the rate that figure was of
/// the goods it was given against, rather than being dropped.
num? _holdRate(Map<String, dynamic> json, List<CartLine> lines) {
  final rate = json['orderDiscountPercent'];
  if (rate is num) return rate;
  final flat = json['orderDiscount'];
  if (flat is! num || flat <= 0) return null;
  final goods = Exact.sum(lines.map((line) => line.subtotal));
  if (goods <= Decimal.zero) return null;
  final asRate = (Exact.of(flat) * Decimal.fromInt(100) / goods)
      .toDecimal(scaleOnInfinitePrecision: 4);
  final value = asRate.round(scale: 2).toDouble();
  return value > 100 ? 100 : value;
}

/// The cart, as a Riverpod notifier.
///
/// Deliberately **not** scope-keyed by hand: it is `autoDispose`-free and lives
/// as long as the POS screen's provider scope, and the screen itself is rebuilt
/// by the session scope above it. A cart carried across a branch switch would
/// hold product ids that answer 404 in the new branch.
class CartController extends Notifier<Cart> {
  @override
  Cart build() {
    // A store or branch switch empties the till. The ids in it belong to the
    // other store, where they are not "forbidden" — they simply do not exist.
    ref.watch(scopeKeyProvider);
    return const Cart();
  }

  /// Adds one, or bumps the line that is already there. Scanning the same
  /// barcode five times makes one line of five, not five lines of one.
  void add(SellableItem item, {num qty = 1}) {
    final existing = state.lineFor(item);
    if (existing == null) {
      state = state.copyWith(
        lines: [...state.lines, CartLine(item: item, qty: qty)],
      );
      return;
    }
    setQty(existing.key, existing.qty + qty);
  }

  void setQty(String key, num qty) {
    if (qty <= 0) {
      remove(key);
      return;
    }
    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.key == key) line.copyWith(qty: qty) else line,
      ],
    );
  }

  void remove(String key) => state = state.copyWith(
        lines: state.lines.where((line) => line.key != key).toList(),
      );

  /// Only reachable with `pos.sale.change_price`; the UI never offers it
  /// otherwise, because the server would ignore the field and the cashier would
  /// watch a price they typed fail to appear on the receipt.
  void setUnitPrice(String key, num? price) => state = state.copyWith(
        lines: [
          for (final line in state.lines)
            if (line.key == key)
              line.copyWith(unitPrice: price, clearUnitPrice: price == null)
            else
              line,
        ],
      );

  /// Only reachable with `pos.sale.give_discount`.
  void setLineDiscount(String key, num? discount) => state = state.copyWith(
        lines: [
          for (final line in state.lines)
            if (line.key == key)
              line.copyWith(
                lineDiscount: discount,
                clearDiscount: discount == null,
              )
            else
              line,
        ],
      );

  /// A rate, clamped to 0–100. Null or zero removes it.
  void setOrderDiscountPercent(num? rate) {
    if (rate == null || rate <= 0) {
      state = state.copyWith(clearOrderDiscount: true);
      return;
    }
    state = state.copyWith(orderDiscountPercent: rate > 100 ? 100 : rate);
  }

  void setCustomer(PosCustomer? customer) {
    if (customer == null) {
      // Points only exist against a named customer, so dropping the customer
      // drops the redemption with it rather than leaving a `422` waiting at
      // checkout.
      state = state.copyWith(clearCustomer: true, redeemPoints: 0);
      return;
    }
    state = state.copyWith(customer: customer);
  }

  void setRedeemPoints(num points) =>
      state = state.copyWith(redeemPoints: points < 0 ? 0 : points);

  void setNote(String? note) => state = state.copyWith(note: note ?? '');

  void replace(Cart cart) => state = cart;

  void clear() => state = const Cart();
}

final cartProvider = NotifierProvider<CartController, Cart>(CartController.new);
