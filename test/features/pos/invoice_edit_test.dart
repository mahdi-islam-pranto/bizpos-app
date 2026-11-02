import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/network/envelope.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/features/pos/data/pos_models.dart';
import 'package:bizpos_app/features/pos/state/cart.dart';
import 'package:bizpos_app/features/pos/state/invoice_edit.dart';
import 'package:bizpos_app/features/sales/data/sale_models.dart';
import 'package:bizpos_app/features/sales/data/sales_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_adapter.dart';

/// Correcting an invoice on the till: `GET /sales/{id}/edit` becomes a cart,
/// the till's own cart waits aside, and `POST /sales/{id}/edit` gets the
/// checkout body without `collectPrevious`.
void main() {
  // The doc's own shape for `GET /sales/{id}/edit`.
  final draftJson = <String, dynamic>{
    'id': 5521,
    'invoiceNo': 'INV-005521',
    'saleDate': '2026-10-30T11:40:00+06:00',
    'lines': [
      {
        'productId': 42,
        'name': 'Napa 500mg',
        'unit': 'pcs',
        'qty': 10,
        'unitPrice': 1.2,
        'basePrice': 1.2,
        'mrp': 1.5,
        'cost': 0.9,
        'discount': 0,
        'vatPercent': 0,
        'stock': 30,
      },
      {
        'productId': 77,
        'name': 'Seclo 20',
        'qty': 2,
        'unitPrice': 6.5,
        'basePrice': 7,
        'discount': 1,
        'vatPercent': 0,
        'stock': 4,
      },
    ],
    'sold': {'42': 10, '77': 2},
    'customer': {
      'id': 9,
      'name': 'Arif Uddin',
      'phone': '01811000022',
      'due': 0,
    },
    'orderDiscountPercent': 5,
    'note': 'Deliver Friday',
    'paid': 25,
    'method': 'bkash',
    'accountId': 3,
    'cashReceived': 25,
    'pointsRedeemed': 0,
  };

  group('the invoice comes back as a cart', () {
    final draft = SaleEditDraft.fromJson(draftJson);

    test('reads the doc shape, sold included', () {
      expect(draft.id, 5521);
      expect(draft.invoiceNo, 'INV-005521');
      expect(draft.lines, hasLength(2));
      expect(draft.sold, {42: 10, 77: 2});
      expect(draft.method, PayMethod.bkash);
      expect(draft.accountId, 3);
      expect(draft.paid, 25);
    });

    test('a price unlike the product\'s own is kept as the line\'s price', () {
      final cart = cartFromDraft(draft);
      final napa = cart.lines.firstWhere((l) => l.item.id == 42);
      final seclo = cart.lines.firstWhere((l) => l.item.id == 77);

      expect(napa.unitPrice, isNull);
      expect(napa.item.purchasePrice, 0.9);
      expect(seclo.unitPrice, 6.5);
      expect(seclo.item.salePrice, 7);
      expect(seclo.lineDiscount, 1);
      expect(cart.customer?.name, 'Arif Uddin');
      expect(cart.orderDiscountPercent, 5);
      expect(cart.note, 'Deliver Friday');
    });

    test('saved untouched, it sends the same bill back', () {
      final body = cartFromDraft(draft).toCheckoutBody(
        mayChangePrice: true,
        mayDiscount: true,
        payments: const [],
      );

      expect(body['customerId'], 9);
      expect(body['orderDiscountPercent'], 5);
      expect(body['lines'], [
        {'storeProductId': 42, 'qty': 10},
        {'storeProductId': 77, 'qty': 2, 'unitPrice': 6.5, 'discount': 1},
      ]);
    });

    test('two lines of one product become one', () {
      final doubled = SaleEditDraft.fromJson({
        ...draftJson,
        'lines': [
          {
            'productId': 42,
            'name': 'Napa',
            'qty': 2,
            'unitPrice': 1.2,
            'basePrice': 1.2,
          },
          {
            'productId': 42,
            'name': 'Napa',
            'qty': 3,
            'unitPrice': 1.2,
            'basePrice': 1.2,
            'discount': 0.5,
          },
        ],
      });
      final cart = cartFromDraft(doubled);

      expect(cart.lines, hasLength(1));
      expect(cart.lines.single.qty, 5);
      expect(cart.lines.single.lineDiscount, 0.5);
    });

    test('a walk-in invoice has no customer on the cart', () {
      final walkIn = SaleEditDraft.fromJson({
        ...draftJson,
        'customer': {'id': 1, 'name': 'Walk-in Customer', 'isWalkIn': true},
      });

      expect(cartFromDraft(walkIn).customer, isNull);
    });
  });

  group('the till while editing', () {
    ProviderContainer till() {
      final container = ProviderContainer(
        overrides: [scopeKeyProvider.overrideWithValue('test')],
      );
      addTearDown(container.dispose);
      return container;
    }

    const waiting = SellableItem(
      id: 5,
      name: 'Waiting on the till',
      salePrice: 10,
      isPackage: false,
    );

    test('parks the till\'s cart and gives it back when the edit ends', () {
      final container = till();
      container.read(cartProvider.notifier).add(waiting, qty: 3);

      container
          .read(invoiceEditProvider.notifier)
          .start(SaleEditDraft.fromJson(draftJson));
      expect(container.read(cartProvider).lines.map((l) => l.item.id), [
        42,
        77,
      ]);
      expect(container.read(invoiceEditProvider)?.saleId, 5521);

      container.read(invoiceEditProvider.notifier).end();
      expect(container.read(invoiceEditProvider), isNull);
      expect(container.read(cartProvider).lines.single.item.id, 5);
      expect(container.read(cartProvider).lines.single.qty, 3);
    });

    test(
      'a second invoice still parks the till\'s cart, not the first edit',
      () {
        final container = till();
        container.read(cartProvider.notifier).add(waiting);
        final edits = container.read(invoiceEditProvider.notifier);

        edits.start(SaleEditDraft.fromJson(draftJson));
        edits.start(
          SaleEditDraft.fromJson({...draftJson, 'id': 6000, 'invoiceNo': 'X'}),
        );
        edits.end();

        expect(container.read(cartProvider).lines.single.item.id, 5);
      },
    );

    test('what the invoice sold counts as back on the shelf', () {
      final container = till();
      container
          .read(invoiceEditProvider.notifier)
          .start(SaleEditDraft.fromJson(draftJson));
      final edit = container.read(invoiceEditProvider)!;

      const searched = SellableItem(
        id: 42,
        name: 'Napa 500mg',
        salePrice: 1.2,
        isPackage: false,
        stock: 20,
      );
      expect(edit.withSold(searched).stock, 30);
      // Nothing of this one was on the invoice.
      expect(edit.withSold(waiting).stock, isNull);
    });

    test('the payment starts at the share of the bill that was paid', () {
      InvoiceEdit paying(num paid) => InvoiceEdit(
        saleId: 1,
        invoiceNo: 'INV-1',
        sold: const {},
        paid: paid,
        originalTotal: 100,
        parked: const Cart(),
      );

      // Paid in full: the corrected bill in full.
      expect(paying(100).openingPayment(120), 120);
      // All on the khata: still nothing.
      expect(paying(0).openingPayment(120), 0);
      // Part-paid: what was paid, never more than the new bill.
      expect(paying(40).openingPayment(120), 40);
      expect(paying(40).openingPayment(30), 30);
    });
  });

  group('on the wire', () {
    late FakeAdapter adapter;
    late ApiClient client;

    setUp(() {
      adapter = FakeAdapter();
      client = ApiClient.create(
        baseUrl: 'https://example.test/api/v1',
        readToken: () => 'test-token',
        onUnauthenticated: () async {},
      );
      client.dio.httpClientAdapter = adapter;
    });

    test('the draft is a GET of /sales/{id}/edit', () async {
      adapter.body = {'data': draftJson};

      final draft = await SalesRepository(
        client,
        CancelToken(),
      ).editDraft(5521);

      expect(adapter.lastRequest.method, 'GET');
      expect(adapter.lastRequest.path, '/sales/5521/edit');
      expect(draft.invoiceNo, 'INV-005521');
    });

    test('saving posts the body without collectPrevious', () async {
      adapter.body = {
        'data': {
          'saleId': 5521,
          'invoiceNo': 'INV-005521',
          'total': 18.5,
          'paid': 18.5,
          'due': 0,
          'paymentStatus': 'paid',
        },
      };

      final result = await SalesRepository(client, CancelToken()).saveEdit(
        5521,
        {
          'customerId': 9,
          'lines': [
            {'storeProductId': 42, 'qty': 5},
          ],
          'payments': [
            {'method': 'cash', 'amount': 18.5},
          ],
          'collectPrevious': true,
        },
      );

      final sent = adapter.lastRequest;
      expect(sent.method, 'POST');
      expect(sent.path, '/sales/5521/edit');
      expect((sent.data as Map).containsKey('collectPrevious'), isFalse);
      expect((sent.data as Map)['customerId'], 9);
      expect(result.saleId, 5521);
      expect(result.total, 18.5);
    });
  });

  group('who is offered Edit', () {
    SaleDetailResult resultWith(Map<String, dynamic> meta) => SaleDetailResult(
      sale: SaleDetail.fromJson(const {
        'id': 1,
        'invoiceNo': 'INV-1',
        'status': 'completed',
        'paymentStatus': 'paid',
      }),
      meta: Meta(meta),
    );

    test(
      'only an explicit mayEdit: there is no permission to fall back on',
      () {
        expect(resultWith(const {}).mayEdit, isFalse);
        expect(resultWith(const {'mayEdit': false}).mayEdit, isFalse);
        expect(resultWith(const {'mayEdit': true}).mayEdit, isTrue);
      },
    );

    test('editBlocked carries the reason, and null is no reason', () {
      expect(
        resultWith(const {
          'mayEdit': false,
          'editBlocked': 'Undo the returns first.',
        }).editBlocked,
        'Undo the returns first.',
      );
      expect(resultWith(const {'editBlocked': null}).editBlocked, isNull);
    });
  });
}
