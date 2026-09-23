import 'package:bizpos_app/core/network/envelope.dart';
import 'package:bizpos_app/features/customers/data/customer_models.dart';
import 'package:bizpos_app/features/pos/data/pos_models.dart';
import 'package:bizpos_app/features/products/data/product_models.dart';
import 'package:bizpos_app/features/sales/data/sale_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fields `docs/MOBILE-API-NEW.md` added to responses the app already
/// reads. Each payload is shaped like what the live server returned when this
/// was written, including its long binary-float tails.
void main() {
  group('products carry a markup', () {
    test('a stated rate and a derived one are told apart', () {
      final named = Product.fromJson({
        'id': 1,
        'name': '3 F 500',
        'purchasePrice': 140,
        'salePrice': 154.21999999999999886,
        'profitPercent': null,
        'profitRate': 10.160000000000000142,
      });
      final stated = Product.fromJson({
        'id': 2,
        'name': 'Napa',
        'purchasePrice': 80,
        'salePrice': 84,
        'profitPercent': 5,
        'profitRate': 5,
      });

      // Null is "nobody set a rate", which is not a rate of zero.
      expect(named.profitPercent, isNull);
      expect(named.profitRate, closeTo(10.16, 0.001));
      expect(stated.profitPercent, 5);
    });

    test('cost plus a rate is worked out to the paisa', () {
      expect(markupPrice(90, 5), 94.5);
      expect(markupPrice(80, 5), 84);
      // 1.1 x 1.2 in binary floating point is 1.32000000000000006.
      expect(markupPrice(1.1, 20), 1.32);
      expect(markupPrice(33.33, 7), 35.66);
    });

    test('below cost is the rule, and an unknown cost is not below it', () {
      expect(isBelowCost(cost: 10, sale: 9.99), isTrue);
      expect(isBelowCost(cost: 10, sale: 10), isFalse);
      expect(isBelowCost(cost: null, sale: 1), isFalse);
    });

    test('the lookups offer companies and units', () {
      final lookups = ProductLookups.fromJson({
        'brands': ['ACI Pharmaceuticals', 'Beximco'],
        'units': [
          {'short': 'pc', 'label': 'Piece', 'labelBn': 'পিস'},
        ],
      });

      expect(lookups.brands, hasLength(2));
      expect(lookups.units.single.short, 'pc');
      expect(lookups.units.single.labelFor('bn'), 'পিস');
    });
  });

  group('invoices carry their whole arithmetic', () {
    test('a list row reads discount, rate and previous due', () {
      final row = SaleListItem.fromJson({
        'id': 1546,
        'invoiceNo': 'INV-2026-001546',
        'subtotal': 155.0,
        'discount': 15.5,
        'discountPercent': null,
        'discountRate': 10,
        'vat': 0,
        'total': 139.5,
        'paid': 139.5,
        'due': 0,
        'previousDue': 500.0,
        'paymentStatus': 'paid',
        'status': 'completed',
        'itemCount': 3,
      });

      expect(row.subtotal, 155);
      expect(row.discount, 15.5);
      expect(row.discountPercent, isNull, reason: 'not given, so not zero');
      expect(row.discountRate, 10);
      expect(row.previousDue, 500);
    });

    test('the summary reads goods, discount and paid', () {
      final summary = SalesSummary.from(Meta({
        'summary': {
          'count': 1540,
          'goods': 2531708.1,
          'discount': 5014.95,
          'vat': 0,
          'total': 2526693.15,
          'paid': 2513888.32,
          'due': 12804.83,
        },
      }))!;

      expect(summary.goods, 2531708.1);
      expect(summary.discount, 5014.95);
      expect(summary.paid, 2513888.32);
    });

    test('a detail splits line and bill discounts, and the MRP saving', () {
      final sale = SaleDetail.fromJson({
        'id': 1,
        'invoiceNo': 'INV-1',
        'subtotal': 1000,
        'discount': 150,
        'lineDiscount': 50,
        'orderDiscount': 100,
        'discountPercent': 10,
        'mrpSaving': 200,
        'previousDue': 300,
        'vat': 0,
        'total': 850,
        'paid': 850,
        'due': 0,
        'status': 'completed',
        'paymentStatus': 'paid',
        'items': [
          {
            'id': 9,
            'name': 'Napa',
            'qty': 1,
            'unitPrice': 300,
            'mrp': 500,
            'mrpDiscount': 200,
            'mrpDiscountPercent': 40,
            'discount': 50,
            'discountPercent': 16.67,
            'total': 250,
          },
        ],
      });

      expect(sale.lineDiscount, 50);
      expect(sale.orderDiscount, 100);
      expect(sale.discountPercent, 10);
      expect(sale.mrpSaving, 200);
      expect(sale.previousDue, 300);
      final item = sale.items.single;
      // 500 sold at 300 is 40% off the printed price, not 67%.
      expect(item.mrpDiscountPercent, 40);
      expect(item.discountPercent, 16.67);
    });

    test('an invoice from before the split still reads', () {
      final sale = SaleDetail.fromJson({
        'id': 1,
        'invoiceNo': 'INV-1',
        'subtotal': 100,
        'discount': 10,
        'total': 90,
        'status': 'completed',
        'paymentStatus': 'paid',
      });

      expect(sale.discount, 10);
      expect(sale.lineDiscount, isNull);
      expect(sale.mrpSaving, isNull);
    });
  });

  group('the khata', () {
    test('a customer owes an opening balance plus their invoices', () {
      final customer = Customer.fromJson({
        'id': 25,
        'name': 'Arif Uddin',
        'isWalkIn': false,
        'saleCount': 12,
        'openingBalance': 500,
        'invoiceDue': 1276.14,
        'due': 1776.14,
      });

      expect(customer.openingBalance, 500);
      expect(customer.invoiceDue, 1276.14);
      expect(customer.due, 1776.14);
    });

    test('checkout reports the previous due and what is owed now', () {
      final result = CheckoutResult.fromJson({
        'saleId': 5522,
        'invoiceNo': 'INV-005522',
        'total': 300,
        'paid': 600,
        'due': 0,
        'paymentStatus': 'paid',
        'previousDue': 500,
        'outstanding': 200,
      });

      expect(result.previousDue, 500);
      expect(result.outstanding, 200);
    });
  });

  group('the drawer report', () {
    test('reads a day at a time, with no shift open', () {
      // Verbatim shape of the live answer with no drawer open.
      final report = ShiftReport.fromJson({
        'shift': null,
        'openingCash': 0,
        'cashTaken': 13192.030000000000654836185276508331298828125,
        'expected': 13192.030000000000654836185276508331298828125,
        'days': [
          {
            'date': '2026-09-23',
            'invoices': 9,
            'sold': 14868.59,
            'dueGiven': 0,
            'cash': 13192.03,
            'digital': 2534.17,
            'collected': 857.61,
          },
        ],
        'totals': {
          'invoices': 9,
          'sold': 14868.59,
          'cash': 13192.03,
          'digital': 2534.17,
          'dueGiven': 0,
          'collected': 857.61,
        },
      });

      expect(report.shiftId, isNull);
      expect(report.expected, closeTo(13192.03, 0.001));
      expect(report.days.single.date, '2026-09-23');
      expect(report.totals.invoices, 9);
      expect(report.totals.collected, 857.61);
    });

    test('an open shift names itself', () {
      final report = ShiftReport.fromJson({
        'shift': {'id': 31, 'openedAt': '2026-09-23T09:00:00+06:00'},
        'openingCash': 2000,
        'cashTaken': 8450,
        'expected': 10450,
        'days': [],
        'totals': {},
      });

      expect(report.shiftId, 31);
      expect(report.openedAt, isNotNull);
      expect(report.expected, 10450);
    });
  });
}
