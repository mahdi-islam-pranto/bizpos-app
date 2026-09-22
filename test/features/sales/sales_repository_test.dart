import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/network/envelope.dart';
import 'package:bizpos_app/features/customers/data/customers_repository.dart';
import 'package:bizpos_app/features/sales/data/sale_models.dart';
import 'package:bizpos_app/features/sales/data/sales_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_adapter.dart';

/// What actually goes on the wire for the counter's write calls.
///
/// The whole interceptor chain runs here, so these cover the two things that
/// are invisible from a screen: that a `PATCH` leaves as a `POST` carrying the
/// override header, and that the permission-shaped and tri-state fields are
/// read the way the doc defines them.
void main() {
  late FakeAdapter adapter;
  late ApiClient client;
  late CancelToken cancel;

  setUp(() {
    adapter = FakeAdapter();
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test/api/v1',
        validateStatus: (status) => status != null && status < 300,
      ),
    );
    client = ApiClient.create(
      baseUrl: 'https://example.test/api/v1',
      readToken: () => 'test-token',
      onUnauthenticated: () async {},
    );
    client.dio.httpClientAdapter = adapter;
    dio.close();
    cancel = CancelToken();
  });

  group('voiding a sale', () {
    test('posts the reason and reads back what went on the shelf', () async {
      adapter.statusCode = 200;
      adapter.body = {
        'data': {
          'id': 5521,
          'invoiceNo': 'INV-005521',
          'status': 'void',
          'restored': 12,
        },
      };

      final result = await SalesRepository(client, cancel)
          .voidSale(5521, reason: 'Rung up on the wrong customer');

      final sent = adapter.lastRequest;
      expect(sent.method, 'POST');
      expect(sent.path, '/sales/5521/void');
      expect(
        (sent.data as Map)['reason'],
        'Rung up on the wrong customer',
      );
      // `restored` is often smaller than the invoice's item count: lines
      // already returned brought their own stock back and are left alone.
      expect(result.restored, 12);
      expect(result.invoiceNo, 'INV-005521');
    });
  });

  group('the invoice list query', () {
    test('sends days when a window is chosen', () async {
      adapter.body = {'data': [], 'meta': {'total': 0}};

      await SalesRepository(client, cancel).list(query: 'INV-1', days: 7);

      final query = adapter.lastRequest.queryParameters;
      expect(query['q'], 'INV-1');
      expect(query['days'], 7);
      expect(query['page'], 1);
    });

    test('drops days entirely for "all", rather than sending zero', () async {
      // The doc reads `0` or absent as "all"; absent is the unambiguous one,
      // and sending an empty q would narrow to nothing.
      adapter.body = {'data': [], 'meta': {'total': 0}};

      await SalesRepository(client, cancel).list(days: null);

      final query = adapter.lastRequest.queryParameters;
      expect(query.containsKey('days'), isFalse);
      expect(query.containsKey('q'), isFalse);
    });
  });

  group('editing a customer', () {
    test('a PATCH leaves as a POST carrying the override header', () async {
      // LiteSpeed refuses a real PATCH with its own HTML 403 before Laravel
      // ever sees it, so this is not a style choice — it is the only way the
      // request arrives.
      adapter.body = {
        'data': {'id': 12},
      };

      await CustomersRepository(client, cancel).update(
        12,
        name: 'Rahim Uddin',
        phone: '01711000000',
      );

      final sent = adapter.lastRequest;
      expect(sent.method, 'POST');
      expect(sent.headers['X-HTTP-Method-Override'], 'PATCH');
      expect(sent.path, '/customers/12');
    });

    test('a credit limit the caller did not pass is left out', () async {
      // Without `customers.credit.manage` the server ignores the field. The
      // form never offers it, and nothing empty is sent in its place.
      adapter.body = {
        'data': {'id': 12},
      };

      await CustomersRepository(client, cancel)
          .update(12, name: 'Rahim Uddin');

      expect((adapter.lastRequest.data as Map).containsKey('creditLimit'),
          isFalse);
    });
  });

  group('the may* flags are tri-state', () {
    SaleDetailResult resultWith(Map<String, dynamic> meta) => SaleDetailResult(
          sale: SaleDetail.fromJson(const {
            'id': 1,
            'invoiceNo': 'INV-1',
            'status': 'completed',
            'paymentStatus': 'paid',
          }),
          meta: Meta(meta),
        );

    test('absent means the endpoint said nothing, so the permission decides',
        () {
      // `permission && (flag ?? true)` — treating an absent flag as false is
      // how working buttons get hidden.
      expect(resultWith(const {}).mayVoid, isNull);
    });

    test('false is an explicit denial', () {
      expect(resultWith(const {'mayVoid': false}).mayVoid, isFalse);
    });
  });

  group('a sale status is read for what it is', () {
    test('void is its own thing, not a kind of return', () {
      expect(SaleStatus.parse('void'), SaleStatus.isVoid);
      expect(SaleStatus.parse('void').isCancelled, isTrue);
      expect(SaleStatus.parse('returned').isCancelled, isFalse);
    });

    test('an unknown status reads as completed rather than blowing up', () {
      expect(SaleStatus.parse('something-new'), SaleStatus.completed);
    });
  });
}
