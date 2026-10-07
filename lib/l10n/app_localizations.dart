import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BizPOS'**
  String get appName;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the account your store owner gave you.'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @serverLabel.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverLabel;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @packages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packages;

  /// No description provided for @catalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get catalogue;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get mainMenu;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Not built yet'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'{screen} arrives in a later phase. Your role already has access to it.'**
  String comingSoonBody(String screen);

  /// No description provided for @noStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'No store assigned'**
  String get noStoreTitle;

  /// No description provided for @noStoreBody.
  ///
  /// In en, this message translates to:
  /// **'This account does not belong to an active store yet, or it has been suspended. Ask your store owner to add you.'**
  String get noStoreBody;

  /// No description provided for @notAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get notAllowedTitle;

  /// No description provided for @notAllowedBody.
  ///
  /// In en, this message translates to:
  /// **'Your role does not include this screen.'**
  String get notAllowedBody;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @switchStore.
  ///
  /// In en, this message translates to:
  /// **'Switch store'**
  String get switchStore;

  /// No description provided for @switchBranch.
  ///
  /// In en, this message translates to:
  /// **'Switch branch'**
  String get switchBranch;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBangla;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Signed-in devices'**
  String get devices;

  /// No description provided for @devicesBody.
  ///
  /// In en, this message translates to:
  /// **'Sign out a phone you no longer have.'**
  String get devicesBody;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used {when}'**
  String lastUsed(String when);

  /// No description provided for @revokeDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get revokeDevice;

  /// No description provided for @revokeDeviceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign {name} out? Whoever holds it will need the password again.'**
  String revokeDeviceConfirm(String name);

  /// No description provided for @supportMode.
  ///
  /// In en, this message translates to:
  /// **'Support mode — you are inside this store as platform staff'**
  String get supportMode;

  /// No description provided for @sessionExpiresSoon.
  ///
  /// In en, this message translates to:
  /// **'This device will be signed out on {date}.'**
  String sessionExpiresSoon(String date);

  /// No description provided for @permissionsHeading.
  ///
  /// In en, this message translates to:
  /// **'What you may do'**
  String get permissionsHeading;

  /// No description provided for @permissionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No permissions} =1{1 permission} other{{count} permissions}}'**
  String permissionCount(int count);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyTitle;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get genericError;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get offline;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This is required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @posTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get posTitle;

  /// No description provided for @posSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Scan or search by name, barcode'**
  String get posSearchHint;

  /// No description provided for @posScan.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode'**
  String get posScan;

  /// No description provided for @posTabProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get posTabProducts;

  /// No description provided for @posTabPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get posTabPackages;

  /// No description provided for @posNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched'**
  String get posNoResults;

  /// No description provided for @posNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try part of the name, or the barcode.'**
  String get posNoResultsBody;

  /// No description provided for @posStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Ring it up'**
  String get posStartTitle;

  /// No description provided for @posStartBody.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode or search for the first item.'**
  String get posStartBody;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String inStock(String count);

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String addedToCart(String name);

  /// No description provided for @packageBadge.
  ///
  /// In en, this message translates to:
  /// **'Bundle'**
  String get packageBadge;

  /// No description provided for @buildable.
  ///
  /// In en, this message translates to:
  /// **'{count} can be made'**
  String buildable(String count);

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'The cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Scanned items show up here.'**
  String get cartEmptyBody;

  /// No description provided for @cartItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String cartItems(int count);

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @orderDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount on the bill'**
  String get orderDiscount;

  /// No description provided for @estimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get estimatedTotal;

  /// No description provided for @estimatedNote.
  ///
  /// In en, this message translates to:
  /// **'The server works out VAT and the final total.'**
  String get estimatedNote;

  /// No description provided for @lineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Line discount'**
  String get lineDiscount;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get unitPrice;

  /// No description provided for @editLine.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editLine(String name);

  /// No description provided for @removeLine.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLine;

  /// No description provided for @overStockWarning.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left in this branch. The server will refuse more.'**
  String overStockWarning(String count);

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Empty the cart'**
  String get clearCart;

  /// No description provided for @clearCartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove every item and start again?'**
  String get clearCartConfirm;

  /// No description provided for @noteOnSale.
  ///
  /// In en, this message translates to:
  /// **'Note on this sale'**
  String get noteOnSale;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in customer'**
  String get walkInCustomer;

  /// No description provided for @chooseCustomer.
  ///
  /// In en, this message translates to:
  /// **'Choose a customer'**
  String get chooseCustomer;

  /// No description provided for @customerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Phone or name (2+ characters)'**
  String get customerSearchHint;

  /// No description provided for @customerSearchShort.
  ///
  /// In en, this message translates to:
  /// **'Type at least two characters'**
  String get customerSearchShort;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add a customer'**
  String get addCustomer;

  /// No description provided for @quickAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get quickAddCustomer;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customerName;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get customerPhone;

  /// No description provided for @customerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get customerEmail;

  /// No description provided for @customerAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get customerAddress;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditLimit;

  /// No description provided for @creditLimitHelp.
  ///
  /// In en, this message translates to:
  /// **'How much this customer may owe at once.'**
  String get creditLimitHelp;

  /// No description provided for @customerExists.
  ///
  /// In en, this message translates to:
  /// **'{name} was already on file with that phone.'**
  String customerExists(String name);

  /// No description provided for @customerAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String customerAdded(String name);

  /// No description provided for @customerSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get customerSaved;

  /// No description provided for @clearCustomer.
  ///
  /// In en, this message translates to:
  /// **'Remove customer'**
  String get clearCustomer;

  /// No description provided for @walkInNoCredit.
  ///
  /// In en, this message translates to:
  /// **'Walk-in customers cannot buy on credit.'**
  String get walkInNoCredit;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueLabel;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @pointsBalance.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String pointsBalance(String count);

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get noPhone;

  /// No description provided for @charge.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get charge;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add another payment'**
  String get addPayment;

  /// No description provided for @payMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payMethodCash;

  /// No description provided for @payMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payMethodCard;

  /// No description provided for @payMethodBkash.
  ///
  /// In en, this message translates to:
  /// **'bKash'**
  String get payMethodBkash;

  /// No description provided for @payMethodNagad.
  ///
  /// In en, this message translates to:
  /// **'Nagad'**
  String get payMethodNagad;

  /// No description provided for @payMethodRocket.
  ///
  /// In en, this message translates to:
  /// **'Rocket'**
  String get payMethodRocket;

  /// No description provided for @payMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get payMethodBank;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @amountReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get amountReceived;

  /// No description provided for @exactAmount.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get exactAmount;

  /// No description provided for @changeDue.
  ///
  /// In en, this message translates to:
  /// **'Change to give back'**
  String get changeDue;

  /// No description provided for @remainingDue.
  ///
  /// In en, this message translates to:
  /// **'Left as due'**
  String get remainingDue;

  /// No description provided for @dueNeedsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Leaving a due needs a named customer.'**
  String get dueNeedsCustomer;

  /// No description provided for @creditOff.
  ///
  /// In en, this message translates to:
  /// **'This store does not allow credit sales.'**
  String get creditOff;

  /// No description provided for @redeemPoints.
  ///
  /// In en, this message translates to:
  /// **'Redeem points'**
  String get redeemPoints;

  /// No description provided for @redeemPointsHelp.
  ///
  /// In en, this message translates to:
  /// **'{count} points available, worth {worth}.'**
  String redeemPointsHelp(String count, String worth);

  /// No description provided for @redeemMax.
  ///
  /// In en, this message translates to:
  /// **'Use the most allowed'**
  String get redeemMax;

  /// No description provided for @redeemCapNote.
  ///
  /// In en, this message translates to:
  /// **'The server caps this, so the receipt may show fewer.'**
  String get redeemCapNote;

  /// No description provided for @completeSale.
  ///
  /// In en, this message translates to:
  /// **'Complete the sale'**
  String get completeSale;

  /// No description provided for @payFull.
  ///
  /// In en, this message translates to:
  /// **'Pay in full'**
  String get payFull;

  /// No description provided for @saleComplete.
  ///
  /// In en, this message translates to:
  /// **'Sale complete'**
  String get saleComplete;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice {no}'**
  String invoiceNumber(String no);

  /// No description provided for @totalCharged.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalCharged;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @pointsEarned.
  ///
  /// In en, this message translates to:
  /// **'{count} points earned'**
  String pointsEarned(String count);

  /// No description provided for @pointsRedeemed.
  ///
  /// In en, this message translates to:
  /// **'{count} points redeemed'**
  String pointsRedeemed(String count);

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'Next sale'**
  String get newSale;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get viewReceipt;

  /// No description provided for @holdCart.
  ///
  /// In en, this message translates to:
  /// **'Hold this cart'**
  String get holdCart;

  /// No description provided for @heldCarts.
  ///
  /// In en, this message translates to:
  /// **'Held carts'**
  String get heldCarts;

  /// No description provided for @heldCartsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No held carts} =1{1 held cart} other{{count} held carts}}'**
  String heldCartsCount(int count);

  /// No description provided for @holdLabel.
  ///
  /// In en, this message translates to:
  /// **'A name to find it by'**
  String get holdLabel;

  /// No description provided for @holdLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Blue shirt man'**
  String get holdLabelHint;

  /// No description provided for @holdSaved.
  ///
  /// In en, this message translates to:
  /// **'Held as “{label}”'**
  String holdSaved(String label);

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @discardHoldConfirm.
  ///
  /// In en, this message translates to:
  /// **'Throw away “{label}”? The cart cannot be brought back.'**
  String discardHoldConfirm(String label);

  /// No description provided for @resumeOverwrites.
  ///
  /// In en, this message translates to:
  /// **'Resuming replaces what is in the cart now.'**
  String get resumeOverwrites;

  /// No description provided for @noHeldCarts.
  ///
  /// In en, this message translates to:
  /// **'Nothing is on hold'**
  String get noHeldCarts;

  /// No description provided for @cashDrawer.
  ///
  /// In en, this message translates to:
  /// **'Cash drawer'**
  String get cashDrawer;

  /// No description provided for @openDrawer.
  ///
  /// In en, this message translates to:
  /// **'Open the drawer'**
  String get openDrawer;

  /// No description provided for @closeDrawer.
  ///
  /// In en, this message translates to:
  /// **'Close the drawer'**
  String get closeDrawer;

  /// No description provided for @drawerOpen.
  ///
  /// In en, this message translates to:
  /// **'Drawer open'**
  String get drawerOpen;

  /// No description provided for @drawerClosed.
  ///
  /// In en, this message translates to:
  /// **'Drawer closed'**
  String get drawerClosed;

  /// No description provided for @drawerClosedBody.
  ///
  /// In en, this message translates to:
  /// **'Sales still go through, but none of them are counted in a drawer.'**
  String get drawerClosedBody;

  /// No description provided for @openingCash.
  ///
  /// In en, this message translates to:
  /// **'Cash in the drawer now'**
  String get openingCash;

  /// No description provided for @countedCash.
  ///
  /// In en, this message translates to:
  /// **'Cash counted'**
  String get countedCash;

  /// No description provided for @openedAt.
  ///
  /// In en, this message translates to:
  /// **'Opened {when}'**
  String openedAt(String when);

  /// No description provided for @expectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expectedCash;

  /// No description provided for @countedLabel.
  ///
  /// In en, this message translates to:
  /// **'Counted'**
  String get countedLabel;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @shortBy.
  ///
  /// In en, this message translates to:
  /// **'Short by {amount}'**
  String shortBy(String amount);

  /// No description provided for @overBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String overBy(String amount);

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'It balances'**
  String get balanced;

  /// No description provided for @drawerOpened.
  ///
  /// In en, this message translates to:
  /// **'The drawer is open'**
  String get drawerOpened;

  /// No description provided for @closingNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get closingNote;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @invoiceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Invoice no, customer or phone'**
  String get invoiceSearchHint;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get filterWeek;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @invoiceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} invoices'**
  String invoiceCount(String count);

  /// No description provided for @invoiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get invoiceTotal;

  /// No description provided for @invoiceDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get invoiceDue;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get statusPartial;

  /// No description provided for @statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get statusUnpaid;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get statusReturned;

  /// No description provided for @statusVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get statusVoid;

  /// No description provided for @noInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get noInvoices;

  /// No description provided for @noInvoicesBody.
  ///
  /// In en, this message translates to:
  /// **'Sales made at this counter show up here.'**
  String get noInvoicesBody;

  /// No description provided for @ownInvoicesOnly.
  ///
  /// In en, this message translates to:
  /// **'Your own sales'**
  String get ownInvoicesOnly;

  /// No description provided for @soldBy.
  ///
  /// In en, this message translates to:
  /// **'Sold by {name}'**
  String soldBy(String name);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @vat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vat;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get grandTotal;

  /// No description provided for @collectDue.
  ///
  /// In en, this message translates to:
  /// **'Collect due'**
  String get collectDue;

  /// No description provided for @acceptReturn.
  ///
  /// In en, this message translates to:
  /// **'Accept a return'**
  String get acceptReturn;

  /// No description provided for @voidInvoice.
  ///
  /// In en, this message translates to:
  /// **'Cancel this sale'**
  String get voidInvoice;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printReceipt;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @collectTitle.
  ///
  /// In en, this message translates to:
  /// **'Collect a due'**
  String get collectTitle;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @collectAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount collected'**
  String get collectAmount;

  /// No description provided for @collectAll.
  ///
  /// In en, this message translates to:
  /// **'Collect it all'**
  String get collectAll;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'{amount} collected'**
  String collected(String amount);

  /// No description provided for @overPayment.
  ///
  /// In en, this message translates to:
  /// **'That is more than is owed.'**
  String get overPayment;

  /// No description provided for @returnTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept a return'**
  String get returnTitle;

  /// No description provided for @returnBody.
  ///
  /// In en, this message translates to:
  /// **'Choose what is coming back. Stock goes up and the customer\'s balance comes down.'**
  String get returnBody;

  /// No description provided for @returnQty.
  ///
  /// In en, this message translates to:
  /// **'Returning'**
  String get returnQty;

  /// No description provided for @returnReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get returnReason;

  /// No description provided for @returnReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Damaged pack'**
  String get returnReasonHint;

  /// No description provided for @returnNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing is selected to return.'**
  String get returnNothing;

  /// No description provided for @returnDone.
  ///
  /// In en, this message translates to:
  /// **'Return {no} recorded'**
  String returnDone(String no);

  /// No description provided for @returnOf.
  ///
  /// In en, this message translates to:
  /// **'of {count}'**
  String returnOf(String count);

  /// No description provided for @voidTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this sale'**
  String get voidTitle;

  /// No description provided for @voidBody.
  ///
  /// In en, this message translates to:
  /// **'A return brings goods back and the invoice stands. Cancelling says the sale should not have happened: stock goes back, the money is reversed out of its account, the customer\'s debt is credited and points are undone. The invoice stays on the list marked void.'**
  String get voidBody;

  /// No description provided for @voidReason.
  ///
  /// In en, this message translates to:
  /// **'Why is it being cancelled?'**
  String get voidReason;

  /// No description provided for @voidReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Rung up on the wrong customer'**
  String get voidReasonHint;

  /// No description provided for @voidConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel the sale'**
  String get voidConfirm;

  /// No description provided for @voidDone.
  ///
  /// In en, this message translates to:
  /// **'{no} cancelled. {count} units went back on the shelf.'**
  String voidDone(String no, String count);

  /// No description provided for @voidNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only a completed invoice can be cancelled.'**
  String get voidNotAllowed;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customerSearchListHint.
  ///
  /// In en, this message translates to:
  /// **'Name or phone'**
  String get customerSearchListHint;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomers;

  /// No description provided for @noCustomersBody.
  ///
  /// In en, this message translates to:
  /// **'Add one at the till, or with the button below.'**
  String get noCustomersBody;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @ledgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this ledger yet'**
  String get ledgerEmpty;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Owed'**
  String get debit;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get credit;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @pointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Loyalty points'**
  String get pointsTitle;

  /// No description provided for @pointsWorth.
  ///
  /// In en, this message translates to:
  /// **'Worth {amount}'**
  String pointsWorth(String amount);

  /// No description provided for @adjustPoints.
  ///
  /// In en, this message translates to:
  /// **'Adjust points'**
  String get adjustPoints;

  /// No description provided for @adjustPointsHelp.
  ///
  /// In en, this message translates to:
  /// **'A positive number adds, a negative number takes away.'**
  String get adjustPointsHelp;

  /// No description provided for @pointsNote.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get pointsNote;

  /// No description provided for @pointsAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Balance is now {count}'**
  String pointsAdjusted(String count);

  /// No description provided for @pointsNegative.
  ///
  /// In en, this message translates to:
  /// **'That would take the balance below zero.'**
  String get pointsNegative;

  /// No description provided for @salesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sales} =1{1 sale} other{{count} sales}}'**
  String salesCount(int count);

  /// No description provided for @customerSince.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String customerSince(String name);

  /// No description provided for @viewInvoices.
  ///
  /// In en, this message translates to:
  /// **'Their invoices'**
  String get viewInvoices;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @notAllowedAction.
  ///
  /// In en, this message translates to:
  /// **'Your role does not include this.'**
  String get notAllowedAction;

  /// No description provided for @cameraDenied.
  ///
  /// In en, this message translates to:
  /// **'The camera is not available. Type the barcode instead.'**
  String get cameraDenied;

  /// No description provided for @typeBarcode.
  ///
  /// In en, this message translates to:
  /// **'Type a barcode'**
  String get typeBarcode;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the barcode'**
  String get scanning;

  /// No description provided for @torch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get torch;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @productsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, barcode or SKU'**
  String get productsSearchHint;

  /// No description provided for @productsLowOnly.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get productsLowOnly;

  /// No description provided for @productsTrashed.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get productsTrashed;

  /// No description provided for @productsLive.
  ///
  /// In en, this message translates to:
  /// **'On the shelf'**
  String get productsLive;

  /// No description provided for @productsNone.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get productsNone;

  /// No description provided for @productsNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Add the first one, or bring it in from the catalogue.'**
  String get productsNoneBody;

  /// No description provided for @productsNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched'**
  String get productsNoResults;

  /// No description provided for @productsNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try part of the name, the barcode or the SKU.'**
  String get productsNoResultsBody;

  /// No description provided for @productsNoneTrashed.
  ///
  /// In en, this message translates to:
  /// **'Nothing deleted'**
  String get productsNoneTrashed;

  /// No description provided for @productsNoneTrashedBody.
  ///
  /// In en, this message translates to:
  /// **'Deleted products wait here until they are restored.'**
  String get productsNoneTrashedBody;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add a product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editProduct;

  /// No description provided for @productSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get productSaved;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} is on the shelf'**
  String productAdded(String name);

  /// No description provided for @stockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock value'**
  String get stockValue;

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing low} =1{1 running low} other{{count} running low}}'**
  String lowStockCount(int count);

  /// No description provided for @expiringCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None expiring} =1{1 expiring} other{{count} expiring}}'**
  String expiringCount(int count);

  /// No description provided for @productCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product} other{{count} products}}'**
  String productCount(int count);

  /// No description provided for @showingOf.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}'**
  String showingOf(String shown, String total);

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get costLabel;

  /// No description provided for @saleLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get saleLabel;

  /// No description provided for @wholesaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Wholesale'**
  String get wholesaleLabel;

  /// No description provided for @mrpLabel.
  ///
  /// In en, this message translates to:
  /// **'MRP'**
  String get mrpLabel;

  /// No description provided for @marginLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get marginLabel;

  /// No description provided for @vatLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatLabel;

  /// No description provided for @skuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get skuLabel;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @brandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brandLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @minimumStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Reorder at'**
  String get minimumStockLabel;

  /// No description provided for @openingStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening stock'**
  String get openingStockLabel;

  /// No description provided for @trackBatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Track batches and expiry'**
  String get trackBatchLabel;

  /// No description provided for @genericNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Generic name'**
  String get genericNameLabel;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get productNameLabel;

  /// No description provided for @inactiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Not for sale'**
  String get inactiveBadge;

  /// No description provided for @deletedBadge.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedBadge;

  /// No description provided for @onShelf.
  ///
  /// In en, this message translates to:
  /// **'{qty} on the shelf'**
  String onShelf(String qty);

  /// No description provided for @changePrices.
  ///
  /// In en, this message translates to:
  /// **'Change prices'**
  String get changePrices;

  /// No description provided for @pricesSaved.
  ///
  /// In en, this message translates to:
  /// **'Prices changed'**
  String get pricesSaved;

  /// No description provided for @pricesUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing to change'**
  String get pricesUnchanged;

  /// No description provided for @priceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price history'**
  String get priceHistory;

  /// No description provided for @stockHistory.
  ///
  /// In en, this message translates to:
  /// **'Stock history'**
  String get stockHistory;

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get currentPrice;

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get adjustStock;

  /// No description provided for @adjustQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Change by'**
  String get adjustQtyLabel;

  /// No description provided for @adjustHelp.
  ///
  /// In en, this message translates to:
  /// **'Signed and not zero. −3 takes three off the shelf, 3 puts three back.'**
  String get adjustHelp;

  /// No description provided for @adjustReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adjustReasonLabel;

  /// No description provided for @adjustReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason'**
  String get adjustReasonHint;

  /// No description provided for @adjustReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other (type a reason)'**
  String get adjustReasonOther;

  /// No description provided for @adjustReasonTyped.
  ///
  /// In en, this message translates to:
  /// **'Type the reason'**
  String get adjustReasonTyped;

  /// No description provided for @adjustIsDamage.
  ///
  /// In en, this message translates to:
  /// **'This is damage, not a correction'**
  String get adjustIsDamage;

  /// No description provided for @adjustDone.
  ///
  /// In en, this message translates to:
  /// **'Stock adjusted'**
  String get adjustDone;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete this product'**
  String get deleteProduct;

  /// No description provided for @deleteProductBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves the till, the lists and every stock figure. Past sales still name it, and you can restore it.'**
  String get deleteProductBody;

  /// No description provided for @deleteProductDone.
  ///
  /// In en, this message translates to:
  /// **'Deleted. {qty} came off the shelf.'**
  String deleteProductDone(String qty);

  /// No description provided for @restoreProduct.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreProduct;

  /// No description provided for @restoreProductDone.
  ///
  /// In en, this message translates to:
  /// **'{name} is back'**
  String restoreProductDone(String name);

  /// No description provided for @deletedOn.
  ///
  /// In en, this message translates to:
  /// **'Deleted {date}'**
  String deletedOn(String date);

  /// No description provided for @noMovements.
  ///
  /// In en, this message translates to:
  /// **'No stock movements yet'**
  String get noMovements;

  /// No description provided for @noPrices.
  ///
  /// In en, this message translates to:
  /// **'No price changes yet'**
  String get noPrices;

  /// No description provided for @movementOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get movementOpening;

  /// No description provided for @movementPurchase.
  ///
  /// In en, this message translates to:
  /// **'Goods in'**
  String get movementPurchase;

  /// No description provided for @movementSale.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get movementSale;

  /// No description provided for @movementReturn.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get movementReturn;

  /// No description provided for @movementAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjusted'**
  String get movementAdjustment;

  /// No description provided for @movementDamage.
  ///
  /// In en, this message translates to:
  /// **'Damage'**
  String get movementDamage;

  /// No description provided for @movementTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get movementTransfer;

  /// No description provided for @balanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Left: {qty}'**
  String balanceAfter(String qty);

  /// No description provided for @priceBelowCost.
  ///
  /// In en, this message translates to:
  /// **'Below cost'**
  String get priceBelowCost;

  /// No description provided for @saleBelowPurchase.
  ///
  /// In en, this message translates to:
  /// **'Selling price can\'t be below the cost.'**
  String get saleBelowPurchase;

  /// No description provided for @costHidden.
  ///
  /// In en, this message translates to:
  /// **'Costs are hidden for your role.'**
  String get costHidden;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @trialEndsToday.
  ///
  /// In en, this message translates to:
  /// **'Your trial ends today. Contact the platform to keep this shop open.'**
  String get trialEndsToday;

  /// No description provided for @trialDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left on your trial} other{{days} days left on your trial}}'**
  String trialDaysLeft(int days);

  /// No description provided for @profitPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit %'**
  String get profitPercentLabel;

  /// No description provided for @saleAboveMrp.
  ///
  /// In en, this message translates to:
  /// **'Above the printed MRP.'**
  String get saleAboveMrp;

  /// No description provided for @wholesaleBlankHelp.
  ///
  /// In en, this message translates to:
  /// **'Blank = selling price'**
  String get wholesaleBlankHelp;

  /// No description provided for @markupLabel.
  ///
  /// In en, this message translates to:
  /// **'Markup'**
  String get markupLabel;

  /// No description provided for @stopSelling.
  ///
  /// In en, this message translates to:
  /// **'Stop selling'**
  String get stopSelling;

  /// No description provided for @resumeSelling.
  ///
  /// In en, this message translates to:
  /// **'Sell again'**
  String get resumeSelling;

  /// No description provided for @stoppedSellingNote.
  ///
  /// In en, this message translates to:
  /// **'Not offered at the till. Stock and history are kept.'**
  String get stoppedSellingNote;

  /// No description provided for @productStopped.
  ///
  /// In en, this message translates to:
  /// **'No longer sold at the till.'**
  String get productStopped;

  /// No description provided for @productResumed.
  ///
  /// In en, this message translates to:
  /// **'Back on sale.'**
  String get productResumed;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get newProduct;

  /// No description provided for @lineBelowCost.
  ///
  /// In en, this message translates to:
  /// **'A line is priced below its cost, and the sale would be refused. Change its price or discount.'**
  String get lineBelowCost;

  /// No description provided for @lineBelowCostShort.
  ///
  /// In en, this message translates to:
  /// **'Below cost — the sale would be refused.'**
  String get lineBelowCostShort;

  /// No description provided for @discountBelowCost.
  ///
  /// In en, this message translates to:
  /// **'That discount takes the bill below what the goods cost.'**
  String get discountBelowCost;

  /// No description provided for @orderDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'Bill discount (%)'**
  String get orderDiscountPercent;

  /// No description provided for @previousDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous due'**
  String get previousDueLabel;

  /// No description provided for @collectPreviousDue.
  ///
  /// In en, this message translates to:
  /// **'Collect previous due too'**
  String get collectPreviousDue;

  /// No description provided for @outstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Owes in total'**
  String get outstandingLabel;

  /// No description provided for @cashTaken.
  ///
  /// In en, this message translates to:
  /// **'Cash taken'**
  String get cashTaken;

  /// No description provided for @digitalTaken.
  ///
  /// In en, this message translates to:
  /// **'Digital payments'**
  String get digitalTaken;

  /// No description provided for @duesCollected.
  ///
  /// In en, this message translates to:
  /// **'Dues collected'**
  String get duesCollected;

  /// No description provided for @dueGiven.
  ///
  /// In en, this message translates to:
  /// **'Given on credit'**
  String get dueGiven;

  /// No description provided for @shiftSpansDays.
  ///
  /// In en, this message translates to:
  /// **'This drawer has been open for {count} days.'**
  String shiftSpansDays(int count);

  /// No description provided for @lineDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Line discounts'**
  String get lineDiscounts;

  /// No description provided for @youSaved.
  ///
  /// In en, this message translates to:
  /// **'You saved (vs MRP)'**
  String get youSaved;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @openingBalanceHelp.
  ///
  /// In en, this message translates to:
  /// **'What they owed before this shop used BizPOS.'**
  String get openingBalanceHelp;

  /// No description provided for @ledgerSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get ledgerSale;

  /// No description provided for @ledgerPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get ledgerPayment;

  /// No description provided for @ledgerReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get ledgerReturn;

  /// No description provided for @ledgerVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get ledgerVoid;

  /// No description provided for @ledgerOpeningCorrection.
  ///
  /// In en, this message translates to:
  /// **'Opening balance corrected'**
  String get ledgerOpeningCorrection;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your shop'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign your shop up and start selling straight away — the till, cash drawer and walk-in customer are set up for you.'**
  String get registerSubtitle;

  /// No description provided for @registerTrialNote.
  ///
  /// In en, this message translates to:
  /// **'Free for {days} days. After that an admin has to extend it; nothing is deleted.'**
  String registerTrialNote(int days);

  /// No description provided for @openShopTrialNote.
  ///
  /// In en, this message translates to:
  /// **'A new shop runs free for {days} days, like any sign-up.'**
  String openShopTrialNote(int days);

  /// No description provided for @registerShopSection.
  ///
  /// In en, this message translates to:
  /// **'The shop'**
  String get registerShopSection;

  /// No description provided for @registerOwnerSection.
  ///
  /// In en, this message translates to:
  /// **'The owner'**
  String get registerOwnerSection;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopName;

  /// No description provided for @storeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Kind of shop'**
  String get storeTypeLabel;

  /// No description provided for @storeTypeHelp.
  ///
  /// In en, this message translates to:
  /// **'Decides which product catalogue you start from.'**
  String get storeTypeHelp;

  /// No description provided for @shopAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get shopAddressOptional;

  /// No description provided for @branchNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Branch name (optional)'**
  String get branchNameOptional;

  /// No description provided for @branchNameHint.
  ///
  /// In en, this message translates to:
  /// **'Main Branch'**
  String get branchNameHint;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get ownerName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @shopPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'How the platform reaches you about your shop.'**
  String get shopPhoneHelp;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a phone number.'**
  String get invalidPhone;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters.'**
  String get passwordRule;

  /// No description provided for @registerAction.
  ///
  /// In en, this message translates to:
  /// **'Create shop'**
  String get registerAction;

  /// No description provided for @registering.
  ///
  /// In en, this message translates to:
  /// **'Creating your shop…'**
  String get registering;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @signInInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInInstead;

  /// No description provided for @registerCta.
  ///
  /// In en, this message translates to:
  /// **'New shop? Create an account'**
  String get registerCta;

  /// No description provided for @signInThenAddShop.
  ///
  /// In en, this message translates to:
  /// **'After signing in, open your new shop from Profile → Open another shop.'**
  String get signInThenAddShop;

  /// No description provided for @openAnotherShop.
  ///
  /// In en, this message translates to:
  /// **'Open another shop'**
  String get openAnotherShop;

  /// No description provided for @openShopAction.
  ///
  /// In en, this message translates to:
  /// **'Open shop'**
  String get openShopAction;

  /// No description provided for @shopOpened.
  ///
  /// In en, this message translates to:
  /// **'{name} is open. You\'re working in it now.'**
  String shopOpened(String name);

  /// No description provided for @shopLocked.
  ///
  /// In en, this message translates to:
  /// **'{name} has been closed by the platform.'**
  String shopLocked(String name);

  /// No description provided for @packagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packagesTitle;

  /// No description provided for @newPackage.
  ///
  /// In en, this message translates to:
  /// **'New package'**
  String get newPackage;

  /// No description provided for @packagesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search packages'**
  String get packagesSearchHint;

  /// No description provided for @packagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No packages yet'**
  String get packagesEmpty;

  /// No description provided for @packagesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Bundle products that sell together at one price.'**
  String get packagesEmptyBody;

  /// No description provided for @deletePackage.
  ///
  /// In en, this message translates to:
  /// **'Delete package'**
  String get deletePackage;

  /// No description provided for @deletePackageBody.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? Past sales keep it; the till stops offering it.'**
  String deletePackageBody(String name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @packageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Package deleted.'**
  String get packageDeleted;

  /// No description provided for @packageSaved.
  ///
  /// In en, this message translates to:
  /// **'Package saved.'**
  String get packageSaved;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String fromDate(String date);

  /// No description provided for @untilDate.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String untilDate(String date);

  /// No description provided for @packageSaves.
  ///
  /// In en, this message translates to:
  /// **'Saves {amount}'**
  String packageSaves(String amount);

  /// No description provided for @packageBuildable.
  ///
  /// In en, this message translates to:
  /// **'Can make {count}'**
  String packageBuildable(String count);

  /// No description provided for @packageOnSale.
  ///
  /// In en, this message translates to:
  /// **'On sale'**
  String get packageOnSale;

  /// No description provided for @availabilityLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get availabilityLive;

  /// No description provided for @availabilityScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get availabilityScheduled;

  /// No description provided for @availabilityExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get availabilityExpired;

  /// No description provided for @availabilityInactive.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get availabilityInactive;

  /// No description provided for @packageName.
  ///
  /// In en, this message translates to:
  /// **'Package name'**
  String get packageName;

  /// No description provided for @packagePrice.
  ///
  /// In en, this message translates to:
  /// **'Package price'**
  String get packagePrice;

  /// No description provided for @packageItems.
  ///
  /// In en, this message translates to:
  /// **'What\'s inside'**
  String get packageItems;

  /// No description provided for @packageNeedsItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least one product.'**
  String get packageNeedsItems;

  /// No description provided for @packageComponents.
  ///
  /// In en, this message translates to:
  /// **'Items at their own prices'**
  String get packageComponents;

  /// No description provided for @packageSaving.
  ///
  /// In en, this message translates to:
  /// **'Customer saves'**
  String get packageSaving;

  /// No description provided for @packageAboveItems.
  ///
  /// In en, this message translates to:
  /// **'Costs more than the items alone'**
  String get packageAboveItems;

  /// No description provided for @packageStartsAny.
  ///
  /// In en, this message translates to:
  /// **'Starts now'**
  String get packageStartsAny;

  /// No description provided for @packageEndsNever.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get packageEndsNever;

  /// No description provided for @packageClearDates.
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get packageClearDates;

  /// No description provided for @packageWindowInvalid.
  ///
  /// In en, this message translates to:
  /// **'The end date must come after the start.'**
  String get packageWindowInvalid;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @addToPackage.
  ///
  /// In en, this message translates to:
  /// **'Add to package'**
  String get addToPackage;

  /// No description provided for @catalogueTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get catalogueTitle;

  /// No description provided for @catalogueSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, company or generic'**
  String get catalogueSearchHint;

  /// No description provided for @catalogueAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catalogueAll;

  /// No description provided for @catalogueMine.
  ///
  /// In en, this message translates to:
  /// **'In my store ({count})'**
  String catalogueMine(String count);

  /// No description provided for @catalogueMissing.
  ///
  /// In en, this message translates to:
  /// **'Not in my store ({count})'**
  String catalogueMissing(String count);

  /// No description provided for @catalogueNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the catalogue by that name'**
  String get catalogueNoResults;

  /// No description provided for @catalogueNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'If the product is real, suggest it and it can go on sale.'**
  String get catalogueNoResultsBody;

  /// No description provided for @catalogueNothingMissing.
  ///
  /// In en, this message translates to:
  /// **'Your shop already stocks everything in the catalogue'**
  String get catalogueNothingMissing;

  /// No description provided for @suggestProduct.
  ///
  /// In en, this message translates to:
  /// **'Suggest a product'**
  String get suggestProduct;

  /// No description provided for @inMyStore.
  ///
  /// In en, this message translates to:
  /// **'In my store'**
  String get inMyStore;

  /// No description provided for @pendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingBadge;

  /// No description provided for @addToStore.
  ///
  /// In en, this message translates to:
  /// **'Add to my store'**
  String get addToStore;

  /// No description provided for @adoptedProduct.
  ///
  /// In en, this message translates to:
  /// **'{name} is on your shelf.'**
  String adoptedProduct(String name);

  /// No description provided for @alreadyInStoreNote.
  ///
  /// In en, this message translates to:
  /// **'Your store already has this product.'**
  String get alreadyInStoreNote;

  /// No description provided for @mrpHelp.
  ///
  /// In en, this message translates to:
  /// **'The price printed on the pack.'**
  String get mrpHelp;

  /// No description provided for @adoptOpeningHelp.
  ///
  /// In en, this message translates to:
  /// **'How many you have now.'**
  String get adoptOpeningHelp;

  /// No description provided for @localNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name in my shop'**
  String get localNameLabel;

  /// No description provided for @localNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get localNameHelp;

  /// No description provided for @suggestNameHelp.
  ///
  /// In en, this message translates to:
  /// **'We check the catalogue as you type.'**
  String get suggestNameHelp;

  /// No description provided for @suggestReason.
  ///
  /// In en, this message translates to:
  /// **'Why stock it? (optional)'**
  String get suggestReason;

  /// No description provided for @suggestReasonHelp.
  ///
  /// In en, this message translates to:
  /// **'Helps whoever approves it.'**
  String get suggestReasonHelp;

  /// No description provided for @sendSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Send suggestion'**
  String get sendSuggestion;

  /// No description provided for @suggestionEndorsed.
  ///
  /// In en, this message translates to:
  /// **'On sale in your store now. The platform will review it for other shops.'**
  String get suggestionEndorsed;

  /// No description provided for @suggestionSent.
  ///
  /// In en, this message translates to:
  /// **'Sent for approval.'**
  String get suggestionSent;

  /// No description provided for @alreadyInCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Already in the catalogue'**
  String get alreadyInCatalogue;

  /// No description provided for @alreadyInCatalogueBody.
  ///
  /// In en, this message translates to:
  /// **'The catalogue already has {name}. Send yours anyway?'**
  String alreadyInCatalogueBody(String name);

  /// No description provided for @sendAnyway.
  ///
  /// In en, this message translates to:
  /// **'Send anyway'**
  String get sendAnyway;

  /// No description provided for @verdictExists.
  ///
  /// In en, this message translates to:
  /// **'This is already in the catalogue — add it instead of suggesting it.'**
  String get verdictExists;

  /// No description provided for @verdictVariant.
  ///
  /// In en, this message translates to:
  /// **'The same product exists at another strength. Yours is a different product.'**
  String get verdictVariant;

  /// No description provided for @verdictOtherBrand.
  ///
  /// In en, this message translates to:
  /// **'The same product exists from another company.'**
  String get verdictOtherBrand;

  /// No description provided for @verdictSimilar.
  ///
  /// In en, this message translates to:
  /// **'Something similar exists. Worth a look first.'**
  String get verdictSimilar;

  /// No description provided for @verdictNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing like it in the catalogue — it\'s new.'**
  String get verdictNew;

  /// No description provided for @adoptThisInstead.
  ///
  /// In en, this message translates to:
  /// **'Add this one instead'**
  String get adoptThisInstead;

  /// No description provided for @suggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestionsTitle;

  /// No description provided for @suggestionsPending.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting for you'**
  String suggestionsPending(int count);

  /// No description provided for @suggestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get suggestionsEmpty;

  /// No description provided for @suggestionsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Products your staff suggest appear here for approval.'**
  String get suggestionsEmptyBody;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusPending;

  /// No description provided for @statusEndorsed.
  ///
  /// In en, this message translates to:
  /// **'On sale here'**
  String get statusEndorsed;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'In the catalogue'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @askedBy.
  ///
  /// In en, this message translates to:
  /// **'Asked by {name}'**
  String askedBy(String name);

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @approveAndStock.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveAndStock;

  /// No description provided for @reviewNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get reviewNoteOptional;

  /// No description provided for @rejectReason.
  ///
  /// In en, this message translates to:
  /// **'Why not?'**
  String get rejectReason;

  /// No description provided for @suggestionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved — it\'s on sale in your store.'**
  String get suggestionApproved;

  /// No description provided for @suggestionRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected.'**
  String get suggestionRejected;

  /// No description provided for @purchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchaseTitle;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @goodsIn.
  ///
  /// In en, this message translates to:
  /// **'Goods in'**
  String get goodsIn;

  /// No description provided for @purchaseSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by bill no or supplier'**
  String get purchaseSearchHint;

  /// No description provided for @purchasesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No purchases yet'**
  String get purchasesEmpty;

  /// No description provided for @purchasesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Record goods as they come in, and the stock rises with them.'**
  String get purchasesEmptyBody;

  /// No description provided for @billsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bill} other{{count} bills}}'**
  String billsCount(int count);

  /// No description provided for @owedToSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Owed to suppliers'**
  String get owedToSuppliers;

  /// No description provided for @owedToSupplier.
  ///
  /// In en, this message translates to:
  /// **'Owed to the supplier'**
  String get owedToSupplier;

  /// No description provided for @noSupplier.
  ///
  /// In en, this message translates to:
  /// **'No supplier'**
  String get noSupplier;

  /// No description provided for @photosUploaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo added} other{{count} photos added}}'**
  String photosUploaded(int count);

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get deletePhoto;

  /// No description provided for @deletePhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo from the bill? The bill itself is not changed.'**
  String get deletePhotoBody;

  /// No description provided for @billPhotos.
  ///
  /// In en, this message translates to:
  /// **'Bill photos ({count}/{max})'**
  String billPhotos(int count, int max);

  /// No description provided for @noBillPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos of this bill.'**
  String get noBillPhotos;

  /// No description provided for @billPhotosHelp.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of the paper bill — it goes up after the bill is saved.'**
  String get billPhotosHelp;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @photoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera or gallery.'**
  String get photoPickFailed;

  /// No description provided for @photosTooBig.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo is over 8 MB and was left out} other{{count} photos are over 8 MB and were left out}}'**
  String photosTooBig(int count);

  /// No description provided for @addSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add supplier'**
  String get addSupplier;

  /// No description provided for @suppliersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suppliers yet'**
  String get suppliersEmpty;

  /// No description provided for @supplierSaved.
  ///
  /// In en, this message translates to:
  /// **'Supplier saved.'**
  String get supplierSaved;

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get supplierName;

  /// No description provided for @supplierCompany.
  ///
  /// In en, this message translates to:
  /// **'Company (optional)'**
  String get supplierCompany;

  /// No description provided for @supplierSearch.
  ///
  /// In en, this message translates to:
  /// **'Who is it from?'**
  String get supplierSearch;

  /// No description provided for @newSupplierNote.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is new — it will be saved with this bill.'**
  String newSupplierNote(String name);

  /// No description provided for @pickSupplierFromList.
  ///
  /// In en, this message translates to:
  /// **'Pick a supplier from the list.'**
  String get pickSupplierFromList;

  /// No description provided for @itemsReceived.
  ///
  /// In en, this message translates to:
  /// **'What came in'**
  String get itemsReceived;

  /// No description provided for @noItemsReceived.
  ///
  /// In en, this message translates to:
  /// **'Add the products on this bill.'**
  String get noItemsReceived;

  /// No description provided for @batchShort.
  ///
  /// In en, this message translates to:
  /// **'Batch {batch}'**
  String batchShort(String batch);

  /// No description provided for @expiresShort.
  ///
  /// In en, this message translates to:
  /// **'Exp {date}'**
  String expiresShort(String date);

  /// No description provided for @billDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'Discount on the bill'**
  String get billDiscountPercent;

  /// No description provided for @paidToSupplier.
  ///
  /// In en, this message translates to:
  /// **'Paid now'**
  String get paidToSupplier;

  /// No description provided for @paidFollowsTotal.
  ///
  /// In en, this message translates to:
  /// **'The whole bill, unless you type less.'**
  String get paidFollowsTotal;

  /// No description provided for @paidOverTotal.
  ///
  /// In en, this message translates to:
  /// **'More than the bill.'**
  String get paidOverTotal;

  /// No description provided for @payInFull.
  ///
  /// In en, this message translates to:
  /// **'Pay in full'**
  String get payInFull;

  /// No description provided for @payNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing paid'**
  String get payNothing;

  /// No description provided for @paidFrom.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get paidFrom;

  /// No description provided for @purchaseNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get purchaseNote;

  /// No description provided for @purchaseNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Supplier\'s invoice no'**
  String get purchaseNoteHint;

  /// No description provided for @saveBill.
  ///
  /// In en, this message translates to:
  /// **'Save bill'**
  String get saveBill;

  /// No description provided for @purchaseSaved.
  ///
  /// In en, this message translates to:
  /// **'Bill {refNo} saved. Stock is updated.'**
  String purchaseSaved(String refNo);

  /// No description provided for @photoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The photos didn\'t go up'**
  String get photoUploadFailed;

  /// No description provided for @photoUploadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The bill is saved. The photos could not be uploaded: {reason}'**
  String photoUploadFailedBody(String reason);

  /// No description provided for @skipPhotos.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipPhotos;

  /// No description provided for @pickProduct.
  ///
  /// In en, this message translates to:
  /// **'Pick a product'**
  String get pickProduct;

  /// No description provided for @purchaseAddFromCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Not in your store yet? Add it from the catalogue first.'**
  String get purchaseAddFromCatalogue;

  /// No description provided for @tracksBatches.
  ///
  /// In en, this message translates to:
  /// **'Batch and expiry'**
  String get tracksBatches;

  /// No description provided for @quantityReceived.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityReceived;

  /// No description provided for @unitCost.
  ///
  /// In en, this message translates to:
  /// **'Cost each'**
  String get unitCost;

  /// No description provided for @batchNo.
  ///
  /// In en, this message translates to:
  /// **'Batch no'**
  String get batchNo;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDate;

  /// No description provided for @notYours.
  ///
  /// In en, this message translates to:
  /// **'Not in your access'**
  String get notYours;

  /// No description provided for @sectionLocked.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this section.'**
  String get sectionLocked;

  /// No description provided for @scopeBranch.
  ///
  /// In en, this message translates to:
  /// **'This branch'**
  String get scopeBranch;

  /// No description provided for @scopeStore.
  ///
  /// In en, this message translates to:
  /// **'Whole store'**
  String get scopeStore;

  /// No description provided for @scopeMixed.
  ///
  /// In en, this message translates to:
  /// **'Branch and store'**
  String get scopeMixed;

  /// No description provided for @reportSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get reportSales;

  /// No description provided for @reportProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get reportProfit;

  /// No description provided for @reportStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get reportStock;

  /// No description provided for @reportDues.
  ///
  /// In en, this message translates to:
  /// **'Dues'**
  String get reportDues;

  /// No description provided for @reportWindow.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportWindow;

  /// No description provided for @lastDays.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String lastDays(int days);

  /// No description provided for @lastMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String lastMonths(int count);

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Pick dates…'**
  String get customRange;

  /// No description provided for @rangeCapped.
  ///
  /// In en, this message translates to:
  /// **'Trimmed to the last {days} days — the longest the dashboard shows.'**
  String rangeCapped(int days);

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @averageSale.
  ///
  /// In en, this message translates to:
  /// **'Average sale'**
  String get averageSale;

  /// No description provided for @dailySales.
  ///
  /// In en, this message translates to:
  /// **'Sales by day'**
  String get dailySales;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Best sellers'**
  String get topProducts;

  /// No description provided for @nothingSold.
  ///
  /// In en, this message translates to:
  /// **'Nothing sold in this period.'**
  String get nothingSold;

  /// No description provided for @qtySold.
  ///
  /// In en, this message translates to:
  /// **'{qty} sold'**
  String qtySold(String qty);

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @byMethod.
  ///
  /// In en, this message translates to:
  /// **'By payment method'**
  String get byMethod;

  /// No description provided for @byStaff.
  ///
  /// In en, this message translates to:
  /// **'By staff'**
  String get byStaff;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get netProfit;

  /// No description provided for @grossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross profit'**
  String get grossProfit;

  /// No description provided for @howItAddsUp.
  ///
  /// In en, this message translates to:
  /// **'How it adds up'**
  String get howItAddsUp;

  /// No description provided for @costOfGoods.
  ///
  /// In en, this message translates to:
  /// **'Cost of goods'**
  String get costOfGoods;

  /// No description provided for @returnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returnsLabel;

  /// No description provided for @expensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesLabel;

  /// No description provided for @stockOnHand.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockOnHand;

  /// No description provided for @unitsOnHand.
  ///
  /// In en, this message translates to:
  /// **'Units on hand'**
  String get unitsOnHand;

  /// No description provided for @nothingLow.
  ///
  /// In en, this message translates to:
  /// **'Nothing is running low.'**
  String get nothingLow;

  /// No description provided for @minimumIs.
  ///
  /// In en, this message translates to:
  /// **'Minimum {qty}'**
  String minimumIs(String qty);

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get expiringSoon;

  /// No description provided for @nothingExpiring.
  ///
  /// In en, this message translates to:
  /// **'Nothing expires soon.'**
  String get nothingExpiring;

  /// No description provided for @onHand.
  ///
  /// In en, this message translates to:
  /// **'{qty} on hand'**
  String onHand(String qty);

  /// No description provided for @deadStock.
  ///
  /// In en, this message translates to:
  /// **'No sale in 90 days'**
  String get deadStock;

  /// No description provided for @nothingDead.
  ///
  /// In en, this message translates to:
  /// **'Everything on the shelf has sold lately.'**
  String get nothingDead;

  /// No description provided for @owedToShop.
  ///
  /// In en, this message translates to:
  /// **'Owed to the shop'**
  String get owedToShop;

  /// No description provided for @whoOwes.
  ///
  /// In en, this message translates to:
  /// **'Who owes'**
  String get whoOwes;

  /// No description provided for @nobodyOwes.
  ///
  /// In en, this message translates to:
  /// **'Nobody owes the shop anything.'**
  String get nobodyOwes;

  /// No description provided for @daysOld.
  ///
  /// In en, this message translates to:
  /// **'{days} days old'**
  String daysOld(int days);

  /// No description provided for @overCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Over credit limit'**
  String get overCreditLimit;

  /// No description provided for @headline.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get headline;

  /// No description provided for @discountGiven.
  ///
  /// In en, this message translates to:
  /// **'Discount given'**
  String get discountGiven;

  /// No description provided for @dueRaised.
  ///
  /// In en, this message translates to:
  /// **'Left as due'**
  String get dueRaised;

  /// No description provided for @moneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get moneyIn;

  /// No description provided for @collectedTotal.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collectedTotal;

  /// No description provided for @onTodaysBills.
  ///
  /// In en, this message translates to:
  /// **'On this period\'s bills'**
  String get onTodaysBills;

  /// No description provided for @onOldDues.
  ///
  /// In en, this message translates to:
  /// **'On older dues'**
  String get onOldDues;

  /// No description provided for @onPreviousDue.
  ///
  /// In en, this message translates to:
  /// **'Old debt settled with a bill'**
  String get onPreviousDue;

  /// No description provided for @billsSettledBy.
  ///
  /// In en, this message translates to:
  /// **'How the bills were paid'**
  String get billsSettledBy;

  /// No description provided for @capital.
  ///
  /// In en, this message translates to:
  /// **'Where the money is now'**
  String get capital;

  /// No description provided for @stockAtCost.
  ///
  /// In en, this message translates to:
  /// **'Stock at cost'**
  String get stockAtCost;

  /// No description provided for @receivable.
  ///
  /// In en, this message translates to:
  /// **'Receivable'**
  String get receivable;

  /// No description provided for @inAccounts.
  ///
  /// In en, this message translates to:
  /// **'In accounts'**
  String get inAccounts;

  /// No description provided for @payable.
  ///
  /// In en, this message translates to:
  /// **'Payable'**
  String get payable;

  /// No description provided for @invested.
  ///
  /// In en, this message translates to:
  /// **'Invested'**
  String get invested;

  /// No description provided for @netWorth.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get netWorth;

  /// No description provided for @dues.
  ///
  /// In en, this message translates to:
  /// **'Dues'**
  String get dues;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @timesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{once} other{{count} times}}'**
  String timesCount(int count);

  /// No description provided for @cashDrawers.
  ///
  /// In en, this message translates to:
  /// **'Cash drawers'**
  String get cashDrawers;

  /// No description provided for @restockSoon.
  ///
  /// In en, this message translates to:
  /// **'Order soon'**
  String get restockSoon;

  /// No description provided for @rising.
  ///
  /// In en, this message translates to:
  /// **'Selling more'**
  String get rising;

  /// No description provided for @falling.
  ///
  /// In en, this message translates to:
  /// **'Selling less'**
  String get falling;

  /// No description provided for @moverNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get moverNew;

  /// No description provided for @moverStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get moverStopped;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'{qty}/day'**
  String perDay(String qty);

  /// No description provided for @daysCover.
  ///
  /// In en, this message translates to:
  /// **'lasts {days} days'**
  String daysCover(String days);

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysLeft(String days);

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transferDone.
  ///
  /// In en, this message translates to:
  /// **'Money moved.'**
  String get transferDone;

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromAccount;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toAccount;

  /// No description provided for @sameAccount.
  ///
  /// In en, this message translates to:
  /// **'Pick two different accounts.'**
  String get sameAccount;

  /// No description provided for @expenseTypes.
  ///
  /// In en, this message translates to:
  /// **'Expense types'**
  String get expenseTypes;

  /// No description provided for @expenseType.
  ///
  /// In en, this message translates to:
  /// **'Expense type'**
  String get expenseType;

  /// No description provided for @expenseTypeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get expenseTypeName;

  /// No description provided for @newExpenseType.
  ///
  /// In en, this message translates to:
  /// **'New type…'**
  String get newExpenseType;

  /// No description provided for @editExpenseType.
  ///
  /// In en, this message translates to:
  /// **'Edit expense type'**
  String get editExpenseType;

  /// No description provided for @newTypeHelp.
  ///
  /// In en, this message translates to:
  /// **'Saved as a new expense type with this expense.'**
  String get newTypeHelp;

  /// No description provided for @noExpenseTypes.
  ///
  /// In en, this message translates to:
  /// **'No expense types yet.'**
  String get noExpenseTypes;

  /// No description provided for @expenseTypeSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense type saved.'**
  String get expenseTypeSaved;

  /// No description provided for @deleteExpenseType.
  ///
  /// In en, this message translates to:
  /// **'Delete type'**
  String get deleteExpenseType;

  /// No description provided for @deleteExpenseTypeBody.
  ///
  /// In en, this message translates to:
  /// **'A type that has expenses behind it is retired instead, so the old expenses keep their name.'**
  String get deleteExpenseTypeBody;

  /// No description provided for @expenseTypeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense type deleted.'**
  String get expenseTypeDeleted;

  /// No description provided for @expenseTypeRetired.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Retired.} =1{Retired — 1 expense uses it.} other{Retired — {count} expenses use it.}}'**
  String expenseTypeRetired(int count);

  /// No description provided for @retired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get retired;

  /// No description provided for @iconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get iconLabel;

  /// No description provided for @defaultAmount.
  ///
  /// In en, this message translates to:
  /// **'Default amount'**
  String get defaultAmount;

  /// No description provided for @defaultAmountHelp.
  ///
  /// In en, this message translates to:
  /// **'What a quick tile records in one tap.'**
  String get defaultAmountHelp;

  /// No description provided for @quickTile.
  ///
  /// In en, this message translates to:
  /// **'Quick tile'**
  String get quickTile;

  /// No description provided for @quickTileHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown as a one-tap tile on the accounts screen.'**
  String get quickTileHelp;

  /// No description provided for @salaryType.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salaryType;

  /// No description provided for @salaryTypeHelp.
  ///
  /// In en, this message translates to:
  /// **'Asks for the employee\'s name and the month it covers.'**
  String get salaryTypeHelp;

  /// No description provided for @inUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get inUse;

  /// No description provided for @recordExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get recordExpense;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @expenseRecorded.
  ///
  /// In en, this message translates to:
  /// **'{name}: {amount} recorded.'**
  String expenseRecorded(String name, String amount);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @employeeName.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employeeName;

  /// No description provided for @employeeNameHelp.
  ///
  /// In en, this message translates to:
  /// **'A name, not a login — anyone the shop pays.'**
  String get employeeNameHelp;

  /// No description provided for @salaryMonth.
  ///
  /// In en, this message translates to:
  /// **'Salary for'**
  String get salaryMonth;

  /// No description provided for @salaryMonthHelp.
  ///
  /// In en, this message translates to:
  /// **'The month it covers, not the day it was paid.'**
  String get salaryMonthHelp;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @backdatedHelp.
  ///
  /// In en, this message translates to:
  /// **'Recorded on an earlier day.'**
  String get backdatedHelp;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @recordedBy.
  ///
  /// In en, this message translates to:
  /// **'Recorded by'**
  String get recordedBy;

  /// No description provided for @forMonth.
  ///
  /// In en, this message translates to:
  /// **'for {month}'**
  String forMonth(String month);

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet.'**
  String get noExpenses;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get noTransactions;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete expense'**
  String get deleteExpense;

  /// No description provided for @deleteExpenseBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} goes back into {account}.'**
  String deleteExpenseBody(String amount, String account);

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted. The money is back in the account.'**
  String get expenseDeleted;

  /// No description provided for @spentToday.
  ///
  /// In en, this message translates to:
  /// **'Spent today'**
  String get spentToday;

  /// No description provided for @spentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent this month'**
  String get spentThisMonth;

  /// No description provided for @salaryThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Salary this month'**
  String get salaryThisMonth;

  /// No description provided for @quickExpenses.
  ///
  /// In en, this message translates to:
  /// **'Quick expenses'**
  String get quickExpenses;

  /// No description provided for @salaryAsks.
  ///
  /// In en, this message translates to:
  /// **'Asks for a name'**
  String get salaryAsks;

  /// No description provided for @typeAmount.
  ///
  /// In en, this message translates to:
  /// **'Type amount'**
  String get typeAmount;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @accountAdded.
  ///
  /// In en, this message translates to:
  /// **'Account added.'**
  String get accountAdded;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @accountNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. City Bank, bKash merchant'**
  String get accountNameHint;

  /// No description provided for @accountCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountCash;

  /// No description provided for @accountBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountBank;

  /// No description provided for @accountMfs.
  ///
  /// In en, this message translates to:
  /// **'Mobile money'**
  String get accountMfs;

  /// No description provided for @txnSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get txnSale;

  /// No description provided for @txnDuePayment.
  ///
  /// In en, this message translates to:
  /// **'Due collected'**
  String get txnDuePayment;

  /// No description provided for @txnRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get txnRefund;

  /// No description provided for @qtyPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get qtyPickerTitle;

  /// No description provided for @qtyCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom quantity'**
  String get qtyCustom;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get teamMembers;

  /// No description provided for @branchesTab.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branchesTab;

  /// No description provided for @storeTab.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get storeTab;

  /// No description provided for @activityTab.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTab;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @addBranch.
  ///
  /// In en, this message translates to:
  /// **'Add branch'**
  String get addBranch;

  /// No description provided for @editBranch.
  ///
  /// In en, this message translates to:
  /// **'Edit branch'**
  String get editBranch;

  /// No description provided for @activeMembers.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String activeMembers(int count);

  /// No description provided for @suspendedMembers.
  ///
  /// In en, this message translates to:
  /// **'Suspended ({count})'**
  String suspendedMembers(int count);

  /// No description provided for @membersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one on the team yet'**
  String get membersEmpty;

  /// No description provided for @youBadge.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youBadge;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeBadge;

  /// No description provided for @suspendedBadge.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspendedBadge;

  /// No description provided for @lockedBadge.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedBadge;

  /// No description provided for @neverSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Never signed in'**
  String get neverSignedIn;

  /// No description provided for @lastSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Last signed in {when}'**
  String lastSignedIn(String when);

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get changeRole;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Choose a role'**
  String get chooseRole;

  /// No description provided for @whatRoleCanDo.
  ///
  /// In en, this message translates to:
  /// **'What {role} can do'**
  String whatRoleCanDo(String role);

  /// No description provided for @builtInRole.
  ///
  /// In en, this message translates to:
  /// **'A built-in role. Its permissions are set by the platform.'**
  String get builtInRole;

  /// No description provided for @roleChanged.
  ///
  /// In en, this message translates to:
  /// **'{name} is now {role}'**
  String roleChanged(String name, String role);

  /// No description provided for @suspendMember.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspendMember;

  /// No description provided for @reactivateMember.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivateMember;

  /// No description provided for @suspendMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend {name}?'**
  String suspendMemberTitle(String name);

  /// No description provided for @reactivateMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate {name}?'**
  String reactivateMemberTitle(String name);

  /// No description provided for @suspendMemberBody.
  ///
  /// In en, this message translates to:
  /// **'They lose access to this store at their next step. Nothing they did is deleted, and you can reactivate them at any time.'**
  String get suspendMemberBody;

  /// No description provided for @reactivateMemberBody.
  ///
  /// In en, this message translates to:
  /// **'They can sign in to this store again, with the role they had.'**
  String get reactivateMemberBody;

  /// No description provided for @memberSuspended.
  ///
  /// In en, this message translates to:
  /// **'{name} suspended'**
  String memberSuspended(String name);

  /// No description provided for @memberReactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} can sign in again'**
  String memberReactivated(String name);

  /// No description provided for @cannotChangeSelf.
  ///
  /// In en, this message translates to:
  /// **'This is you. Nobody can change their own role or suspend themselves — ask another owner.'**
  String get cannotChangeSelf;

  /// No description provided for @readOnlyTeam.
  ///
  /// In en, this message translates to:
  /// **'You can see the team but not change it.'**
  String get readOnlyTeam;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @memberFormNote.
  ///
  /// In en, this message translates to:
  /// **'If this email already has a BizPOS account, they join with their own password and the one above is not used.'**
  String get memberFormNote;

  /// No description provided for @memberAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added to the team'**
  String memberAdded(String name);

  /// No description provided for @memberReusedAccount.
  ///
  /// In en, this message translates to:
  /// **'{name} added — they already had an account, so they sign in with their own password.'**
  String memberReusedAccount(String name);

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchName;

  /// No description provided for @branchCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get branchCode;

  /// No description provided for @branchCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Short and unique, e.g. MRP'**
  String get branchCodeHelp;

  /// No description provided for @branchSaved.
  ///
  /// In en, this message translates to:
  /// **'Branch saved'**
  String get branchSaved;

  /// No description provided for @branchesNote.
  ///
  /// In en, this message translates to:
  /// **'Stock, sales, cash drawers and reports are kept per branch. Switch branch from your profile.'**
  String get branchesNote;

  /// No description provided for @youAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get youAreHere;

  /// No description provided for @storeDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get storeDetails;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editStore.
  ///
  /// In en, this message translates to:
  /// **'Edit store'**
  String get editStore;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @atTheCounter.
  ///
  /// In en, this message translates to:
  /// **'At the counter'**
  String get atTheCounter;

  /// No description provided for @vatInclusive.
  ///
  /// In en, this message translates to:
  /// **'Included in prices'**
  String get vatInclusive;

  /// No description provided for @vatExclusive.
  ///
  /// In en, this message translates to:
  /// **'Added on top'**
  String get vatExclusive;

  /// No description provided for @receiptPaper.
  ///
  /// In en, this message translates to:
  /// **'Receipt paper'**
  String get receiptPaper;

  /// No description provided for @invoicePrefix.
  ///
  /// In en, this message translates to:
  /// **'Invoice prefix'**
  String get invoicePrefix;

  /// No description provided for @invoicePrefixHelp.
  ///
  /// In en, this message translates to:
  /// **'Printed before every invoice number'**
  String get invoicePrefixHelp;

  /// No description provided for @allowCreditSale.
  ///
  /// In en, this message translates to:
  /// **'Sales on credit (due)'**
  String get allowCreditSale;

  /// No description provided for @allowCreditSaleHelp.
  ///
  /// In en, this message translates to:
  /// **'A named customer may pay less than the bill and owe the rest.'**
  String get allowCreditSaleHelp;

  /// No description provided for @allowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get allowed;

  /// No description provided for @notAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get notAllowed;

  /// No description provided for @storeSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get storeSaved;

  /// No description provided for @loyaltyTitle.
  ///
  /// In en, this message translates to:
  /// **'Loyalty points'**
  String get loyaltyTitle;

  /// No description provided for @loyaltyStatus.
  ///
  /// In en, this message translates to:
  /// **'Programme'**
  String get loyaltyStatus;

  /// No description provided for @loyaltyOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get loyaltyOn;

  /// No description provided for @loyaltyOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get loyaltyOff;

  /// No description provided for @loyaltyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Customers earn points'**
  String get loyaltyEnabled;

  /// No description provided for @loyaltyEarning.
  ///
  /// In en, this message translates to:
  /// **'Earning'**
  String get loyaltyEarning;

  /// No description provided for @loyaltyEarnRule.
  ///
  /// In en, this message translates to:
  /// **'{points} point(s) for every {amount} spent'**
  String loyaltyEarnRule(String points, String amount);

  /// No description provided for @loyaltyEarnPoints.
  ///
  /// In en, this message translates to:
  /// **'Points earned'**
  String get loyaltyEarnPoints;

  /// No description provided for @loyaltyEarnPer.
  ///
  /// In en, this message translates to:
  /// **'For every'**
  String get loyaltyEarnPer;

  /// No description provided for @loyaltyWorth.
  ///
  /// In en, this message translates to:
  /// **'One point is worth'**
  String get loyaltyWorth;

  /// No description provided for @loyaltyPointValue.
  ///
  /// In en, this message translates to:
  /// **'1 point = {amount}'**
  String loyaltyPointValue(String amount);

  /// No description provided for @loyaltyMinRedeem.
  ///
  /// In en, this message translates to:
  /// **'Fewest points to redeem'**
  String get loyaltyMinRedeem;

  /// No description provided for @loyaltyMaxRedeemPct.
  ///
  /// In en, this message translates to:
  /// **'Most of a bill paid by points (%)'**
  String get loyaltyMaxRedeemPct;

  /// No description provided for @loyaltyRound.
  ///
  /// In en, this message translates to:
  /// **'Rounding of points earned'**
  String get loyaltyRound;

  /// No description provided for @roundDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get roundDown;

  /// No description provided for @roundNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get roundNearest;

  /// No description provided for @roundUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get roundUp;

  /// No description provided for @mustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Must be more than 0'**
  String get mustBePositive;

  /// No description provided for @percentRange.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and 100'**
  String get percentRange;

  /// No description provided for @activityLocked.
  ///
  /// In en, this message translates to:
  /// **'The activity log is not open to you.'**
  String get activityLocked;

  /// No description provided for @activitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the log'**
  String get activitySearchHint;

  /// No description provided for @activitySubject.
  ///
  /// In en, this message translates to:
  /// **'What changed'**
  String get activitySubject;

  /// No description provided for @activityAllSubjects.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get activityAllSubjects;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed in this period'**
  String get activityEmpty;

  /// No description provided for @activityEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try a longer period or another filter.'**
  String get activityEmptyBody;

  /// No description provided for @activitySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get activitySystem;

  /// No description provided for @emptyValue.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get emptyValue;

  /// No description provided for @platformStores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get platformStores;

  /// No description provided for @platformSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions ({count})'**
  String platformSuggestions(int count);

  /// No description provided for @platformCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get platformCatalogue;

  /// No description provided for @newStore.
  ///
  /// In en, this message translates to:
  /// **'New store'**
  String get newStore;

  /// No description provided for @createStore.
  ///
  /// In en, this message translates to:
  /// **'Create store'**
  String get createStore;

  /// No description provided for @storeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, phone, email or owner'**
  String get storeSearchHint;

  /// No description provided for @allStoresCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String allStoresCount(int count);

  /// No description provided for @trialEndingCount.
  ///
  /// In en, this message translates to:
  /// **'Trial ending ({count})'**
  String trialEndingCount(int count);

  /// No description provided for @lockedCount.
  ///
  /// In en, this message translates to:
  /// **'Locked ({count})'**
  String lockedCount(int count);

  /// No description provided for @noStoresMatch.
  ///
  /// In en, this message translates to:
  /// **'No stores match'**
  String get noStoresMatch;

  /// No description provided for @trialOver.
  ///
  /// In en, this message translates to:
  /// **'Trial over'**
  String get trialOver;

  /// No description provided for @dbNotReady.
  ///
  /// In en, this message translates to:
  /// **'Database not ready'**
  String get dbNotReady;

  /// No description provided for @dbNotMoved.
  ///
  /// In en, this message translates to:
  /// **'Not moved to its own database yet'**
  String get dbNotMoved;

  /// No description provided for @dbServing.
  ///
  /// In en, this message translates to:
  /// **'Served from its own database'**
  String get dbServing;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planLabel;

  /// No description provided for @noPlan.
  ///
  /// In en, this message translates to:
  /// **'No plan'**
  String get noPlan;

  /// No description provided for @trialLabel.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trialLabel;

  /// No description provided for @noTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'No time limit'**
  String get noTimeLimit;

  /// No description provided for @ownerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerLabel;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdLabel;

  /// No description provided for @databaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get databaseLabel;

  /// No description provided for @timezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timezoneLabel;

  /// No description provided for @enterStore.
  ///
  /// In en, this message translates to:
  /// **'Enter for support'**
  String get enterStore;

  /// No description provided for @enterStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter {name}?'**
  String enterStoreTitle(String name);

  /// No description provided for @enterStoreBody.
  ///
  /// In en, this message translates to:
  /// **'This device moves into that store as platform staff. Everything you do there is logged, and the banner at the top brings you back.'**
  String get enterStoreBody;

  /// No description provided for @youAreInThisStore.
  ///
  /// In en, this message translates to:
  /// **'This device is in this store now'**
  String get youAreInThisStore;

  /// No description provided for @reactivateFirst.
  ///
  /// In en, this message translates to:
  /// **'Reactivate the store first'**
  String get reactivateFirst;

  /// No description provided for @leaveSupport.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveSupport;

  /// No description provided for @leaveSupportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not leave support mode. Switch store from your profile.'**
  String get leaveSupportFailed;

  /// No description provided for @editStoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editStoreDetails;

  /// No description provided for @storeTypeChangeWarning.
  ///
  /// In en, this message translates to:
  /// **'A different kind of shop reads a different shared catalogue. Products it already has stay, but may no longer be found there.'**
  String get storeTypeChangeWarning;

  /// No description provided for @storeTypeChangedNote.
  ///
  /// In en, this message translates to:
  /// **'Saved. The store now reads another kind of shop\'s catalogue.'**
  String get storeTypeChangedNote;

  /// No description provided for @extendTrial.
  ///
  /// In en, this message translates to:
  /// **'Extend trial'**
  String get extendTrial;

  /// No description provided for @extendUnlimited.
  ///
  /// In en, this message translates to:
  /// **'No time limit'**
  String get extendUnlimited;

  /// No description provided for @extendUnlimitedHelp.
  ///
  /// In en, this message translates to:
  /// **'For a shop that has started paying.'**
  String get extendUnlimitedHelp;

  /// No description provided for @extendDays.
  ///
  /// In en, this message translates to:
  /// **'Days to add'**
  String get extendDays;

  /// No description provided for @extendDaysRange.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and 3650 days'**
  String get extendDaysRange;

  /// No description provided for @extendActivate.
  ///
  /// In en, this message translates to:
  /// **'Switch the store on as well'**
  String get extendActivate;

  /// No description provided for @extendFromEnd.
  ///
  /// In en, this message translates to:
  /// **'Days are added after the current end date.'**
  String get extendFromEnd;

  /// No description provided for @extendFromToday.
  ///
  /// In en, this message translates to:
  /// **'The trial has ended, so days count from today.'**
  String get extendFromToday;

  /// No description provided for @trialCurrentlyEnds.
  ///
  /// In en, this message translates to:
  /// **'The trial ends {date}'**
  String trialCurrentlyEnds(String date);

  /// No description provided for @trialNowEnds.
  ///
  /// In en, this message translates to:
  /// **'{name}: trial now ends {date}'**
  String trialNowEnds(String name, String date);

  /// No description provided for @trialNowUnlimited.
  ///
  /// In en, this message translates to:
  /// **'{name} has no time limit now'**
  String trialNowUnlimited(String name);

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @suspendStore.
  ///
  /// In en, this message translates to:
  /// **'Suspend store'**
  String get suspendStore;

  /// No description provided for @reactivateStore.
  ///
  /// In en, this message translates to:
  /// **'Reactivate store'**
  String get reactivateStore;

  /// No description provided for @suspendStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend {name}?'**
  String suspendStoreTitle(String name);

  /// No description provided for @reactivateStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate {name}?'**
  String reactivateStoreTitle(String name);

  /// No description provided for @suspendStoreBody.
  ///
  /// In en, this message translates to:
  /// **'Nobody can sign in to this store while it is suspended. Nothing in it is deleted.'**
  String get suspendStoreBody;

  /// No description provided for @reactivateStoreBody.
  ///
  /// In en, this message translates to:
  /// **'Its team can sign in again.'**
  String get reactivateStoreBody;

  /// No description provided for @storeSuspended.
  ///
  /// In en, this message translates to:
  /// **'{name} suspended'**
  String storeSuspended(String name);

  /// No description provided for @storeReactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} is active again'**
  String storeReactivated(String name);

  /// No description provided for @optionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalDetails;

  /// No description provided for @storeCreated.
  ///
  /// In en, this message translates to:
  /// **'{name} created'**
  String storeCreated(String name);

  /// No description provided for @ownerReusedAccount.
  ///
  /// In en, this message translates to:
  /// **'The owner already had an account and signs in with it.'**
  String get ownerReusedAccount;

  /// No description provided for @dbProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'The store exists, but its database was not finished'**
  String get dbProblemTitle;

  /// No description provided for @dbSteps.
  ///
  /// In en, this message translates to:
  /// **'Database created: {created} · Tables made: {migrated}'**
  String dbSteps(String created, String migrated);

  /// No description provided for @dbProblemNote.
  ///
  /// In en, this message translates to:
  /// **'The owner cannot work in it until this is fixed on the server (php artisan tenancy:status).'**
  String get dbProblemNote;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @suggestedFrom.
  ///
  /// In en, this message translates to:
  /// **'From {who}'**
  String suggestedFrom(String who);

  /// No description provided for @platformSuggestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suggestions waiting'**
  String get platformSuggestionsEmpty;

  /// No description provided for @platformSuggestionsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Products shops put up for the shared catalogue appear here.'**
  String get platformSuggestionsEmptyBody;

  /// No description provided for @platformSuggestionAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to the shared catalogue'**
  String get platformSuggestionAdded;

  /// No description provided for @platformSuggestionMatched.
  ///
  /// In en, this message translates to:
  /// **'Approved — it matched an entry already in the catalogue'**
  String get platformSuggestionMatched;

  /// No description provided for @platformSuggestionRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get platformSuggestionRejected;

  /// No description provided for @newCatalogEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newCatalogEntry;

  /// No description provided for @editCatalogEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editCatalogEntry;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All kinds'**
  String get allTypes;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'Any status'**
  String get allStatuses;

  /// No description provided for @deletedCount.
  ///
  /// In en, this message translates to:
  /// **'Deleted ({count})'**
  String deletedCount(int count);

  /// No description provided for @inStoresCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{In no shops} =1{In 1 shop} other{In {count} shops}}'**
  String inStoresCount(int count);

  /// No description provided for @catalogStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get catalogStatus;

  /// No description provided for @catalogStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get catalogStatusApproved;

  /// No description provided for @catalogStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get catalogStatusPending;

  /// No description provided for @catalogStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get catalogStatusDraft;

  /// No description provided for @catalogStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get catalogStatusRejected;

  /// No description provided for @catalogEditNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shop sells this.} other{{count} shops sell this.}} Their own names and prices are not touched by an edit here.'**
  String catalogEditNote(int count);

  /// No description provided for @catalogEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get catalogEntrySaved;

  /// No description provided for @deleteCatalogEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteCatalogEntryTitle(String name);

  /// No description provided for @deleteCatalogEntryBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves every catalogue list and the duplicate check. Shops already selling it keep their product and its history.'**
  String get deleteCatalogEntryBody;

  /// No description provided for @catalogEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Deleted} =1{Deleted — 1 shop keeps it on its shelf} other{Deleted — {count} shops keep it on their shelves}}'**
  String catalogEntryDeleted(int count);

  /// No description provided for @catalogEntryIsDeleted.
  ///
  /// In en, this message translates to:
  /// **'This entry is deleted. Restoring it puts it back on every catalogue list.'**
  String get catalogEntryIsDeleted;

  /// No description provided for @catalogRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get catalogRestore;

  /// No description provided for @catalogEntryRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get catalogEntryRestored;

  /// No description provided for @noStockLeft.
  ///
  /// In en, this message translates to:
  /// **'No more {name} in stock'**
  String noStockLeft(String name);

  /// No description provided for @sellingPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get sellingPriceLabel;

  /// No description provided for @maxLineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Up to {amount} keeps this line above cost'**
  String maxLineDiscount(String amount);

  /// No description provided for @lineDiscountTooHigh.
  ///
  /// In en, this message translates to:
  /// **'More than {amount} sells below cost'**
  String lineDiscountTooHigh(String amount);

  /// No description provided for @unitPriceBelowCost.
  ///
  /// In en, this message translates to:
  /// **'Below the cost of {amount}'**
  String unitPriceBelowCost(String amount);

  /// No description provided for @maxBillDiscount.
  ///
  /// In en, this message translates to:
  /// **'Up to {rate}% ({amount}) keeps the bill above cost'**
  String maxBillDiscount(String rate, String amount);

  /// No description provided for @billDiscountTooHigh.
  ///
  /// In en, this message translates to:
  /// **'More than {rate}% sells below cost'**
  String billDiscountTooHigh(String rate);

  /// No description provided for @noDiscountRoom.
  ///
  /// In en, this message translates to:
  /// **'No room for a discount — the bill is already at cost'**
  String get noDiscountRoom;

  /// No description provided for @chooseUnit.
  ///
  /// In en, this message translates to:
  /// **'Choose a unit'**
  String get chooseUnit;

  /// No description provided for @unitSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search units, or type a new one'**
  String get unitSearchHint;

  /// No description provided for @useNewUnit.
  ///
  /// In en, this message translates to:
  /// **'Use “{unit}” as a new unit'**
  String useNewUnit(String unit);

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptServedBy.
  ///
  /// In en, this message translates to:
  /// **'Served by'**
  String get receiptServedBy;

  /// No description provided for @receiptItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get receiptItem;

  /// No description provided for @receiptAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get receiptAmount;

  /// No description provided for @receiptLineDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Item discounts'**
  String get receiptLineDiscounts;

  /// No description provided for @receiptTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get receiptTotal;

  /// No description provided for @receiptYouSaved.
  ///
  /// In en, this message translates to:
  /// **'YOU SAVED'**
  String get receiptYouSaved;

  /// No description provided for @receiptThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you, please come again'**
  String get receiptThanks;

  /// No description provided for @receiptMrpSave.
  ///
  /// In en, this message translates to:
  /// **'MRP {mrp} · save {amount}{rate}'**
  String receiptMrpSave(String mrp, String amount, String rate);

  /// No description provided for @noPrinterChosen.
  ///
  /// In en, this message translates to:
  /// **'No printer chosen'**
  String get noPrinterChosen;

  /// No description provided for @changePrinter.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get changePrinter;

  /// No description provided for @choosePrinter.
  ///
  /// In en, this message translates to:
  /// **'Choose a printer'**
  String get choosePrinter;

  /// No description provided for @paperWidth.
  ///
  /// In en, this message translates to:
  /// **'Paper width'**
  String get paperWidth;

  /// No description provided for @noPairedPrinters.
  ///
  /// In en, this message translates to:
  /// **'No paired printers. Pair the printer in the phone\'s Bluetooth settings, then try again.'**
  String get noPairedPrinters;

  /// No description provided for @bluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn it on to print.'**
  String get bluetoothOff;

  /// No description provided for @bluetoothDenied.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission was refused. Allow it in the app\'s settings to print.'**
  String get bluetoothDenied;

  /// No description provided for @saveAsImage.
  ///
  /// In en, this message translates to:
  /// **'Save as image'**
  String get saveAsImage;

  /// No description provided for @receiptSaved.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved to the gallery'**
  String get receiptSaved;

  /// No description provided for @receiptSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the receipt image'**
  String get receiptSaveFailed;

  /// No description provided for @printSent.
  ///
  /// In en, this message translates to:
  /// **'Printed on {printer}'**
  String printSent(String printer);

  /// No description provided for @printerUnreachableSaved.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach {printer}, so the receipt was saved to the gallery.'**
  String printerUnreachableSaved(String printer);

  /// No description provided for @bluetoothOffSaved.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off, so the receipt was saved to the gallery.'**
  String get bluetoothOffSaved;

  /// No description provided for @bluetoothDeniedSaved.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth permission, so the receipt was saved to the gallery.'**
  String get bluetoothDeniedSaved;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppL10nBn();
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
