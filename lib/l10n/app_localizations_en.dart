// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BizPOS';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle => 'Use the account your store owner gave you.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get signOut => 'Sign out';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get serverLabel => 'Server';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get sell => 'Sell';

  @override
  String get invoices => 'Invoices';

  @override
  String get customers => 'Customers';

  @override
  String get products => 'Products';

  @override
  String get packages => 'Packages';

  @override
  String get catalogue => 'Catalogue';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get purchase => 'Purchase';

  @override
  String get accounts => 'Accounts';

  @override
  String get reports => 'Reports';

  @override
  String get team => 'Team';

  @override
  String get platform => 'Platform';

  @override
  String get more => 'More';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get menu => 'Menu';

  @override
  String get mainMenu => 'Main menu';

  @override
  String get profile => 'Profile';

  @override
  String get comingSoonTitle => 'Not built yet';

  @override
  String comingSoonBody(String screen) {
    return '$screen arrives in a later phase. Your role already has access to it.';
  }

  @override
  String get noStoreTitle => 'No store assigned';

  @override
  String get noStoreBody =>
      'This account does not belong to an active store yet, or it has been suspended. Ask your store owner to add you.';

  @override
  String get notAllowedTitle => 'Not allowed';

  @override
  String get notAllowedBody => 'Your role does not include this screen.';

  @override
  String get store => 'Store';

  @override
  String get branch => 'Branch';

  @override
  String get role => 'Role';

  @override
  String get switchStore => 'Switch store';

  @override
  String get switchBranch => 'Switch branch';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get devices => 'Signed-in devices';

  @override
  String get devicesBody => 'Sign out a phone you no longer have.';

  @override
  String get thisDevice => 'This device';

  @override
  String lastUsed(String when) {
    return 'Last used $when';
  }

  @override
  String get revokeDevice => 'Sign out';

  @override
  String revokeDeviceConfirm(String name) {
    return 'Sign $name out? Whoever holds it will need the password again.';
  }

  @override
  String get supportMode =>
      'Support mode — you are inside this store as platform staff';

  @override
  String sessionExpiresSoon(String date) {
    return 'This device will be signed out on $date.';
  }

  @override
  String get permissionsHeading => 'What you may do';

  @override
  String permissionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permissions',
      one: '1 permission',
      zero: 'No permissions',
    );
    return '$_temp0';
  }

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get genericError => 'Something went wrong.';

  @override
  String get offline => 'No connection';

  @override
  String get requiredField => 'This is required';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get posTitle => 'Sell';

  @override
  String get posSearchHint => 'Scan or search by name, barcode';

  @override
  String get posScan => 'Scan a barcode';

  @override
  String get posTabProducts => 'Products';

  @override
  String get posTabPackages => 'Packages';

  @override
  String get posNoResults => 'Nothing matched';

  @override
  String get posNoResultsBody => 'Try part of the name, or the barcode.';

  @override
  String get posStartTitle => 'Ring it up';

  @override
  String get posStartBody => 'Scan a barcode or search for the first item.';

  @override
  String inStock(String count) {
    return '$count in stock';
  }

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get lowStock => 'Low stock';

  @override
  String addedToCart(String name) {
    return '$name added';
  }

  @override
  String get packageBadge => 'Bundle';

  @override
  String buildable(String count) {
    return '$count can be made';
  }

  @override
  String get cart => 'Cart';

  @override
  String get cartEmpty => 'The cart is empty';

  @override
  String get cartEmptyBody => 'Scanned items show up here.';

  @override
  String cartItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get subtotal => 'Subtotal';

  @override
  String get orderDiscount => 'Discount on the bill';

  @override
  String get estimatedTotal => 'Estimated total';

  @override
  String get estimatedNote => 'The server works out VAT and the final total.';

  @override
  String get lineDiscount => 'Line discount';

  @override
  String get unitPrice => 'Unit price';

  @override
  String editLine(String name) {
    return 'Edit $name';
  }

  @override
  String get removeLine => 'Remove';

  @override
  String overStockWarning(String count) {
    return 'Only $count left in this branch. The server will refuse more.';
  }

  @override
  String get clearCart => 'Empty the cart';

  @override
  String get clearCartConfirm => 'Remove every item and start again?';

  @override
  String get noteOnSale => 'Note on this sale';

  @override
  String get customer => 'Customer';

  @override
  String get walkInCustomer => 'Walk-in customer';

  @override
  String get chooseCustomer => 'Choose a customer';

  @override
  String get customerSearchHint => 'Phone or name (2+ characters)';

  @override
  String get customerSearchShort => 'Type at least two characters';

  @override
  String get addCustomer => 'Add a customer';

  @override
  String get quickAddCustomer => 'New customer';

  @override
  String get customerName => 'Name';

  @override
  String get customerPhone => 'Phone';

  @override
  String get customerEmail => 'Email';

  @override
  String get customerAddress => 'Address';

  @override
  String get creditLimit => 'Credit limit';

  @override
  String get creditLimitHelp => 'How much this customer may owe at once.';

  @override
  String customerExists(String name) {
    return '$name was already on file with that phone.';
  }

  @override
  String customerAdded(String name) {
    return '$name added';
  }

  @override
  String get customerSaved => 'Saved';

  @override
  String get clearCustomer => 'Remove customer';

  @override
  String get walkInNoCredit => 'Walk-in customers cannot buy on credit.';

  @override
  String get dueLabel => 'Due';

  @override
  String get points => 'Points';

  @override
  String pointsBalance(String count) {
    return '$count points';
  }

  @override
  String get noPhone => 'No phone';

  @override
  String get charge => 'Charge';

  @override
  String get payment => 'Payment';

  @override
  String get payments => 'Payments';

  @override
  String get addPayment => 'Add another payment';

  @override
  String get payMethodCash => 'Cash';

  @override
  String get payMethodCard => 'Card';

  @override
  String get payMethodBkash => 'bKash';

  @override
  String get payMethodNagad => 'Nagad';

  @override
  String get payMethodRocket => 'Rocket';

  @override
  String get payMethodBank => 'Bank';

  @override
  String get account => 'Account';

  @override
  String get reference => 'Reference';

  @override
  String get amountReceived => 'Amount received';

  @override
  String get exactAmount => 'Exact';

  @override
  String get changeDue => 'Change to give back';

  @override
  String get remainingDue => 'Left as due';

  @override
  String get dueNeedsCustomer => 'Leaving a due needs a named customer.';

  @override
  String get creditOff => 'This store does not allow credit sales.';

  @override
  String get redeemPoints => 'Redeem points';

  @override
  String redeemPointsHelp(String count, String worth) {
    return '$count points available, worth $worth.';
  }

  @override
  String get redeemMax => 'Use the most allowed';

  @override
  String get redeemCapNote =>
      'The server caps this, so the receipt may show fewer.';

  @override
  String get completeSale => 'Complete the sale';

  @override
  String get payFull => 'Pay in full';

  @override
  String get saleComplete => 'Sale complete';

  @override
  String invoiceNumber(String no) {
    return 'Invoice $no';
  }

  @override
  String get totalCharged => 'Total';

  @override
  String get paidLabel => 'Paid';

  @override
  String pointsEarned(String count) {
    return '$count points earned';
  }

  @override
  String pointsRedeemed(String count) {
    return '$count points redeemed';
  }

  @override
  String get newSale => 'Next sale';

  @override
  String get viewReceipt => 'View receipt';

  @override
  String get holdCart => 'Hold this cart';

  @override
  String get heldCarts => 'Held carts';

  @override
  String heldCartsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count held carts',
      one: '1 held cart',
      zero: 'No held carts',
    );
    return '$_temp0';
  }

  @override
  String get holdLabel => 'A name to find it by';

  @override
  String get holdLabelHint => 'Blue shirt man';

  @override
  String holdSaved(String label) {
    return 'Held as “$label”';
  }

  @override
  String get resume => 'Resume';

  @override
  String get discard => 'Discard';

  @override
  String discardHoldConfirm(String label) {
    return 'Throw away “$label”? The cart cannot be brought back.';
  }

  @override
  String get resumeOverwrites => 'Resuming replaces what is in the cart now.';

  @override
  String get noHeldCarts => 'Nothing is on hold';

  @override
  String get cashDrawer => 'Cash drawer';

  @override
  String get openDrawer => 'Open the drawer';

  @override
  String get closeDrawer => 'Close the drawer';

  @override
  String get drawerOpen => 'Drawer open';

  @override
  String get drawerClosed => 'Drawer closed';

  @override
  String get drawerClosedBody =>
      'Sales still go through, but none of them are counted in a drawer.';

  @override
  String get openingCash => 'Cash in the drawer now';

  @override
  String get countedCash => 'Cash counted';

  @override
  String openedAt(String when) {
    return 'Opened $when';
  }

  @override
  String get expectedCash => 'Expected';

  @override
  String get countedLabel => 'Counted';

  @override
  String get difference => 'Difference';

  @override
  String shortBy(String amount) {
    return 'Short by $amount';
  }

  @override
  String overBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get balanced => 'It balances';

  @override
  String get drawerOpened => 'The drawer is open';

  @override
  String get closingNote => 'Note';

  @override
  String get done => 'Done';

  @override
  String get invoiceSearchHint => 'Invoice no, customer or phone';

  @override
  String get filterToday => 'Today';

  @override
  String get filterWeek => '7 days';

  @override
  String get filterAll => 'All';

  @override
  String invoiceCount(String count) {
    return '$count invoices';
  }

  @override
  String get invoiceTotal => 'Total';

  @override
  String get invoiceDue => 'Due';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusPartial => 'Partial';

  @override
  String get statusUnpaid => 'Unpaid';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusReturned => 'Returned';

  @override
  String get statusVoid => 'Void';

  @override
  String get noInvoices => 'No invoices yet';

  @override
  String get noInvoicesBody => 'Sales made at this counter show up here.';

  @override
  String get ownInvoicesOnly => 'Your own sales';

  @override
  String soldBy(String name) {
    return 'Sold by $name';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get loadMore => 'Load more';

  @override
  String get invoice => 'Invoice';

  @override
  String get receipt => 'Receipt';

  @override
  String get items => 'Items';

  @override
  String get vat => 'VAT';

  @override
  String get discount => 'Discount';

  @override
  String get grandTotal => 'Total';

  @override
  String get collectDue => 'Collect due';

  @override
  String get acceptReturn => 'Accept a return';

  @override
  String get voidInvoice => 'Cancel this sale';

  @override
  String get printReceipt => 'Print';

  @override
  String get share => 'Share';

  @override
  String get collectTitle => 'Collect a due';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get collectAmount => 'Amount collected';

  @override
  String get collectAll => 'Collect it all';

  @override
  String collected(String amount) {
    return '$amount collected';
  }

  @override
  String get overPayment => 'That is more than is owed.';

  @override
  String get returnTitle => 'Accept a return';

  @override
  String get returnBody =>
      'Choose what is coming back. Stock goes up and the customer\'s balance comes down.';

  @override
  String get returnQty => 'Returning';

  @override
  String get returnReason => 'Reason';

  @override
  String get returnReasonHint => 'Damaged pack';

  @override
  String get returnNothing => 'Nothing is selected to return.';

  @override
  String returnDone(String no) {
    return 'Return $no recorded';
  }

  @override
  String returnOf(String count) {
    return 'of $count';
  }

  @override
  String get voidTitle => 'Cancel this sale';

  @override
  String get voidBody =>
      'A return brings goods back and the invoice stands. Cancelling says the sale should not have happened: stock goes back, the money is reversed out of its account, the customer\'s debt is credited and points are undone. The invoice stays on the list marked void.';

  @override
  String get voidReason => 'Why is it being cancelled?';

  @override
  String get voidReasonHint => 'Rung up on the wrong customer';

  @override
  String get voidConfirm => 'Cancel the sale';

  @override
  String voidDone(String no, String count) {
    return '$no cancelled. $count units went back on the shelf.';
  }

  @override
  String get voidNotAllowed => 'Only a completed invoice can be cancelled.';

  @override
  String get customersTitle => 'Customers';

  @override
  String get customerSearchListHint => 'Name or phone';

  @override
  String get noCustomers => 'No customers yet';

  @override
  String get noCustomersBody =>
      'Add one at the till, or with the button below.';

  @override
  String get editCustomer => 'Edit customer';

  @override
  String get newCustomer => 'New customer';

  @override
  String get ledger => 'Ledger';

  @override
  String get ledgerEmpty => 'Nothing on this ledger yet';

  @override
  String get debit => 'Owed';

  @override
  String get credit => 'Paid';

  @override
  String get balance => 'Balance';

  @override
  String get pointsTitle => 'Loyalty points';

  @override
  String pointsWorth(String amount) {
    return 'Worth $amount';
  }

  @override
  String get adjustPoints => 'Adjust points';

  @override
  String get adjustPointsHelp =>
      'A positive number adds, a negative number takes away.';

  @override
  String get pointsNote => 'Why';

  @override
  String pointsAdjusted(String count) {
    return 'Balance is now $count';
  }

  @override
  String get pointsNegative => 'That would take the balance below zero.';

  @override
  String salesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
      zero: 'No sales',
    );
    return '$_temp0';
  }

  @override
  String customerSince(String name) {
    return 'Added by $name';
  }

  @override
  String get viewInvoices => 'Their invoices';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get apply => 'Apply';

  @override
  String get remove => 'Remove';

  @override
  String get search => 'Search';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get notAllowedAction => 'Your role does not include this.';

  @override
  String get cameraDenied =>
      'The camera is not available. Type the barcode instead.';

  @override
  String get typeBarcode => 'Type a barcode';

  @override
  String get scanning => 'Point the camera at the barcode';

  @override
  String get torch => 'Torch';

  @override
  String get productsTitle => 'Products';

  @override
  String get productsSearchHint => 'Name, barcode or SKU';

  @override
  String get productsLowOnly => 'Low stock';

  @override
  String get productsTrashed => 'Deleted';

  @override
  String get productsLive => 'On the shelf';

  @override
  String get productsNone => 'No products yet';

  @override
  String get productsNoneBody =>
      'Add the first one, or bring it in from the catalogue.';

  @override
  String get productsNoResults => 'Nothing matched';

  @override
  String get productsNoResultsBody =>
      'Try part of the name, the barcode or the SKU.';

  @override
  String get productsNoneTrashed => 'Nothing deleted';

  @override
  String get productsNoneTrashedBody =>
      'Deleted products wait here until they are restored.';

  @override
  String get addProduct => 'Add a product';

  @override
  String get editProduct => 'Edit';

  @override
  String get productSaved => 'Saved';

  @override
  String productAdded(String name) {
    return '$name is on the shelf';
  }

  @override
  String get stockValue => 'Stock value';

  @override
  String lowStockCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count running low',
      one: '1 running low',
      zero: 'Nothing low',
    );
    return '$_temp0';
  }

  @override
  String expiringCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expiring',
      one: '1 expiring',
      zero: 'None expiring',
    );
    return '$_temp0';
  }

  @override
  String productCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String showingOf(String shown, String total) {
    return 'Showing $shown of $total';
  }

  @override
  String get costLabel => 'Cost';

  @override
  String get saleLabel => 'Sale';

  @override
  String get wholesaleLabel => 'Wholesale';

  @override
  String get mrpLabel => 'MRP';

  @override
  String get marginLabel => 'Margin';

  @override
  String get vatLabel => 'VAT';

  @override
  String get skuLabel => 'SKU';

  @override
  String get barcodeLabel => 'Barcode';

  @override
  String get unitLabel => 'Unit';

  @override
  String get brandLabel => 'Brand';

  @override
  String get categoryLabel => 'Category';

  @override
  String get minimumStockLabel => 'Reorder at';

  @override
  String get openingStockLabel => 'Opening stock';

  @override
  String get trackBatchLabel => 'Track batches and expiry';

  @override
  String get genericNameLabel => 'Generic name';

  @override
  String get productNameLabel => 'Name';

  @override
  String get inactiveBadge => 'Not for sale';

  @override
  String get deletedBadge => 'Deleted';

  @override
  String onShelf(String qty) {
    return '$qty on the shelf';
  }

  @override
  String get changePrices => 'Change prices';

  @override
  String get pricesSaved => 'Prices changed';

  @override
  String get pricesUnchanged => 'Nothing to change';

  @override
  String get priceHistory => 'Price history';

  @override
  String get stockHistory => 'Stock history';

  @override
  String get currentPrice => 'Now';

  @override
  String get adjustStock => 'Adjust stock';

  @override
  String get adjustQtyLabel => 'Change by';

  @override
  String get adjustHelp =>
      'Signed and not zero. −3 takes three off the shelf, 3 puts three back.';

  @override
  String get adjustReasonLabel => 'Reason';

  @override
  String get adjustReasonHint => 'Choose a reason';

  @override
  String get adjustReasonOther => 'Other (type a reason)';

  @override
  String get adjustReasonTyped => 'Type the reason';

  @override
  String get adjustIsDamage => 'This is damage, not a correction';

  @override
  String get adjustDone => 'Stock adjusted';

  @override
  String get deleteProduct => 'Delete this product';

  @override
  String get deleteProductBody =>
      'It leaves the till, the lists and every stock figure. Past sales still name it, and you can restore it.';

  @override
  String deleteProductDone(String qty) {
    return 'Deleted. $qty came off the shelf.';
  }

  @override
  String get restoreProduct => 'Restore';

  @override
  String restoreProductDone(String name) {
    return '$name is back';
  }

  @override
  String deletedOn(String date) {
    return 'Deleted $date';
  }

  @override
  String get noMovements => 'No stock movements yet';

  @override
  String get noPrices => 'No price changes yet';

  @override
  String get movementOpening => 'Opening';

  @override
  String get movementPurchase => 'Goods in';

  @override
  String get movementSale => 'Sold';

  @override
  String get movementReturn => 'Returned';

  @override
  String get movementAdjustment => 'Adjusted';

  @override
  String get movementDamage => 'Damage';

  @override
  String get movementTransfer => 'Transfer';

  @override
  String balanceAfter(String qty) {
    return 'Left: $qty';
  }

  @override
  String get priceBelowCost => 'Below cost';

  @override
  String get saleBelowPurchase => 'Selling price can\'t be below the cost.';

  @override
  String get costHidden => 'Costs are hidden for your role.';

  @override
  String get yes => 'Yes';

  @override
  String get trialEndsToday =>
      'Your trial ends today. Contact the platform to keep this shop open.';

  @override
  String trialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left on your trial',
      one: '1 day left on your trial',
    );
    return '$_temp0';
  }

  @override
  String get profitPercentLabel => 'Profit %';

  @override
  String get saleAboveMrp => 'Above the printed MRP.';

  @override
  String get wholesaleBlankHelp => 'Blank = selling price';

  @override
  String get markupLabel => 'Markup';

  @override
  String get stopSelling => 'Stop selling';

  @override
  String get resumeSelling => 'Sell again';

  @override
  String get stoppedSellingNote =>
      'Not offered at the till. Stock and history are kept.';

  @override
  String get productStopped => 'No longer sold at the till.';

  @override
  String get productResumed => 'Back on sale.';

  @override
  String get newProduct => 'New product';

  @override
  String get lineBelowCost =>
      'A line is priced below its cost, and the sale would be refused. Change its price or discount.';

  @override
  String get lineBelowCostShort => 'Below cost — the sale would be refused.';

  @override
  String get discountBelowCost =>
      'That discount takes the bill below what the goods cost.';

  @override
  String get orderDiscountPercent => 'Bill discount (%)';

  @override
  String get previousDueLabel => 'Previous due';

  @override
  String get collectPreviousDue => 'Collect previous due too';

  @override
  String get outstandingLabel => 'Owes in total';

  @override
  String get cashTaken => 'Cash taken';

  @override
  String get digitalTaken => 'Digital payments';

  @override
  String get duesCollected => 'Dues collected';

  @override
  String get dueGiven => 'Given on credit';

  @override
  String shiftSpansDays(int count) {
    return 'This drawer has been open for $count days.';
  }

  @override
  String get lineDiscounts => 'Line discounts';

  @override
  String get youSaved => 'You saved (vs MRP)';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get openingBalanceHelp =>
      'What they owed before this shop used BizPOS.';

  @override
  String get ledgerSale => 'Sale';

  @override
  String get ledgerPayment => 'Payment';

  @override
  String get ledgerReturn => 'Return';

  @override
  String get ledgerVoid => 'Void';

  @override
  String get ledgerOpeningCorrection => 'Opening balance corrected';

  @override
  String get registerTitle => 'Create your shop';

  @override
  String get registerSubtitle =>
      'Sign your shop up and start selling straight away — the till, cash drawer and walk-in customer are set up for you.';

  @override
  String registerTrialNote(int days) {
    return 'Free for $days days. After that an admin has to extend it; nothing is deleted.';
  }

  @override
  String openShopTrialNote(int days) {
    return 'A new shop runs free for $days days, like any sign-up.';
  }

  @override
  String get registerShopSection => 'The shop';

  @override
  String get registerOwnerSection => 'The owner';

  @override
  String get shopName => 'Shop name';

  @override
  String get storeTypeLabel => 'Kind of shop';

  @override
  String get storeTypeHelp => 'Decides which product catalogue you start from.';

  @override
  String get shopAddressOptional => 'Address (optional)';

  @override
  String get branchNameOptional => 'Branch name (optional)';

  @override
  String get branchNameHint => 'Main Branch';

  @override
  String get ownerName => 'Your name';

  @override
  String get phone => 'Phone';

  @override
  String get shopPhoneHelp => 'How the platform reaches you about your shop.';

  @override
  String get invalidPhone => 'That doesn\'t look like a phone number.';

  @override
  String get passwordRule => 'At least 6 characters.';

  @override
  String get registerAction => 'Create shop';

  @override
  String get registering => 'Creating your shop…';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get signInInstead => 'Sign in';

  @override
  String get registerCta => 'New shop? Create an account';

  @override
  String get signInThenAddShop =>
      'After signing in, open your new shop from Profile → Open another shop.';

  @override
  String get openAnotherShop => 'Open another shop';

  @override
  String get openShopAction => 'Open shop';

  @override
  String shopOpened(String name) {
    return '$name is open. You\'re working in it now.';
  }

  @override
  String shopLocked(String name) {
    return '$name has been closed by the platform.';
  }

  @override
  String get packagesTitle => 'Packages';

  @override
  String get newPackage => 'New package';

  @override
  String get packagesSearchHint => 'Search packages';

  @override
  String get packagesEmpty => 'No packages yet';

  @override
  String get packagesEmptyBody =>
      'Bundle products that sell together at one price.';

  @override
  String get deletePackage => 'Delete package';

  @override
  String deletePackageBody(String name) {
    return 'Delete $name? Past sales keep it; the till stops offering it.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get packageDeleted => 'Package deleted.';

  @override
  String get packageSaved => 'Package saved.';

  @override
  String fromDate(String date) {
    return 'From $date';
  }

  @override
  String untilDate(String date) {
    return 'Until $date';
  }

  @override
  String packageSaves(String amount) {
    return 'Saves $amount';
  }

  @override
  String packageBuildable(String count) {
    return 'Can make $count';
  }

  @override
  String get packageOnSale => 'On sale';

  @override
  String get availabilityLive => 'Live';

  @override
  String get availabilityScheduled => 'Scheduled';

  @override
  String get availabilityExpired => 'Expired';

  @override
  String get availabilityInactive => 'Off';

  @override
  String get packageName => 'Package name';

  @override
  String get packagePrice => 'Package price';

  @override
  String get packageItems => 'What\'s inside';

  @override
  String get packageNeedsItems => 'Add at least one product.';

  @override
  String get packageComponents => 'Items at their own prices';

  @override
  String get packageSaving => 'Customer saves';

  @override
  String get packageAboveItems => 'Costs more than the items alone';

  @override
  String get packageStartsAny => 'Starts now';

  @override
  String get packageEndsNever => 'No end date';

  @override
  String get packageClearDates => 'Clear dates';

  @override
  String get packageWindowInvalid => 'The end date must come after the start.';

  @override
  String get description => 'Description';

  @override
  String get addToPackage => 'Add to package';

  @override
  String get catalogueTitle => 'Catalogue';

  @override
  String get catalogueSearchHint => 'Search by name, company or generic';

  @override
  String get catalogueAll => 'All';

  @override
  String catalogueMine(String count) {
    return 'In my store ($count)';
  }

  @override
  String catalogueMissing(String count) {
    return 'Not in my store ($count)';
  }

  @override
  String get catalogueNoResults => 'Nothing in the catalogue by that name';

  @override
  String get catalogueNoResultsBody =>
      'If the product is real, suggest it and it can go on sale.';

  @override
  String get catalogueNothingMissing =>
      'Your shop already stocks everything in the catalogue';

  @override
  String get suggestProduct => 'Suggest a product';

  @override
  String get inMyStore => 'In my store';

  @override
  String get pendingBadge => 'Pending';

  @override
  String get addToStore => 'Add to my store';

  @override
  String adoptedProduct(String name) {
    return '$name is on your shelf.';
  }

  @override
  String get alreadyInStoreNote => 'Your store already has this product.';

  @override
  String get mrpHelp => 'The price printed on the pack.';

  @override
  String get adoptOpeningHelp => 'How many you have now.';

  @override
  String get localNameLabel => 'Name in my shop';

  @override
  String get localNameHelp => 'Optional';

  @override
  String get suggestNameHelp => 'We check the catalogue as you type.';

  @override
  String get suggestReason => 'Why stock it? (optional)';

  @override
  String get suggestReasonHelp => 'Helps whoever approves it.';

  @override
  String get sendSuggestion => 'Send suggestion';

  @override
  String get suggestionEndorsed =>
      'On sale in your store now. The platform will review it for other shops.';

  @override
  String get suggestionSent => 'Sent for approval.';

  @override
  String get alreadyInCatalogue => 'Already in the catalogue';

  @override
  String alreadyInCatalogueBody(String name) {
    return 'The catalogue already has $name. Send yours anyway?';
  }

  @override
  String get sendAnyway => 'Send anyway';

  @override
  String get verdictExists =>
      'This is already in the catalogue — add it instead of suggesting it.';

  @override
  String get verdictVariant =>
      'The same product exists at another strength. Yours is a different product.';

  @override
  String get verdictOtherBrand =>
      'The same product exists from another company.';

  @override
  String get verdictSimilar => 'Something similar exists. Worth a look first.';

  @override
  String get verdictNew => 'Nothing like it in the catalogue — it\'s new.';

  @override
  String get adoptThisInstead => 'Add this one instead';

  @override
  String get suggestionsTitle => 'Suggestions';

  @override
  String suggestionsPending(int count) {
    return '$count waiting for you';
  }

  @override
  String get suggestionsEmpty => 'No suggestions';

  @override
  String get suggestionsEmptyBody =>
      'Products your staff suggest appear here for approval.';

  @override
  String get statusPending => 'Waiting';

  @override
  String get statusEndorsed => 'On sale here';

  @override
  String get statusApproved => 'In the catalogue';

  @override
  String get statusRejected => 'Rejected';

  @override
  String askedBy(String name) {
    return 'Asked by $name';
  }

  @override
  String get reject => 'Reject';

  @override
  String get approveAndStock => 'Approve';

  @override
  String get reviewNoteOptional => 'Note (optional)';

  @override
  String get rejectReason => 'Why not?';

  @override
  String get suggestionApproved => 'Approved — it\'s on sale in your store.';

  @override
  String get suggestionRejected => 'Rejected.';

  @override
  String get purchaseTitle => 'Purchases';

  @override
  String get suppliers => 'Suppliers';

  @override
  String get supplier => 'Supplier';

  @override
  String get goodsIn => 'Goods in';

  @override
  String get purchaseSearchHint => 'Search by bill no or supplier';

  @override
  String get purchasesEmpty => 'No purchases yet';

  @override
  String get purchasesEmptyBody =>
      'Record goods as they come in, and the stock rises with them.';

  @override
  String billsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills',
      one: '1 bill',
    );
    return '$_temp0';
  }

  @override
  String get owedToSuppliers => 'Owed to suppliers';

  @override
  String get owedToSupplier => 'Owed to the supplier';

  @override
  String get noSupplier => 'No supplier';

  @override
  String photosUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos added',
      one: '1 photo added',
    );
    return '$_temp0';
  }

  @override
  String get deletePhoto => 'Remove photo';

  @override
  String get deletePhotoBody =>
      'Remove this photo from the bill? The bill itself is not changed.';

  @override
  String billPhotos(int count, int max) {
    return 'Bill photos ($count/$max)';
  }

  @override
  String get noBillPhotos => 'No photos of this bill.';

  @override
  String get billPhotosHelp =>
      'Add a photo of the paper bill — it goes up after the bill is saved.';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get photoPickFailed => 'Couldn\'t open the camera or gallery.';

  @override
  String photosTooBig(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos are over 8 MB and were left out',
      one: '1 photo is over 8 MB and was left out',
    );
    return '$_temp0';
  }

  @override
  String get addSupplier => 'Add supplier';

  @override
  String get suppliersEmpty => 'No suppliers yet';

  @override
  String get supplierSaved => 'Supplier saved.';

  @override
  String get supplierName => 'Name';

  @override
  String get supplierCompany => 'Company (optional)';

  @override
  String get supplierSearch => 'Who is it from?';

  @override
  String newSupplierNote(String name) {
    return '\"$name\" is new — it will be saved with this bill.';
  }

  @override
  String get pickSupplierFromList => 'Pick a supplier from the list.';

  @override
  String get itemsReceived => 'What came in';

  @override
  String get noItemsReceived => 'Add the products on this bill.';

  @override
  String batchShort(String batch) {
    return 'Batch $batch';
  }

  @override
  String expiresShort(String date) {
    return 'Exp $date';
  }

  @override
  String get billDiscountPercent => 'Discount on the bill';

  @override
  String get paidToSupplier => 'Paid now';

  @override
  String get paidFollowsTotal => 'The whole bill, unless you type less.';

  @override
  String get paidOverTotal => 'More than the bill.';

  @override
  String get payInFull => 'Pay in full';

  @override
  String get payNothing => 'Nothing paid';

  @override
  String get paidFrom => 'Paid from';

  @override
  String get purchaseNote => 'Note (optional)';

  @override
  String get purchaseNoteHint => 'Supplier\'s invoice no';

  @override
  String get saveBill => 'Save bill';

  @override
  String purchaseSaved(String refNo) {
    return 'Bill $refNo saved. Stock is updated.';
  }

  @override
  String get photoUploadFailed => 'The photos didn\'t go up';

  @override
  String photoUploadFailedBody(String reason) {
    return 'The bill is saved. The photos could not be uploaded: $reason';
  }

  @override
  String get skipPhotos => 'Skip';

  @override
  String get pickProduct => 'Pick a product';

  @override
  String get purchaseAddFromCatalogue =>
      'Not in your store yet? Add it from the catalogue first.';

  @override
  String get tracksBatches => 'Batch and expiry';

  @override
  String get quantityReceived => 'Quantity';

  @override
  String get unitCost => 'Cost each';

  @override
  String get batchNo => 'Batch no';

  @override
  String get expiryDate => 'Expiry date';

  @override
  String get notYours => 'Not in your access';

  @override
  String get sectionLocked => 'You don\'t have access to this section.';

  @override
  String get scopeBranch => 'This branch';

  @override
  String get scopeStore => 'Whole store';

  @override
  String get scopeMixed => 'Branch and store';

  @override
  String get reportSales => 'Sales';

  @override
  String get reportProfit => 'Profit';

  @override
  String get reportStock => 'Stock';

  @override
  String get reportDues => 'Dues';

  @override
  String get reportWindow => 'Period';

  @override
  String lastDays(int days) {
    return 'Last $days days';
  }

  @override
  String lastMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get customRange => 'Pick dates…';

  @override
  String rangeCapped(int days) {
    return 'Trimmed to the last $days days — the longest the dashboard shows.';
  }

  @override
  String get revenue => 'Revenue';

  @override
  String get averageSale => 'Average sale';

  @override
  String get dailySales => 'Sales by day';

  @override
  String get topProducts => 'Best sellers';

  @override
  String get nothingSold => 'Nothing sold in this period.';

  @override
  String qtySold(String qty) {
    return '$qty sold';
  }

  @override
  String get profit => 'Profit';

  @override
  String get byMethod => 'By payment method';

  @override
  String get byStaff => 'By staff';

  @override
  String get netProfit => 'Net profit';

  @override
  String get grossProfit => 'Gross profit';

  @override
  String get howItAddsUp => 'How it adds up';

  @override
  String get costOfGoods => 'Cost of goods';

  @override
  String get returnsLabel => 'Returns';

  @override
  String get expensesLabel => 'Expenses';

  @override
  String get stockOnHand => 'Stock';

  @override
  String get unitsOnHand => 'Units on hand';

  @override
  String get nothingLow => 'Nothing is running low.';

  @override
  String minimumIs(String qty) {
    return 'Minimum $qty';
  }

  @override
  String get expiringSoon => 'Expiring soon';

  @override
  String get nothingExpiring => 'Nothing expires soon.';

  @override
  String onHand(String qty) {
    return '$qty on hand';
  }

  @override
  String get deadStock => 'No sale in 90 days';

  @override
  String get nothingDead => 'Everything on the shelf has sold lately.';

  @override
  String get owedToShop => 'Owed to the shop';

  @override
  String get whoOwes => 'Who owes';

  @override
  String get nobodyOwes => 'Nobody owes the shop anything.';

  @override
  String daysOld(int days) {
    return '$days days old';
  }

  @override
  String get overCreditLimit => 'Over credit limit';

  @override
  String get headline => 'At a glance';

  @override
  String get discountGiven => 'Discount given';

  @override
  String get dueRaised => 'Left as due';

  @override
  String get moneyIn => 'Money in';

  @override
  String get collectedTotal => 'Collected';

  @override
  String get onTodaysBills => 'On this period\'s bills';

  @override
  String get onOldDues => 'On older dues';

  @override
  String get onPreviousDue => 'Old debt settled with a bill';

  @override
  String get billsSettledBy => 'How the bills were paid';

  @override
  String get capital => 'Where the money is now';

  @override
  String get stockAtCost => 'Stock at cost';

  @override
  String get receivable => 'Receivable';

  @override
  String get inAccounts => 'In accounts';

  @override
  String get payable => 'Payable';

  @override
  String get invested => 'Invested';

  @override
  String get netWorth => 'Net';

  @override
  String get dues => 'Dues';

  @override
  String get total => 'Total';

  @override
  String timesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return '$_temp0';
  }

  @override
  String get cashDrawers => 'Cash drawers';

  @override
  String get restockSoon => 'Order soon';

  @override
  String get rising => 'Selling more';

  @override
  String get falling => 'Selling less';

  @override
  String get moverNew => 'New';

  @override
  String get moverStopped => 'Stopped';

  @override
  String perDay(String qty) {
    return '$qty/day';
  }

  @override
  String daysCover(String days) {
    return 'lasts $days days';
  }

  @override
  String daysLeft(String days) {
    return '$days days left';
  }

  @override
  String get overview => 'Overview';

  @override
  String get transactions => 'Transactions';

  @override
  String get transfer => 'Transfer';

  @override
  String get transferDone => 'Money moved.';

  @override
  String get fromAccount => 'From';

  @override
  String get toAccount => 'To';

  @override
  String get sameAccount => 'Pick two different accounts.';

  @override
  String get expenseTypes => 'Expense types';

  @override
  String get expenseType => 'Expense type';

  @override
  String get expenseTypeName => 'Name';

  @override
  String get newExpenseType => 'New type…';

  @override
  String get editExpenseType => 'Edit expense type';

  @override
  String get newTypeHelp => 'Saved as a new expense type with this expense.';

  @override
  String get noExpenseTypes => 'No expense types yet.';

  @override
  String get expenseTypeSaved => 'Expense type saved.';

  @override
  String get deleteExpenseType => 'Delete type';

  @override
  String get deleteExpenseTypeBody =>
      'A type that has expenses behind it is retired instead, so the old expenses keep their name.';

  @override
  String get expenseTypeDeleted => 'Expense type deleted.';

  @override
  String expenseTypeRetired(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Retired — $count expenses use it.',
      one: 'Retired — 1 expense uses it.',
      zero: 'Retired.',
    );
    return '$_temp0';
  }

  @override
  String get retired => 'Retired';

  @override
  String get iconLabel => 'Icon';

  @override
  String get defaultAmount => 'Default amount';

  @override
  String get defaultAmountHelp => 'What a quick tile records in one tap.';

  @override
  String get quickTile => 'Quick tile';

  @override
  String get quickTileHelp => 'Shown as a one-tap tile on the accounts screen.';

  @override
  String get salaryType => 'Salary';

  @override
  String get salaryTypeHelp =>
      'Asks for the employee\'s name and the month it covers.';

  @override
  String get inUse => 'In use';

  @override
  String get recordExpense => 'Expense';

  @override
  String get expense => 'Expense';

  @override
  String expenseRecorded(String name, String amount) {
    return '$name: $amount recorded.';
  }

  @override
  String get undo => 'Undo';

  @override
  String get amount => 'Amount';

  @override
  String get employeeName => 'Employee';

  @override
  String get employeeNameHelp => 'A name, not a login — anyone the shop pays.';

  @override
  String get salaryMonth => 'Salary for';

  @override
  String get salaryMonthHelp => 'The month it covers, not the day it was paid.';

  @override
  String get dateLabel => 'Date';

  @override
  String get backdatedHelp => 'Recorded on an earlier day.';

  @override
  String get note => 'Note';

  @override
  String get recordedBy => 'Recorded by';

  @override
  String forMonth(String month) {
    return 'for $month';
  }

  @override
  String get noExpenses => 'No expenses yet.';

  @override
  String get noTransactions => 'No transactions yet.';

  @override
  String get deleteExpense => 'Delete expense';

  @override
  String deleteExpenseBody(String amount, String account) {
    return '$amount goes back into $account.';
  }

  @override
  String get expenseDeleted =>
      'Expense deleted. The money is back in the account.';

  @override
  String get spentToday => 'Spent today';

  @override
  String get spentThisMonth => 'Spent this month';

  @override
  String get salaryThisMonth => 'Salary this month';

  @override
  String get quickExpenses => 'Quick expenses';

  @override
  String get salaryAsks => 'Asks for a name';

  @override
  String get typeAmount => 'Type amount';

  @override
  String get addAccount => 'Add account';

  @override
  String get accountAdded => 'Account added.';

  @override
  String get accountName => 'Account name';

  @override
  String get accountNameHint => 'e.g. City Bank, bKash merchant';

  @override
  String get accountCash => 'Cash';

  @override
  String get accountBank => 'Bank';

  @override
  String get accountMfs => 'Mobile money';

  @override
  String get txnSale => 'Sale';

  @override
  String get txnDuePayment => 'Due collected';

  @override
  String get txnRefund => 'Refund';

  @override
  String get qtyPickerTitle => 'Quantity';

  @override
  String get qtyCustom => 'Custom quantity';

  @override
  String get teamMembers => 'Members';

  @override
  String get branchesTab => 'Branches';

  @override
  String get storeTab => 'Store';

  @override
  String get activityTab => 'Activity';

  @override
  String get addMember => 'Add member';

  @override
  String get addBranch => 'Add branch';

  @override
  String get editBranch => 'Edit branch';

  @override
  String activeMembers(int count) {
    return 'Active ($count)';
  }

  @override
  String suspendedMembers(int count) {
    return 'Suspended ($count)';
  }

  @override
  String get membersEmpty => 'No one on the team yet';

  @override
  String get youBadge => 'You';

  @override
  String get activeBadge => 'Active';

  @override
  String get suspendedBadge => 'Suspended';

  @override
  String get lockedBadge => 'Locked';

  @override
  String get neverSignedIn => 'Never signed in';

  @override
  String lastSignedIn(String when) {
    return 'Last signed in $when';
  }

  @override
  String get changeRole => 'Change role';

  @override
  String get chooseRole => 'Choose a role';

  @override
  String whatRoleCanDo(String role) {
    return 'What $role can do';
  }

  @override
  String get builtInRole =>
      'A built-in role. Its permissions are set by the platform.';

  @override
  String roleChanged(String name, String role) {
    return '$name is now $role';
  }

  @override
  String get suspendMember => 'Suspend';

  @override
  String get reactivateMember => 'Reactivate';

  @override
  String suspendMemberTitle(String name) {
    return 'Suspend $name?';
  }

  @override
  String reactivateMemberTitle(String name) {
    return 'Reactivate $name?';
  }

  @override
  String get suspendMemberBody =>
      'They lose access to this store at their next step. Nothing they did is deleted, and you can reactivate them at any time.';

  @override
  String get reactivateMemberBody =>
      'They can sign in to this store again, with the role they had.';

  @override
  String memberSuspended(String name) {
    return '$name suspended';
  }

  @override
  String memberReactivated(String name) {
    return '$name can sign in again';
  }

  @override
  String get cannotChangeSelf =>
      'This is you. Nobody can change their own role or suspend themselves — ask another owner.';

  @override
  String get readOnlyTeam => 'You can see the team but not change it.';

  @override
  String get fullName => 'Full name';

  @override
  String get memberFormNote =>
      'If this email already has a BizPOS account, they join with their own password and the one above is not used.';

  @override
  String memberAdded(String name) {
    return '$name added to the team';
  }

  @override
  String memberReusedAccount(String name) {
    return '$name added — they already had an account, so they sign in with their own password.';
  }

  @override
  String get branchName => 'Branch name';

  @override
  String get branchCode => 'Code';

  @override
  String get branchCodeHelp => 'Short and unique, e.g. MRP';

  @override
  String get branchSaved => 'Branch saved';

  @override
  String get branchesNote =>
      'Stock, sales, cash drawers and reports are kept per branch. Switch branch from your profile.';

  @override
  String get youAreHere => 'You are here';

  @override
  String get storeDetails => 'Details';

  @override
  String get edit => 'Edit';

  @override
  String get editStore => 'Edit store';

  @override
  String get addressLabel => 'Address';

  @override
  String get cityLabel => 'City';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get atTheCounter => 'At the counter';

  @override
  String get vatInclusive => 'Included in prices';

  @override
  String get vatExclusive => 'Added on top';

  @override
  String get receiptPaper => 'Receipt paper';

  @override
  String get invoicePrefix => 'Invoice prefix';

  @override
  String get invoicePrefixHelp => 'Printed before every invoice number';

  @override
  String get allowCreditSale => 'Sales on credit (due)';

  @override
  String get allowCreditSaleHelp =>
      'A named customer may pay less than the bill and owe the rest.';

  @override
  String get allowed => 'Allowed';

  @override
  String get notAllowed => 'Not allowed';

  @override
  String get storeSaved => 'Saved';

  @override
  String get loyaltyTitle => 'Loyalty points';

  @override
  String get loyaltyStatus => 'Programme';

  @override
  String get loyaltyOn => 'On';

  @override
  String get loyaltyOff => 'Off';

  @override
  String get loyaltyEnabled => 'Customers earn points';

  @override
  String get loyaltyEarning => 'Earning';

  @override
  String loyaltyEarnRule(String points, String amount) {
    return '$points point(s) for every $amount spent';
  }

  @override
  String get loyaltyEarnPoints => 'Points earned';

  @override
  String get loyaltyEarnPer => 'For every';

  @override
  String get loyaltyWorth => 'One point is worth';

  @override
  String loyaltyPointValue(String amount) {
    return '1 point = $amount';
  }

  @override
  String get loyaltyMinRedeem => 'Fewest points to redeem';

  @override
  String get loyaltyMaxRedeemPct => 'Most of a bill paid by points (%)';

  @override
  String get loyaltyRound => 'Rounding of points earned';

  @override
  String get roundDown => 'Down';

  @override
  String get roundNearest => 'Nearest';

  @override
  String get roundUp => 'Up';

  @override
  String get mustBePositive => 'Must be more than 0';

  @override
  String get percentRange => 'Between 1 and 100';

  @override
  String get activityLocked => 'The activity log is not open to you.';

  @override
  String get activitySearchHint => 'Search the log';

  @override
  String get activitySubject => 'What changed';

  @override
  String get activityAllSubjects => 'Everything';

  @override
  String get activityEmpty => 'Nothing changed in this period';

  @override
  String get activityEmptyBody => 'Try a longer period or another filter.';

  @override
  String get activitySystem => 'System';

  @override
  String get emptyValue => '(empty)';

  @override
  String get platformStores => 'Stores';

  @override
  String platformSuggestions(int count) {
    return 'Suggestions ($count)';
  }

  @override
  String get platformCatalogue => 'Catalogue';

  @override
  String get newStore => 'New store';

  @override
  String get createStore => 'Create store';

  @override
  String get storeSearchHint => 'Name, phone, email or owner';

  @override
  String allStoresCount(int count) {
    return 'All ($count)';
  }

  @override
  String trialEndingCount(int count) {
    return 'Trial ending ($count)';
  }

  @override
  String lockedCount(int count) {
    return 'Locked ($count)';
  }

  @override
  String get noStoresMatch => 'No stores match';

  @override
  String get trialOver => 'Trial over';

  @override
  String get dbNotReady => 'Database not ready';

  @override
  String get dbNotMoved => 'Not moved to its own database yet';

  @override
  String get dbServing => 'Served from its own database';

  @override
  String get planLabel => 'Plan';

  @override
  String get noPlan => 'No plan';

  @override
  String get trialLabel => 'Trial';

  @override
  String get noTimeLimit => 'No time limit';

  @override
  String get ownerLabel => 'Owner';

  @override
  String get createdLabel => 'Created';

  @override
  String get databaseLabel => 'Database';

  @override
  String get timezoneLabel => 'Time zone';

  @override
  String get enterStore => 'Enter for support';

  @override
  String enterStoreTitle(String name) {
    return 'Enter $name?';
  }

  @override
  String get enterStoreBody =>
      'This device moves into that store as platform staff. Everything you do there is logged, and the banner at the top brings you back.';

  @override
  String get youAreInThisStore => 'This device is in this store now';

  @override
  String get reactivateFirst => 'Reactivate the store first';

  @override
  String get leaveSupport => 'Leave';

  @override
  String get leaveSupportFailed =>
      'Could not leave support mode. Switch store from your profile.';

  @override
  String get editStoreDetails => 'Edit details';

  @override
  String get storeTypeChangeWarning =>
      'A different kind of shop reads a different shared catalogue. Products it already has stay, but may no longer be found there.';

  @override
  String get storeTypeChangedNote =>
      'Saved. The store now reads another kind of shop\'s catalogue.';

  @override
  String get extendTrial => 'Extend trial';

  @override
  String get extendUnlimited => 'No time limit';

  @override
  String get extendUnlimitedHelp => 'For a shop that has started paying.';

  @override
  String get extendDays => 'Days to add';

  @override
  String get extendDaysRange => 'Between 1 and 3650 days';

  @override
  String get extendActivate => 'Switch the store on as well';

  @override
  String get extendFromEnd => 'Days are added after the current end date.';

  @override
  String get extendFromToday =>
      'The trial has ended, so days count from today.';

  @override
  String trialCurrentlyEnds(String date) {
    return 'The trial ends $date';
  }

  @override
  String trialNowEnds(String name, String date) {
    return '$name: trial now ends $date';
  }

  @override
  String trialNowUnlimited(String name) {
    return '$name has no time limit now';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get suspendStore => 'Suspend store';

  @override
  String get reactivateStore => 'Reactivate store';

  @override
  String suspendStoreTitle(String name) {
    return 'Suspend $name?';
  }

  @override
  String reactivateStoreTitle(String name) {
    return 'Reactivate $name?';
  }

  @override
  String get suspendStoreBody =>
      'Nobody can sign in to this store while it is suspended. Nothing in it is deleted.';

  @override
  String get reactivateStoreBody => 'Its team can sign in again.';

  @override
  String storeSuspended(String name) {
    return '$name suspended';
  }

  @override
  String storeReactivated(String name) {
    return '$name is active again';
  }

  @override
  String get optionalDetails => 'Optional';

  @override
  String storeCreated(String name) {
    return '$name created';
  }

  @override
  String get ownerReusedAccount =>
      'The owner already had an account and signs in with it.';

  @override
  String get dbProblemTitle =>
      'The store exists, but its database was not finished';

  @override
  String dbSteps(String created, String migrated) {
    return 'Database created: $created · Tables made: $migrated';
  }

  @override
  String get dbProblemNote =>
      'The owner cannot work in it until this is fixed on the server (php artisan tenancy:status).';

  @override
  String get no => 'No';

  @override
  String get approve => 'Approve';

  @override
  String suggestedFrom(String who) {
    return 'From $who';
  }

  @override
  String get platformSuggestionsEmpty => 'No suggestions waiting';

  @override
  String get platformSuggestionsEmptyBody =>
      'Products shops put up for the shared catalogue appear here.';

  @override
  String get platformSuggestionAdded => 'Added to the shared catalogue';

  @override
  String get platformSuggestionMatched =>
      'Approved — it matched an entry already in the catalogue';

  @override
  String get platformSuggestionRejected => 'Rejected';

  @override
  String get newCatalogEntry => 'New entry';

  @override
  String get editCatalogEntry => 'Edit entry';

  @override
  String get allTypes => 'All kinds';

  @override
  String get allStatuses => 'Any status';

  @override
  String deletedCount(int count) {
    return 'Deleted ($count)';
  }

  @override
  String inStoresCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count shops',
      one: 'In 1 shop',
      zero: 'In no shops',
    );
    return '$_temp0';
  }

  @override
  String get catalogStatus => 'Status';

  @override
  String get catalogStatusApproved => 'Approved';

  @override
  String get catalogStatusPending => 'Pending';

  @override
  String get catalogStatusDraft => 'Draft';

  @override
  String get catalogStatusRejected => 'Rejected';

  @override
  String catalogEditNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shops sell this.',
      one: '1 shop sells this.',
    );
    return '$_temp0 Their own names and prices are not touched by an edit here.';
  }

  @override
  String get catalogEntrySaved => 'Saved';

  @override
  String deleteCatalogEntryTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteCatalogEntryBody =>
      'It leaves every catalogue list and the duplicate check. Shops already selling it keep their product and its history.';

  @override
  String catalogEntryDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted — $count shops keep it on their shelves',
      one: 'Deleted — 1 shop keeps it on its shelf',
      zero: 'Deleted',
    );
    return '$_temp0';
  }

  @override
  String get catalogEntryIsDeleted =>
      'This entry is deleted. Restoring it puts it back on every catalogue list.';

  @override
  String get catalogRestore => 'Restore';

  @override
  String get catalogEntryRestored => 'Restored';

  @override
  String noStockLeft(String name) {
    return 'No more $name in stock';
  }

  @override
  String get sellingPriceLabel => 'Selling price';

  @override
  String maxLineDiscount(String amount) {
    return 'Up to $amount keeps this line above cost';
  }

  @override
  String lineDiscountTooHigh(String amount) {
    return 'More than $amount sells below cost';
  }

  @override
  String unitPriceBelowCost(String amount) {
    return 'Below the cost of $amount';
  }

  @override
  String maxBillDiscount(String rate, String amount) {
    return 'Up to $rate% ($amount) keeps the bill above cost';
  }

  @override
  String billDiscountTooHigh(String rate) {
    return 'More than $rate% sells below cost';
  }

  @override
  String get noDiscountRoom =>
      'No room for a discount — the bill is already at cost';

  @override
  String get chooseUnit => 'Choose a unit';

  @override
  String get unitSearchHint => 'Search units, or type a new one';

  @override
  String useNewUnit(String unit) {
    return 'Use “$unit” as a new unit';
  }

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptServedBy => 'Served by';

  @override
  String get receiptItem => 'Item';

  @override
  String get receiptAmount => 'Amount';

  @override
  String get receiptLineDiscounts => 'Item discounts';

  @override
  String get receiptTotal => 'TOTAL';

  @override
  String get receiptYouSaved => 'YOU SAVED';

  @override
  String get receiptThanks => 'Thank you, please come again';

  @override
  String receiptMrpSave(String mrp, String amount, String rate) {
    return 'MRP $mrp · save $amount$rate';
  }

  @override
  String get noPrinterChosen => 'No printer chosen';

  @override
  String get changePrinter => 'Printer';

  @override
  String get choosePrinter => 'Choose a printer';

  @override
  String get paperWidth => 'Paper width';

  @override
  String get noPairedPrinters =>
      'No paired printers. Pair the printer in the phone\'s Bluetooth settings, then try again.';

  @override
  String get bluetoothOff => 'Bluetooth is off. Turn it on to print.';

  @override
  String get bluetoothDenied =>
      'Bluetooth permission was refused. Allow it in the app\'s settings to print.';

  @override
  String get saveAsImage => 'Save as image';

  @override
  String get receiptSaved => 'Receipt saved to the gallery';

  @override
  String get receiptSaveFailed => 'Couldn\'t save the receipt image';

  @override
  String printSent(String printer) {
    return 'Printed on $printer';
  }

  @override
  String printerUnreachableSaved(String printer) {
    return 'Couldn\'t reach $printer, so the receipt was saved to the gallery.';
  }

  @override
  String get bluetoothOffSaved =>
      'Bluetooth is off, so the receipt was saved to the gallery.';

  @override
  String get bluetoothDeniedSaved =>
      'No Bluetooth permission, so the receipt was saved to the gallery.';
}
