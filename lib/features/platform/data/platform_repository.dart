import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/paged.dart';
import '../../../core/session/session_controller.dart';
import 'platform_models.dart';

/// `docs/MOBILE-API-NEW.md` section 5.10 and section 6, "Super admin". Every
/// call needs an `admin.*` permission only platform staff hold.
///
/// Entering a store for support is not here: it moves this device into
/// another shop, so it belongs to the session —
/// `SessionController.impersonate`.
class PlatformRepository {
  PlatformRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  Future<PlatformOverview> overview() async {
    final response = await _client.get(
      ApiPaths.adminOverview,
      parse: parseObject(PlatformOverview.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Makes the owner, the main branch, the default accounts — and the shop's
  /// own database. Never retried: a second call is a second shop.
  Future<StoreCreated> createStore(NewStoreDraft draft) async {
    final response = await _client.post(
      ApiPaths.adminStores,
      parse: parseObject(StoreCreated.fromJson),
      body: draft.toBody(),
    );
    return response.data;
  }

  Future<StoreUpdated> updateStore(int id, StoreEdit edit) async {
    final response = await _client.patch(
      ApiPaths.adminStore(id),
      parse: parseObject(StoreUpdated.fromJson),
      body: edit.toBody(),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// `active` or `suspended`. Nothing in a suspended store is deleted.
  Future<void> setStatus(int id, {required bool active}) => _client.patch(
    ApiPaths.adminStoreStatus(id),
    parse: parseNothing,
    body: {'status': active ? 'active' : 'suspended'},
    cancelToken: _cancel,
  );

  /// Lets a shop carry on: [days] from the later of today and the current end,
  /// or [unlimited] to take the clock off. The server switches the shop back
  /// on unless [activate] is false. `422 nothing_to_do`.
  Future<TrialState> extend(
    int id, {
    int? days,
    bool unlimited = false,
    bool activate = true,
  }) async {
    final response = await _client.post(
      ApiPaths.adminStoreExtend(id),
      parse: parseObject(TrialState.fromJson),
      body: {
        if (unlimited) 'unlimited': true else 'days': ?days,
        // Only said when it differs from the server's default.
        if (!activate) 'activate': false,
      },
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<bool> reviewSuggestion(
    int id, {
    required bool approve,
    String? note,
  }) async {
    final text = note?.trim();
    final response = await _client.post(
      ApiPaths.adminSuggestionReview(id),
      parse: parseObject((json) => json),
      body: {
        'approve': approve,
        if (text != null && text.isNotEmpty) 'note': text,
      },
      cancelToken: _cancel,
    );
    return response.data['created'] == true;
  }

  /// One of the four endpoints that genuinely paginate.
  Future<Paged<AdminCatalogEntry>> catalog({
    AdminCatalogFilter filter = const AdminCatalogFilter(),
    int page = 1,
    int perPage = 30,
  }) async {
    final response = await _client.get(
      ApiPaths.adminCatalog,
      parse: parseListOf(AdminCatalogEntry.fromJson),
      query: {...filter.toQuery(), 'page': page, 'perPage': perPage},
      cancelToken: _cancel,
    );
    return Paged.from(response, fallbackPage: page);
  }

  Future<AdminCatalogLookups> catalogLookups(int? storeTypeId) async {
    final response = await _client.get(
      ApiPaths.adminCatalogLookups,
      parse: parseObject(AdminCatalogLookups.fromJson),
      query: {'storeType': ?storeTypeId},
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<AdminCatalogEntry> createEntry(CatalogEntryDraft draft) async {
    final response = await _client.post(
      ApiPaths.adminCatalog,
      parse: parseObject(AdminCatalogEntry.fromJson),
      body: draft.toBody(),
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<AdminCatalogEntry> updateEntry(int id, CatalogEntryDraft draft) async {
    final response = await _client.patch(
      ApiPaths.adminCatalogEntry(id),
      parse: parseObject(AdminCatalogEntry.fromJson),
      body: draft.toBody(),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// A soft delete. Returns how many shops sell it — they keep their product.
  Future<int> deleteEntry(int id) async {
    final response = await _client.delete(
      ApiPaths.adminCatalogEntry(id),
      parse: parseObject((json) => json),
      cancelToken: _cancel,
    );
    final n = response.data['storesAffected'];
    return n is num ? n.toInt() : 0;
  }

  Future<void> restoreEntry(int id) => _client.post(
    ApiPaths.adminCatalogRestore(id),
    parse: parseNothing,
    cancelToken: _cancel,
  );
}

final platformRepositoryProvider = Provider<PlatformRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return PlatformRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

final platformOverviewProvider = FutureProvider.autoDispose<PlatformOverview>((
  ref,
) {
  ref.watch(sessionScopeProvider);
  return ref.watch(platformRepositoryProvider).overview();
});

class AdminCatalogFilterController extends Notifier<AdminCatalogFilter> {
  @override
  AdminCatalogFilter build() {
    ref.watch(sessionScopeProvider);
    return const AdminCatalogFilter();
  }

  void set(AdminCatalogFilter filter) => state = filter;
}

final adminCatalogFilterProvider =
    NotifierProvider<AdminCatalogFilterController, AdminCatalogFilter>(
      AdminCatalogFilterController.new,
    );

/// The shared catalogue, accumulated across pages.
class AdminCatalogController extends AsyncNotifier<Paged<AdminCatalogEntry>> {
  bool get isLoadingMore => _loadingMore;
  bool _loadingMore = false;

  @override
  Future<Paged<AdminCatalogEntry>> build() {
    ref.watch(sessionScopeProvider);
    final filter = ref.watch(adminCatalogFilterProvider);
    _loadingMore = false;
    return ref.watch(platformRepositoryProvider).catalog(filter: filter);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadingMore) return;
    _loadingMore = true;
    ref.notifyListeners();
    try {
      final next = await ref
          .read(platformRepositoryProvider)
          .catalog(
            filter: ref.read(adminCatalogFilterProvider),
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

final adminCatalogProvider =
    AsyncNotifierProvider<AdminCatalogController, Paged<AdminCatalogEntry>>(
      AdminCatalogController.new,
    );

final adminCatalogLookupsProvider = FutureProvider.autoDispose
    .family<AdminCatalogLookups, int?>((ref, storeTypeId) {
      ref.watch(sessionScopeProvider);
      return ref.watch(platformRepositoryProvider).catalogLookups(storeTypeId);
    });
