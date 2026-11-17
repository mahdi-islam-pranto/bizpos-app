import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/features/customers/data/customers_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_adapter.dart';

/// The two customer-due writes from `docs/MOBILE-API-NEW.md`, section 6.
void main() {
  late FakeAdapter adapter;
  late ApiClient client;
  late CustomersRepository repo;

  setUp(() {
    adapter = FakeAdapter();
    client = ApiClient.create(
      baseUrl: 'https://example.test/api/v1',
      readToken: () => 'tok',
      onUnauthenticated: () async {},
    );
    client.dio.httpClientAdapter = adapter;
    repo = CustomersRepository(client, CancelToken());
  });

  Map<String, dynamic> sentBody() =>
      adapter.lastRequest.data as Map<String, dynamic>;

  test('collect sends the amount, the discount and where the money landed',
      () async {
    adapter.body = {
      'data': {
        'collected': 300,
        'discounted': 57.36,
        'outstanding': 0,
      },
    };

    final result = await repo.collect(
      4,
      amount: 300,
      discount: 57.36,
      discountReason: 'Regular customer',
      accountId: 1,
      method: 'cash',
    );

    final sent = adapter.lastRequest;
    expect(sent.method, 'POST');
    expect(sent.path, endsWith('/customers/4/collect'));
    expect(sentBody(), {
      'amount': 300,
      'discount': 57.36,
      'discountReason': 'Regular customer',
      'accountId': 1,
      'method': 'cash',
    });
    expect(result.collected, 300);
    expect(result.discounted, 57.36);
    expect(result.outstanding, 0);
  });

  test('a plain collection leaves the discount keys out', () async {
    adapter.body = {
      'data': {'collected': 357.36, 'discounted': 0, 'outstanding': 0},
    };

    await repo.collect(4, amount: 357.36);

    // Null means "not sent", not "send a zero discount with no reason": the
    // server would refuse a discount reason that is missing.
    expect(sentBody(), {'amount': 357.36});
  });

  test('add due sends the amount and the required remark', () async {
    adapter.statusCode = 201;
    adapter.body = {
      'data': {'id': 90, 'added': 100, 'outstanding': 457.36},
    };

    final result = await repo.addDue(
      4,
      amount: 100,
      remark: 'Old notebook balance',
    );

    final sent = adapter.lastRequest;
    expect(sent.method, 'POST');
    expect(sent.path, endsWith('/customers/4/add-due'));
    expect(sentBody(), {'amount': 100, 'remark': 'Old notebook balance'});
    expect(result.id, 90);
    expect(result.added, 100);
    expect(result.outstanding, 457.36);
  });
}
