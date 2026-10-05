import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/session/session_controller.dart';
import 'team_models.dart';

/// `docs/MOBILE-API-NEW.md` section 5.9 and section 6, "Settings and team".
///
/// Two member endpoints, two identifiers: suspending takes the member's
/// [StoreUserId], changing a role takes the person's [UserId]. The types keep
/// them apart.
class TeamRepository {
  TeamRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  Future<SettingsOverview> overview() async {
    final response = await _client.get(
      ApiPaths.settings,
      parse: parseObject((json) => json),
      cancelToken: _cancel,
    );
    return SettingsOverview.fromJson(response.data, response.meta);
  }

  Future<void> updateStore(StoreDraft draft) => _client.patch(
    ApiPaths.settingsStore,
    parse: parseNothing,
    body: draft.toBody(),
    cancelToken: _cancel,
  );

  /// `422 plan_limit` when the plan's branches are used up.
  Future<int> createBranch(BranchDraft draft) async {
    final response = await _client.post(
      ApiPaths.settingsBranches,
      parse: parseObject((json) => json),
      body: draft.toBody(),
      cancelToken: _cancel,
    );
    final id = response.data['id'];
    return id is num ? id.toInt() : 0;
  }

  Future<void> updateBranch(int id, BranchDraft draft) => _client.patch(
    ApiPaths.settingsBranch(id),
    parse: parseNothing,
    body: draft.toBody(),
    cancelToken: _cancel,
  );

  /// `422 plan_limit`, `duplicate` or `bad_role`; the message says which.
  Future<MemberAdded> addMember(MemberDraft draft) async {
    final response = await _client.post(
      ApiPaths.settingsMembers,
      parse: parseObject(MemberAdded.fromJson),
      body: draft.toBody(),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Suspend or reactivate. `422 self` for one's own row.
  Future<void> setMemberActive(StoreUserId member, {required bool active}) =>
      _client.patch(
        ApiPaths.settingsMemberStatus(member.value),
        parse: parseNothing,
        body: {'active': active},
        cancelToken: _cancel,
      );

  /// `422 self`, `403 forbidden_role` (a role above one's own).
  Future<void> changeRole(UserId user, {required int roleId}) => _client.patch(
    ApiPaths.settingsMemberRole(user.value),
    parse: parseNothing,
    body: {'roleId': roleId},
    cancelToken: _cancel,
  );

  Future<RoleDetail> role(int id) async {
    final response = await _client.get(
      ApiPaths.settingsRole(id),
      parse: parseObject(RoleDetail.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<ActivityLog> activity(ActivityQuery query) async {
    final response = await _client.get(
      ApiPaths.settingsActivity,
      parse: parseListOf(ActivityEntry.fromJson),
      query: query.toQuery(),
      cancelToken: _cancel,
    );
    return ActivityLog.from(response.data, response.meta);
  }
}

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return TeamRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

final settingsOverviewProvider = FutureProvider.autoDispose<SettingsOverview>((
  ref,
) {
  ref.watch(sessionScopeProvider);
  return ref.watch(teamRepositoryProvider).overview();
});

final activityLogProvider = FutureProvider.autoDispose
    .family<ActivityLog, ActivityQuery>((ref, query) {
      ref.watch(sessionScopeProvider);
      return ref.watch(teamRepositoryProvider).activity(query);
    });

final roleDetailProvider = FutureProvider.autoDispose.family<RoleDetail, int>((
  ref,
  id,
) {
  ref.watch(sessionScopeProvider);
  return ref.watch(teamRepositoryProvider).role(id);
});
