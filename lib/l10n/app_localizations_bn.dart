// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppL10nBn extends AppL10n {
  AppL10nBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'বিজপস';

  @override
  String get signInTitle => 'সাইন ইন';

  @override
  String get signInSubtitle => 'দোকান মালিকের দেওয়া অ্যাকাউন্ট ব্যবহার করুন।';

  @override
  String get email => 'ইমেইল';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get signingIn => 'সাইন ইন হচ্ছে…';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get showPassword => 'পাসওয়ার্ড দেখান';

  @override
  String get hidePassword => 'পাসওয়ার্ড লুকান';

  @override
  String get serverLabel => 'সার্ভার';

  @override
  String get dashboard => 'ড্যাশবোর্ড';

  @override
  String get sell => 'বিক্রি';

  @override
  String get invoices => 'ইনভয়েস';

  @override
  String get customers => 'কাস্টমার';

  @override
  String get products => 'পণ্য';

  @override
  String get packages => 'প্যাকেজ';

  @override
  String get catalogue => 'ক্যাটালগ';

  @override
  String get suggestions => 'প্রস্তাবনা';

  @override
  String get purchase => 'ক্রয়';

  @override
  String get accounts => 'হিসাব';

  @override
  String get reports => 'রিপোর্ট';

  @override
  String get team => 'টিম';

  @override
  String get platform => 'প্ল্যাটফর্ম';

  @override
  String get more => 'আরও';

  @override
  String get pressBackAgainToExit => 'বের হতে আবার ব্যাক চাপুন';

  @override
  String get menu => 'মেনু';

  @override
  String get mainMenu => 'প্রধান মেনু';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get comingSoonTitle => 'এখনও তৈরি হয়নি';

  @override
  String comingSoonBody(String screen) {
    return '$screen পরের ধাপে আসছে। আপনার রোলে এটির অনুমতি আছে।';
  }

  @override
  String get noStoreTitle => 'কোনো দোকান নেই';

  @override
  String get noStoreBody =>
      'এই অ্যাকাউন্ট এখনও কোনো সক্রিয় দোকানের সঙ্গে যুক্ত নয়, বা স্থগিত করা হয়েছে। দোকান মালিককে যুক্ত করতে বলুন।';

  @override
  String get notAllowedTitle => 'অনুমতি নেই';

  @override
  String get notAllowedBody => 'আপনার রোলে এই স্ক্রিনটি নেই।';

  @override
  String get store => 'দোকান';

  @override
  String get branch => 'শাখা';

  @override
  String get role => 'রোল';

  @override
  String get switchStore => 'দোকান বদলান';

  @override
  String get switchBranch => 'শাখা বদলান';

  @override
  String get appearance => 'থিম';

  @override
  String get themeLight => 'দিনের আলো';

  @override
  String get themeDark => 'রাতের আঁধার';

  @override
  String get language => 'ভাষা';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get devices => 'সাইন ইন করা ডিভাইস';

  @override
  String get devicesBody => 'হারিয়ে যাওয়া ফোন সাইন আউট করে দিন।';

  @override
  String get thisDevice => 'এই ডিভাইস';

  @override
  String lastUsed(String when) {
    return 'সর্বশেষ ব্যবহার $when';
  }

  @override
  String get revokeDevice => 'সাইন আউট';

  @override
  String revokeDeviceConfirm(String name) {
    return '$name সাইন আউট করবেন? যার কাছে আছে তাকে আবার পাসওয়ার্ড দিতে হবে।';
  }

  @override
  String get supportMode =>
      'সাপোর্ট মোড — আপনি প্ল্যাটফর্ম স্টাফ হিসেবে এই দোকানে আছেন';

  @override
  String sessionExpiresSoon(String date) {
    return 'এই ডিভাইস $date তারিখে সাইন আউট হয়ে যাবে।';
  }

  @override
  String get permissionsHeading => 'আপনি যা করতে পারেন';

  @override
  String permissionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি অনুমতি',
      one: '১টি অনুমতি',
      zero: 'কোনো অনুমতি নেই',
    );
    return '$_temp0';
  }

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get close => 'বন্ধ';

  @override
  String get confirm => 'নিশ্চিত করুন';

  @override
  String get emptyTitle => 'এখানে এখনও কিছু নেই';

  @override
  String get genericError => 'কিছু একটা সমস্যা হয়েছে।';

  @override
  String get offline => 'সংযোগ নেই';

  @override
  String get requiredField => 'এটি দিতে হবে';

  @override
  String get invalidEmail => 'সঠিক ইমেইল দিন';

  @override
  String get posTitle => 'বিক্রয়';

  @override
  String get posSearchHint => 'স্ক্যান করুন অথবা নাম, বারকোড দিয়ে খুঁজুন';

  @override
  String get posScan => 'বারকোড স্ক্যান';

  @override
  String get posTabProducts => 'পণ্য';

  @override
  String get posTabPackages => 'প্যাকেজ';

  @override
  String get posNoResults => 'কিছু মিলল না';

  @override
  String get posNoResultsBody => 'নামের কিছু অংশ অথবা বারকোড দিয়ে দেখুন।';

  @override
  String get posStartTitle => 'বিক্রয় শুরু করুন';

  @override
  String get posStartBody => 'প্রথম পণ্যটি স্ক্যান করুন অথবা খুঁজুন।';

  @override
  String inStock(String count) {
    return 'স্টকে $count';
  }

  @override
  String get outOfStock => 'স্টক নেই';

  @override
  String get lowStock => 'স্টক কম';

  @override
  String addedToCart(String name) {
    return '$name যোগ হয়েছে';
  }

  @override
  String get packageBadge => 'প্যাকেজ';

  @override
  String buildable(String count) {
    return '$count টি বানানো যাবে';
  }

  @override
  String get cart => 'কার্ট';

  @override
  String get cartEmpty => 'কার্ট খালি';

  @override
  String get cartEmptyBody => 'স্ক্যান করা পণ্য এখানে আসবে।';

  @override
  String cartItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পণ্য',
      one: '১টি পণ্য',
    );
    return '$_temp0';
  }

  @override
  String get subtotal => 'সাবটোটাল';

  @override
  String get orderDiscount => 'বিলে ছাড়';

  @override
  String get estimatedTotal => 'আনুমানিক মোট';

  @override
  String get estimatedNote => 'ভ্যাট ও চূড়ান্ত মোট সার্ভার হিসাব করে।';

  @override
  String get lineDiscount => 'লাইনে ছাড়';

  @override
  String get unitPrice => 'একক দাম';

  @override
  String editLine(String name) {
    return '$name সম্পাদনা';
  }

  @override
  String get removeLine => 'বাদ দিন';

  @override
  String overStockWarning(String count) {
    return 'এই শাখায় আর $count টি আছে। বেশি দিলে সার্ভার নেবে না।';
  }

  @override
  String get clearCart => 'কার্ট খালি করুন';

  @override
  String get clearCartConfirm => 'সব পণ্য বাদ দিয়ে নতুন করে শুরু করবেন?';

  @override
  String get noteOnSale => 'এই বিক্রয়ে নোট';

  @override
  String get customer => 'ক্রেতা';

  @override
  String get walkInCustomer => 'ওয়াক-ইন ক্রেতা';

  @override
  String get chooseCustomer => 'ক্রেতা বাছুন';

  @override
  String get customerSearchHint => 'ফোন অথবা নাম (২+ অক্ষর)';

  @override
  String get customerSearchShort => 'কমপক্ষে দুইটি অক্ষর লিখুন';

  @override
  String get addCustomer => 'ক্রেতা যোগ করুন';

  @override
  String get quickAddCustomer => 'নতুন ক্রেতা';

  @override
  String get customerName => 'নাম';

  @override
  String get customerPhone => 'ফোন';

  @override
  String get customerEmail => 'ইমেইল';

  @override
  String get customerAddress => 'ঠিকানা';

  @override
  String get creditLimit => 'বাকির সীমা';

  @override
  String get creditLimitHelp => 'একসাথে সর্বোচ্চ কত বাকি রাখতে পারবে।';

  @override
  String customerExists(String name) {
    return 'এই ফোনে $name আগে থেকেই আছেন।';
  }

  @override
  String customerAdded(String name) {
    return '$name যোগ হয়েছেন';
  }

  @override
  String get customerSaved => 'সংরক্ষিত';

  @override
  String get clearCustomer => 'ক্রেতা সরান';

  @override
  String get walkInNoCredit => 'ওয়াক-ইন ক্রেতা বাকিতে কিনতে পারেন না।';

  @override
  String get dueLabel => 'বাকি';

  @override
  String get points => 'পয়েন্ট';

  @override
  String pointsBalance(String count) {
    return '$count পয়েন্ট';
  }

  @override
  String get noPhone => 'ফোন নেই';

  @override
  String get charge => 'চার্জ';

  @override
  String get payment => 'পেমেন্ট';

  @override
  String get payments => 'পেমেন্ট';

  @override
  String get addPayment => 'আরেকটি পেমেন্ট যোগ করুন';

  @override
  String get payMethodCash => 'নগদ';

  @override
  String get payMethodCard => 'কার্ড';

  @override
  String get payMethodBkash => 'বিকাশ';

  @override
  String get payMethodNagad => 'নগদ';

  @override
  String get payMethodRocket => 'রকেট';

  @override
  String get payMethodBank => 'ব্যাংক';

  @override
  String get account => 'অ্যাকাউন্ট';

  @override
  String get reference => 'রেফারেন্স';

  @override
  String get amountReceived => 'প্রাপ্ত টাকা';

  @override
  String get exactAmount => 'সমপরিমাণ';

  @override
  String get changeDue => 'ফেরত দিতে হবে';

  @override
  String get remainingDue => 'বাকি রইল';

  @override
  String get dueNeedsCustomer => 'বাকি রাখতে নামসহ ক্রেতা লাগবে।';

  @override
  String get creditOff => 'এই দোকানে বাকিতে বিক্রয় বন্ধ।';

  @override
  String get redeemPoints => 'পয়েন্ট ভাঙান';

  @override
  String redeemPointsHelp(String count, String worth) {
    return '$count পয়েন্ট আছে, মূল্য $worth।';
  }

  @override
  String get redeemMax => 'সর্বোচ্চ ব্যবহার করুন';

  @override
  String get redeemCapNote =>
      'সার্ভার এটি সীমিত করে, তাই রসিদে কম দেখাতে পারে।';

  @override
  String get completeSale => 'বিক্রয় শেষ করুন';

  @override
  String get payFull => 'পুরোটা পরিশোধ';

  @override
  String get saleComplete => 'বিক্রয় সম্পন্ন';

  @override
  String invoiceNumber(String no) {
    return 'ইনভয়েস $no';
  }

  @override
  String get totalCharged => 'মোট';

  @override
  String get paidLabel => 'পরিশোধ';

  @override
  String pointsEarned(String count) {
    return '$count পয়েন্ট পেয়েছেন';
  }

  @override
  String pointsRedeemed(String count) {
    return '$count পয়েন্ট ভাঙানো হয়েছে';
  }

  @override
  String get newSale => 'পরবর্তী বিক্রয়';

  @override
  String get viewReceipt => 'রসিদ দেখুন';

  @override
  String get holdCart => 'কার্ট রেখে দিন';

  @override
  String get heldCarts => 'রাখা কার্ট';

  @override
  String heldCartsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি কার্ট রাখা',
      one: '১টি কার্ট রাখা',
      zero: 'কোনো কার্ট রাখা নেই',
    );
    return '$_temp0';
  }

  @override
  String get holdLabel => 'চেনার মতো একটি নাম';

  @override
  String get holdLabelHint => 'নীল শার্ট পরা ভদ্রলোক';

  @override
  String holdSaved(String label) {
    return '“$label” নামে রাখা হলো';
  }

  @override
  String get resume => 'ফিরিয়ে আনুন';

  @override
  String get discard => 'বাতিল';

  @override
  String discardHoldConfirm(String label) {
    return '“$label” ফেলে দেবেন? এটি আর ফেরত আনা যাবে না।';
  }

  @override
  String get resumeOverwrites => 'এখনকার কার্টের জায়গায় এটি বসবে।';

  @override
  String get noHeldCarts => 'কোনো কার্ট রাখা নেই';

  @override
  String get cashDrawer => 'ক্যাশ ড্রয়ার';

  @override
  String get openDrawer => 'ড্রয়ার খুলুন';

  @override
  String get closeDrawer => 'ড্রয়ার বন্ধ করুন';

  @override
  String get drawerOpen => 'ড্রয়ার খোলা';

  @override
  String get drawerClosed => 'ড্রয়ার বন্ধ';

  @override
  String get drawerClosedBody =>
      'বিক্রয় হবে, কিন্তু কোনো ড্রয়ারে হিসাব হবে না।';

  @override
  String get openingCash => 'এখন ড্রয়ারে যত টাকা';

  @override
  String get countedCash => 'গণনা করা টাকা';

  @override
  String openedAt(String when) {
    return 'খোলা হয়েছে $when';
  }

  @override
  String get expectedCash => 'হওয়ার কথা';

  @override
  String get countedLabel => 'গণনা';

  @override
  String get difference => 'পার্থক্য';

  @override
  String shortBy(String amount) {
    return '$amount কম আছে';
  }

  @override
  String overBy(String amount) {
    return '$amount বেশি আছে';
  }

  @override
  String get balanced => 'হিসাব মিলেছে';

  @override
  String get drawerOpened => 'ড্রয়ার খোলা হলো';

  @override
  String get closingNote => 'নোট';

  @override
  String get done => 'হয়েছে';

  @override
  String get invoiceSearchHint => 'ইনভয়েস নং, ক্রেতা অথবা ফোন';

  @override
  String get filterToday => 'আজ';

  @override
  String get filterWeek => '৭ দিন';

  @override
  String get filterAll => 'সব';

  @override
  String invoiceCount(String count) {
    return '$count টি ইনভয়েস';
  }

  @override
  String get invoiceTotal => 'মোট';

  @override
  String get invoiceDue => 'বাকি';

  @override
  String get statusPaid => 'পরিশোধিত';

  @override
  String get statusPartial => 'আংশিক';

  @override
  String get statusUnpaid => 'বাকি';

  @override
  String get statusCompleted => 'সম্পন্ন';

  @override
  String get statusReturned => 'ফেরত';

  @override
  String get statusVoid => 'বাতিল';

  @override
  String get noInvoices => 'এখনও কোনো ইনভয়েস নেই';

  @override
  String get noInvoicesBody => 'এই কাউন্টারের বিক্রয় এখানে আসবে।';

  @override
  String get ownInvoicesOnly => 'আপনার নিজের বিক্রয়';

  @override
  String soldBy(String name) {
    return 'বিক্রয় $name';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পণ্য',
      one: '১টি পণ্য',
    );
    return '$_temp0';
  }

  @override
  String get loadMore => 'আরও দেখুন';

  @override
  String get invoice => 'ইনভয়েস';

  @override
  String get receipt => 'রসিদ';

  @override
  String get items => 'পণ্য';

  @override
  String get vat => 'ভ্যাট';

  @override
  String get discount => 'ছাড়';

  @override
  String get grandTotal => 'মোট';

  @override
  String get collectDue => 'বাকি আদায়';

  @override
  String get acceptReturn => 'ফেরত নিন';

  @override
  String get voidInvoice => 'বিক্রয় বাতিল';

  @override
  String get printReceipt => 'প্রিন্ট';

  @override
  String get printingSoon => 'ব্লুটুথ প্রিন্ট পরের ধাপে আসছে।';

  @override
  String get share => 'শেয়ার';

  @override
  String get collectTitle => 'বাকি আদায়';

  @override
  String get outstanding => 'বকেয়া';

  @override
  String get collectAmount => 'আদায়কৃত টাকা';

  @override
  String get collectAll => 'পুরোটা আদায়';

  @override
  String collected(String amount) {
    return '$amount আদায় হয়েছে';
  }

  @override
  String get overPayment => 'বকেয়ার চেয়ে বেশি।';

  @override
  String get returnTitle => 'ফেরত নিন';

  @override
  String get returnBody =>
      'কি ফেরত আসছে বাছুন। স্টক বাড়বে আর ক্রেতার হিসাব কমবে।';

  @override
  String get returnQty => 'ফেরত';

  @override
  String get returnReason => 'কারণ';

  @override
  String get returnReasonHint => 'প্যাক নষ্ট';

  @override
  String get returnNothing => 'ফেরতের জন্য কিছু বাছা হয়নি।';

  @override
  String returnDone(String no) {
    return 'ফেরত $no লিপিবদ্ধ হয়েছে';
  }

  @override
  String returnOf(String count) {
    return '$count এর মধ্যে';
  }

  @override
  String get voidTitle => 'বিক্রয় বাতিল';

  @override
  String get voidBody =>
      'ফেরতে পণ্য ফিরে আসে, ইনভয়েস থাকে। বাতিল বলে বিক্রয়টি হওয়াই উচিত ছিল না: স্টক ফিরে যায়, টাকা তার অ্যাকাউন্ট থেকে ফেরত যায়, ক্রেতার দেনা বাদ যায় আর পয়েন্ট বাতিল হয়। ইনভয়েসটি তালিকায় বাতিল হিসেবে থাকে।';

  @override
  String get voidReason => 'কেন বাতিল করা হচ্ছে?';

  @override
  String get voidReasonHint => 'ভুল ক্রেতার নামে তোলা হয়েছিল';

  @override
  String get voidConfirm => 'বিক্রয় বাতিল করুন';

  @override
  String voidDone(String no, String count) {
    return '$no বাতিল হয়েছে। $count একক স্টকে ফিরেছে।';
  }

  @override
  String get voidNotAllowed => 'কেবল সম্পন্ন ইনভয়েস বাতিল করা যায়।';

  @override
  String get customersTitle => 'ক্রেতা';

  @override
  String get customerSearchListHint => 'নাম অথবা ফোন';

  @override
  String get noCustomers => 'এখনও কোনো ক্রেতা নেই';

  @override
  String get noCustomersBody => 'কাউন্টারে অথবা নিচের বাটন দিয়ে যোগ করুন।';

  @override
  String get editCustomer => 'ক্রেতা সম্পাদনা';

  @override
  String get newCustomer => 'নতুন ক্রেতা';

  @override
  String get ledger => 'খাতা';

  @override
  String get ledgerEmpty => 'এই খাতায় এখনও কিছু নেই';

  @override
  String get debit => 'দেনা';

  @override
  String get credit => 'জমা';

  @override
  String get balance => 'ব্যালেন্স';

  @override
  String get pointsTitle => 'লয়্যালটি পয়েন্ট';

  @override
  String pointsWorth(String amount) {
    return 'মূল্য $amount';
  }

  @override
  String get adjustPoints => 'পয়েন্ট সমন্বয়';

  @override
  String get adjustPointsHelp => 'ধনাত্মক সংখ্যা যোগ করে, বিয়োগাত্মক বাদ দেয়।';

  @override
  String get pointsNote => 'কারণ';

  @override
  String pointsAdjusted(String count) {
    return 'এখন ব্যালেন্স $count';
  }

  @override
  String get pointsNegative => 'এতে ব্যালেন্স শূন্নের নিচে যাবে।';

  @override
  String salesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি বিক্রয়',
      one: '১টি বিক্রয়',
      zero: 'কোনো বিক্রয় নেই',
    );
    return '$_temp0';
  }

  @override
  String customerSince(String name) {
    return 'যোগ করেছেন $name';
  }

  @override
  String get viewInvoices => 'তাঁর ইনভয়েস';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get add => 'যোগ';

  @override
  String get apply => 'প্রয়োগ';

  @override
  String get remove => 'বাদ';

  @override
  String get search => 'খুঁজুন';

  @override
  String get all => 'সব';

  @override
  String get today => 'আজ';

  @override
  String get yesterday => 'গতকাল';

  @override
  String get notAllowedAction => 'আপনার ভূমিকায় এটি নেই।';

  @override
  String get cameraDenied => 'ক্যামেরা পাওয়া যাচ্ছে না। বারকোড লিখে দিন।';

  @override
  String get typeBarcode => 'বারকোড লিখুন';

  @override
  String get scanning => 'বারকোডের দিকে ক্যামেরা ধরুন';

  @override
  String get torch => 'টর্চ';

  @override
  String get productsTitle => 'পণ্য';

  @override
  String get productsSearchHint => 'নাম, বারকোড বা SKU';

  @override
  String get productsLowOnly => 'কম স্টক';

  @override
  String get productsTrashed => 'মুছে ফেলা';

  @override
  String get productsLive => 'তাকে আছে';

  @override
  String get productsNone => 'এখনও কোনো পণ্য নেই';

  @override
  String get productsNoneBody => 'প্রথমটি যোগ করুন, বা ক্যাটালগ থেকে আনুন।';

  @override
  String get productsNoResults => 'কিছু মেলেনি';

  @override
  String get productsNoResultsBody => 'নামের অংশ, বারকোড বা SKU দিয়ে দেখুন।';

  @override
  String get productsNoneTrashed => 'কিছু মোছা হয়নি';

  @override
  String get productsNoneTrashedBody =>
      'মুছে ফেলা পণ্য ফেরত আনার আগ পর্যন্ত এখানে থাকে।';

  @override
  String get addProduct => 'পণ্য যোগ করুন';

  @override
  String get editProduct => 'সম্পাদনা';

  @override
  String get productSaved => 'সংরক্ষিত';

  @override
  String productAdded(String name) {
    return '$name তাকে উঠেছে';
  }

  @override
  String get stockValue => 'স্টকের মূল্য';

  @override
  String lowStockCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি কমে এসেছে',
      zero: 'কিছু কম নেই',
    );
    return '$_temp0';
  }

  @override
  String expiringCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটির মেয়াদ শেষ হচ্ছে',
      zero: 'মেয়াদ শেষের কিছু নেই',
    );
    return '$_temp0';
  }

  @override
  String productCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পণ্য',
    );
    return '$_temp0';
  }

  @override
  String showingOf(String shown, String total) {
    return '$totalটির মধ্যে $shownটি';
  }

  @override
  String get costLabel => 'ক্রয়মূল্য';

  @override
  String get saleLabel => 'বিক্রয়মূল্য';

  @override
  String get wholesaleLabel => 'পাইকারি';

  @override
  String get mrpLabel => 'এমআরপি';

  @override
  String get marginLabel => 'লাভ';

  @override
  String get vatLabel => 'ভ্যাট';

  @override
  String get skuLabel => 'SKU';

  @override
  String get barcodeLabel => 'বারকোড';

  @override
  String get unitLabel => 'একক';

  @override
  String get brandLabel => 'ব্র্যান্ড';

  @override
  String get categoryLabel => 'শ্রেণি';

  @override
  String get minimumStockLabel => 'পুনরায় আনুন';

  @override
  String get openingStockLabel => 'শুরুর স্টক';

  @override
  String get trackBatchLabel => 'ব্যাচ ও মেয়াদ রাখুন';

  @override
  String get genericNameLabel => 'জেনেরিক নাম';

  @override
  String get productNameLabel => 'নাম';

  @override
  String get inactiveBadge => 'বিক্রয়ে নেই';

  @override
  String get deletedBadge => 'মুছে ফেলা';

  @override
  String onShelf(String qty) {
    return 'তাকে $qtyটি';
  }

  @override
  String get changePrices => 'দাম বদলান';

  @override
  String get pricesSaved => 'দাম বদলেছে';

  @override
  String get pricesUnchanged => 'বদলানোর কিছু নেই';

  @override
  String get priceHistory => 'দামের ইতিহাস';

  @override
  String get stockHistory => 'স্টকের ইতিহাস';

  @override
  String get currentPrice => 'এখন';

  @override
  String get adjustStock => 'স্টক সমন্বয়';

  @override
  String get adjustQtyLabel => 'পরিবর্তন';

  @override
  String get adjustHelp =>
      'চিহ্নসহ, শূন্য নয়। −৩ মানে তাক থেকে তিনটি কমল, ৩ মানে তিনটি ফিরল।';

  @override
  String get adjustReasonLabel => 'কারণ';

  @override
  String get adjustReasonHint => 'একটি কারণ বেছে নিন';

  @override
  String get adjustReasonOther => 'অন্য (কারণ লিখুন)';

  @override
  String get adjustReasonTyped => 'কারণ লিখুন';

  @override
  String get adjustIsDamage => 'এটি ক্ষতি, সংশোধন নয়';

  @override
  String get adjustDone => 'স্টক সমন্বয় হয়েছে';

  @override
  String get deleteProduct => 'পণ্যটি মুছুন';

  @override
  String get deleteProductBody =>
      'এটি বিক্রয়, তালিকা ও স্টকের হিসাব থেকে সরে যাবে। পুরোনো বিক্রয়ে নাম থাকবে, আর ফেরত আনা যাবে।';

  @override
  String deleteProductDone(String qty) {
    return 'মোছা হয়েছে। তাক থেকে $qtyটি সরল।';
  }

  @override
  String get restoreProduct => 'ফেরত আনুন';

  @override
  String restoreProductDone(String name) {
    return '$name ফিরেছে';
  }

  @override
  String deletedOn(String date) {
    return '$date মোছা হয়েছে';
  }

  @override
  String get noMovements => 'এখনও স্টক নড়েনি';

  @override
  String get noPrices => 'এখনও দাম বদলায়নি';

  @override
  String get movementOpening => 'শুরুর';

  @override
  String get movementPurchase => 'মাল এসেছে';

  @override
  String get movementSale => 'বিক্রি';

  @override
  String get movementReturn => 'ফেরত';

  @override
  String get movementAdjustment => 'সমন্বয়';

  @override
  String get movementDamage => 'ক্ষতি';

  @override
  String get movementTransfer => 'স্থানান্তর';

  @override
  String balanceAfter(String qty) {
    return 'বাকি: $qty';
  }

  @override
  String get priceBelowCost => 'ক্রয়মূল্যের কম';

  @override
  String get saleBelowPurchase => 'বিক্রয়মূল্য ক্রয়মূল্যের কম হতে পারে না।';

  @override
  String get costHidden => 'আপনার ভূমিকার জন্য ক্রয়মূল্য দেখানো হয় না।';

  @override
  String get yes => 'হ্যাঁ';

  @override
  String get trialEndsToday =>
      'আজ আপনার ট্রায়াল শেষ। দোকান চালু রাখতে প্ল্যাটফর্মের সাথে যোগাযোগ করুন।';

  @override
  String trialDaysLeft(int days) {
    return 'ট্রায়ালের আর $days দিন বাকি';
  }

  @override
  String get profitPercentLabel => 'লাভ %';

  @override
  String get saleAboveMrp => 'ছাপা MRP-এর চেয়ে বেশি।';

  @override
  String get wholesaleBlankHelp => 'খালি = বিক্রয়মূল্য';

  @override
  String get markupLabel => 'মার্কআপ';

  @override
  String get stopSelling => 'বিক্রি বন্ধ করুন';

  @override
  String get resumeSelling => 'আবার বিক্রি করুন';

  @override
  String get stoppedSellingNote => 'ক্যাশে দেখানো হবে না। স্টক ও ইতিহাস থাকবে।';

  @override
  String get productStopped => 'ক্যাশে আর বিক্রি হবে না।';

  @override
  String get productResumed => 'আবার বিক্রিতে।';

  @override
  String get newProduct => 'নতুন পণ্য';

  @override
  String get lineBelowCost =>
      'একটি পণ্যের দাম ক্রয়মূল্যের নিচে, বিক্রি বাতিল হবে। দাম বা ছাড় বদলান।';

  @override
  String get lineBelowCostShort => 'ক্রয়মূল্যের নিচে — বিক্রি বাতিল হবে।';

  @override
  String get discountBelowCost =>
      'এই ছাড়ে বিলটি পণ্যের ক্রয়মূল্যের নিচে চলে যায়।';

  @override
  String get orderDiscountPercent => 'বিলে ছাড় (%)';

  @override
  String get previousDueLabel => 'আগের বাকি';

  @override
  String get collectPreviousDue => 'আগের বাকিও নিন';

  @override
  String get outstandingLabel => 'মোট বাকি';

  @override
  String get cashTaken => 'নগদ গ্রহণ';

  @override
  String get digitalTaken => 'ডিজিটাল পেমেন্ট';

  @override
  String get duesCollected => 'বাকি আদায়';

  @override
  String get dueGiven => 'বাকিতে দেওয়া';

  @override
  String shiftSpansDays(int count) {
    return 'এই ক্যাশ ড্রয়ার $count দিন ধরে খোলা।';
  }

  @override
  String get lineDiscounts => 'পণ্যে ছাড়';

  @override
  String get youSaved => 'আপনার সাশ্রয় (MRP থেকে)';

  @override
  String get openingBalance => 'প্রারম্ভিক বাকি';

  @override
  String get openingBalanceHelp => 'bizPOS ব্যবহারের আগে থেকে যা বাকি ছিল।';

  @override
  String get ledgerSale => 'বিক্রি';

  @override
  String get ledgerPayment => 'পরিশোধ';

  @override
  String get ledgerReturn => 'ফেরত';

  @override
  String get ledgerVoid => 'বাতিল';

  @override
  String get ledgerOpeningCorrection => 'প্রারম্ভিক বাকি সংশোধন';

  @override
  String get registerTitle => 'আপনার দোকান খুলুন';

  @override
  String get registerSubtitle =>
      'দোকান নিবন্ধন করুন আর এখনই বিক্রি শুরু করুন — ক্যাশ, ড্রয়ার আর সাধারণ গ্রাহক আগে থেকেই তৈরি থাকবে।';

  @override
  String registerTrialNote(int days) {
    return '$days দিন বিনামূল্যে। এরপর অ্যাডমিনকে মেয়াদ বাড়াতে হবে; কিছুই মুছে যাবে না।';
  }

  @override
  String openShopTrialNote(int days) {
    return 'নতুন দোকান যেকোনো নিবন্ধনের মতো $days দিন বিনামূল্যে চলবে।';
  }

  @override
  String get registerShopSection => 'দোকান';

  @override
  String get registerOwnerSection => 'মালিক';

  @override
  String get shopName => 'দোকানের নাম';

  @override
  String get storeTypeLabel => 'দোকানের ধরন';

  @override
  String get storeTypeHelp => 'কোন পণ্য তালিকা থেকে শুরু করবেন তা ঠিক করে।';

  @override
  String get shopAddressOptional => 'ঠিকানা (ঐচ্ছিক)';

  @override
  String get branchNameOptional => 'শাখার নাম (ঐচ্ছিক)';

  @override
  String get branchNameHint => 'প্রধান শাখা';

  @override
  String get ownerName => 'আপনার নাম';

  @override
  String get phone => 'ফোন';

  @override
  String get shopPhoneHelp =>
      'দোকান নিয়ে প্ল্যাটফর্ম আপনার সাথে এই নম্বরে যোগাযোগ করবে।';

  @override
  String get invalidPhone => 'এটা ফোন নম্বর মনে হচ্ছে না।';

  @override
  String get passwordRule => 'কমপক্ষে ৬ অক্ষর।';

  @override
  String get registerAction => 'দোকান খুলুন';

  @override
  String get registering => 'দোকান তৈরি হচ্ছে…';

  @override
  String get haveAccount => 'অ্যাকাউন্ট আছে? সাইন ইন করুন';

  @override
  String get signInInstead => 'সাইন ইন';

  @override
  String get registerCta => 'নতুন দোকান? অ্যাকাউন্ট খুলুন';

  @override
  String get signInThenAddShop =>
      'সাইন ইনের পর প্রোফাইল → আরেকটি দোকান খুলুন থেকে নতুন দোকান খুলুন।';

  @override
  String get openAnotherShop => 'আরেকটি দোকান খুলুন';

  @override
  String get openShopAction => 'দোকান খুলুন';

  @override
  String shopOpened(String name) {
    return '$name খোলা হয়েছে। এখন আপনি এই দোকানে আছেন।';
  }

  @override
  String shopLocked(String name) {
    return '$name প্ল্যাটফর্ম বন্ধ করে দিয়েছে।';
  }

  @override
  String get packagesTitle => 'প্যাকেজ';

  @override
  String get newPackage => 'নতুন প্যাকেজ';

  @override
  String get packagesSearchHint => 'প্যাকেজ খুঁজুন';

  @override
  String get packagesEmpty => 'এখনো কোনো প্যাকেজ নেই';

  @override
  String get packagesEmptyBody =>
      'একসাথে বিক্রি হয় এমন পণ্য এক দামে প্যাকেজ করুন।';

  @override
  String get deletePackage => 'প্যাকেজ মুছুন';

  @override
  String deletePackageBody(String name) {
    return '$name মুছবেন? আগের বিক্রিতে থাকবে; ক্যাশে আর দেখাবে না।';
  }

  @override
  String get delete => 'মুছুন';

  @override
  String get packageDeleted => 'প্যাকেজ মুছে ফেলা হয়েছে।';

  @override
  String get packageSaved => 'প্যাকেজ সংরক্ষিত।';

  @override
  String fromDate(String date) {
    return '$date থেকে';
  }

  @override
  String untilDate(String date) {
    return '$date পর্যন্ত';
  }

  @override
  String packageSaves(String amount) {
    return '$amount সাশ্রয়';
  }

  @override
  String packageBuildable(String count) {
    return '$countটি বানানো যাবে';
  }

  @override
  String get packageOnSale => 'বিক্রিতে আছে';

  @override
  String get availabilityLive => 'চালু';

  @override
  String get availabilityScheduled => 'নির্ধারিত';

  @override
  String get availabilityExpired => 'মেয়াদোত্তীর্ণ';

  @override
  String get availabilityInactive => 'বন্ধ';

  @override
  String get packageName => 'প্যাকেজের নাম';

  @override
  String get packagePrice => 'প্যাকেজের দাম';

  @override
  String get packageItems => 'ভেতরে যা আছে';

  @override
  String get packageNeedsItems => 'অন্তত একটি পণ্য যোগ করুন।';

  @override
  String get packageComponents => 'আলাদা দামে পণ্যগুলো';

  @override
  String get packageSaving => 'গ্রাহকের সাশ্রয়';

  @override
  String get packageAboveItems => 'আলাদা পণ্যের চেয়ে বেশি দাম';

  @override
  String get packageStartsAny => 'এখন থেকে';

  @override
  String get packageEndsNever => 'শেষ তারিখ নেই';

  @override
  String get packageClearDates => 'তারিখ মুছুন';

  @override
  String get packageWindowInvalid => 'শেষ তারিখ শুরুর পরে হতে হবে।';

  @override
  String get description => 'বিবরণ';

  @override
  String get addToPackage => 'প্যাকেজে যোগ করুন';

  @override
  String get catalogueTitle => 'পণ্য তালিকা';

  @override
  String get catalogueSearchHint => 'নাম, কোম্পানি বা জেনেরিক দিয়ে খুঁজুন';

  @override
  String get catalogueAll => 'সব';

  @override
  String catalogueMine(String count) {
    return 'আমার দোকানে ($count)';
  }

  @override
  String catalogueMissing(String count) {
    return 'আমার দোকানে নেই ($count)';
  }

  @override
  String get catalogueNoResults => 'এই নামে তালিকায় কিছু নেই';

  @override
  String get catalogueNoResultsBody =>
      'পণ্যটি থাকলে প্রস্তাব করুন, তাহলে বিক্রি শুরু করা যাবে।';

  @override
  String get catalogueNothingMissing => 'তালিকার সব পণ্যই আপনার দোকানে আছে';

  @override
  String get suggestProduct => 'পণ্য প্রস্তাব করুন';

  @override
  String get inMyStore => 'আমার দোকানে';

  @override
  String get pendingBadge => 'অপেক্ষমাণ';

  @override
  String get addToStore => 'দোকানে যোগ করুন';

  @override
  String adoptedProduct(String name) {
    return '$name আপনার দোকানে যোগ হয়েছে।';
  }

  @override
  String get alreadyInStoreNote => 'এই পণ্য আপনার দোকানে আগেই আছে।';

  @override
  String get mrpHelp => 'প্যাকেটে ছাপা দাম।';

  @override
  String get adoptOpeningHelp => 'এখন কয়টি আছে।';

  @override
  String get localNameLabel => 'দোকানে যে নামে';

  @override
  String get localNameHelp => 'ঐচ্ছিক';

  @override
  String get suggestNameHelp => 'লেখার সাথে সাথে তালিকা মিলিয়ে দেখা হয়।';

  @override
  String get suggestReason => 'কেন রাখবেন? (ঐচ্ছিক)';

  @override
  String get suggestReasonHelp => 'যিনি অনুমোদন দেবেন তার সুবিধা হয়।';

  @override
  String get sendSuggestion => 'প্রস্তাব পাঠান';

  @override
  String get suggestionEndorsed =>
      'এখন আপনার দোকানে বিক্রিতে। অন্য দোকানের জন্য প্ল্যাটফর্ম যাচাই করবে।';

  @override
  String get suggestionSent => 'অনুমোদনের জন্য পাঠানো হয়েছে।';

  @override
  String get alreadyInCatalogue => 'তালিকায় আগেই আছে';

  @override
  String alreadyInCatalogueBody(String name) {
    return 'তালিকায় $name আগেই আছে। তবুও পাঠাবেন?';
  }

  @override
  String get sendAnyway => 'তবুও পাঠান';

  @override
  String get verdictExists =>
      'এটি তালিকায় আগেই আছে — প্রস্তাব না করে যোগ করুন।';

  @override
  String get verdictVariant =>
      'অন্য মাত্রায় একই পণ্য আছে। আপনারটি আলাদা পণ্য।';

  @override
  String get verdictOtherBrand => 'অন্য কোম্পানির একই পণ্য আছে।';

  @override
  String get verdictSimilar => 'কাছাকাছি পণ্য আছে। আগে দেখে নিন।';

  @override
  String get verdictNew => 'তালিকায় এমন কিছু নেই — এটি নতুন।';

  @override
  String get adoptThisInstead => 'বরং এটি যোগ করুন';

  @override
  String get suggestionsTitle => 'প্রস্তাব';

  @override
  String suggestionsPending(int count) {
    return '$countটি আপনার অপেক্ষায়';
  }

  @override
  String get suggestionsEmpty => 'কোনো প্রস্তাব নেই';

  @override
  String get suggestionsEmptyBody =>
      'কর্মীদের প্রস্তাবিত পণ্য অনুমোদনের জন্য এখানে আসবে।';

  @override
  String get statusPending => 'অপেক্ষমাণ';

  @override
  String get statusEndorsed => 'এখানে বিক্রিতে';

  @override
  String get statusApproved => 'তালিকায়';

  @override
  String get statusRejected => 'বাতিল';

  @override
  String askedBy(String name) {
    return '$name চেয়েছেন';
  }

  @override
  String get reject => 'বাতিল';

  @override
  String get approveAndStock => 'অনুমোদন';

  @override
  String get reviewNoteOptional => 'নোট (ঐচ্ছিক)';

  @override
  String get rejectReason => 'কেন নয়?';

  @override
  String get suggestionApproved => 'অনুমোদিত — আপনার দোকানে বিক্রিতে।';

  @override
  String get suggestionRejected => 'বাতিল করা হয়েছে।';

  @override
  String get purchaseTitle => 'ক্রয়';

  @override
  String get suppliers => 'সরবরাহকারী';

  @override
  String get supplier => 'সরবরাহকারী';

  @override
  String get goodsIn => 'মাল গ্রহণ';

  @override
  String get purchaseSearchHint => 'বিল নং বা সরবরাহকারী দিয়ে খুঁজুন';

  @override
  String get purchasesEmpty => 'এখনো কোনো ক্রয় নেই';

  @override
  String get purchasesEmptyBody =>
      'মাল আসার সাথে সাথে লিখুন, স্টক নিজেই বাড়বে।';

  @override
  String billsCount(int count) {
    return '$countটি বিল';
  }

  @override
  String get owedToSuppliers => 'সরবরাহকারীদের পাওনা';

  @override
  String get owedToSupplier => 'সরবরাহকারীর পাওনা';

  @override
  String get noSupplier => 'সরবরাহকারী নেই';

  @override
  String photosUploaded(int count) {
    return '$countটি ছবি যোগ হয়েছে';
  }

  @override
  String get deletePhoto => 'ছবি সরান';

  @override
  String get deletePhotoBody => 'বিল থেকে এই ছবিটি সরাবেন? বিল নিজে বদলাবে না।';

  @override
  String billPhotos(int count, int max) {
    return 'বিলের ছবি ($count/$max)';
  }

  @override
  String get noBillPhotos => 'এই বিলের কোনো ছবি নেই।';

  @override
  String get billPhotosHelp =>
      'কাগজের বিলের ছবি দিন — বিল সংরক্ষণের পরে আপলোড হবে।';

  @override
  String get takePhoto => 'ছবি তুলুন';

  @override
  String get chooseFromGallery => 'গ্যালারি থেকে নিন';

  @override
  String get photoPickFailed => 'ক্যামেরা বা গ্যালারি খোলা যায়নি।';

  @override
  String photosTooBig(int count) {
    return '$countটি ছবি ৮ MB-এর বেশি, বাদ দেওয়া হয়েছে';
  }

  @override
  String get addSupplier => 'সরবরাহকারী যোগ করুন';

  @override
  String get suppliersEmpty => 'এখনো কোনো সরবরাহকারী নেই';

  @override
  String get supplierSaved => 'সরবরাহকারী সংরক্ষিত।';

  @override
  String get supplierName => 'নাম';

  @override
  String get supplierCompany => 'কোম্পানি (ঐচ্ছিক)';

  @override
  String get supplierSearch => 'কার কাছ থেকে?';

  @override
  String newSupplierNote(String name) {
    return '\"$name\" নতুন — এই বিলের সাথে সংরক্ষিত হবে।';
  }

  @override
  String get pickSupplierFromList => 'তালিকা থেকে সরবরাহকারী বেছে নিন।';

  @override
  String get itemsReceived => 'যা এসেছে';

  @override
  String get noItemsReceived => 'এই বিলের পণ্যগুলো যোগ করুন।';

  @override
  String batchShort(String batch) {
    return 'ব্যাচ $batch';
  }

  @override
  String expiresShort(String date) {
    return 'মেয়াদ $date';
  }

  @override
  String get billDiscountPercent => 'বিলে ছাড়';

  @override
  String get paidToSupplier => 'এখন পরিশোধ';

  @override
  String get paidFollowsTotal => 'কম না লিখলে পুরো বিল।';

  @override
  String get paidOverTotal => 'বিলের চেয়ে বেশি।';

  @override
  String get payInFull => 'পুরো পরিশোধ';

  @override
  String get payNothing => 'কিছুই না';

  @override
  String get paidFrom => 'যে হিসাব থেকে';

  @override
  String get purchaseNote => 'নোট (ঐচ্ছিক)';

  @override
  String get purchaseNoteHint => 'সরবরাহকারীর ইনভয়েস নং';

  @override
  String get saveBill => 'বিল সংরক্ষণ';

  @override
  String purchaseSaved(String refNo) {
    return 'বিল $refNo সংরক্ষিত। স্টক আপডেট হয়েছে।';
  }

  @override
  String get photoUploadFailed => 'ছবি আপলোড হয়নি';

  @override
  String photoUploadFailedBody(String reason) {
    return 'বিল সংরক্ষিত। ছবি আপলোড করা যায়নি: $reason';
  }

  @override
  String get skipPhotos => 'বাদ দিন';

  @override
  String get pickProduct => 'পণ্য বেছে নিন';

  @override
  String get purchaseAddFromCatalogue =>
      'দোকানে এখনো নেই? আগে তালিকা থেকে যোগ করুন।';

  @override
  String get tracksBatches => 'ব্যাচ ও মেয়াদ';

  @override
  String get quantityReceived => 'পরিমাণ';

  @override
  String get unitCost => 'প্রতিটির দাম';

  @override
  String get batchNo => 'ব্যাচ নং';

  @override
  String get expiryDate => 'মেয়াদ শেষ';

  @override
  String get notYours => 'আপনার অনুমতিতে নেই';

  @override
  String get sectionLocked => 'এই অংশ দেখার অনুমতি আপনার নেই।';

  @override
  String get scopeBranch => 'এই শাখা';

  @override
  String get scopeStore => 'পুরো দোকান';

  @override
  String get scopeMixed => 'শাখা ও দোকান';

  @override
  String get reportSales => 'বিক্রি';

  @override
  String get reportProfit => 'লাভ';

  @override
  String get reportStock => 'স্টক';

  @override
  String get reportDues => 'বাকি';

  @override
  String get reportWindow => 'সময়কাল';

  @override
  String lastDays(int days) {
    return 'গত $days দিন';
  }

  @override
  String lastMonths(int count) {
    return '$count মাস';
  }

  @override
  String get customRange => 'তারিখ বাছুন…';

  @override
  String rangeCapped(int days) {
    return 'শেষ $days দিনে ছোট করা হয়েছে — ড্যাশবোর্ড এর বেশি দেখায় না।';
  }

  @override
  String get revenue => 'বিক্রয়';

  @override
  String get averageSale => 'গড় বিক্রি';

  @override
  String get dailySales => 'দিনভিত্তিক বিক্রি';

  @override
  String get topProducts => 'সবচেয়ে বেশি বিক্রি';

  @override
  String get nothingSold => 'এই সময়ে কিছু বিক্রি হয়নি।';

  @override
  String qtySold(String qty) {
    return '$qtyটি বিক্রি';
  }

  @override
  String get profit => 'লাভ';

  @override
  String get byMethod => 'পেমেন্ট পদ্ধতি অনুযায়ী';

  @override
  String get byStaff => 'কর্মী অনুযায়ী';

  @override
  String get netProfit => 'নিট লাভ';

  @override
  String get grossProfit => 'মোট লাভ';

  @override
  String get howItAddsUp => 'হিসাব যেভাবে দাঁড়ায়';

  @override
  String get costOfGoods => 'পণ্যের ক্রয়মূল্য';

  @override
  String get returnsLabel => 'ফেরত';

  @override
  String get expensesLabel => 'খরচ';

  @override
  String get stockOnHand => 'স্টক';

  @override
  String get unitsOnHand => 'মজুদ একক';

  @override
  String get nothingLow => 'কোনো পণ্য কমে যায়নি।';

  @override
  String minimumIs(String qty) {
    return 'ন্যূনতম $qty';
  }

  @override
  String get expiringSoon => 'শীঘ্রই মেয়াদ শেষ';

  @override
  String get nothingExpiring => 'শীঘ্রই কোনো মেয়াদ শেষ হচ্ছে না।';

  @override
  String onHand(String qty) {
    return 'মজুদ $qty';
  }

  @override
  String get deadStock => '৯০ দিনে বিক্রি নেই';

  @override
  String get nothingDead => 'তাকের সব পণ্যই সম্প্রতি বিক্রি হয়েছে।';

  @override
  String get owedToShop => 'দোকানের পাওনা';

  @override
  String get whoOwes => 'কার কাছে পাওনা';

  @override
  String get nobodyOwes => 'কারো কাছে দোকানের পাওনা নেই।';

  @override
  String daysOld(int days) {
    return '$days দিন পুরনো';
  }

  @override
  String get overCreditLimit => 'বাকির সীমা পেরিয়েছে';

  @override
  String get headline => 'এক নজরে';

  @override
  String get discountGiven => 'দেওয়া ছাড়';

  @override
  String get dueRaised => 'বাকি রাখা';

  @override
  String get moneyIn => 'টাকা এসেছে';

  @override
  String get collectedTotal => 'মোট আদায়';

  @override
  String get onTodaysBills => 'এই সময়ের বিলে';

  @override
  String get onOldDues => 'পুরনো বাকিতে';

  @override
  String get onPreviousDue => 'বিলের সাথে পুরনো বাকি';

  @override
  String get billsSettledBy => 'বিল যেভাবে পরিশোধ হয়েছে';

  @override
  String get capital => 'টাকা এখন কোথায়';

  @override
  String get stockAtCost => 'ক্রয়মূল্যে স্টক';

  @override
  String get receivable => 'পাওনা';

  @override
  String get inAccounts => 'অ্যাকাউন্টে';

  @override
  String get payable => 'দেনা';

  @override
  String get invested => 'বিনিয়োগ';

  @override
  String get netWorth => 'নিট';

  @override
  String get dues => 'বাকি';

  @override
  String get total => 'মোট';

  @override
  String timesCount(int count) {
    return '$count বার';
  }

  @override
  String get cashDrawers => 'ক্যাশ ড্রয়ার';

  @override
  String get restockSoon => 'শীঘ্রই অর্ডার দিন';

  @override
  String get rising => 'বিক্রি বাড়ছে';

  @override
  String get falling => 'বিক্রি কমছে';

  @override
  String get moverNew => 'নতুন';

  @override
  String get moverStopped => 'বন্ধ';

  @override
  String perDay(String qty) {
    return 'দিনে $qty';
  }

  @override
  String daysCover(String days) {
    return '$days দিন চলবে';
  }

  @override
  String daysLeft(String days) {
    return '$days দিন বাকি';
  }

  @override
  String get overview => 'সারসংক্ষেপ';

  @override
  String get transactions => 'লেনদেন';

  @override
  String get transfer => 'স্থানান্তর';

  @override
  String get transferDone => 'টাকা স্থানান্তর হয়েছে।';

  @override
  String get fromAccount => 'থেকে';

  @override
  String get toAccount => 'তে';

  @override
  String get sameAccount => 'দুটি ভিন্ন অ্যাকাউন্ট বাছুন।';

  @override
  String get expenseTypes => 'খরচের ধরন';

  @override
  String get expenseType => 'খরচের ধরন';

  @override
  String get expenseTypeName => 'নাম';

  @override
  String get newExpenseType => 'নতুন ধরন…';

  @override
  String get editExpenseType => 'খরচের ধরন সম্পাদনা';

  @override
  String get newTypeHelp => 'এই খরচের সাথে নতুন ধরন হিসেবে সংরক্ষিত হবে।';

  @override
  String get noExpenseTypes => 'এখনো কোনো খরচের ধরন নেই।';

  @override
  String get expenseTypeSaved => 'খরচের ধরন সংরক্ষিত।';

  @override
  String get deleteExpenseType => 'ধরন মুছুন';

  @override
  String get deleteExpenseTypeBody =>
      'যে ধরনে খরচ আছে সেটি মুছে না গিয়ে অবসরে যাবে, যাতে পুরনো খরচের নাম থাকে।';

  @override
  String get expenseTypeDeleted => 'খরচের ধরন মোছা হয়েছে।';

  @override
  String expenseTypeRetired(int count) {
    return 'অবসরে গেছে — $countটি খরচে ব্যবহৃত।';
  }

  @override
  String get retired => 'অবসরপ্রাপ্ত';

  @override
  String get iconLabel => 'আইকন';

  @override
  String get defaultAmount => 'নির্ধারিত পরিমাণ';

  @override
  String get defaultAmountHelp => 'কুইক টাইল এক চাপে যা লিখবে।';

  @override
  String get quickTile => 'কুইক টাইল';

  @override
  String get quickTileHelp => 'অ্যাকাউন্ট পাতায় এক চাপের টাইল হিসেবে দেখাবে।';

  @override
  String get salaryType => 'বেতন';

  @override
  String get salaryTypeHelp => 'কর্মীর নাম ও কোন মাসের বেতন তা জিজ্ঞেস করবে।';

  @override
  String get inUse => 'ব্যবহৃত হচ্ছে';

  @override
  String get recordExpense => 'খরচ';

  @override
  String get expense => 'খরচ';

  @override
  String expenseRecorded(String name, String amount) {
    return '$name: $amount লেখা হয়েছে।';
  }

  @override
  String get undo => 'ফিরিয়ে নিন';

  @override
  String get amount => 'পরিমাণ';

  @override
  String get employeeName => 'কর্মী';

  @override
  String get employeeNameHelp => 'নাম লিখুন — লগইন লাগবে না।';

  @override
  String get salaryMonth => 'কোন মাসের বেতন';

  @override
  String get salaryMonthHelp => 'যে মাসের বেতন, যেদিন দেওয়া হলো সেদিন নয়।';

  @override
  String get dateLabel => 'তারিখ';

  @override
  String get backdatedHelp => 'আগের তারিখে লেখা হবে।';

  @override
  String get note => 'নোট';

  @override
  String get recordedBy => 'লিখেছেন';

  @override
  String forMonth(String month) {
    return '$month মাসের';
  }

  @override
  String get noExpenses => 'এখনো কোনো খরচ নেই।';

  @override
  String get noTransactions => 'এখনো কোনো লেনদেন নেই।';

  @override
  String get deleteExpense => 'খরচ মুছুন';

  @override
  String deleteExpenseBody(String amount, String account) {
    return '$amount আবার $account-এ ফিরে যাবে।';
  }

  @override
  String get expenseDeleted => 'খরচ মোছা হয়েছে। টাকা অ্যাকাউন্টে ফিরেছে।';

  @override
  String get spentToday => 'আজকের খরচ';

  @override
  String get spentThisMonth => 'এ মাসের খরচ';

  @override
  String get salaryThisMonth => 'এ মাসের বেতন';

  @override
  String get quickExpenses => 'দ্রুত খরচ';

  @override
  String get salaryAsks => 'নাম জিজ্ঞেস করবে';

  @override
  String get typeAmount => 'পরিমাণ লিখুন';

  @override
  String get addAccount => 'অ্যাকাউন্ট যোগ করুন';

  @override
  String get accountAdded => 'অ্যাকাউন্ট যোগ হয়েছে।';

  @override
  String get accountName => 'অ্যাকাউন্টের নাম';

  @override
  String get accountNameHint => 'যেমন সিটি ব্যাংক, বিকাশ মার্চেন্ট';

  @override
  String get accountCash => 'নগদ';

  @override
  String get accountBank => 'ব্যাংক';

  @override
  String get accountMfs => 'মোবাইল ব্যাংকিং';

  @override
  String get txnSale => 'বিক্রি';

  @override
  String get txnDuePayment => 'বাকি আদায়';

  @override
  String get txnRefund => 'ফেরত';

  @override
  String get qtyPickerTitle => 'পরিমাণ';

  @override
  String get qtyCustom => 'নিজে পরিমাণ লিখুন';

  @override
  String get teamMembers => 'সদস্য';

  @override
  String get branchesTab => 'শাখা';

  @override
  String get storeTab => 'দোকান';

  @override
  String get activityTab => 'কার্যকলাপ';

  @override
  String get addMember => 'সদস্য যোগ করুন';

  @override
  String get addBranch => 'শাখা যোগ করুন';

  @override
  String get editBranch => 'শাখা সম্পাদনা';

  @override
  String activeMembers(int count) {
    return 'সক্রিয় ($count)';
  }

  @override
  String suspendedMembers(int count) {
    return 'স্থগিত ($count)';
  }

  @override
  String get membersEmpty => 'দলে এখনো কেউ নেই';

  @override
  String get youBadge => 'আপনি';

  @override
  String get activeBadge => 'সক্রিয়';

  @override
  String get suspendedBadge => 'স্থগিত';

  @override
  String get lockedBadge => 'বন্ধ';

  @override
  String get neverSignedIn => 'কখনো সাইন ইন করেননি';

  @override
  String lastSignedIn(String when) {
    return 'শেষ সাইন ইন $when';
  }

  @override
  String get changeRole => 'ভূমিকা বদলান';

  @override
  String get chooseRole => 'ভূমিকা বেছে নিন';

  @override
  String whatRoleCanDo(String role) {
    return '$role কী কী করতে পারেন';
  }

  @override
  String get builtInRole => 'নির্ধারিত ভূমিকা। এর অনুমতি প্ল্যাটফর্ম ঠিক করে।';

  @override
  String roleChanged(String name, String role) {
    return '$name এখন $role';
  }

  @override
  String get suspendMember => 'স্থগিত করুন';

  @override
  String get reactivateMember => 'আবার চালু করুন';

  @override
  String suspendMemberTitle(String name) {
    return '$name-কে স্থগিত করবেন?';
  }

  @override
  String reactivateMemberTitle(String name) {
    return '$name-কে আবার চালু করবেন?';
  }

  @override
  String get suspendMemberBody =>
      'পরের পদক্ষেপেই তিনি এই দোকানে ঢুকতে পারবেন না। তাঁর কোনো কাজ মুছে যাবে না, যেকোনো সময় আবার চালু করা যাবে।';

  @override
  String get reactivateMemberBody =>
      'তিনি আগের ভূমিকা নিয়ে আবার এই দোকানে সাইন ইন করতে পারবেন।';

  @override
  String memberSuspended(String name) {
    return '$name স্থগিত হয়েছেন';
  }

  @override
  String memberReactivated(String name) {
    return '$name আবার সাইন ইন করতে পারবেন';
  }

  @override
  String get cannotChangeSelf =>
      'এটি আপনি। কেউ নিজের ভূমিকা বদলাতে বা নিজেকে স্থগিত করতে পারেন না — অন্য মালিককে বলুন।';

  @override
  String get readOnlyTeam => 'আপনি দলটি দেখতে পারেন, বদলাতে পারেন না।';

  @override
  String get fullName => 'পুরো নাম';

  @override
  String get memberFormNote =>
      'এই ইমেইলে আগে থেকেই bizPOS অ্যাকাউন্ট থাকলে তিনি নিজের পাসওয়ার্ডেই যোগ দেবেন, ওপরেরটি ব্যবহার হবে না।';

  @override
  String memberAdded(String name) {
    return '$name দলে যুক্ত হয়েছেন';
  }

  @override
  String memberReusedAccount(String name) {
    return '$name যুক্ত হয়েছেন — তাঁর আগেই অ্যাকাউন্ট ছিল, তাই নিজের পাসওয়ার্ডে সাইন ইন করবেন।';
  }

  @override
  String get branchName => 'শাখার নাম';

  @override
  String get branchCode => 'কোড';

  @override
  String get branchCodeHelp => 'ছোট ও আলাদা, যেমন MRP';

  @override
  String get branchSaved => 'শাখা সংরক্ষিত';

  @override
  String get branchesNote =>
      'স্টক, বিক্রি, ক্যাশ ড্রয়ার ও রিপোর্ট শাখা অনুযায়ী থাকে। প্রোফাইল থেকে শাখা বদলান।';

  @override
  String get youAreHere => 'আপনি এখানে';

  @override
  String get storeDetails => 'বিবরণ';

  @override
  String get edit => 'সম্পাদনা';

  @override
  String get editStore => 'দোকান সম্পাদনা';

  @override
  String get addressLabel => 'ঠিকানা';

  @override
  String get cityLabel => 'শহর';

  @override
  String get currencyLabel => 'মুদ্রা';

  @override
  String get atTheCounter => 'কাউন্টারে';

  @override
  String get vatInclusive => 'দামের মধ্যে ধরা';

  @override
  String get vatExclusive => 'দামের ওপর যোগ';

  @override
  String get receiptPaper => 'রসিদের কাগজ';

  @override
  String get invoicePrefix => 'ইনভয়েস প্রিফিক্স';

  @override
  String get invoicePrefixHelp => 'প্রতিটি ইনভয়েস নম্বরের আগে ছাপা হয়';

  @override
  String get allowCreditSale => 'বাকিতে বিক্রি';

  @override
  String get allowCreditSaleHelp =>
      'নাম দেওয়া ক্রেতা বিলের চেয়ে কম দিয়ে বাকিটা পরে দিতে পারবেন।';

  @override
  String get allowed => 'চালু';

  @override
  String get notAllowed => 'বন্ধ';

  @override
  String get storeSaved => 'সংরক্ষিত';

  @override
  String get loyaltyTitle => 'লয়্যালটি পয়েন্ট';

  @override
  String get loyaltyStatus => 'প্রোগ্রাম';

  @override
  String get loyaltyOn => 'চালু';

  @override
  String get loyaltyOff => 'বন্ধ';

  @override
  String get loyaltyEnabled => 'ক্রেতারা পয়েন্ট পাবেন';

  @override
  String get loyaltyEarning => 'পয়েন্ট পাওয়া';

  @override
  String loyaltyEarnRule(String points, String amount) {
    return 'প্রতি $amount কেনায় $points পয়েন্ট';
  }

  @override
  String get loyaltyEarnPoints => 'পয়েন্ট';

  @override
  String get loyaltyEarnPer => 'প্রতি';

  @override
  String get loyaltyWorth => 'এক পয়েন্টের মূল্য';

  @override
  String loyaltyPointValue(String amount) {
    return '১ পয়েন্ট = $amount';
  }

  @override
  String get loyaltyMinRedeem => 'খরচ করতে কমপক্ষে পয়েন্ট';

  @override
  String get loyaltyMaxRedeemPct => 'বিলের সর্বোচ্চ কত % পয়েন্টে';

  @override
  String get loyaltyRound => 'পাওয়া পয়েন্টের রাউন্ডিং';

  @override
  String get roundDown => 'নিচে';

  @override
  String get roundNearest => 'কাছের';

  @override
  String get roundUp => 'ওপরে';

  @override
  String get mustBePositive => '০-এর বেশি হতে হবে';

  @override
  String get percentRange => '১ থেকে ১০০-এর মধ্যে';

  @override
  String get activityLocked => 'কার্যকলাপের লগ আপনার জন্য খোলা নয়।';

  @override
  String get activitySearchHint => 'লগে খুঁজুন';

  @override
  String get activitySubject => 'কী বদলেছে';

  @override
  String get activityAllSubjects => 'সব';

  @override
  String get activityEmpty => 'এই সময়ে কিছু বদলায়নি';

  @override
  String get activityEmptyBody => 'আরও লম্বা সময় বা অন্য ফিল্টার দেখুন।';

  @override
  String get activitySystem => 'সিস্টেম';

  @override
  String get emptyValue => '(খালি)';

  @override
  String get platformStores => 'দোকান';

  @override
  String platformSuggestions(int count) {
    return 'প্রস্তাব ($count)';
  }

  @override
  String get platformCatalogue => 'ক্যাটালগ';

  @override
  String get newStore => 'নতুন দোকান';

  @override
  String get createStore => 'দোকান তৈরি করুন';

  @override
  String get storeSearchHint => 'নাম, ফোন, ইমেইল বা মালিক';

  @override
  String allStoresCount(int count) {
    return 'সব ($count)';
  }

  @override
  String trialEndingCount(int count) {
    return 'ট্রায়াল শেষের পথে ($count)';
  }

  @override
  String lockedCount(int count) {
    return 'বন্ধ ($count)';
  }

  @override
  String get noStoresMatch => 'কোনো দোকান মেলেনি';

  @override
  String get trialOver => 'ট্রায়াল শেষ';

  @override
  String get dbNotReady => 'ডাটাবেস প্রস্তুত নয়';

  @override
  String get dbNotMoved => 'এখনো নিজের ডাটাবেসে সরানো হয়নি';

  @override
  String get dbServing => 'নিজের ডাটাবেস থেকে চলছে';

  @override
  String get planLabel => 'প্ল্যান';

  @override
  String get noPlan => 'প্ল্যান নেই';

  @override
  String get trialLabel => 'ট্রায়াল';

  @override
  String get noTimeLimit => 'সময়সীমা নেই';

  @override
  String get ownerLabel => 'মালিক';

  @override
  String get createdLabel => 'তৈরি';

  @override
  String get databaseLabel => 'ডাটাবেস';

  @override
  String get timezoneLabel => 'টাইম জোন';

  @override
  String get enterStore => 'সাপোর্টের জন্য ঢুকুন';

  @override
  String enterStoreTitle(String name) {
    return '$name-এ ঢুকবেন?';
  }

  @override
  String get enterStoreBody =>
      'এই ডিভাইসটি প্ল্যাটফর্ম কর্মী হিসেবে ওই দোকানে যাবে। সেখানে আপনার সব কাজ লগ হবে, ওপরের ব্যানার থেকে ফিরে আসা যাবে।';

  @override
  String get youAreInThisStore => 'এই ডিভাইস এখন এই দোকানে';

  @override
  String get reactivateFirst => 'আগে দোকানটি চালু করুন';

  @override
  String get leaveSupport => 'বের হন';

  @override
  String get leaveSupportFailed =>
      'সাপোর্ট মোড থেকে বের হওয়া গেল না। প্রোফাইল থেকে দোকান বদলান।';

  @override
  String get editStoreDetails => 'বিবরণ সম্পাদনা';

  @override
  String get storeTypeChangeWarning =>
      'অন্য ধরনের দোকান অন্য শেয়ার্ড ক্যাটালগ দেখে। আগের পণ্য থাকবে, তবে ক্যাটালগে আর না-ও পাওয়া যেতে পারে।';

  @override
  String get storeTypeChangedNote =>
      'সংরক্ষিত। দোকানটি এখন অন্য ধরনের ক্যাটালগ দেখবে।';

  @override
  String get extendTrial => 'ট্রায়াল বাড়ান';

  @override
  String get extendUnlimited => 'সময়সীমা নেই';

  @override
  String get extendUnlimitedHelp => 'যে দোকান টাকা দেওয়া শুরু করেছে তার জন্য।';

  @override
  String get extendDays => 'কত দিন যোগ হবে';

  @override
  String get extendDaysRange => '১ থেকে ৩৬৫০ দিনের মধ্যে';

  @override
  String get extendActivate => 'দোকানটিও চালু করুন';

  @override
  String get extendFromEnd => 'বর্তমান শেষ তারিখের পর থেকে দিন যোগ হবে।';

  @override
  String get extendFromToday => 'ট্রায়াল শেষ, তাই আজ থেকে দিন গোনা হবে।';

  @override
  String trialCurrentlyEnds(String date) {
    return 'ট্রায়াল শেষ হবে $date';
  }

  @override
  String trialNowEnds(String name, String date) {
    return '$name: ট্রায়াল এখন শেষ হবে $date';
  }

  @override
  String trialNowUnlimited(String name) {
    return '$name-এর এখন কোনো সময়সীমা নেই';
  }

  @override
  String daysCount(int count) {
    return '$count দিন';
  }

  @override
  String get suspendStore => 'দোকান স্থগিত করুন';

  @override
  String get reactivateStore => 'দোকান আবার চালু করুন';

  @override
  String suspendStoreTitle(String name) {
    return '$name স্থগিত করবেন?';
  }

  @override
  String reactivateStoreTitle(String name) {
    return '$name আবার চালু করবেন?';
  }

  @override
  String get suspendStoreBody =>
      'স্থগিত থাকা অবস্থায় কেউ এই দোকানে সাইন ইন করতে পারবেন না। কিছুই মুছে যাবে না।';

  @override
  String get reactivateStoreBody => 'এর দল আবার সাইন ইন করতে পারবে।';

  @override
  String storeSuspended(String name) {
    return '$name স্থগিত';
  }

  @override
  String storeReactivated(String name) {
    return '$name আবার চালু';
  }

  @override
  String get optionalDetails => 'ঐচ্ছিক';

  @override
  String storeCreated(String name) {
    return '$name তৈরি হয়েছে';
  }

  @override
  String get ownerReusedAccount =>
      'মালিকের আগেই অ্যাকাউন্ট ছিল, সেটি দিয়েই সাইন ইন করবেন।';

  @override
  String get dbProblemTitle =>
      'দোকান তৈরি হয়েছে, কিন্তু ডাটাবেস সম্পূর্ণ হয়নি';

  @override
  String dbSteps(String created, String migrated) {
    return 'ডাটাবেস তৈরি: $created · টেবিল তৈরি: $migrated';
  }

  @override
  String get dbProblemNote =>
      'সার্ভারে এটি ঠিক না হওয়া পর্যন্ত মালিক এতে কাজ করতে পারবেন না (php artisan tenancy:status)।';

  @override
  String get no => 'না';

  @override
  String get approve => 'অনুমোদন';

  @override
  String suggestedFrom(String who) {
    return '$who থেকে';
  }

  @override
  String get platformSuggestionsEmpty => 'কোনো প্রস্তাব অপেক্ষায় নেই';

  @override
  String get platformSuggestionsEmptyBody =>
      'দোকানগুলো শেয়ার্ড ক্যাটালগের জন্য যে পণ্য প্রস্তাব করে, তা এখানে আসবে।';

  @override
  String get platformSuggestionAdded => 'শেয়ার্ড ক্যাটালগে যুক্ত হয়েছে';

  @override
  String get platformSuggestionMatched =>
      'অনুমোদিত — ক্যাটালগের একটি পুরোনো এন্ট্রির সাথে মিলেছে';

  @override
  String get platformSuggestionRejected => 'বাতিল';

  @override
  String get newCatalogEntry => 'নতুন এন্ট্রি';

  @override
  String get editCatalogEntry => 'এন্ট্রি সম্পাদনা';

  @override
  String get allTypes => 'সব ধরন';

  @override
  String get allStatuses => 'যেকোনো অবস্থা';

  @override
  String deletedCount(int count) {
    return 'মুছে ফেলা ($count)';
  }

  @override
  String inStoresCount(int count) {
    return '$countটি দোকানে';
  }

  @override
  String get catalogStatus => 'অবস্থা';

  @override
  String get catalogStatusApproved => 'অনুমোদিত';

  @override
  String get catalogStatusPending => 'অপেক্ষমাণ';

  @override
  String get catalogStatusDraft => 'খসড়া';

  @override
  String get catalogStatusRejected => 'বাতিল';

  @override
  String catalogEditNote(int count) {
    return '$countটি দোকান এটি বিক্রি করে। এখানে সম্পাদনায় তাদের নিজেদের নাম ও দাম বদলাবে না।';
  }

  @override
  String get catalogEntrySaved => 'সংরক্ষিত';

  @override
  String deleteCatalogEntryTitle(String name) {
    return '$name মুছবেন?';
  }

  @override
  String get deleteCatalogEntryBody =>
      'এটি সব ক্যাটালগ তালিকা ও ডুপ্লিকেট যাচাই থেকে সরে যাবে। যারা আগে থেকে বিক্রি করছে, তাদের পণ্য ও ইতিহাস থাকবে।';

  @override
  String catalogEntryDeleted(int count) {
    return 'মুছে ফেলা হয়েছে — $countটি দোকানে থেকে যাবে';
  }

  @override
  String get catalogEntryIsDeleted =>
      'এই এন্ট্রিটি মুছে ফেলা। ফিরিয়ে আনলে আবার সব ক্যাটালগ তালিকায় দেখা যাবে।';

  @override
  String get catalogRestore => 'ফিরিয়ে আনুন';

  @override
  String get catalogEntryRestored => 'ফিরিয়ে আনা হয়েছে';
}
