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

  // POS — docs/MOBILE-API-UPDATED.md section 6, "POS"
  static const posLookups = '/pos/lookups';
  static const posSearch = '/pos/search';
  static const posCheckout = '/pos/checkout';
  static const posHold = '/pos/hold';
  static String posHoldResume(int id) => '/pos/hold/$id/resume';
  static String posHoldDiscard(int id) => '/pos/hold/$id';
  static const posShiftOpen = '/pos/shift/open';
  static const posShiftClose = '/pos/shift/close';
  static const packagesSellable = '/packages/sellable';

  // Sales
  static const sales = '/sales';
  static String sale(int id) => '/sales/$id';
  static String saleReturns(int id) => '/sales/$id/returns';
  static String salePayments(int id) => '/sales/$id/payments';

  /// New in the updated spec: a void undoes the whole sale, where a return only
  /// brings goods back. `pos.sale.void`, and `GET /sales/{id}` gates it with
  /// `meta.mayVoid`.
  static String saleVoid(int id) => '/sales/$id/void';

  // Customers
  static const customers = '/customers';
  static const customerSearch = '/customers/search';
  static const customerQuick = '/customers/quick';
  static String customer(int id) => '/customers/$id';
  static String customerLedger(int id) => '/customers/$id/ledger';
  static String customerPoints(int id) => '/customers/$id/points';

  // Reports used by the counter
  static const reportDues = '/reports/dues';

  /// The two endpoints that need no token. The auth interceptor skips these.
  static const anonymous = {login, publicPermissions};
}
