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
}
