import '../network/api_client.dart';
import '../network/api_paths.dart';
import 'me.dart';

/// The auth and session endpoints. Everything here is documented in
/// `docs/MOBILE-API.md` section 2.
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  /// Needs no token. Limited to 10 tries a minute, so this is never retried —
  /// a retry loop would lock the counter out.
  Future<LoginResult> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final response = await _client.post<LoginResult>(
      ApiPaths.login,
      body: {
        'email': email,
        'password': password,
        if (deviceName != null && deviceName.isNotEmpty)
          'deviceName': deviceName,
      },
      parse: parseObject(LoginResult.fromJson),
    );
    return response.data;
  }

  /// Who am I, where am I, what may I do.
  ///
  /// Called at start-up, after switching store or branch, when the app returns
  /// to the foreground after a while, and after a 403 — an owner may have
  /// changed this person's role in the meantime.
  Future<Me> me() async {
    final response = await _client.get<Me>(
      ApiPaths.me,
      parse: parseObject(Me.fromJson),
    );
    return response.data;
  }

  /// The branch resets to the new store's default, and permissions may differ,
  /// so the caller must refetch [me] afterwards.
  Future<void> switchStore(int storeId) => _client.post<void>(
        ApiPaths.switchStore,
        body: {'storeId': storeId},
        parse: parseNothing,
      );

  Future<void> switchBranch(int branchId) => _client.post<void>(
        ApiPaths.switchBranch,
        body: {'branchId': branchId},
        parse: parseNothing,
      );

  /// `locale` is `bn` or `en`; `theme` is one of the five the API accepts. Both
  /// are optional and saved on the account, so the web workspace sees them too.
  Future<void> savePreferences({String? locale, String? theme}) =>
      _client.patch<void>(
        ApiPaths.preferences,
        body: {'locale': ?locale, 'theme': ?theme},
        parse: parseNothing,
      );

  Future<List<DeviceSession>> devices() async {
    final response = await _client.get<List<DeviceSession>>(
      ApiPaths.devices,
      parse: parseListOf(DeviceSession.fromJson),
    );
    return response.data;
  }

  /// Signs that phone out — what to do with a lost one.
  Future<void> revokeDevice(int id) => _client.delete<void>(
        ApiPaths.device(id),
        parse: parseNothing,
      );

  /// Signs *this* device out. The token stops working immediately.
  Future<void> logout() => _client.post<void>(
        ApiPaths.logout,
        parse: parseNothing,
      );
}
