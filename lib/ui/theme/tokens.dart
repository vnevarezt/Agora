import 'package:flutter/material.dart';

/// Color tokens, converted from oklch to exact sRGB.
///
/// Each palette defines its light and dark version; add a new palette
/// (Granate, Salvia, Biblioteca) es declarar otra constante [AppPalette].
class AppTokens extends ThemeExtension<AppTokens> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color border2;
  final Color text;
  final Color textDim;
  final Color textMute;
  final Color accent;
  final Color accentStrong;
  final Color accentInk;
  final Color accentSoft;
  final Color accentTint;

  // Status roles. Each family is a soft tint used as a background plus the ink
  // that sits on it; `*Strong` is the solid version for marks that sit
  // directly on [bg]/[surface] (dots, standalone icons) with no tint behind.
  // Material's `colorScheme.error` stays separate: that is validation and
  // destructive actions, this is content status.
  final Color success;
  final Color successSoft;
  final Color successStrong;
  final Color warning;
  final Color warningSoft;
  final Color warningStrong;
  final Color alert;
  final Color alertSoft;

  const AppTokens({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.border2,
    required this.text,
    required this.textDim,
    required this.textMute,
    required this.accent,
    required this.accentStrong,
    required this.accentInk,
    required this.accentSoft,
    required this.accentTint,
    required this.success,
    required this.successSoft,
    required this.successStrong,
    required this.warning,
    required this.warningSoft,
    required this.warningStrong,
    required this.alert,
    required this.alertSoft,
  });

  @override
  AppTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? border2,
    Color? text,
    Color? textDim,
    Color? textMute,
    Color? accent,
    Color? accentStrong,
    Color? accentInk,
    Color? accentSoft,
    Color? accentTint,
    Color? success,
    Color? successSoft,
    Color? successStrong,
    Color? warning,
    Color? warningSoft,
    Color? warningStrong,
    Color? alert,
    Color? alertSoft,
  }) {
    return AppTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      border2: border2 ?? this.border2,
      text: text ?? this.text,
      textDim: textDim ?? this.textDim,
      textMute: textMute ?? this.textMute,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      accentTint: accentTint ?? this.accentTint,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      successStrong: successStrong ?? this.successStrong,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      warningStrong: warningStrong ?? this.warningStrong,
      alert: alert ?? this.alert,
      alertSoft: alertSoft ?? this.alertSoft,
    );
  }

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      text: Color.lerp(text, other.text, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      textMute: Color.lerp(textMute, other.textMute, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      successStrong: Color.lerp(successStrong, other.successStrong, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      warningStrong: Color.lerp(warningStrong, other.warningStrong, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
      alertSoft: Color.lerp(alertSoft, other.alertSoft, t)!,
    );
  }
}

/// A palette with its two modes. The app uses [pizarra]; the others are
/// added here when needed.
class AppPalette {
  final String id;
  final AppTokens light;
  final AppTokens dark;

  const AppPalette({required this.id, required this.light, required this.dark});
}

const pizarra = AppPalette(
  id: 'pizarra',
  light: AppTokens(
    bg: Color(0xFFF8FAFD),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF4F7FB),
    border: Color(0xFFDEE2E7),
    border2: Color(0xFFECEFF2),
    text: Color(0xFF1F242D),
    textDim: Color(0xFF5D646F),
    textMute: Color(0xFF878C96),
    accent: Color(0xFF41629F),
    accentStrong: Color(0xFF2E5091),
    accentInk: Color(0xFFF8FCFF),
    accentSoft: Color(0xFFE7F1FF),
    accentTint: Color(0xFFF2F7FF),
    success: Color(0xFF2E6A3E),
    successSoft: Color(0xFFDCF0E0),
    successStrong: Color(0xFF4FA06A),
    warning: Color(0xFF7A6512),
    warningSoft: Color(0xFFF3ECD2),
    warningStrong: Color(0xFFB9890F),
    alert: Color(0xFFB5562F),
    alertSoft: Color(0xFFFBE7DF),
  ),
  dark: AppTokens(
    bg: Color(0xFF0B0F14),
    surface: Color(0xFF13181E),
    surface2: Color(0xFF191F26),
    border: Color(0xFF282E36),
    border2: Color(0xFF21262C),
    text: Color(0xFFECEFF2),
    textDim: Color(0xFFA6ABB2),
    textMute: Color(0xFF767B81),
    accent: Color(0xFF6F97E2),
    accentStrong: Color(0xFF5A84D4),
    accentInk: Color(0xFF060D1A),
    accentSoft: Color(0xFF21344C),
    accentTint: Color(0xFF192431),
    success: Color(0xFFA9D8B8),
    successSoft: Color(0xFF1E3A2A),
    successStrong: Color(0xFF4FA06A),
    warning: Color(0xFFD9C27A),
    warningSoft: Color(0xFF3A3115),
    warningStrong: Color(0xFFB9890F),
    alert: Color(0xFFE8A38C),
    alertSoft: Color(0xFF40231C),
  ),
);

extension AppTokensX on BuildContext {
  /// Shortcut to the active theme tokens: `context.tokens.accent`.
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
