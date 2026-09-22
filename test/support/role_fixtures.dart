import 'package:bizpos_app/core/permissions/permission_set.dart';
import 'package:bizpos_app/core/permissions/permissions.dart';

/// The default permissions of each preset role, transcribed from the matrix in
/// `docs/MOBILE-API.md` section 3.
///
/// Keeping them here rather than inside one test means the same six roles can
/// be reused by any test that needs to ask "what does this person's app look
/// like".
class Roles {
  const Roles._();

  static const owner = <String>[
    // POS
    P.posSaleCreate,
    P.posSaleChangePrice,
    P.posSaleGiveDiscount,
    P.posSaleHold,
    P.posShiftManage,
    P.posSaleRedeemPoints,
    P.posSalePrint,
    // `pos.sale.void` got its endpoint in docs/MOBILE-API-UPDATED.md. The
    // permission matrix has no row for it, but section 3 defines a manager as
    // the owner minus "voiding invoices" — so it belongs to the owner, and the
    // derived manager list below takes it away.
    P.posSaleVoid,
    // Catalogue
    P.catalogProductSearch,
    P.catalogProductImport,
    P.catalogProductSuggest,
    P.catalogSuggestionReview,
    // Products and stock
    P.inventoryProductView,
    P.inventoryProductUpdate,
    P.inventoryProductViewCost,
    P.inventoryStockView,
    P.inventoryAdjustCreate,
    P.inventoryPackageView,
    P.inventoryPackageManage,
    // Sales
    P.salesInvoiceView,
    P.salesInvoiceViewAll,
    P.salesReturnCreate,
    P.salesPaymentCollect,
    // Customers
    P.customersCustomerView,
    P.customersCustomerCreate,
    P.customersCustomerUpdate,
    P.customersCreditManage,
    P.customersLedgerView,
    P.customersPointsView,
    P.customersPointsAdjust,
    // Purchase
    P.purchaseBillView,
    P.purchaseBillCreate,
    P.purchaseSupplierManage,
    // Accounts
    P.accountsAccountView,
    P.accountsAccountManage,
    P.accountsTransferCreate,
    P.accountsExpenseCreate,
    P.accountsExpenseDelete,
    P.accountsCategoryManage,
    // Reports
    P.reportSalesView,
    P.reportProfitView,
    P.reportStockView,
    P.reportDueView,
    // Settings
    P.settingsStoreView,
    P.settingsStoreUpdate,
    P.settingsBranchManage,
    P.settingsUserManage,
    P.settingsRoleManage,
    P.settingsActivityView,
  ];

  /// "Owner minus profit report, role management and voiding invoices" — the
  /// doc's own wording, expressed as exactly that so the two cannot drift apart.
  static final manager = owner
      .where((p) =>
          p != P.reportProfitView &&
          p != P.settingsRoleManage &&
          p != P.posSaleVoid)
      .toList();

  static const cashier = <String>[
    P.posSaleCreate,
    P.posSaleHold,
    P.posShiftManage,
    P.posSaleRedeemPoints,
    P.posSalePrint,
    P.catalogProductSearch,
    P.inventoryProductView,
    P.inventoryStockView,
    P.inventoryPackageView,
    P.salesInvoiceView,
    P.salesPaymentCollect,
    P.customersCustomerView,
    P.customersCustomerCreate,
    P.customersPointsView,
  ];

  static const stockKeeper = <String>[
    P.catalogProductSearch,
    P.catalogProductImport,
    P.catalogProductSuggest,
    P.inventoryProductView,
    P.inventoryProductUpdate,
    P.inventoryProductViewCost,
    P.inventoryStockView,
    P.inventoryAdjustCreate,
    P.inventoryPackageView,
    P.inventoryPackageManage,
    P.purchaseBillView,
    P.purchaseBillCreate,
    P.purchaseSupplierManage,
    P.reportStockView,
  ];

  static const accountant = <String>[
    P.inventoryProductView,
    P.inventoryProductViewCost,
    P.inventoryStockView,
    P.salesInvoiceViewAll,
    P.salesPaymentCollect,
    P.customersCustomerView,
    P.customersLedgerView,
    P.customersPointsView,
    P.purchaseBillView,
    P.accountsAccountView,
    P.accountsAccountManage,
    P.accountsTransferCreate,
    P.accountsExpenseCreate,
    P.accountsExpenseDelete,
    P.accountsCategoryManage,
    P.reportSalesView,
    P.reportProfitView,
    P.reportStockView,
    P.reportDueView,
  ];

  /// Read-only view of everything. No create, edit, delete or approve.
  static const auditor = <String>[
    P.catalogProductSearch,
    P.inventoryProductView,
    P.inventoryProductViewCost,
    P.inventoryStockView,
    P.inventoryPackageView,
    P.salesInvoiceView,
    P.salesInvoiceViewAll,
    P.customersCustomerView,
    P.customersLedgerView,
    P.customersPointsView,
    P.purchaseBillView,
    P.accountsAccountView,
    P.reportSalesView,
    P.reportProfitView,
    P.reportStockView,
    P.reportDueView,
    P.settingsStoreView,
    P.settingsActivityView,
  ];

  static PermissionSet set(List<String> permissions) =>
      PermissionSet(permissions);

  static final superAdmin =
      PermissionSet(const <String>[], isSuperAdmin: true);
}
