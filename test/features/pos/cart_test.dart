import 'package:bizpos_app/features/pos/data/pos_models.dart';
import 'package:bizpos_app/features/pos/state/cart.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rules the till has to get right before anything is sent.
///
/// These are the invariants from `docs/MOBILE-API-NEW.md` sections 5.1 and
/// 6 that produce no error when broken — the server simply ignores a field, or
/// charges a different number — which is exactly the kind of bug a test has to
/// catch because a person at a counter will not.
void main() {
  SellableItem product(
    int id, {
    num price = 1.2,
    num? stock = 100,
    num? cost,
  }) =>
      SellableItem(
        id: id,
        name: 'Napa 500mg',
        salePrice: price,
        isPackage: false,
        barcode: '894110050001$id',
        stock: stock,
        purchasePrice: cost,
      );

  SellableItem package(int id, {num price = 250}) => SellableItem(
        id: id,
        name: 'Cold pack',
        salePrice: price,
        isPackage: true,
      );

  group('the cart adds up exactly', () {
    test('1.2 x 10 is 12, not 11.999999999999998', () {
      final cart = Cart(lines: [CartLine(item: product(42), qty: 10)]);

      // The whole reason `decimal` is a dependency: in binary floating point
      // this subtotal is 11.999999999999998, and a cashier reading it next to
      // a receipt that says 12 has no way to tell which is wrong.
      expect(cart.linesTotal.toString(), '12');
      expect(cart.linesTotal.toDouble(), 12.0);
    });

    test('a line discount comes off before the total', () {
      final cart = Cart(
        lines: [CartLine(item: product(42, price: 100), qty: 2, lineDiscount: 30)],
      );

      expect(cart.linesTotal.toDouble(), 170);
    });

    test('a discount larger than the line does not make the line negative', () {
      final cart = Cart(
        lines: [CartLine(item: product(42, price: 10), qty: 1, lineDiscount: 50)],
      );

      expect(cart.linesTotal.toDouble(), 0);
    });

    test('the bill rate comes off the goods after line discounts', () {
      // 2 x 100 less 30 off the line is 170; ten percent of that is 17. The
      // server works the taka out the same way, so the preview matches.
      final cart = Cart(
        lines: [
          CartLine(item: product(42, price: 100), qty: 2, lineDiscount: 30),
        ],
        orderDiscountPercent: 10,
      );

      expect(cart.orderDiscountAmount.toDouble(), 17);
      expect(cart.estimatedTotal.toDouble(), 153);
    });

    test('a rate survives the basket changing under it', () {
      final controller = Cart(
        lines: [CartLine(item: product(42, price: 100), qty: 1)],
        orderDiscountPercent: 10,
      );
      final bigger = controller.copyWith(
        lines: [CartLine(item: product(42, price: 100), qty: 3)],
      );

      expect(controller.orderDiscountAmount.toDouble(), 10);
      expect(bigger.orderDiscountAmount.toDouble(), 30);
    });

    test('the rate is rounded to the paisa', () {
      final cart = Cart(
        lines: [CartLine(item: product(42, price: 33.33), qty: 1)],
        orderDiscountPercent: 7,
      );

      // 7% of 33.33 is 2.3331.
      expect(cart.orderDiscountAmount.toString(), '2.33');
    });
  });

  group('nothing goes out below what it cost', () {
    test('a line discounted under its cost is caught', () {
      final cart = Cart(
        lines: [
          CartLine(
            item: product(42, price: 10, cost: 8),
            qty: 2,
            lineDiscount: 5,
          ),
        ],
      );

      // 20 less 5 is 7.50 each, under the 8 it cost.
      expect(cart.lines.single.belowCost, isTrue);
      expect(cart.belowCost, isTrue);
    });

    test('a price typed over the shelf price is judged too', () {
      final cart = Cart(
        lines: [
          CartLine(item: product(42, price: 10, cost: 8), qty: 1, unitPrice: 7),
        ],
      );

      expect(cart.belowCost, isTrue);
    });

    test('a bill discount that takes the basket under cost is caught', () {
      final cart = Cart(
        lines: [CartLine(item: product(42, price: 10, cost: 9), qty: 10)],
        orderDiscountPercent: 15,
      );

      // No single line is under cost; the bill as a whole is (85 < 90).
      expect(cart.hasBelowCostLine, isFalse);
      expect(cart.discountBelowCost, isTrue);
    });

    test('a hidden cost is left to the server', () {
      // A cashier's search result carries no cost. There is nothing to compare
      // against, and blocking on a guess would stop honest sales.
      final cart = Cart(
        lines: [CartLine(item: product(42, price: 10), qty: 1, unitPrice: 1)],
        orderDiscountPercent: 90,
      );

      expect(cart.belowCost, isFalse);
    });

    test('a package is never judged line by line', () {
      final cart = Cart(
        lines: [
          CartLine(
            item: const SellableItem(
              id: 3,
              name: 'Cold pack',
              salePrice: 100,
              isPackage: true,
              purchasePrice: 500,
            ),
            qty: 1,
          ),
        ],
      );

      expect(cart.belowCost, isFalse);
    });
  });

  group('scanning the same thing twice', () {
    test('bumps the line that exists rather than making a second one', () {
      var cart = const Cart();
      final napa = product(42);

      // What a scanner actually does: the same barcode, three times.
      for (var i = 0; i < 3; i++) {
        final existing = cart.lineFor(napa);
        cart = existing == null
            ? cart.copyWith(lines: [...cart.lines, CartLine(item: napa, qty: 1)])
            : cart.copyWith(
                lines: [
                  for (final line in cart.lines)
                    if (line.key == existing.key)
                      line.copyWith(qty: line.qty + 1)
                    else
                      line,
                ],
              );
      }

      expect(cart.lineCount, 1);
      expect(cart.lines.single.qty, 3);
    });

    test('a package and a product with the same id are different lines', () {
      // They are different things behind the same integer, and checkout sends
      // them under different keys — so the cart must not merge them.
      expect(
        CartLine(item: product(7), qty: 1).key,
        isNot(CartLine(item: package(7), qty: 1).key),
      );
    });
  });

  group('over-stock is flagged, never blocked', () {
    test('a line past this branch stock is marked', () {
      final cart = Cart(
        lines: [CartLine(item: product(42, stock: 4), qty: 10)],
      );

      expect(cart.hasOverStockLine, isTrue);
    });

    test('a null stock is unknown, not zero', () {
      // A response that did not say how much stock there is must not read as
      // "none left" and paint the whole cart as an oversell.
      final cart = Cart(
        lines: [CartLine(item: product(42, stock: null), qty: 999)],
      );

      expect(cart.hasOverStockLine, isFalse);
    });
  });

  group('the checkout body honours permissions', () {
    final cart = Cart(
      lines: [
        CartLine(item: product(42), qty: 2, unitPrice: 95, lineDiscount: 5),
        CartLine(item: package(3), qty: 1),
      ],
      customer: const PosCustomer(id: 12, name: 'Rahim', phone: '01711'),
      orderDiscountPercent: 10,
      redeemPoints: 50,
      note: 'Delivered',
    );

    Map<String, dynamic> body({
      required bool mayChangePrice,
      required bool mayDiscount,
    }) =>
        cart.toCheckoutBody(
          mayChangePrice: mayChangePrice,
          mayDiscount: mayDiscount,
          payments: const [
            CartPayment(method: PayMethod.cash, amount: 100, accountId: 1),
          ],
        );

    test('a cashier sends no unitPrice, no discount, no bill rate', () {
      // The server ignores all three without the permission. Sending them is
      // worse than useless: the response comes back without them and nothing
      // in it says why.
      final sent = body(mayChangePrice: false, mayDiscount: false);
      final lines = sent['lines'] as List;

      expect((lines.first as Map).containsKey('unitPrice'), isFalse);
      expect((lines.first as Map).containsKey('discount'), isFalse);
      expect(sent.containsKey('orderDiscountPercent'), isFalse);
      expect(sent.containsKey('orderDiscount'), isFalse);
    });

    test('a manager sends all three', () {
      final sent = body(mayChangePrice: true, mayDiscount: true);
      final lines = sent['lines'] as List;

      expect((lines.first as Map)['unitPrice'], 95);
      expect((lines.first as Map)['discount'], 5);
      // The till sends the rate. A flat `orderDiscount` is for imports and
      // bills settled by hand, and the rate wins if both arrive.
      expect(sent['orderDiscountPercent'], 10);
      expect(sent.containsKey('orderDiscount'), isFalse);
    });

    test('collectPrevious travels only with a named customer', () {
      final named = cart.toCheckoutBody(
        mayChangePrice: false,
        mayDiscount: false,
        payments: const [],
        collectPrevious: true,
      );
      expect(named['collectPrevious'], isTrue);

      final walkIn = Cart(lines: cart.lines).toCheckoutBody(
        mayChangePrice: false,
        mayDiscount: false,
        payments: const [],
        collectPrevious: true,
      );
      expect(walkIn.containsKey('collectPrevious'), isFalse);

      expect(body(mayChangePrice: false, mayDiscount: false)
          .containsKey('collectPrevious'), isFalse);
    });

    test('nothing paid is an empty payments list, for the khata', () {
      final sent = cart.toCheckoutBody(
        mayChangePrice: false,
        mayDiscount: false,
        payments: const [CartPayment(method: PayMethod.cash, amount: 0)],
      );

      expect(sent['payments'], isEmpty);
      expect(sent['customerId'], 12);
    });

    test('a line carries storeProductId or packageId, never both', () {
      final lines =
          body(mayChangePrice: true, mayDiscount: true)['lines'] as List;

      final productLine = lines.first as Map;
      expect(productLine['storeProductId'], 42);
      expect(productLine.containsKey('packageId'), isFalse);

      final packageLine = lines.last as Map;
      expect(packageLine['packageId'], 3);
      expect(packageLine.containsKey('storeProductId'), isFalse);
    });

    test('a named customer is sent; the walk-in one is not', () {
      expect(
        body(mayChangePrice: false, mayDiscount: false)['customerId'],
        12,
      );

      final walkIn = Cart(
        lines: cart.lines,
        customer: const PosCustomer(id: 1, name: 'Walk-in', isWalkIn: true),
      );
      expect(
        walkIn
            .toCheckoutBody(
              mayChangePrice: false,
              mayDiscount: false,
              payments: const [],
            )
            .containsKey('customerId'),
        isFalse,
      );
    });

    test('no payment is ever a credit or points method', () {
      final payments =
          body(mayChangePrice: false, mayDiscount: false)['payments'] as List;

      for (final payment in payments.cast<Map>()) {
        expect(payment['method'], isNot('credit'));
        expect(payment['method'], isNot('points'));
        expect(PayMethod.values.map((m) => m.wire), contains(payment['method']));
      }
      // Points travel in their own field instead.
      expect(
        body(mayChangePrice: false, mayDiscount: false)['redeemPoints'],
        50,
      );
    });

    test('a zero payment is dropped rather than sent', () {
      final sent = cart.toCheckoutBody(
        mayChangePrice: false,
        mayDiscount: false,
        payments: const [
          CartPayment(method: PayMethod.cash, amount: 0),
          CartPayment(method: PayMethod.bkash, amount: 50),
        ],
      );

      expect((sent['payments'] as List), hasLength(1));
    });
  });

  group('a held cart survives the round trip', () {
    test('lines, customer, discount and points all come back', () {
      final original = Cart(
        lines: [
          CartLine(item: product(42), qty: 3, unitPrice: 95, lineDiscount: 5),
          CartLine(item: package(3), qty: 1),
        ],
        customer: const PosCustomer(id: 12, name: 'Rahim', phone: '01711'),
        orderDiscountPercent: 10,
        redeemPoints: 50,
        note: 'Delivered',
      );

      // The server stores this JSON without reading it and hands the same
      // bytes back, so the app owns both ends.
      final restored = Cart.fromHoldJson(original.toHoldJson());

      expect(restored.lineCount, 2);
      expect(restored.lines.first.qty, 3);
      expect(restored.lines.first.unitPrice, 95);
      expect(restored.lines.first.item.isPackage, isFalse);
      expect(restored.lines.last.item.isPackage, isTrue);
      expect(restored.customer?.id, 12);
      expect(restored.orderDiscountPercent, 10);
      expect(restored.redeemPoints, 50);
      expect(restored.note, 'Delivered');
      expect(restored.linesTotal.toDouble(), original.linesTotal.toDouble());
    });

    test('a hold written by an older build brings back what it can', () {
      // Forgiving on purpose: losing a cart to a parse error is worse than
      // losing the one line that could not be read.
      final restored = Cart.fromHoldJson({
        'lines': [
          {'id': 42, 'name': 'Napa', 'salePrice': 1.2, 'qty': 2},
          {'name': 'no id at all'},
          'not even an object',
        ],
      });

      expect(restored.lineCount, 1);
      expect(restored.lines.single.item.id, 42);
    });

    test('a flat discount from an older hold comes back as its rate', () {
      final restored = Cart.fromHoldJson({
        'v': 1,
        'lines': [
          {'id': 42, 'name': 'Napa', 'salePrice': 100, 'qty': 2},
        ],
        'orderDiscount': 20,
      });

      // 20 off 200 was ten percent.
      expect(restored.orderDiscountPercent, 10);
      expect(restored.estimatedTotal.toDouble(), 180);
    });

    test('the cost rides along, so a resumed cart is still checked', () {
      final original = Cart(
        lines: [CartLine(item: product(42, price: 10, cost: 8), qty: 1)],
      );

      final restored = Cart.fromHoldJson(original.toHoldJson());
      expect(restored.lines.single.item.purchasePrice, 8);
    });
  });

  group('loyalty caps', () {
    const loyalty = LoyaltyConfig(
      enabled: true,
      earnPer: 100,
      earnPoints: 1,
      valuePer: 1,
      minRedeem: 50,
      maxRedeemPct: 50,
      round: 'down',
      mayRedeem: true,
    );

    test('never more than half the bill, when that is the tighter limit', () {
      // 1000 points in hand, but a 200 bill caps redemption at 100 points.
      expect(loyalty.capFor(200, 1000), 100);
    });

    test('never more than the balance', () {
      expect(loyalty.capFor(1000, 30), 30);
    });

    test('a store with loyalty off caps at nothing', () {
      expect(const LoyaltyConfig.off().capFor(1000, 1000), 0);
    });
  });
}
