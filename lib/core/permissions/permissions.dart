/// Every permission string the server checks.
///
/// These mirror the matrix in `docs/MOBILE-API.md` section 3. The app is built
/// from the list `GET /me` returns — **never** from `role.name`, because an
/// owner can revoke a single permission while the role name stays `cashier`.
class P {
  const P._();

  // POS
  static const posSaleCreate = 'pos.sale.create';
  static const posSalePrint = 'pos.sale.print';
  static const posSaleHold = 'pos.sale.hold';
  static const posSaleChangePrice = 'pos.sale.change_price';
  static const posSaleGiveDiscount = 'pos.sale.give_discount';
  static const posSaleRedeemPoints = 'pos.sale.redeem_points';
  static const posShiftManage = 'pos.shift.manage';

  // Sales
  static const salesInvoiceView = 'sales.invoice.view';
  static const salesInvoiceViewAll = 'sales.invoice.view_all';
  static const salesReturnCreate = 'sales.return.create';
  static const salesPaymentCollect = 'sales.payment.collect';

  // Customers
  static const customersCustomerView = 'customers.customer.view';
  static const customersCustomerCreate = 'customers.customer.create';
  static const customersCustomerUpdate = 'customers.customer.update';
  static const customersLedgerView = 'customers.ledger.view';
  static const customersPointsView = 'customers.points.view';
  static const customersPointsAdjust = 'customers.points.adjust';
  static const customersCreditManage = 'customers.credit.manage';

  // Inventory
  static const inventoryProductView = 'inventory.product.view';
  static const inventoryProductUpdate = 'inventory.product.update';
  static const inventoryProductViewCost = 'inventory.product.view_cost';
  static const inventoryStockView = 'inventory.stock.view';
  static const inventoryAdjustCreate = 'inventory.adjust.create';
  static const inventoryPackageView = 'inventory.package.view';
  static const inventoryPackageManage = 'inventory.package.manage';

  // Catalogue
  static const catalogProductSearch = 'catalog.product.search';
  static const catalogProductImport = 'catalog.product.import';
  static const catalogProductSuggest = 'catalog.product.suggest';
  static const catalogSuggestionReview = 'catalog.suggestion.review';

  // Purchase
  static const purchaseBillView = 'purchase.bill.view';
  static const purchaseBillCreate = 'purchase.bill.create';
  static const purchaseSupplierManage = 'purchase.supplier.manage';

  // Accounts
  static const accountsAccountView = 'accounts.account.view';
  static const accountsAccountManage = 'accounts.account.manage';
  static const accountsExpenseCreate = 'accounts.expense.create';
  static const accountsExpenseDelete = 'accounts.expense.delete';
  static const accountsCategoryManage = 'accounts.category.manage';
  static const accountsTransferCreate = 'accounts.transfer.create';

  // Reports
  static const reportSalesView = 'report.sales.view';
  static const reportProfitView = 'report.profit.view';
  static const reportStockView = 'report.stock.view';
  static const reportDueView = 'report.due.view';

  // Settings and team
  static const settingsStoreView = 'settings.store.view';
  static const settingsStoreUpdate = 'settings.store.update';
  static const settingsBranchManage = 'settings.branch.manage';
  static const settingsUserManage = 'settings.user.manage';
  static const settingsRoleManage = 'settings.role.manage';
  static const settingsActivityView = 'settings.activity.view';

  // Platform (Super Admin only)
  static const adminStoreView = 'admin.store.view';
  static const adminStoreCreate = 'admin.store.create';
  static const adminStoreUpdate = 'admin.store.update';
  static const adminStoreImpersonate = 'admin.store.impersonate';
  static const adminSuggestionReview = 'admin.suggestion.review';

  /// The updated spec (`docs/MOBILE-API-UPDATED.md`) gave the platform direct
  /// control of the shared catalogue: `GET/POST/PATCH/DELETE /admin/catalog`.
  static const adminCatalogManage = 'admin.catalog.manage';

  // ---------------------------------------------------------------------------
  // Added by docs/MOBILE-API-UPDATED.md — these used to be section 7 stubs and
  // now have real endpoints.
  // ---------------------------------------------------------------------------

  /// `POST /sales/{id}/void` — undoes a whole sale, where a return only brings
  /// goods back. Always paired with the detail response's `meta.mayVoid`.
  static const posSaleVoid = 'pos.sale.void';

  /// `POST /products`, `DELETE /products/{id}` (soft) and
  /// `POST /products/{id}/restore`. Phase 2 builds the screens.
  static const inventoryProductCreate = 'inventory.product.create';
  static const inventoryProductDelete = 'inventory.product.delete';

  // ---------------------------------------------------------------------------
  // NO ENDPOINT — docs/MOBILE-API.md section 7.
  //
  // These appear in the role matrix, but nothing in the API serves them yet, in
  // the app or in the web workspace. They are listed so nobody has to guess why
  // they are missing. Do not build a screen or a nav entry for one: ask for the
  // endpoint first.
  // ---------------------------------------------------------------------------
  static const inventoryTransferCreate = 'inventory.transfer.create'; // §7
  static const inventoryTransferApprove = 'inventory.transfer.approve'; // §7
  static const inventoryAdjustApprove = 'inventory.adjust.approve'; // §7
  static const purchaseBillUpdate = 'purchase.bill.update'; // §7
  static const purchaseBillDelete = 'purchase.bill.delete'; // §7
  static const purchasePaymentCreate = 'purchase.payment.create'; // §7
  static const purchaseReturnCreate = 'purchase.return.create'; // §7
  static const customersCustomerDelete = 'customers.customer.delete'; // §7
  static const accountsClosingManage = 'accounts.closing.manage'; // §7
  static const reportVatView = 'report.vat.view'; // §7
  static const reportExport = 'report.export'; // §7
  static const settingsTemplateManage = 'settings.template.manage'; // §7
  static const settingsApikeyManage = 'settings.apikey.manage'; // §7
  static const adminPlanManage = 'admin.plan.manage'; // §7
}
