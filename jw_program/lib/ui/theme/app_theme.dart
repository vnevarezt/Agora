import 'package:flutter/material.dart';

import 'dimens.dart';
import 'tokens.dart';

/// Estilos de texto que no caben en el TextTheme de Material.
abstract final class AppText {
  static const String family = 'Manrope';
  static const String monoFamily = 'JetBrainsMono';

  /// JetBrains Mono para horas, códigos y porcentajes (cifras tabulares).
  static TextStyle mono({
    double size = 12,
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

  /// Etiquetas uppercase pequeñas (labels de campo, slot y grupo del picker).
  /// El texto debe pasarse ya en mayúsculas.
  static TextStyle label({double size = 10.5, Color? color}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.45,
      color: color,
    );
  }
}

/// Construye el [ThemeData] de la app a partir de los tokens de una paleta.
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
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
          color: t.text),
      bodyMedium: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: t.text),
      bodySmall: TextStyle(
          fontSize: 11.5, fontWeight: FontWeight.w600, color: t.textDim),
      titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: t.text),
      titleMedium: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.15,
          color: t.text),
      labelLarge: TextStyle(
          fontSize: 13.5, fontWeight: FontWeight.w700, color: t.text),
    ),
    iconTheme: IconThemeData(color: t.textDim, size: 19),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: t.surface2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      hintStyle: TextStyle(
          color: t.textMute, fontWeight: FontWeight.w600, fontSize: 13.5),
      border: border(t.border),
      enabledBorder: border(t.border),
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
          color: t.surface, fontSize: 12, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: t.text,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.text,
      contentTextStyle: TextStyle(
          color: t.surface, fontSize: 13.5, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.rControl)),
    ),
  );
}
