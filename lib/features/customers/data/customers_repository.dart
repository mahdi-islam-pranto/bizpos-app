import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/envelope.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../accounts/data/account_models.dart' show MoneyAccount;
import '../../accounts/data/accounts_repository.dart';
import '../../pos/data/pos_models.dart' show PosAccount;
import '../../pos/data/pos_repository.dart';
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

  /// `creditLimit` and `openingBalance` are **silently ignored** without
  /// `customers.credit.manage`, so the caller passes them only when the
  /// permission is held — otherwise the form would appear to save a figure
  /// that never landed.
  Future<int> create({
    required String name,
    String? phone,
    String? email,
    String? address,
    num? creditLimit,
    num? openingBalance,
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
        'openingBalance': ?openingBalance,
      },
      cancelToken: _cancel,
    );
    final id = response.data['id'];
    return id is num ? id.toInt() : 0;
  }

  /// Travels as a POST with `X-HTTP-Method-Override: PATCH`, like every other
  /// non-GET verb in this app.
  ///
  /// Changing `openingBalance` later does not rewrite history: the server
  /// writes an `opening_correction` line for the difference.
  Future<void> update(
    int id, {
    required String name,
    String? phone,
    String? email,
    String? address,
    num? creditLimit,
    num? openingBalance,
  }) => _client.patch(
    ApiPaths.customer(id),
    parse: parseNothing,
    body: {
      'name': name,
      'phone': ?phone,
      'email': ?email,
      'address': ?address,
      'creditLimit': ?creditLimit,
      'openingBalance': ?openingBalance,
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

  /// `POST /customers/{id}/collect` — settles the whole balance, oldest first:
  /// the previous due, then invoice by invoice.
  ///
  /// [amount] and [discount] together may not pass what is owed; the server
  /// answers `422` if they do, which is why the sheet stops it first. A
  /// discount needs a [discountReason] of at least three characters and the
  /// `pos.sale.give_discount` permission.
  ///
  /// Sending [accountId] is what puts the money into that account's balance,
  /// so the sheet sends one whenever the role can read the accounts at all.
  /// It stays nullable because `accountId?` is optional on the wire.
  Future<DueCollection> collect(
    int id, {
    required num amount,
    num? discount,
    String? discountReason,
    int? accountId,
    String? method,
  }) async {
    final response = await _client.post(
      ApiPaths.customerCollect(id),
      parse: parseObject(DueCollection.fromJson),
      body: {
        'amount': amount,
        'discount': ?discount,
        'discountReason': ?discountReason,
        'accountId': ?accountId,
        'method': ?method,
      },
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// `POST /customers/{id}/add-due` — debt with no invoice behind it.
  ///
  /// The remark is required (3–200 characters) and travels onto the
  /// `due_added` ledger line, because a balance that grew for no stated reason
  /// is exactly the sort of thing nobody can defend later.
  Future<DueAdded> addDue(
    int id, {
    required num amount,
    required String remark,
  }) async {
    final response = await _client.post(
      ApiPaths.customerAddDue(id),
      parse: parseObject(DueAdded.fromJson),
      body: {'amount': amount, 'remark': remark},
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

final customerLedgerProvider = FutureProvider.family<List<LedgerEntry>, int>((
  ref,
  id,
) {
  ref.watch(sessionScopeProvider);
  return ref.watch(customersRepositoryProvider).ledger(id);
});

final customerPointsProvider = FutureProvider.family<PointsAccount, int>((
  ref,
  id,
) {
  ref.watch(sessionScopeProvider);
  return ref.watch(customersRepositoryProvider).points(id);
});

/// The accounts a collection can land in.
///
/// There is no customer endpoint for them, so they come from wherever this role
/// may read accounts: `GET /accounts` for an accountant, or the till's lookups
/// for a cashier. A role that holds neither still collects — the sheet then
/// sends no `accountId`, which is optional on the wire.
final customerAccountsProvider = FutureProvider.autoDispose<List<PosAccount>>((
  ref,
) async {
  ref.watch(sessionScopeProvider);
  final permissions = ref.watch(permissionsProvider);
  try {
    if (permissions.has(P.accountsAccountView)) {
      final overview = await ref.watch(accountsRepositoryProvider).overview();
      return [
        for (final MoneyAccount account in overview.accounts)
          PosAccount(
            id: account.id,
            name: account.name,
            type: account.type,
            isDefault: account.isDefault,
          ),
      ];
    }
    if (permissions.has(P.posSaleCreate)) {
      return (await ref.watch(posRepositoryProvider).lookups()).accounts;
    }
  } catch (_) {
    // A collection with no account is still a collection; better an empty
    // picker than a sheet that will not open.
  }
  return const [];
});
