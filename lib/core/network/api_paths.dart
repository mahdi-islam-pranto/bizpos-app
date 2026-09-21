/// Every path the app knows, in one place. All are relative to the base URL,
/// which already ends in `/api/v1`.
class ApiPaths {
  const ApiPaths._();

  // Auth and session
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const devices = '/auth/devices';
  static String device(int id) => '/auth/devices/$id';
  static const switchStore = '/auth/switch-store';
  static const switchBranch = '/auth/switch-branch';
  static const me = '/me';
  static const preferences = '/me/preferences';
  static const publicPermissions = '/public/permissions';
  static const palette = '/palette';

  /// The two endpoints that need no token. The auth interceptor skips these.
  static const anonymous = {login, publicPermissions};
}
