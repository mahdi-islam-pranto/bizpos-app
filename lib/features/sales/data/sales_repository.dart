import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/paged.dart';
import '../../../core/session/session_controller.dart';
import 'sale_models.dart';

class SalesRepository {
  SalesRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  /// `GET /sales` — one of only two paginated lists in the API.
  ///
  /// [days] is the doc's own filter: `1` is today, `7` is a week, and **0 or
  /// absent means all**, which is why it is dropped rather than sent as zero.
  /// Scope is the current branch, and without `sales.invoice.view_all` the
  /// server quietly returns only this user's own sales.
  Future<Paged<SaleListItem>> list({
    String? query,
    int? days,
    int page = 1,
    int perPage = Paged.defaultPerPage,
  }) async {
    final response = await _client.get(
      ApiPaths.sales,
      parse: parseListOf(SaleListItem.fromJson),
      query: {
        'q': query,
        if (days != null && days > 0) 'days': days,
        'page': page,
        'perPage': perPage,
      },
      cancelToken: _cancel,
    );
    return Paged.from(response, fallbackPage: page);
  }

  /// The full invoice, plus the `may*` flags that decide which actions show.
  Future<SaleDetailResult> detail(int id) async {
    final response = await _client.get(
      ApiPaths.sale(id),
      parse: parseObject(SaleDetail.fromJson),
      cancelToken: _cancel,
    );
    return SaleDetailResult(sale: response.data, meta: response.meta);
  }

  /// Goods coming back. The invoice itself stands.
  ///
  /// Returning more than is left on a line is a `422` whose message names the
  /// figure ("Only 2 left to return on that line"), so nothing is validated
  /// twice here.
  Future<ReturnResult> createReturn(
    int id, {
    required List<Map<String, dynamic>> items,
    String? reason,
  }) async {
    final response = await _client.post(
      ApiPaths.saleReturns(id),
      parse: parseObject(ReturnResult.fromJson),
      body: {'items': items, 'reason': ?reason},
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Money against an outstanding invoice. Paying more than is due is
  /// `422 over_payment`; a void invoice is refused outright.
  Future<void> collect(
    int id, {
    required num amount,
    String method = 'cash',
    int? accountId,
  }) =>
      _client.post(
        ApiPaths.salePayments(id),
        parse: parseNothing,
        body: {
          'amount': amount,
          'method': method,
          'accountId': ?accountId,
        },
        cancelToken: _cancel,
      );

  /// Undoes the whole sale: stock back, money reversed out of its account, the
  /// customer's debt credited, points unwound. `reason` is required, 3–255
  /// characters, and cancelling twice is a `422`.
  Future<VoidResult> voidSale(int id, {required String reason}) async {
    final response = await _client.post(
      ApiPaths.saleVoid(id),
      parse: parseObject(VoidResult.fromJson),
      body: {'reason': reason},
      cancelToken: _cancel,
    );
    return response.data;
  }
}

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return SalesRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

/// What the invoice list is currently filtered to.
class SalesQuery {
  const SalesQuery({this.text, this.days});

  final String? text;

  /// 1, 7 or null for everything.
  final int? days;

  SalesQuery copyWith({String? text, int? days, bool clearDays = false}) =>
      SalesQuery(
        text: text ?? this.text,
        days: clearDays ? null : (days ?? this.days),
      );

  @override
  bool operator ==(Object other) =>
      other is SalesQuery && other.text == text && other.days == days;

  @override
  int get hashCode => Object.hash(text, days);
}

final salesQueryProvider =
    NotifierProvider<SalesQueryController, SalesQuery>(
  SalesQueryController.new,
);

class SalesQueryController extends Notifier<SalesQuery> {
  @override
  SalesQuery build() {
    ref.watch(scopeKeyProvider);
    // Today, because the invoice a cashier wants is nearly always one they just
    // made. "All" is one tap away.
    return const SalesQuery(days: 1);
  }

  void setText(String? text) =>
      state = SalesQuery(text: (text ?? '').isEmpty ? null : text, days: state.days);

  void setDays(int? days) =>
      state = SalesQuery(text: state.text, days: days);
}

/// The paginated list, accumulated across pages.
///
/// `GET /sales` is genuinely paginated (`meta.total`), so this keeps appending
/// rather than refetching a fixed window — the mistake [Paged] exists to
/// prevent on the endpoints that do not paginate.
class SalesListController extends AsyncNotifier<Paged<SaleListItem>> {
  @override
  Future<Paged<SaleListItem>> build() {
    ref.watch(sessionScopeProvider);
    final query = ref.watch(salesQueryProvider);
    return ref
        .watch(salesRepositoryProvider)
        .list(query: query.text, days: query.days);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || state.isLoading) return;

    final query = ref.read(salesQueryProvider);
    final next = await ref.read(salesRepositoryProvider).list(
          query: query.text,
          days: query.days,
          page: current.nextPage,
        );

    state = AsyncValue.data(
      Paged(
        items: [...current.items, ...next.items],
        total: next.total,
        page: next.page,
        perPage: next.perPage,
        meta: next.meta,
      ),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final salesListProvider =
    AsyncNotifierProvider<SalesListController, Paged<SaleListItem>>(
  SalesListController.new,
);

/// One invoice. Keyed by id and by scope, so an id from a store that has since
/// been switched away from is refetched rather than shown from cache — it would
/// answer 404 in the new store, not 403.
final saleDetailProvider =
    FutureProvider.family<SaleDetailResult, int>((ref, id) {
  ref.watch(sessionScopeProvider);
  return ref.watch(salesRepositoryProvider).detail(id);
});
