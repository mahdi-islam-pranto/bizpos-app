import 'package:bizpos_app/features/pos/data/pos_models.dart';
import 'package:bizpos_app/features/pos/state/cart.dart';
import 'package:flutter_test/flutter_test.dart';

/// The printed price on the pack: what the till shows off it, and the rule
/// that nothing sells above it (`docs/MOBILE-API-NEW.md`, "Changing the price
/// in the cart", rule 5).
void main() {
  SellableItem product({
    num price = 300,
    num? mrp = 500,
    bool package = false,
  }) => SellableItem(
    id: 1,
    name: 'A Fenac SR 100',
    salePrice: price,
    isPackage: package,
    mrp: mrp,
  );

  group('the discount off the MRP', () {
    test('is a rate off the MRP: 500 sold at 300 is 40%, not 67%', () {
      expect(product().mrpDiscountPercent, 40);
    });

    test('is not shown without an MRP, at the MRP, or above it', () {
      expect(product(mrp: null).mrpDiscountPercent, isNull);
      expect(product(mrp: 0).mrpDiscountPercent, isNull);
      expect(product(price: 500).mrpDiscountPercent, isNull);
      expect(product(price: 600).mrpDiscountPercent, isNull);
    });

    test('a package has no printed price to measure against', () {
      expect(product(package: true).mrpDiscountPercent, isNull);
      expect(product(price: 600, package: true).priceAboveMrp, isFalse);
    });
  });

  group('nothing sells above the MRP', () {
    test('a shelf price over the MRP blocks the sale', () {
      final cart = Cart(lines: [CartLine(item: product(price: 600), qty: 1)]);

      expect(cart.lines.single.aboveMrp, isTrue);
      expect(cart.hasAboveMrpLine, isTrue);
      expect(cart.blocked, isTrue);
    });

    test('a price typed over the MRP blocks it too', () {
      final cart = Cart(
        lines: [CartLine(item: product(), qty: 1, unitPrice: 500.01)],
      );

      expect(cart.blocked, isTrue);
    });

    test('lowering the line to the MRP or under clears it', () {
      final atMrp = Cart(
        lines: [CartLine(item: product(price: 600), qty: 1, unitPrice: 500)],
      );

      expect(atMrp.lines.single.aboveMrp, isFalse);
      expect(atMrp.blocked, isFalse);
    });

    test('a product without an MRP is not judged', () {
      final cart = Cart(
        lines: [CartLine(item: product(price: 900, mrp: null), qty: 1)],
      );

      expect(cart.blocked, isFalse);
    });
  });
}
