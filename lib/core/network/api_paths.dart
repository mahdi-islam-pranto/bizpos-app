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

  /// A shop signing itself up — the one endpoint that creates an account.
  /// Throttled to five an hour per address.
  static const register = '/auth/register';

  /// Store types, plans and the trial length, for the sign-up form. Open,
  /// because the form is.
  static const publicStoreTypes = '/public/store-types';

  /// The shops this account may work in, and opening another one. Outside
  /// every store permission: opening a shop of your own is not an action
  /// inside somebody else's.
  static const stores = '/stores';
  static const palette = '/palette';

  // POS — docs/MOBILE-API-NEW.md section 6, "POS"
  static const posLookups = '/pos/lookups';
  static const posSearch = '/pos/search';
  static const posCheckout = '/pos/checkout';
  static const posHold = '/pos/hold';
  static String posHoldResume(int id) => '/pos/hold/$id/resume';
  static String posHoldDiscard(int id) => '/pos/hold/$id';
  static const posShiftOpen = '/pos/shift/open';
  static const posShiftClose = '/pos/shift/close';

  /// The drawer's takings, a day at a time. Answers for today with
  /// `shift: null` when no drawer is open.
  static const posShiftReport = '/pos/shift/report';
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

  // Products and stock — section 6, "Products and stock"
  static const products = '/products';
  static String product(int id) => '/products/$id';
  static const productStats = '/products/stats';

  /// Companies this shop deals in and the units list, for the product form.
  static const productLookups = '/products/lookups';
  static String productHistory(int id) => '/products/$id/history';
  static String productPrices(int id) => '/products/$id/prices';
  static String productAdjust(int id) => '/products/$id/adjust';

  /// New in the updated spec: a soft delete, undone by this.
  static String productRestore(int id) => '/products/$id/restore';

  // Packages (bundles)
  static const packages = '/packages';
  static String package(int id) => '/packages/$id';
  static String packageActive(int id) => '/packages/$id/active';
  static const packageProducts = '/packages/products';

  // Catalogue — section 5.6 and section 6, "Catalogue"
  static const catalog = '/catalog';
  static String catalogAdopt(int id) => '/catalog/$id/adopt';
  static const catalogCheck = '/catalog/check';
  static const catalogLookups = '/catalog/lookups';
  static const catalogSuggestions = '/catalog/suggestions';
  static String catalogSuggestionReview(int id) =>
      '/catalog/suggestions/$id/review';

  // Purchase — section 5.4 and section 6, "Purchase"
  static const purchases = '/purchases';
  static const purchaseProducts = '/purchases/products';

  /// `multipart/form-data`: the one call in the API that is not JSON.
  static String purchasePhotos(int id) => '/purchases/$id/photos';
  static String purchasePhoto(int id, int photoId) =>
      '/purchases/$id/photos/$photoId';
  static const suppliers = '/suppliers';

  /// Accounts and expenses. Phase 3 builds the screen; goods-in only reads
  /// the account list, to say where a payment to a supplier leaves from.
  static const accounts = '/accounts';
  static const supplierSearch = '/suppliers/search';
  static String supplier(int id) => '/suppliers/$id';

  static const accountsTransfer = '/accounts/transfer';
  static const expenses = '/expenses';
  static String expense(int id) => '/expenses/$id';
  static const expenseCategories = '/expense-categories';
  static String expenseCategory(int id) => '/expense-categories/$id';

  // Reports — section 5.8 and section 6, "Reports"
  /// The owner's whole screen in one call. `report.sales.view`.
  static const dashboard = '/dashboard';
  static const reportSales = '/reports/sales';
  static const reportProfit = '/reports/profit';
  static const reportStock = '/reports/stock';
  static const reportDues = '/reports/dues';

  // Settings and team — section 5.9 and section 6, "Settings and team"
  static const settings = '/settings';
  static const settingsStore = '/settings/store';
  static const settingsBranches = '/settings/branches';
  static String settingsBranch(int id) => '/settings/branches/$id';
  static const settingsMembers = '/settings/members';

  /// Takes the member's `storeUserId`.
  static String settingsMemberStatus(int storeUserId) =>
      '/settings/members/$storeUserId/status';

  /// Takes the user's own `id`.
  static String settingsMemberRole(int userId) =>
      '/settings/members/$userId/role';
  static String settingsRole(int id) => '/settings/roles/$id';
  static const settingsActivity = '/settings/activity';

  // Super admin — section 5.10 and section 6, "Super admin"
  static const adminOverview = '/admin/overview';
  static const adminStores = '/admin/stores';
  static String adminStore(int id) => '/admin/stores/$id';
  static String adminStoreStatus(int id) => '/admin/stores/$id/status';
  static String adminStoreExtend(int id) => '/admin/stores/$id/extend';
  static String adminStoreImpersonate(int id) =>
      '/admin/stores/$id/impersonate';
  static String adminSuggestionReview(int id) =>
      '/admin/suggestions/$id/review';
  static const adminCatalog = '/admin/catalog';
  static const adminCatalogLookups = '/admin/catalog/lookups';
  static String adminCatalogEntry(int id) => '/admin/catalog/$id';
  static String adminCatalogRestore(int id) => '/admin/catalog/$id/restore';

  /// The two endpoints that need no token. The auth interceptor skips these.
  static const anonymous = {
    login,
    register,
    publicPermissions,
    publicStoreTypes,
  };
}
