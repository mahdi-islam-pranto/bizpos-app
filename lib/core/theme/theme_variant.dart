import 'package:flutter/material.dart';

/// The five values `PATCH /me/preferences` accepts for `theme`.
///
/// The phone renders two of them today — `daylight` (light green on white) and
/// `midnight` (dark) — and the other three fall back to their nearest sibling.
/// The preference is still **stored and sent unchanged**, so a `paper` theme
/// chosen in the web workspace is never quietly rewritten by the app. When
/// `workspace` (denser) and `contrast` (high-contrast) get their own palettes,
/// only this file changes.
enum ThemeVariant {
  daylight('daylight', Brightness.light),
  midnight('midnight', Brightness.dark),
  workspace('workspace', Brightness.light),
  paper('paper', Brightness.light),
  contrast('contrast', Brightness.light);

  const ThemeVariant(this.apiValue, this.brightness);

  /// What the server calls it.
  final String apiValue;

  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  /// Parses the account preference. An unknown value falls back to the default
  /// rather than failing — a new theme added server-side must not break login.
  static ThemeVariant fromApi(String? value) => values.firstWhere(
        (v) => v.apiValue == value,
        orElse: () => ThemeVariant.daylight,
      );

  /// The two variants offered in the app's own picker.
  static const List<ThemeVariant> selectable = [daylight, midnight];
}
