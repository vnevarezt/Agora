import 'package:flutter/material.dart';

/// Tokens de color del rediseño — espejo de las variables CSS del mock
/// (`--bg`, `--surface`, `--accent`…), convertidas de oklch a sRGB exacto.
///
/// Cada paleta define su versión clara y oscura; add una paleta nueva
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
    );
  }
}

/// Paleta con sus dos modos. La app usa [pizarra]; las demás del mock se
/// agregan aquí cuando se necesiten.
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
  ),
);

extension AppTokensX on BuildContext {
  /// Acceso corto a los tokens del theme activo: `context.tokens.accent`.
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
