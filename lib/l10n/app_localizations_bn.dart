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
}
