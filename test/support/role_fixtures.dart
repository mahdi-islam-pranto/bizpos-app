import 'package:bizpos_app/core/permissions/permission_set.dart';
import 'package:bizpos_app/core/permissions/permissions.dart';

/// The default permissions of each preset role, transcribed from the matrix in
/// `docs/MOBILE-API-NEW.md` section 3.
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
    // `pos.sale.void` got its endpoint in docs/MOBILE-API-NEW.md. The
    // permission matrix has no row for it, but section 3 defines a manager as
    // the owner minus "voiding invoices" — so it belongs to the owner, and the
    // derived manager list below takes it away.
    P.posSaleVoid,
    // Catalogue
    P.catalogProductSearch,
    P.catalogProductImport,
    P.catalogProductSuggest,
    P.catalogSuggestionReview,
    // Products and stock. Create and delete were added to the API by
    // docs/MOBILE-API-NEW.md and are held by the owner on the running
    // backend — checked against the seeded `owner@rahman.test`.
    P.inventoryProductView,
    P.inventoryProductCreate,
    P.inventoryProductUpdate,
    P.inventoryProductDelete,
    P.inventoryProductViewCost,
    P.inventoryStockView,
    P.inventoryAdjustCreate,
    P.inventoryAdjustApprove,
    P.inventoryTransferCreate,
    P.inventoryTransferApprove,
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
  /// The owner minus the four things section 3 takes away: the profit report,
  /// changing roles, voiding an invoice, and the deletes the API offers today —
  /// which since docs/MOBILE-API-NEW.md means deleting a product.
  static final manager = owner
      .where((p) =>
          p != P.reportProfitView &&
          p != P.settingsRoleManage &&
          p != P.posSaleVoid &&
          p != P.inventoryProductDelete)
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
    // Verified against the seeded `stock@rahman.test` on the running backend:
    // a stock keeper may create products but may **not** delete one, so the
    // trashed list and the delete button belong to the owner and the manager.
    P.inventoryProductCreate,
    P.inventoryProductUpdate,
    P.inventoryProductViewCost,
    P.inventoryStockView,
    P.inventoryAdjustCreate,
    P.inventoryTransferCreate,
    P.inventoryTransferApprove,
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
