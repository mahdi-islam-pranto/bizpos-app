import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/session/session_controller.dart';
import 'dashboard_models.dart';

/// `GET /dashboard?range=` — section 5.8. Preferred over fanning the four
/// report endpoints out, because it is the one call that has every figure next
/// to the others.
class DashboardRepository {
  DashboardRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  Future<Dashboard> load(DashboardQuery query) async {
    final response = await _client.get(
      ApiPaths.dashboard,
      parse: parseObject((json) => json),
      query: query.toQuery(),
      cancelToken: _cancel,
    );
    return Dashboard.fromJson(response.data, response.meta);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return DashboardRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

final dashboardProvider = FutureProvider.autoDispose
    .family<Dashboard, DashboardQuery>((ref, query) {
      ref.watch(sessionScopeProvider);
      return ref.watch(dashboardRepositoryProvider).load(query);
    });
