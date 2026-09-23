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
  /// **'bizPOS'**
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

  /// No description provided for @printingSoon.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth printing arrives in a later phase.'**
  String get printingSoon;

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
  /// **'What they owed before this shop used bizPOS.'**
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
