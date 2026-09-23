import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/paged.dart';
import '../../../core/session/session_controller.dart';
import 'product_models.dart';

/// Which slice of the shelves the list is showing.
///
/// A value type so Riverpod can key on it: two identical filters are the same
/// request, and changing one of them is a new one.
class ProductFilter {
  const ProductFilter({this.text, this.lowOnly = false, this.trashed = false});

  final String? text;
  final bool lowOnly;

  /// `trashed=1` lists the soft-deleted products **instead of** the live ones.
  /// It is a different list, not a filter on this one, which is why the screen
  /// changes its actions when it is on.
  final bool trashed;

  bool get isPlain => (text ?? '').isEmpty && !lowOnly && !trashed;

  ProductFilter copyWith({
    String? text,
    bool? lowOnly,
    bool? trashed,
    bool clearText = false,
  }) =>
      ProductFilter(
        text: clearText ? null : (text ?? this.text),
        lowOnly: lowOnly ?? this.lowOnly,
        trashed: trashed ?? this.trashed,
      );

  @override
  bool operator ==(Object other) =>
      other is ProductFilter &&
      other.text == text &&
      other.lowOnly == lowOnly &&
      other.trashed == trashed;

  @override
  int get hashCode => Object.hash(text, lowOnly, trashed);

  @override
  String toString() =>
      'ProductFilter(${text ?? ''}, low: $lowOnly, trashed: $trashed)';
}

class ProductsRepository {
  ProductsRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  /// `GET /products` — one of the four endpoints that genuinely paginates.
  Future<Paged<Product>> list({
    ProductFilter filter = const ProductFilter(),
    int page = 1,
    int perPage = Paged.defaultPerPage,
  }) async {
    final response = await _client.get(
      ApiPaths.products,
      parse: parseListOf(Product.fromJson),
      query: {
        'q': filter.text,
        if (filter.lowOnly) 'lowOnly': 1,
        if (filter.trashed) 'trashed': 1,
        'page': page,
        'perPage': perPage,
      },
      cancelToken: _cancel,
    );
    return Paged.from(response, fallbackPage: page);
  }

  Future<ProductStats> stats() async {
    final response = await _client.get(
      ApiPaths.productStats,
      parse: parseObject(ProductStats.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<ProductLookups> lookups() async {
    final response = await _client.get(
      ApiPaths.productLookups,
      parse: parseObject(ProductLookups.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<ProductHistory> history(int id) async {
    final response = await _client.get(
      ApiPaths.productHistory(id),
      parse: parseObject(ProductHistory.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// `POST /products`.
  ///
  /// `openingStock` defaults to **0** here (adopting from the catalogue is the
  /// other door, and there it defaults to 1). The form still always sends the
  /// number it shows, so what lands on the shelf is what somebody typed.
  ///
  /// [profitPercent] travels **beside** `salePrice`, never instead of it: the
  /// price is the authority on the money, the rate records why it is that
  /// price. Null means the price was named directly.
  Future<int> create({
    required String name,
    required num purchasePrice,
    required num salePrice,
    String? genericName,
    String? brand,
    String? sku,
    String? barcode,
    String? unit,
    num? wholesalePrice,
    num? profitPercent,
    num? mrp,
    num? vatPercent,
    num? minimumStock,
    required num openingStock,
    bool trackBatch = false,
  }) async {
    final response = await _client.post(
      ApiPaths.products,
      parse: parseObject((json) => json),
      body: {
        'name': name,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'genericName': ?genericName,
        'brand': ?brand,
        'sku': ?sku,
        'barcode': ?barcode,
        'unit': ?unit,
        'wholesalePrice': ?wholesalePrice,
        'profitPercent': ?profitPercent,
        'mrp': ?mrp,
        'vatPercent': ?vatPercent,
        'minimumStock': ?minimumStock,
        'openingStock': openingStock,
        'trackBatch': trackBatch,
      },
      cancelToken: _cancel,
    );
    final id = response.data['id'];
    return id is num ? id.toInt() : 0;
  }

  /// `PATCH /products/{id}` — the descriptive fields.
  ///
  /// The endpoint takes the prices too now, but only as a complete set, so
  /// they go through [setPrices] where the set is built in one place. Keeping
  /// them out of here also keeps `isActive` on its own when it is sent alone:
  /// a price beside it would make the all-or-nothing rule apply to a request
  /// that has no business naming a price.
  Future<void> update(
    int id, {
    String? name,
    String? brand,
    String? sku,
    String? barcode,
    String? unit,
    num? mrp,
    num? vatPercent,
    num? minimumStock,
    bool? trackBatch,
    bool? isActive,
  }) =>
      _client.patch(
        ApiPaths.product(id),
        parse: parseNothing,
        body: {
          'name': ?name,
          'brand': ?brand,
          'sku': ?sku,
          'barcode': ?barcode,
          'unit': ?unit,
          'mrp': ?mrp,
          'vatPercent': ?vatPercent,
          'minimumStock': ?minimumStock,
          'trackBatch': ?trackBatch,
          'isActive': ?isActive,
        },
        cancelToken: _cancel,
      );

  /// All three prices are required together — the API takes the set, not a
  /// patch of one, because "selling price at least the cost" is a rule it
  /// checks across them and cannot check with the cost missing.
  ///
  /// `profitPercent` is always sent, `null` included: null is how a stated
  /// rate is cleared when somebody types a price over it.
  Future<bool> setPrices(
    int id, {
    required num purchasePrice,
    required num salePrice,
    required num wholesalePrice,
    required num? profitPercent,
  }) async {
    final response = await _client.patch(
      ApiPaths.productPrices(id),
      parse: parseObject((json) => json),
      body: {
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'wholesalePrice': wholesalePrice,
        'profitPercent': profitPercent,
      },
      cancelToken: _cancel,
    );
    return response.data['changed'] == true;
  }

  /// Signed and never zero: `-3` took three off the shelf, `+3` put them back.
  /// `isDamage` files it as damage rather than a correction, which is a
  /// different line in the stock history and a different conversation.
  Future<void> adjust(
    int id, {
    required num qty,
    required String reason,
    bool isDamage = false,
  }) =>
      _client.post(
        ApiPaths.productAdjust(id),
        parse: parseNothing,
        body: {'qty': qty, 'reason': reason, 'isDamage': isDamage},
        cancelToken: _cancel,
      );

  /// A **soft** delete. The product leaves the list, the till and every stock
  /// figure; past sales still name it, and `restore` puts it back as it was.
  /// `stockWritten` is what was on the shelf when it went — worth saying out
  /// loud, because that is the part nobody expects.
  Future<DeleteOutcome> softDelete(int id) async {
    final response = await _client.delete(
      ApiPaths.product(id),
      parse: parseObject(DeleteOutcome.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<void> restore(int id) => _client.post(
        ApiPaths.productRestore(id),
        parse: parseNothing,
        cancelToken: _cancel,
      );
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return ProductsRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

/// The filter the products screen is showing, held above the screen so it
/// survives a push to a product and back.
class ProductFilterController extends Notifier<ProductFilter> {
  @override
  ProductFilter build() {
    ref.watch(scopeKeyProvider);
    return const ProductFilter();
  }

  void setText(String? text) => state = state.copyWith(
        text: (text ?? '').isEmpty ? null : text,
        clearText: (text ?? '').isEmpty,
      );

  void setLowOnly(bool value) => state = state.copyWith(lowOnly: value);

  /// The trashed list has no low filter to speak of — everything in it is off
  /// the shelf already — so turning it on turns that off.
  void setTrashed(bool value) =>
      state = state.copyWith(trashed: value, lowOnly: value ? false : null);
}

final productFilterProvider =
    NotifierProvider<ProductFilterController, ProductFilter>(
  ProductFilterController.new,
);

/// The paginated list, accumulated across pages.
class ProductsListController extends AsyncNotifier<Paged<Product>> {
  /// True only while a *further* page is on the wire.
  ///
  /// Separate from [AsyncValue.isLoading], which covers the first page too. The
  /// footer needs to tell the two apart: a spinner that means "fetching" is
  /// honest, and a spinner that only means "there is more" spins for ever on a
  /// list too short to scroll.
  bool get isLoadingMore => _loadingMore;
  bool _loadingMore = false;

  @override
  Future<Paged<Product>> build() {
    ref.watch(sessionScopeProvider);
    final filter = ref.watch(productFilterProvider);
    _loadingMore = false;
    return ref.watch(productsRepositoryProvider).list(filter: filter);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadingMore) return;

    _loadingMore = true;
    // The list is already on screen, so the state stays `data` — a reload
    // spinner here would blank what the person is reading.
    ref.notifyListeners();

    final filter = ref.read(productFilterProvider);
    try {
      final next = await ref
          .read(productsRepositoryProvider)
          .list(filter: filter, page: current.nextPage);

      state = AsyncValue.data(
        Paged(
          items: [...current.items, ...next.items],
          total: next.total,
          page: next.page,
          perPage: next.perPage,
          meta: next.meta,
        ),
      );
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final productsListProvider =
    AsyncNotifierProvider<ProductsListController, Paged<Product>>(
  ProductsListController.new,
);

final productStatsProvider = FutureProvider<ProductStats>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(productsRepositoryProvider).stats();
});

/// One product, read out of whichever page it is on.
///
/// There is no `GET /products/{id}`, so the detail screen is fed from the list
/// it was opened from. Refetching the list after an edit is what refreshes it —
/// which is also why every action on the detail screen invalidates the list
/// rather than patching a local copy.
final productProvider = Provider.family<Product?, int>((ref, id) {
  final page = ref.watch(productsListProvider).value;
  if (page == null) return null;
  for (final product in page.items) {
    if (product.id == id) return product;
  }
  return null;
});

/// Companies and units for the product form. Loaded once per scope; a form
/// that opens before it arrives simply offers no suggestions yet.
final productLookupsProvider = FutureProvider<ProductLookups>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(productsRepositoryProvider).lookups();
});

final productHistoryProvider =
    FutureProvider.family<ProductHistory, int>((ref, id) {
  ref.watch(sessionScopeProvider);
  return ref.watch(productsRepositoryProvider).history(id);
});
