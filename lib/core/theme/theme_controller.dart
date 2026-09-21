import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../session/session_controller.dart';
import 'theme_variant.dart';

/// Supported languages. The API stores `bn` or `en` on the account.
const Locale localeEn = Locale('en');
const Locale localeBn = Locale('bn');
const List<Locale> supportedLocales = [localeEn, localeBn];

/// What the app looks like and which language it speaks.
@immutable
class AppPreferences {
  const AppPreferences({required this.variant, required this.locale});

  final ThemeVariant variant;
  final Locale locale;

  String get localeCode => locale.languageCode;

  AppPreferences copyWith({ThemeVariant? variant, Locale? locale}) =>
      AppPreferences(
        variant: variant ?? this.variant,
        locale: locale ?? this.locale,
      );
}

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesController, AppPreferences>(
  AppPreferencesController.new,
);

/// Theme and language.
///
/// Both live on the account so the phone and the web workspace agree, and both
/// are mirrored locally so the app can draw the right theme on its very first
/// frame — before `/me` has answered — and still work while signed out.
class AppPreferencesController extends AsyncNotifier<AppPreferences> {
  static const _themeKey = 'bizpos.pref.theme';
  static const _localeKey = 'bizpos.pref.locale';

  @override
  Future<AppPreferences> build() async {
    // Rebuilds when the session changes, which is how a fresh sign-in picks up
    // that account's saved theme and language.
    final me = ref.watch(meProvider);
    final stored = await _readStored();

    return AppPreferences(
      // A local choice wins: the person changed it on this phone most recently.
      variant: stored.$1 ?? ThemeVariant.fromApi(me?.user.theme),
      locale: stored.$2 ?? _localeFor(me?.user.locale),
    );
  }

  Future<void> setVariant(ThemeVariant variant) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(variant: variant));
    await _store(_themeKey, variant.apiValue);
    await ref
        .read(sessionControllerProvider.notifier)
        .savePreferences(theme: variant.apiValue);
  }

  Future<void> setLocale(Locale locale) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(locale: locale));
    await _store(_localeKey, locale.languageCode);
    await ref
        .read(sessionControllerProvider.notifier)
        .savePreferences(locale: locale.languageCode);
  }

  void toggleLocale() {
    final current = state.value;
    if (current == null) return;
    setLocale(current.locale == localeBn ? localeEn : localeBn);
  }

  static Locale _localeFor(String? code) =>
      code == 'bn' ? localeBn : localeEn;

  /// (theme, locale) as last chosen on this device, either possibly null.
  Future<(ThemeVariant?, Locale?)> _readStored() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString(_themeKey);
      final locale = prefs.getString(_localeKey);
      return (
        theme == null ? null : ThemeVariant.fromApi(theme),
        locale == null ? null : _localeFor(locale),
      );
    } catch (e) {
      developer.log('could not read preferences: $e', name: 'theme');
      return (null, null);
    }
  }

  Future<void> _store(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      developer.log('could not save the preference locally: $e', name: 'theme');
    }
  }
}
