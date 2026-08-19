import { dark, FONT_STACK, light as c } from './palette.js';
import { Kind, Locale, strings } from './copy.js';

export interface Rendered {
  subject: string;
  html: string;
  text: string;
}

function esc(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * The type steps are the app's own (lib/ui/theme/app_theme.dart) and the auth
 * anatomy is lib/ui/auth/auth_card_layout.dart read out in table form: a 30px
 * accent mark at radius 9, the wordmark at 15/800, the title at 22/800 with
 * -0.44 tracking, supporting copy at 13.5/600 on textMute.
 *
 * Tables and inline styles are not a stylistic choice. Outlook renders through
 * Word, which supports neither flexbox nor grid, and Gmail drops `:root`, so a
 * `<div>` layout with custom properties collapses into a left-aligned column of
 * unstyled text in exactly the clients most congregations read mail in.
 */
export function render(kind: Kind, locale: Locale, link: string): Rendered {
  const s = strings(locale, kind);
  const url = esc(link);

  const html = `<!DOCTYPE html>
<html lang="${locale}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<meta name="supported-color-schemes" content="light dark">
<title>${esc(s.subject)}</title>
<style>
  @media (prefers-color-scheme: dark) {
    .a-bg { background: ${dark.bg} !important; }
    .a-card { background: ${dark.surface} !important; border-color: ${dark.border} !important; }
    .a-text { color: ${dark.text} !important; }
    .a-mute { color: ${dark.textMute} !important; }
    .a-rule { border-color: ${dark.border2} !important; }
    .a-btn { background: ${dark.accent} !important; }
    .a-btn a { color: ${dark.accentInk} !important; }
    .a-link { color: ${dark.accentStrong} !important; }
  }
  @media (max-width: 520px) {
    .a-card { width: 100% !important; }
    .a-pad { padding: 24px 18px !important; }
    .a-title { font-size: 20px !important; }
  }
</style>
</head>
<body class="a-bg" style="margin:0;padding:0;background:${c.bg};">
<div style="display:none;font-size:1px;color:${c.bg};max-height:0;overflow:hidden;">${esc(s.preheader)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" class="a-bg" style="background:${c.bg};">
<tr><td align="center" style="padding:40px 12px;">

<table role="presentation" width="480" cellpadding="0" cellspacing="0" border="0" class="a-card" style="width:480px;max-width:480px;background:${c.surface};border:1px solid ${c.border};border-radius:14px;">
<tr><td class="a-pad" style="padding:32px;font-family:${FONT_STACK};">

  <table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
    <td style="width:30px;height:30px;background:${c.accent};border-radius:9px;text-align:center;vertical-align:middle;font-family:${FONT_STACK};font-size:13.5px;font-weight:800;color:${c.accentInk};line-height:30px;">A</td>
    <td style="padding-left:10px;font-family:${FONT_STACK};font-size:15px;font-weight:800;letter-spacing:-0.3px;color:${c.text};" class="a-text">Agora</td>
  </tr></table>

  <h1 class="a-text a-title" style="margin:24px 0 0;font-size:22px;font-weight:800;letter-spacing:-0.44px;line-height:1.25;color:${c.text};">${esc(s.title)}</h1>
  <p class="a-mute" style="margin:12px 0 0;font-size:13.5px;font-weight:600;line-height:1.5;color:${c.textMute};">${esc(s.body)}</p>

  <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:24px 0 0;"><tr>
    <td class="a-btn" style="background:${c.accent};border-radius:10px;">
      <a href="${url}" style="display:inline-block;padding:12px 20px;font-family:${FONT_STACK};font-size:13.5px;font-weight:700;color:${c.accentInk};text-decoration:none;">${esc(s.cta)}</a>
    </td>
  </tr></table>

  <p class="a-mute" style="margin:24px 0 0;font-size:11.5px;font-weight:600;line-height:1.5;color:${c.textMute};">${esc(s.fallback)}</p>
  <p style="margin:4px 0 0;font-size:11.5px;font-weight:600;line-height:1.5;word-break:break-all;"><a class="a-link" href="${url}" style="color:${c.accentStrong};">${url}</a></p>

  <div class="a-rule" style="margin:24px 0 0;border-top:1px solid ${c.border2};font-size:0;line-height:0;">&nbsp;</div>

  <p class="a-mute" style="margin:18px 0 0;font-size:11.5px;font-weight:600;line-height:1.5;color:${c.textMute};">${esc(s.expiry)}</p>
  <p class="a-mute" style="margin:8px 0 0;font-size:11.5px;font-weight:600;line-height:1.5;color:${c.textMute};">${esc(s.ignore)}</p>

</td></tr></table>

<p class="a-mute" style="margin:18px 0 0;font-family:${FONT_STACK};font-size:11.5px;font-weight:600;line-height:1.5;color:${c.textMute};">${esc(s.legal)}</p>

</td></tr>
</table>
</body>
</html>`;

  const text = [
    s.title,
    '',
    s.body,
    '',
    link,
    '',
    s.expiry,
    s.ignore,
    '',
    s.legal,
  ].join('\n');

  return { subject: s.subject, html, text };
}
