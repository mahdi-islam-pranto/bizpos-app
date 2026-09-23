import 'dart:async';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/session/session_controller.dart';
import 'pos_models.dart';

/// Every POS call, in the order the counter makes them.
class PosRepository {
  PosRepository(this._client, this._cancel);

  final ApiClient _client;

  /// Cancelled when the store or branch changes, so a slow answer for the
  /// previous store cannot land in a till that now shows another one.
  final CancelToken _cancel;

  Future<PosLookups> lookups() async {
    final response = await _client.get(
      ApiPaths.posLookups,
      parse: parseObject(PosLookups.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Products of this store with this branch's stock.
  ///
  /// For a scanner, an exact barcode match comes back first, so `data.first` is
  /// the thing that was scanned.
  Future<List<SellableItem>> search(String query, {int limit = 30}) async {
    final response = await _client.get(
      ApiPaths.posSearch,
      parse: parseListOf(SellableItem.fromProduct),
      query: {'q': query, 'limit': limit},
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Bundles on sale now that can be built from this branch's stock.
  Future<List<SellableItem>> sellablePackages([String? query]) async {
    final response = await _client.get(
      ApiPaths.packagesSellable,
      parse: parseListOf(SellableItem.fromPackage),
      query: {'q': query},
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// The sale.
  ///
  /// **Never retried.** There is no idempotency key, so a second attempt is a
  /// second sale — which is why the checkout button disables itself the moment
  /// it is pressed and why no interceptor retries a POST.
  Future<CheckoutResult> checkout(Map<String, dynamic> body) async {
    final response = await _client.post(
      ApiPaths.posCheckout,
      parse: parseObject(CheckoutResult.fromJson),
      body: body,
      // Deliberately not the scope token: a checkout that is in flight when a
      // branch switch happens must be allowed to finish and be reported, not
      // vanish leaving nobody sure whether the sale happened.
    );
    return response.data;
  }

  Future<int> hold({required String label, required Map<String, dynamic> cart}) async {
    final response = await _client.post(
      ApiPaths.posHold,
      parse: parseObject((json) => json),
      body: {'label': label, 'cart': cart},
      cancelToken: _cancel,
    );
    return parseIdOrNull(response.data['id']) ?? 0;
  }

  /// Returns the exact JSON that was held, and deletes the hold.
  Future<Map<String, dynamic>> resumeHold(int id) async {
    final response = await _client.post(
      ApiPaths.posHoldResume(id),
      parse: parseObject((json) => json),
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<void> discardHold(int id) => _client.delete(
        ApiPaths.posHoldDiscard(id),
        parse: parseNothing,
        cancelToken: _cancel,
      );

  /// `422 shift_open` when one is already open — surfaced as the server's own
  /// sentence, not as a code.
  Future<void> openShift(num openingCash) => _client.post(
        ApiPaths.posShiftOpen,
        parse: parseNothing,
        body: {'openingCash': openingCash},
        cancelToken: _cancel,
      );

  Future<ShiftReport> shiftReport() async {
    final response = await _client.get(
      ApiPaths.posShiftReport,
      parse: parseObject(ShiftReport.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// `422 no_shift` when none is open.
  Future<ShiftClosing> closeShift(num countedCash, {String? note}) async {
    final response = await _client.post(
      ApiPaths.posShiftClose,
      parse: parseObject(ShiftClosing.fromJson),
      body: {'countedCash': countedCash, 'note': ?note},
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Up to 8 matches, phone first. Two characters is the server's minimum.
  Future<List<PosCustomer>> searchCustomers(String query) async {
    if (query.trim().length < 2) return const [];
    final response = await _client.get(
      ApiPaths.customerSearch,
      parse: parseListOf(PosCustomer.fromJson),
      query: {'q': query.trim()},
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// This customer's points balance.
  ///
  /// `GET /pos/lookups` hands back the recent customers **without**
  /// `loyaltyPoints` — only `GET /customers/search` carries it. So picking a
  /// regular off the recent list would silently lose the redemption that the
  /// same person, found by typing their phone, is offered. This fills the gap.
  Future<num?> pointsBalance(int customerId) async {
    final response = await _client.get(
      ApiPaths.customerPoints(customerId),
      parse: parseObject((json) => json),
      cancelToken: _cancel,
    );
    final balance = response.data['balance'];
    return balance is num ? balance : null;
  }

  /// `201` for a new person, `200` with `created: false` when the phone was
  /// already on file — which is a different thing to tell the cashier.
  Future<QuickCustomer> quickCustomer({
    required String name,
    required String phone,
  }) async {
    final response = await _client.post(
      ApiPaths.customerQuick,
      parse: parseObject(QuickCustomer.fromJson),
      body: {'name': name, 'phone': phone},
      cancelToken: _cancel,
    );
    return response.data;
  }
}

/// Scope-keyed, like every repository: the first line watches the session scope
/// so a store or branch switch throws this repository and its cancel token away
/// along with everything fetched through them.
final posRepositoryProvider = Provider<PosRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return PosRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

/// `GET /pos/lookups`, fetched once when the till opens.
///
/// Also the source of truth for whether a drawer is open, so opening or closing
/// a shift invalidates this and nothing else needs telling.
final posLookupsProvider = FutureProvider<PosLookups>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(posRepositoryProvider).lookups();
});

/// The drawer's takings so far. Fetched when the close sheet opens, so the
/// cashier counts against a figure they can see rather than being told
/// afterwards that it was short.
final posShiftReportProvider = FutureProvider.autoDispose<ShiftReport>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(posRepositoryProvider).shiftReport();
});

/// What the till is currently asking for: some text, in one of the two lists.
///
/// A value type rather than two arguments, so Riverpod can key a family on it
/// and the same query does not refetch on every rebuild.
class PosQuery {
  const PosQuery({this.text = '', this.packages = false});

  final String text;
  final bool packages;

  PosQuery withText(String value) =>
      PosQuery(text: value, packages: packages);

  PosQuery withPackages(bool value) =>
      PosQuery(text: text, packages: value);

  @override
  bool operator ==(Object other) =>
      other is PosQuery && other.text == text && other.packages == packages;

  @override
  int get hashCode => Object.hash(text, packages);

  @override
  String toString() => 'PosQuery("$text", packages: $packages)';
}

/// The till's product list.
///
/// **This is a provider rather than a fetch in `initState` on purpose.** The
/// repository's cancel token is thrown away and cancelled whenever the session
/// scope changes — including the `/me` refresh that runs a moment after
/// start-up, which bumps the epoch without the store changing. A search started
/// by hand in `initState` was cancelled by that refresh and never came back,
/// leaving the counter staring at a spinner it could not retry: no products, no
/// sale. Asking through a provider means Riverpod re-runs the search against
/// the new repository the instant the scope moves, so the list heals itself.
final posSearchProvider =
    FutureProvider.autoDispose.family<List<SellableItem>, PosQuery>((
  ref,
  query,
) {
  ref.watch(sessionScopeProvider);
  final repository = ref.watch(posRepositoryProvider);
  // Held briefly so flicking between Products and Packages, or backspacing a
  // query, does not refetch what was on screen a second ago.
  ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
  ref.onDispose(timer.cancel);

  return query.packages
      ? repository.sellablePackages(query.text.isEmpty ? null : query.text)
      // An empty query still asks the server, which answers with a recent
      // window — so the till opens showing something rather than a blank.
      : repository.search(query.text);
});

/// `GET /customers/search`, for the counter's customer picker.
///
/// A provider rather than a fetch held in the sheet's state, for the same
/// reason as [posSearchProvider]: the repository's cancel token dies with the
/// session scope, and a hand-rolled future that loses that race becomes a
/// spinner nothing can clear.
final posCustomerSearchProvider =
    FutureProvider.autoDispose.family<List<PosCustomer>, String>((ref, query) {
  ref.watch(sessionScopeProvider);
  return ref.watch(posRepositoryProvider).searchCustomers(query);
});
