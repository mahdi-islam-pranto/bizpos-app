import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/envelope.dart';
import '../../../core/session/session_controller.dart';
import 'customer_models.dart';

/// The customer list and its `may*` flags.
///
/// `GET /customers` does **not** paginate — it returns a fixed window of up to
/// 100 and takes `?q=` to narrow. Wiring an infinite scroll to it would
/// re-request the same hundred forever, which is why this returns a plain list
/// and the screen shows a "search to narrow" footer instead of a page spinner.
class CustomerPage {
  const CustomerPage({required this.customers, required this.meta});

  final List<Customer> customers;
  final Meta meta;

  bool? get mayCreate => meta.flag('mayCreate');
  bool? get mayEdit => meta.flag('mayEdit');
  bool? get maySeeLedger => meta.flag('maySeeLedger');
  bool? get mayManageCredit => meta.flag('mayManageCredit');

  /// True when the server handed back a full window, so there are probably more
  /// behind a search.
  bool get isCapped => customers.length >= 100;
}

class CustomersRepository {
  CustomersRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  Future<CustomerPage> list({String? query}) async {
    final response = await _client.get(
      ApiPaths.customers,
      parse: parseListOf(Customer.fromJson),
      query: {'q': query},
      cancelToken: _cancel,
    );
    return CustomerPage(customers: response.data, meta: response.meta);
  }

  /// `creditLimit` is **silently ignored** without `customers.credit.manage`,
  /// so the caller passes it only when the permission is held — otherwise the
  /// form would appear to save a limit that never landed.
  Future<int> create({
    required String name,
    String? phone,
    String? email,
    String? address,
    num? creditLimit,
  }) async {
    final response = await _client.post(
      ApiPaths.customers,
      parse: parseObject((json) => json),
      body: {
        'name': name,
        'phone': ?phone,
        'email': ?email,
        'address': ?address,
        'creditLimit': ?creditLimit,
      },
      cancelToken: _cancel,
    );
    final id = response.data['id'];
    return id is num ? id.toInt() : 0;
  }

  /// Travels as a POST with `X-HTTP-Method-Override: PATCH`, like every other
  /// non-GET verb in this app.
  Future<void> update(
    int id, {
    required String name,
    String? phone,
    String? email,
    String? address,
    num? creditLimit,
  }) =>
      _client.patch(
        ApiPaths.customer(id),
        parse: parseNothing,
        body: {
          'name': name,
          'phone': ?phone,
          'email': ?email,
          'address': ?address,
          'creditLimit': ?creditLimit,
        },
        cancelToken: _cancel,
      );

  Future<List<LedgerEntry>> ledger(int id) async {
    final response = await _client.get(
      ApiPaths.customerLedger(id),
      parse: parseListOf(LedgerEntry.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<PointsAccount> points(int id) async {
    final response = await _client.get(
      ApiPaths.customerPoints(id),
      parse: parseObject(PointsAccount.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Signed and never zero. Taking the balance below zero is `422 negative`.
  Future<num> adjustPoints(
    int id, {
    required num points,
    required String note,
  }) async {
    final response = await _client.post(
      ApiPaths.customerPoints(id),
      parse: parseObject((json) => json),
      body: {'points': points, 'note': note},
      cancelToken: _cancel,
    );
    final balance = response.data['balance'];
    return balance is num ? balance : 0;
  }
}

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return CustomersRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

/// The current search text on the customers screen.
///
/// `GET /customers` takes `?q=` rather than paginating, so this *is* the
/// paging mechanism: narrowing the query is how a shop with more than a
/// hundred customers reaches the hundred-and-first.
class CustomerQueryController extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(scopeKeyProvider);
    return null;
  }

  void set(String? query) =>
      state = (query == null || query.isEmpty) ? null : query;
}

final customerQueryProvider =
    NotifierProvider<CustomerQueryController, String?>(
  CustomerQueryController.new,
);

final customersProvider = FutureProvider<CustomerPage>((ref) {
  ref.watch(sessionScopeProvider);
  final query = ref.watch(customerQueryProvider);
  return ref.watch(customersRepositoryProvider).list(query: query);
});

final customerLedgerProvider =
    FutureProvider.family<List<LedgerEntry>, int>((ref, id) {
  ref.watch(sessionScopeProvider);
  return ref.watch(customersRepositoryProvider).ledger(id);
});

final customerPointsProvider =
    FutureProvider.family<PointsAccount, int>((ref, id) {
  ref.watch(sessionScopeProvider);
  return ref.watch(customersRepositoryProvider).points(id);
});
