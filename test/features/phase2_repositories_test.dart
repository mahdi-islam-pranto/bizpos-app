import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/network/api_exception.dart';
import 'package:bizpos_app/features/catalogue/data/catalog_models.dart';
import 'package:bizpos_app/features/catalogue/data/catalog_repository.dart';
import 'package:bizpos_app/features/packages/data/package_models.dart';
import 'package:bizpos_app/features/packages/data/packages_repository.dart';
import 'package:bizpos_app/features/purchases/data/purchase_models.dart';
import 'package:bizpos_app/features/purchases/data/purchases_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_adapter.dart';

/// The rest of phase 2 against `docs/MOBILE-API-NEW.md`: packages, the
/// catalogue flow and goods in. Payloads are shaped like the live server's.
void main() {
  late FakeAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = FakeAdapter();
    client = ApiClient.create(
      baseUrl: 'https://example.test/api/v1',
      readToken: () => 'tok',
      onUnauthenticated: () async {},
    );
    client.dio.httpClientAdapter = adapter;
  });

  Map<String, dynamic> sentBody() =>
      adapter.lastRequest.data as Map<String, dynamic>;

  group('packages', () {
    late PackagesRepository repo;
    setUp(() => repo = PackagesRepository(client, CancelToken()));

    test('the list reads availability, saving and what can be built', () async {
      adapter.body = {
        'data': [
          {
            'id': 2,
            'name': 'Winter Offer (ended)',
            'price': 500,
            'vatPercent': 0,
            'startsAt': '2026-07-23T15:36:15+00:00',
            'endsAt': '2026-09-16T15:36:15+00:00',
            'isActive': true,
            'availability': 'expired',
            'sellable': false,
            'buildable': 10,
            'componentTotal': 548.35000000000002,
            'saving': 48.350000000000001,
            'items': [
              {
                'storeProductId': 44,
                'name': 'Ace 500mg (30Pcs)',
                'unit': 'pc',
                'qty': 1,
                'salePrice': 260,
              },
            ],
          },
        ],
        'meta': {'mayManage': true},
      };

      final page = await repo.list();
      final package = page.packages.single;
      // Switched on is not on sale: its window has closed.
      expect(package.isActive, isTrue);
      expect(package.availability, PackageAvailability.expired);
      expect(package.sellable, isFalse);
      expect(package.buildable, 10);
      expect(package.items.single.storeProductId, 44);
      expect(page.mayManage, isTrue);
    });

    test('an edit sends the whole item list and plain dates', () async {
      adapter.body = {
        'data': {'id': 7, 'name': 'Cold pack', 'price': 1050, 'items': []},
      };

      await repo.update(
        7,
        PackageDraft(
          name: 'Cold pack',
          price: 1050,
          items: const [
            PackageItem(storeProductId: 108, name: 'A', qty: 1, salePrice: 390),
            PackageItem(storeProductId: 225, name: 'B', qty: 2, salePrice: 170),
          ],
          startsAt: DateTime(2026, 10, 1, 15, 30),
          endsAt: DateTime(2026, 12, 31),
        ),
      );

      final sent = adapter.lastRequest;
      expect(sent.method, 'POST');
      expect(sent.headers['X-HTTP-Method-Override'], 'PATCH');
      expect(sent.path, endsWith('/packages/7'));
      final body = sentBody();
      expect(body['items'], [
        {'storeProductId': 108, 'qty': 1},
        {'storeProductId': 225, 'qty': 2},
      ]);
      expect(body['startsAt'], '2026-10-01');
      expect(body['endsAt'], '2026-12-31');
    });

    test('an end before the start is caught before sending', () {
      final draft = PackageDraft(
        name: 'x',
        price: 1,
        items: const [],
        startsAt: DateTime(2026, 12, 1),
        endsAt: DateTime(2026, 11, 1),
      );
      expect(draft.windowIsValid, isFalse);
    });

    test('switching on reports what it became', () async {
      adapter.body = {
        'data': {'id': 2, 'availability': 'scheduled'},
      };
      expect(await repo.setActive(2, true), PackageAvailability.scheduled);
      expect(adapter.lastRequest.path, endsWith('/packages/2/active'));
      expect(sentBody(), {'isActive': true});
    });
  });

  group('the catalogue', () {
    late CatalogRepository repo;
    setUp(() => repo = CatalogRepository(client, CancelToken()));

    test('"not in my store" is missing=1, and the counts come back', () async {
      adapter.body = {
        'data': [
          {
            'id': 1,
            'name': '3 F 500(20 Pcs) 500 mg',
            'genericName': 'Levofloxacin Hemihydrate',
            'brand': 'edruc Ltd.',
            'defaultPurchasePrice': 140,
            'defaultSalePrice': 154.22,
            'defaultMrp': 320,
            'vatPercent': 0,
            'alreadyInStore': null,
            'pending': true,
          },
        ],
        'meta': {
          'total': 1,
          'page': 1,
          'perPage': 30,
          'pages': 1,
          'missingCount': 1,
          'mineCount': 1606,
        },
      };

      final page = await repo.list(
        filter: const CatalogFilter(scope: CatalogScope.missing),
      );

      final query = adapter.lastRequest.queryParameters;
      expect(query['missing'], 1);
      expect(query.containsKey('mine'), isFalse);
      expect(page.meta.intValue('mineCount'), 1606);
      final entry = page.items.single;
      expect(entry.isInStore, isFalse);
      expect(entry.pending, isTrue);
      expect(entry.defaultMrp, 320);
    });

    test('adopting sends the opening stock the form shows', () async {
      adapter
        ..statusCode = 201
        ..body = {
          'data': {'id': 1700, 'created': true},
        };

      final result = await repo.adopt(
        5,
        const AdoptDraft(
          purchasePrice: 1.0,
          salePrice: 1.2,
          mrp: 1.5,
          openingStock: 1,
          profitPercent: 20,
        ),
      );

      expect(adapter.lastRequest.path, endsWith('/catalog/5/adopt'));
      final body = sentBody();
      expect(body['openingStock'], 1);
      expect(body['mrp'], 1.5);
      expect(body['profitPercent'], 20);
      expect(body.containsKey('wholesalePrice'), isFalse);
      expect(result.created, isTrue);
      expect(result.productId, 1700);
    });

    test('already on the shelf answers created: false', () async {
      adapter.body = {
        'data': {'id': 42, 'created': false},
      };
      final result = await repo.adopt(
        5,
        const AdoptDraft(purchasePrice: 1, salePrice: 1.2),
      );
      expect(result.created, isFalse);
    });

    test('the check reads its snake_case matches', () async {
      adapter.body = {
        'data': {
          'parsed': {'base': 'napa', 'strength': '500'},
          'verdict': 'variant',
          'exact': null,
          'alreadyInStore': null,
          'matches': [
            {
              'id': 1105,
              'name': 'Napa 500 (510 Pcs) 500mg',
              'generic_name': 'Paracetamol',
              'brand': 'Beximco Pharmaceuticals Ltd',
              'purchase': 520,
              'sale': 555.77,
              'match': 'variant',
              'strength': '500mg',
              'reason_en': 'exists at 500mg; yours is 500.',
              'reason_bn': '৫০০ মিগ্রা-এ আছে।',
            },
          ],
        },
      };

      final check = await repo.check(name: 'Napa 500');
      expect(check.verdict, CheckVerdict.variant);
      final match = check.matches.single;
      expect(match.genericName, 'Paracetamol');
      expect(match.reasonFor('bn'), '৫০০ মিগ্রা-এ আছে।');
      // A match opens the same adopt form as a catalogue row.
      final entry = CatalogEntry.fromMatch(match);
      expect(entry.id, 1105);
      expect(entry.defaultPurchasePrice, 520);
    });

    test('a duplicate is a 409 the resend overrides', () async {
      adapter
        ..statusCode = 409
        ..body = {
          'error': {
            'code': 'already_in_catalog',
            'message': 'That product is already in the catalogue.',
            'match': {'id': 1105, 'name': 'Napa 500'},
            'alreadyInStore': null,
          },
        };
      const draft = SuggestionDraft(
        name: 'Napa 500',
        purchasePrice: 1,
        salePrice: 1.2,
      );

      Object? caught;
      try {
        await repo.suggest(draft);
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<ConflictException>());
      expect((caught! as ConflictException).match?['name'], 'Napa 500');
      expect(sentBody().containsKey('confirmedNew'), isFalse);

      adapter
        ..statusCode = 201
        ..body = {
          'data': {'id': 9, 'endorsed': true, 'storeProductId': 1701},
        };
      final result = await repo.suggest(draft, confirmedNew: true);
      expect(sentBody()['confirmedNew'], isTrue);
      expect(result.endorsed, isTrue);
    });

    test('the review queue reads payload and economics', () async {
      adapter.body = {
        'data': [
          {
            'id': 3,
            'status': 'pending',
            'payload': {
              'name': 'Maxpro 20mg',
              'brand': 'Renata',
              'purchasePrice': 5.4000000000000004,
              'salePrice': 7,
              'reason': 'Cheaper than Sergel.',
            },
            'economics': {'cost': 5.4, 'sale': 7, 'profit': 1.6, 'margin': 22.9},
            'askedBy': 'Jamal Uddin',
            'askedAt': '2026-09-08T15:37:04+00:00',
            'storeProduct': null,
          },
        ],
        'meta': {'pending': 3, 'mayEndorse': true},
      };

      final queue = await repo.suggestions();
      final s = queue.suggestions.single;
      expect(s.name, 'Maxpro 20mg');
      expect(s.isPending, isTrue);
      expect(s.margin, 22.9);
      expect(queue.pending, 3);
    });
  });

  group('goods in', () {
    late PurchasesRepository repo;
    setUp(() => repo = PurchasesRepository(client, CancelToken()));

    const napa = PurchaseProduct(
      id: 1105,
      name: 'Napa',
      trackBatch: true,
      purchasePrice: 520,
    );

    test('a known party goes as supplierId, a new one as supplierName', () {
      final lines = [
        PurchaseLine(
          product: napa,
          qty: 100,
          unitCost: 78.5,
          batchNo: 'B2291',
          expiryDate: DateTime(2027, 6, 30),
        ),
      ];

      final known = PurchaseDraft(lines: lines, supplierId: 3).toBody();
      expect(known['supplierId'], 3);
      expect(known.containsKey('supplierName'), isFalse);
      expect((known['items'] as List).single, {
        'storeProductId': 1105,
        'qty': 100,
        'unitCost': 78.5,
        'batchNo': 'B2291',
        'expiryDate': '2027-06-30',
      });

      final fresh =
          PurchaseDraft(lines: lines, supplierName: 'Karim Traders').toBody();
      expect(fresh['supplierName'], 'Karim Traders');
      expect(fresh.containsKey('supplierId'), isFalse);
    });

    test('the bill rate is previewed exactly and sent as a rate', () {
      final draft = PurchaseDraft(
        lines: const [
          PurchaseLine(product: napa, qty: 3, unitCost: 33.33),
        ],
        supplierId: 1,
        discountPercent: 5,
        paidAmount: 50,
        accountId: 1,
      );

      // 99.99 less 5% (4.9995 → 5.00) is 94.99.
      expect(draft.subtotal.toString(), '99.99');
      expect(draft.discountAmount.toString(), '5');
      expect(draft.total.toString(), '94.99');
      final body = draft.toBody();
      expect(body['discountPercent'], 5);
      expect(body.containsKey('discount'), isFalse);
      expect(body['paidAmount'], 50);
      expect(body['accountId'], 1);
    });

    test('the list carries suppliers, summary and photos', () async {
      adapter.body = {
        'data': [
          {
            'id': 19,
            'refNo': 'PUR-00019',
            'purchaseDate': '2026-09-18T08:35:00+00:00',
            'subtotal': 62282.79,
            'discount': 0,
            'discountPercent': null,
            'total': 62282.79,
            'paid': 24290.29,
            'due': 37992.5,
            'paymentStatus': 'partial',
            'status': 'received',
            'supplier': 'Incepta Sales',
            'itemCount': 42,
            'photos': [
              {'id': 4, 'url': 'https://x/p.jpg', 'name': 'bill.jpg'},
            ],
          },
        ],
        'meta': {
          'suppliers': [
            {'id': 4, 'name': 'ACI Healthcare Depot', 'company': 'ACI Limited'},
          ],
          'summary': {'count': 20, 'total': 10028958.66, 'due': 9258552.01},
          'mayCreate': true,
          'mayManageSuppliers': true,
          'mayEditBill': true,
          'maxPhotos': 5,
        },
      };

      final page = await repo.list();
      expect(page.rows.single.due, 37992.5);
      expect(page.rows.single.discountPercent, isNull);
      expect(page.rows.single.photos.single.id, 4);
      expect(page.suppliers.single.company, 'ACI Limited');
      expect(page.count, 20);
      expect(page.maxPhotos, 5);
    });

    test('photos go up as multipart, one photos[] part each', () async {
      adapter
        ..statusCode = 201
        ..body = {
          'data': [
            {'id': 11, 'url': 'https://x/1.jpg', 'name': 'a.jpg'},
            {'id': 12, 'url': 'https://x/2.jpg', 'name': 'b.jpg'},
          ],
          'meta': {'accepted': 2, 'offered': 2, 'remaining': 3},
        };

      final result = await repo.uploadPhotos(20, const [
        PhotoFile(name: 'a.jpg', bytes: [1, 2, 3]),
        PhotoFile(name: 'b.jpg', bytes: [4, 5, 6]),
      ]);

      final sent = adapter.lastRequest;
      expect(sent.path, endsWith('/purchases/20/photos'));
      expect(sent.method, 'POST');
      final form = sent.data as FormData;
      expect(form.files.map((f) => f.key), ['photos[]', 'photos[]']);
      expect(form.files.first.value.filename, 'a.jpg');
      // Dio writes the boundary; a hand-set JSON type would break the upload.
      expect(sent.contentType, startsWith('multipart/form-data'));
      expect(sent.contentType, contains('boundary='));
      expect(result.accepted, 2);
      expect(result.remaining, 3);
    });
  });
}
