import 'package:flutter/material.dart';

/// The app's colours, as semantic slots rather than a swatch.
///
/// Screens say `palette.positive`, never `Colors.green` — so the light-green
/// identity can be retuned in one place, and so "paid" and "in stock" stay the
/// same green everywhere.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.hairline,
    required this.text,
    required this.muted,
    required this.positive,
    required this.warning,
    required this.danger,
  });

  /// The page behind everything: white with a green cast.
  final Color bg;

  /// Cards, sheets, list backgrounds.
  final Color surface;

  /// Grouped rows, chips, the selected state.
  final Color surfaceAlt;

  /// The one accent. Primary action and active navigation, nothing else.
  final Color accent;

  /// A wash of the accent, for a selected row or a quiet badge.
  final Color accentSoft;

  final Color onAccent;

  /// 1px borders. This design uses hairlines where others use shadows.
  final Color hairline;

  final Color text;
  final Color muted;

  /// Paid, in stock, money in.
  final Color positive;

  /// Partial payment, low stock, expiring.
  final Color warning;

  /// Unpaid, damage, void, destructive actions.
  final Color danger;

  /// Light green on white — the default, and what `daylight` means.
  static const light = AppPalette(
    bg: Color(0xFFF5FAF7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2F8F4),
    accent: Color(0xFF1E9D63),
    accentSoft: Color(0xFFE7F5ED),
    onAccent: Color(0xFFFFFFFF),
    hairline: Color(0xFFE3EEE7),
    text: Color(0xFF11201A),
    muted: Color(0xFF63756B),
    positive: Color(0xFF1E9D63),
    warning: Color(0xFFB4761A),
    danger: Color(0xFFC4443B),
  );

  /// `midnight`. The same greens, lifted so they hold contrast on near-black.
  static const dark = AppPalette(
    bg: Color(0xFF0E1512),
    surface: Color(0xFF161F1B),
    surfaceAlt: Color(0xFF1B2621),
    accent: Color(0xFF4FD198),
    accentSoft: Color(0xFF16301F),
    onAccent: Color(0xFF06120C),
    hairline: Color(0xFF23302A),
    text: Color(0xFFECF3EF),
    muted: Color(0xFF92A39A),
    positive: Color(0xFF4FD198),
    warning: Color(0xFFE0A542),
    danger: Color(0xFFF08079),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? hairline,
    Color? text,
    Color? muted,
    Color? positive,
    Color? warning,
    Color? danger,
  }) =>
      AppPalette(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        accent: accent ?? this.accent,
        accentSoft: accentSoft ?? this.accentSoft,
        onAccent: onAccent ?? this.onAccent,
        hairline: hairline ?? this.hairline,
        text: text ?? this.text,
        muted: muted ?? this.muted,
        positive: positive ?? this.positive,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// `context.palette` — shorter than the extension lookup, and used constantly.
extension PaletteAccess on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
