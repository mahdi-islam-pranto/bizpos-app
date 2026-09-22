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
