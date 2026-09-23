import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/envelope.dart';
import '../../../core/network/paged.dart';
import '../../../core/session/session_controller.dart';
import '../../products/data/product_models.dart' show ProductLookups;
import 'catalog_models.dart';

/// What the catalogue list is showing. A value type so Riverpod can key on it.
class CatalogFilter {
  const CatalogFilter({this.text, this.scope = CatalogScope.all});

  final String? text;
  final CatalogScope scope;

  CatalogFilter copyWith({String? text, CatalogScope? scope, bool clearText = false}) =>
      CatalogFilter(
        text: clearText ? null : (text ?? this.text),
        scope: scope ?? this.scope,
      );

  @override
  bool operator ==(Object other) =>
      other is CatalogFilter && other.text == text && other.scope == scope;

  @override
  int get hashCode => Object.hash(text, scope);
}

/// The review queue and the endpoint's say on it.
class SuggestionQueue {
  const SuggestionQueue({required this.suggestions, required this.meta});

  final List<Suggestion> suggestions;
  final Meta meta;

  int get pending => meta.intValue('pending') ?? 0;
  bool? get mayEndorse => meta.flag('mayEndorse');
}

/// `docs/MOBILE-API-NEW.md` section 5.6 and section 6, "Catalogue".
///
/// Products come from the shared catalogue: search, adopt with this shop's
/// prices, and — when nothing fits — check the name and suggest a new one.
class CatalogRepository {
  CatalogRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  /// One of the four endpoints that genuinely paginate: 30 a page by default.
  Future<Paged<CatalogEntry>> list({
    CatalogFilter filter = const CatalogFilter(),
    int page = 1,
    int perPage = 30,
  }) async {
    final response = await _client.get(
      ApiPaths.catalog,
      parse: parseListOf(CatalogEntry.fromJson),
      query: {
        'q': filter.text,
        if (filter.scope == CatalogScope.mine) 'mine': 1,
        if (filter.scope == CatalogScope.missing) 'missing': 1,
        'page': page,
        'perPage': perPage,
      },
      cancelToken: _cancel,
    );
    return Paged.from(response, fallbackPage: page);
  }

  Future<AdoptResult> adopt(int id, AdoptDraft draft) async {
    final response = await _client.post(
      ApiPaths.catalogAdopt(id),
      parse: parseObject((json) => json),
      body: draft.toBody(),
      cancelToken: _cancel,
    );
    final data = response.data;
    final productId = data['id'];
    return AdoptResult(
      productId: productId is num ? productId.toInt() : 0,
      created: data['created'] != false,
    );
  }

  Future<CatalogCheck> check({
    required String name,
    String? brand,
    String? barcode,
  }) async {
    final response = await _client.get(
      ApiPaths.catalogCheck,
      parse: parseObject(CatalogCheck.fromJson),
      query: {'name': name, 'brand': brand, 'barcode': barcode},
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// The same shape `GET /products/lookups` answers, for the suggestion form.
  Future<ProductLookups> lookups() async {
    final response = await _client.get(
      ApiPaths.catalogLookups,
      parse: parseObject(ProductLookups.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// `409 already_in_catalog` on an exact duplicate; resend with
  /// [confirmedNew] to go ahead anyway.
  Future<SuggestResult> suggest(
    SuggestionDraft draft, {
    bool confirmedNew = false,
  }) async {
    final response = await _client.post(
      ApiPaths.catalogSuggestions,
      parse: parseObject(SuggestResult.fromJson),
      body: draft.toBody(confirmedNew: confirmedNew),
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<SuggestionQueue> suggestions() async {
    final response = await _client.get(
      ApiPaths.catalogSuggestions,
      parse: parseListOf(Suggestion.fromJson),
      cancelToken: _cancel,
    );
    return SuggestionQueue(suggestions: response.data, meta: response.meta);
  }

  /// Approving puts the product on this store's shelf; rejecting needs a note
  /// so whoever asked knows why.
  Future<bool> review(
    int id, {
    required bool approve,
    String? note,
    num? openingStock,
  }) async {
    final response = await _client.post(
      ApiPaths.catalogSuggestionReview(id),
      parse: parseObject((json) => json),
      body: {
        'approve': approve,
        'note': ?note,
        'openingStock': ?openingStock,
      },
      cancelToken: _cancel,
    );
    return response.data['endorsed'] == true;
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return CatalogRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

class CatalogFilterController extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() {
    ref.watch(scopeKeyProvider);
    return const CatalogFilter();
  }

  void setText(String? text) => state = state.copyWith(
        text: (text ?? '').isEmpty ? null : text,
        clearText: (text ?? '').isEmpty,
      );

  void setScope(CatalogScope scope) => state = state.copyWith(scope: scope);
}

final catalogFilterProvider =
    NotifierProvider<CatalogFilterController, CatalogFilter>(
  CatalogFilterController.new,
);

/// The paginated catalogue, accumulated across pages.
class CatalogListController extends AsyncNotifier<Paged<CatalogEntry>> {
  bool get isLoadingMore => _loadingMore;
  bool _loadingMore = false;

  @override
  Future<Paged<CatalogEntry>> build() {
    ref.watch(sessionScopeProvider);
    final filter = ref.watch(catalogFilterProvider);
    _loadingMore = false;
    return ref.watch(catalogRepositoryProvider).list(filter: filter);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadingMore) return;
    _loadingMore = true;
    ref.notifyListeners();
    try {
      final next = await ref.read(catalogRepositoryProvider).list(
            filter: ref.read(catalogFilterProvider),
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
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final catalogListProvider =
    AsyncNotifierProvider<CatalogListController, Paged<CatalogEntry>>(
  CatalogListController.new,
);

final catalogLookupsProvider = FutureProvider<ProductLookups>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(catalogRepositoryProvider).lookups();
});

final suggestionQueueProvider =
    FutureProvider.autoDispose<SuggestionQueue>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(catalogRepositoryProvider).suggestions();
});
