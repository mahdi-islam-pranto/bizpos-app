import 'package:dio/dio.dart' show CancelToken, FormData, MultipartFile;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../pos/data/pos_models.dart' show PosAccount;
import '../../pos/data/pos_repository.dart' show posRepositoryProvider;
import 'purchase_models.dart';

/// A picked photo, as bytes: works the same on a phone and in a browser.
class PhotoFile {
  const PhotoFile({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

/// `docs/MOBILE-API-NEW.md` section 5.4 and section 6, "Purchase".
class PurchasesRepository {
  PurchasesRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  /// The latest 50; `q` on ref no or supplier narrows it. Not paginated.
  Future<PurchasePage> list({String? query}) async {
    final response = await _client.get(
      ApiPaths.purchases,
      parse: parseListOf(PurchaseRow.fromJson),
      query: {'q': query},
      cancelToken: _cancel,
    );
    return PurchasePage(
      rows: response.data,
      suppliers: response.meta
          .listValue('suppliers')
          .map(Supplier.fromJson)
          .toList(),
      meta: response.meta,
    );
  }

  Future<List<PurchaseProduct>> products(String query) async {
    final response = await _client.get(
      ApiPaths.purchaseProducts,
      parse: parseListOf(PurchaseProduct.fromJson),
      query: {'q': query},
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Name, company and phone; 15 at most. What the party box suggests.
  Future<List<Supplier>> searchSuppliers(String query) async {
    final response = await _client.get(
      ApiPaths.supplierSearch,
      parse: parseListOf(Supplier.fromJson),
      query: {'q': query},
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Never retried: a second one is a second bill, and a second lot of stock.
  Future<PurchaseCreated> create(PurchaseDraft draft) async {
    final response = await _client.post(
      ApiPaths.purchases,
      parse: parseObject(PurchaseCreated.fromJson),
      body: draft.toBody(),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// `multipart/form-data`, one `photos[]` part per file. Dio writes the
  /// boundary into the content type itself; nothing here sets one by hand.
  ///
  /// Sent **after** the bill exists and never as part of it: a purchase is
  /// stock and money, and a dropped upload must not cost the shop that.
  Future<PhotoUpload> uploadPhotos(int purchaseId, List<PhotoFile> files) async {
    final form = FormData();
    for (final file in files) {
      form.files.add(
        MapEntry(
          'photos[]',
          MultipartFile.fromBytes(file.bytes, filename: file.name),
        ),
      );
    }
    final response = await _client.post(
      ApiPaths.purchasePhotos(purchaseId),
      parse: parseListOf(PurchasePhoto.fromJson),
      body: form,
    );
    return PhotoUpload(
      photos: response.data,
      accepted: response.meta.intValue('accepted') ?? response.data.length,
      remaining: response.meta.intValue('remaining') ?? 0,
    );
  }

  Future<void> deletePhoto(int purchaseId, int photoId) => _client.delete(
        ApiPaths.purchasePhoto(purchaseId, photoId),
        parse: parseNothing,
        cancelToken: _cancel,
      );

  Future<int> createSupplier({
    required String name,
    String? company,
    String? phone,
    String? address,
  }) async {
    final response = await _client.post(
      ApiPaths.suppliers,
      parse: parseObject((json) => json),
      body: {
        'name': name,
        'company': ?company,
        'phone': ?phone,
        'address': ?address,
      },
      cancelToken: _cancel,
    );
    final id = response.data['id'];
    return id is num ? id.toInt() : 0;
  }

  Future<void> updateSupplier(
    int id, {
    required String name,
    String? company,
    String? phone,
    String? address,
  }) =>
      _client.patch(
        ApiPaths.supplier(id),
        parse: parseNothing,
        body: {
          'name': name,
          'company': ?company,
          'phone': ?phone,
          'address': ?address,
        },
        cancelToken: _cancel,
      );

  /// `GET /accounts`'s account list, for a role that may read it.
  Future<List<PosAccount>> accounts() async {
    final response = await _client.get(
      ApiPaths.accounts,
      parse: parseObject((json) => json),
      cancelToken: _cancel,
    );
    final raw = response.data['accounts'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(PosAccount.fromJson).toList();
  }
}

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return PurchasesRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

final purchasesProvider =
    FutureProvider.autoDispose.family<PurchasePage, String>((ref, query) {
  ref.watch(sessionScopeProvider);
  return ref.watch(purchasesRepositoryProvider).list(query: query);
});

final purchaseProductsProvider = FutureProvider.autoDispose
    .family<List<PurchaseProduct>, String>((ref, query) {
  ref.watch(sessionScopeProvider);
  return ref.watch(purchasesRepositoryProvider).products(query);
});

/// The accounts a payment to a supplier can leave from.
///
/// There is no purchase endpoint for them, so they come from wherever this
/// role may read accounts: the till's lookups, or `GET /accounts`. A stock
/// keeper holds neither, and then the bill goes up without an `accountId` and
/// the server uses the shop's default.
final purchaseAccountsProvider =
    FutureProvider.autoDispose<List<PosAccount>>((ref) async {
  ref.watch(sessionScopeProvider);
  final permissions = ref.watch(permissionsProvider);
  try {
    if (permissions.has(P.accountsAccountView)) {
      return await ref.watch(purchasesRepositoryProvider).accounts();
    }
    if (permissions.has(P.posSaleCreate)) {
      return (await ref.watch(posRepositoryProvider).lookups()).accounts;
    }
  } catch (_) {
    // Paying from the default account is still paying.
  }
  return const [];
});
