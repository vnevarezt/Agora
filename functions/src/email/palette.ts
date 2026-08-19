/**
 * The light half of the `pizarra` palette, copied out of lib/ui/theme/tokens.dart.
 *
 * Hardcoded rather than read from site/tokens.css because mail clients do not
 * resolve CSS custom properties: Gmail strips `:root` outright, so every colour
 * has to arrive already inlined on the element that uses it. Dark values are
 * kept alongside for the `prefers-color-scheme` block, which Apple Mail honours
 * and Gmail ignores — the light set therefore has to stand on its own.
 */
export const light = {
  bg: '#f8fafd',
  surface: '#ffffff',
  surface2: '#f4f7fb',
  border: '#dee2e7',
  border2: '#eceff2',
  text: '#1f242d',
  textDim: '#5d646f',
  textMute: '#6b7079',
  accent: '#41629f',
  accentStrong: '#2e5091',
  accentInk: '#f8fcff',
  accentSoft: '#e7f1ff',
  warning: '#7a6512',
  warningSoft: '#f3ecd2',
} as const;

export const dark = {
  bg: '#0b0f14',
  surface: '#13181e',
  surface2: '#191f26',
  border: '#282e36',
  border2: '#21262c',
  text: '#eceff2',
  textDim: '#a6abb2',
  textMute: '#868b92',
  accent: '#6f97e2',
  accentStrong: '#5a84d4',
  accentInk: '#060d1a',
  accentSoft: '#21344c',
  warning: '#d9c27a',
  warningSoft: '#3a3115',
} as const;

/**
 * Manrope is bundled by the site but cannot be webfont-loaded in mail, so the
 * stack falls straight through to the host UI face — the same fallback chain
 * site/landing.css declares, minus Manrope itself.
 */
export const FONT_STACK =
  "system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif";
