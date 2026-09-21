import 'package:flutter/material.dart';

import 'palette.dart';
import 'theme_variant.dart';
import 'tokens.dart';

/// Builds the one `ThemeData` the app uses.
///
/// Flat surfaces, hairlines instead of shadows, a single accent. Everything a
/// screen needs comes from here or from [AppPalette]; no widget invents a colour
/// or a radius of its own.
class AppTheme {
  const AppTheme._();

  static ThemeData of(ThemeVariant variant, {String locale = 'en'}) {
    final palette = variant.isDark ? AppPalette.dark : AppPalette.light;
    final scheme = _scheme(palette, variant.brightness);
    final text = _textTheme(palette, locale);

    return ThemeData(
      useMaterial3: true,
      brightness: variant.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.bg,
      canvasColor: palette.bg,
      extensions: [palette],
      textTheme: text,
      // Bengali is 20-40% wider than the same text in English, and a tight
      // density is what makes it overflow. One comfortable density for both.
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(
        color: palette.hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: BorderSide(color: palette.hairline)),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.row),
          side: BorderSide(color: palette.hairline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.muted,
        textColor: palette.text,
        minVerticalPadding: Insets.s12,
        contentPadding: const EdgeInsets.symmetric(horizontal: Insets.s16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.surfaceAlt,
          disabledForegroundColor: palette.muted,
          minimumSize: const Size.fromHeight(kMinTapTarget),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.row),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          side: BorderSide(color: palette.hairline),
          minimumSize: const Size.fromHeight(kMinTapTarget),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.row),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: text.bodyMedium?.copyWith(color: palette.muted),
        labelStyle: text.bodyMedium?.copyWith(color: palette.muted),
        floatingLabelStyle: text.bodySmall?.copyWith(color: palette.accent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.s16,
          vertical: Insets.s16,
        ),
        border: _border(palette.hairline),
        enabledBorder: _border(palette.hairline),
        focusedBorder: _border(palette.accent, width: 1.5),
        errorBorder: _border(palette.danger),
        focusedErrorBorder: _border(palette.danger, width: 1.5),
        errorStyle: text.bodySmall?.copyWith(color: palette.danger),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.accentSoft,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? palette.accent
                : palette.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? palette.accent
                : palette.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: palette.hairline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: palette.bg),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.row),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceAlt,
        selectedColor: palette.accentSoft,
        side: BorderSide(color: palette.hairline),
        labelStyle: text.labelMedium,
        shape: const StadiumBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: palette.surfaceAlt,
        circularTrackColor: palette.surfaceAlt,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.onAccent
              : palette.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : palette.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.all(palette.hairline),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.row),
        borderSide: BorderSide(color: color, width: width),
      );

  static ColorScheme _scheme(AppPalette palette, Brightness brightness) =>
      ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
      ).copyWith(
        primary: palette.accent,
        onPrimary: palette.onAccent,
        primaryContainer: palette.accentSoft,
        onPrimaryContainer: palette.accent,
        surface: palette.surface,
        onSurface: palette.text,
        surfaceContainerHighest: palette.surfaceAlt,
        onSurfaceVariant: palette.muted,
        outline: palette.hairline,
        outlineVariant: palette.hairline,
        error: palette.danger,
      );

  /// Three sizes carry the whole app, plus one tabular style for money.
  ///
  /// No custom font is bundled yet, so this relies on the platform's own family
  /// — which already covers Bengali on Android and iOS. Bundling Inter and Noto
  /// Sans Bengali is a later step; the only thing that changes then is the
  /// `fontFamily` below.
  static TextTheme _textTheme(AppPalette palette, String locale) {
    // Bengali glyphs need more room between lines than Latin does.
    final height = locale == 'bn' ? 1.45 : 1.25;

    TextStyle style(double size, FontWeight weight, {Color? color}) =>
        TextStyle(
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? palette.text,
        );

    return TextTheme(
      headlineSmall: style(24, FontWeight.w600),
      titleLarge: style(20, FontWeight.w600),
      titleMedium: style(16, FontWeight.w600),
      bodyLarge: style(16, FontWeight.w400),
      bodyMedium: style(15, FontWeight.w400),
      bodySmall: style(13, FontWeight.w400, color: palette.muted),
      labelLarge: style(15, FontWeight.w600),
      labelMedium: style(13, FontWeight.w500),
      labelSmall: style(12, FontWeight.w500),
    );
  }

  /// Money and quantities, so digits line up in a column.
  static TextStyle money(BuildContext context, {double? size, Color? color}) {
    final palette = context.palette;
    return TextStyle(
      fontSize: size ?? 15,
      fontWeight: FontWeight.w600,
      color: color ?? palette.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
