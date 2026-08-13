import 'package:flutter/material.dart';

import 'dimens.dart';
import 'tokens.dart';

/// Text styles that do not fit in the Material TextTheme.
abstract final class AppText {
  static const String family = 'Manrope';
  static const String monoFamily = 'JetBrainsMono';

  // ---- type scale ---------------------------------------------------------
  // Every font size in the app comes from here; a bare number at a call site
  // is drift. Deliberately coarse at seven steps — the free-form scale this
  // replaces had grown to nineteen distinct values between 9.5 and 19 with no
  // rule for choosing among them, which is why equivalent elements on
  // different screens did not match.

  /// Uppercase labels and badges. The floor: nothing renders smaller.
  static const double micro = 10.5;

  /// Secondary and helper text.
  static const double caption = 11.5;

  /// Dense supporting text inside cards and rows.
  static const double small = 12.5;

  /// Default reading size.
  static const double body = 13.5;

  /// Emphasised body: primary names, list item titles.
  static const double bodyLarge = 15;

  /// Section and modal titles.
  static const double title = 16.5;

  /// Screen titles and large counts.
  static const double display = 19;

  /// JetBrains Mono for times, codes and percentages (tabular figures).
  static TextStyle mono({
    double size = small,
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Small uppercase labels (field, slot and picker-group labels).
  /// The text must be passed already uppercased.
  static TextStyle label({double size = micro, Color? color}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.45,
      color: color,
    );
  }
}

/// Builds the app [ThemeData] from a palette tokens.
ThemeData buildAppTheme(AppTokens t, Brightness brightness) {
  final esClaro = brightness == Brightness.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: t.accent,
    onPrimary: t.accentInk,
    secondary: t.accentSoft,
    onSecondary: t.accentStrong,
    error: esClaro ? const Color(0xFFB3261E) : const Color(0xFFF2B8B5),
    onError: esClaro ? Colors.white : const Color(0xFF601410),
    surface: t.surface,
    onSurface: t.text,
    surfaceContainerHighest: t.surface2,
    outline: t.border,
    outlineVariant: t.border2,
  );

  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimens.rControl),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.bg,
    fontFamily: AppText.family,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: t.border,
    extensions: [t],
    textTheme: TextTheme(
      bodyLarge: TextStyle(
          fontSize: AppText.bodyLarge,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
          color: t.text),
      bodyMedium: TextStyle(
          fontSize: AppText.body,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: t.text),
      bodySmall: TextStyle(
          fontSize: AppText.caption,
          fontWeight: FontWeight.w600,
          color: t.textDim),
      titleLarge: TextStyle(
          fontSize: AppText.title,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: t.text),
      titleMedium: TextStyle(
          fontSize: AppText.bodyLarge,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.15,
          color: t.text),
      labelLarge: TextStyle(
          fontSize: AppText.body, fontWeight: FontWeight.w700, color: t.text),
    ),
    iconTheme: IconThemeData(color: t.textDim, size: 19),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: t.surface2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      hintStyle: TextStyle(
          color: t.textMute,
          fontWeight: FontWeight.w600,
          fontSize: AppText.body),
      // borderControl, not border: the outline is what identifies the field.
      border: border(t.borderControl),
      enabledBorder: border(t.borderControl),
      focusedBorder: border(t.accent, 1.5),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.accent,
      selectionColor: t.accentSoft,
      selectionHandleColor: t.accent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.accent : t.border,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(99),
      thumbColor: WidgetStatePropertyAll(t.border),
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: TextStyle(
          color: t.surface, fontSize: AppText.small, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: t.text,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.text,
      contentTextStyle: TextStyle(
          color: t.surface, fontSize: AppText.body, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.rControl)),
    ),
  );
}
