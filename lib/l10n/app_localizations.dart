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
