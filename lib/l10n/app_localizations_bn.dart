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
}
