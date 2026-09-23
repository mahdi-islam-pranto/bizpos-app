import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/envelope.dart';
import '../../../core/session/session_controller.dart';
import 'package_models.dart';

/// The list and the endpoint's own say on managing it.
class PackagePage {
  const PackagePage({required this.packages, required this.meta});

  final List<Package> packages;
  final Meta meta;

  /// Tri-state: absent means the permission alone decides.
  bool? get mayManage => meta.flag('mayManage');
}

/// `docs/MOBILE-API-NEW.md` section 6, "Packages (bundles)". Not paginated:
/// the list is the store's bundles, and `q` narrows it.
class PackagesRepository {
  PackagesRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  Future<PackagePage> list({String? query}) async {
    final response = await _client.get(
      ApiPaths.packages,
      parse: parseListOf(Package.fromJson),
      query: {'q': query},
      cancelToken: _cancel,
    );
    return PackagePage(packages: response.data, meta: response.meta);
  }

  /// The picker behind "add a product to this bundle".
  Future<List<PackageProduct>> products(String query) async {
    final response = await _client.get(
      ApiPaths.packageProducts,
      parse: parseListOf(PackageProduct.fromJson),
      query: {'q': query},
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<Package> create(PackageDraft draft) async {
    final response = await _client.post(
      ApiPaths.packages,
      parse: parseObject(Package.fromJson),
      body: draft.toBody(),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Items are replaced, not merged.
  Future<Package> update(int id, PackageDraft draft) async {
    final response = await _client.patch(
      ApiPaths.package(id),
      parse: parseObject(Package.fromJson),
      body: draft.toBody(),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Returns the new `availability`, which is not simply "on" or "off": a
  /// package switched on outside its window comes back `scheduled` or
  /// `expired`.
  Future<PackageAvailability> setActive(int id, bool isActive) async {
    final response = await _client.patch(
      ApiPaths.packageActive(id),
      parse: parseObject((json) => json),
      body: {'isActive': isActive},
      cancelToken: _cancel,
    );
    return PackageAvailability.parse('${response.data['availability']}');
  }

  Future<void> delete(int id) => _client.delete(
        ApiPaths.package(id),
        parse: parseNothing,
        cancelToken: _cancel,
      );
}

final packagesRepositoryProvider = Provider<PackagesRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return PackagesRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

/// Keyed on the query, so a store switch re-runs it against the new
/// repository rather than leaving a cancelled future on screen.
final packagesProvider =
    FutureProvider.autoDispose.family<PackagePage, String>((ref, query) {
  ref.watch(sessionScopeProvider);
  return ref.watch(packagesRepositoryProvider).list(query: query);
});

final packageProductsProvider = FutureProvider.autoDispose
    .family<List<PackageProduct>, String>((ref, query) {
  ref.watch(sessionScopeProvider);
  return ref.watch(packagesRepositoryProvider).products(query);
});
