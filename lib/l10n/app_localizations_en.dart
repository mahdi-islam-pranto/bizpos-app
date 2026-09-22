// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'bizPOS';

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
  String get printingSoon => 'Bluetooth printing arrives in a later phase.';

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
}
