import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { defineSecret, defineString } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions';

import { asLocale, Kind } from './email/copy.js';
import { render } from './email/render.js';
import { send } from './email/send.js';
import { allow } from './throttle.js';

initializeApp();

// Only the password is a secret; the rest is configuration that belongs in
// version-visible params so a deploy shows what it is pointing at.
const SMTP_PASS = defineSecret('SMTP_PASS');
const SMTP_HOST = defineString('SMTP_HOST', { default: 'mail.spacemail.com' });
const SMTP_PORT = defineString('SMTP_PORT', { default: '465' });
const SMTP_USER = defineString('SMTP_USER', {
  default: 'noreply@agora.mobi',
});
// Must dress up SMTP_USER, not some other address: Spacemail authenticates the
// mailbox and rejects a From that does not match it.
const MAIL_FROM = defineString('MAIL_FROM', {
  default: 'Agora <noreply@agora.mobi>',
});
const SITE_ORIGIN = defineString('SITE_ORIGIN', {
  default: 'https://agora.mobi',
});

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Firebase hands back a link pointing at its own action handler. We keep only
 * the oobCode and rebuild the URL against our page, which is what makes the
 * whole flow ours without setting a custom action URL in the console: the code
 * is the credential, the host around it is presentation.
 */
function toSiteLink(generated: string, mode: string, lang: string): string {
  const code = new URL(generated).searchParams.get('oobCode');
  if (!code) throw new Error('generated link carried no oobCode');
  // Locale lives in the path, not a query param, matching how tool/build_site.py
  // lays the site out: the default locale at the root, the rest under /<code>/.
  const prefix = lang === 'es' ? '' : `/${lang}`;
  const params = new URLSearchParams({ mode, oobCode: code });
  return `${SITE_ORIGIN.value()}${prefix}/auth/action/?${params.toString()}`;
}

async function deliver(
  kind: Kind,
  mode: string,
  email: string,
  lang: string,
  generated: string,
): Promise<void> {
  const link = toSiteLink(generated, mode, lang);
  const mail = render(kind, asLocale(lang), link);
  await send(
    {
      host: SMTP_HOST.value(),
      port: Number(SMTP_PORT.value()),
      user: SMTP_USER.value(),
      pass: SMTP_PASS.value(),
    },
    MAIL_FROM.value(),
    email,
    mail,
  );
}

export const requestPasswordReset = onCall(
  { secrets: [SMTP_PASS], cors: true },
  async (req) => {
    const email = String(req.data?.email ?? '').trim().toLowerCase();
    const lang = asLocale(req.data?.lang);
    if (!EMAIL_RE.test(email)) {
      throw new HttpsError('invalid-argument', 'malformed email');
    }

    // Every branch below returns the same shape on purpose. Reporting "no such
    // account" here would turn this endpoint into a membership oracle for any
    // address someone cares to try.
    if (!(await allow('reset', email))) return { ok: true };

    // Existence is probed separately because generatePasswordResetLink does not
    // report a missing account cleanly: it throws auth/internal-error carrying
    // "INTERNAL ASSERT FAILED: Unable to create the email action link", which is
    // indistinguishable from a real fault. Swallowing that code wholesale would
    // silence genuine breakage; getUserByEmail answers with auth/user-not-found
    // and leaves every other failure loud.
    try {
      await getAuth().getUserByEmail(email);
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === 'auth/user-not-found' || code === 'auth/email-not-found') {
        return { ok: true };
      }
      logger.error('reset lookup failed', { code, err: String(err) });
      throw new HttpsError('internal', 'could not send');
    }

    try {
      const generated = await getAuth().generatePasswordResetLink(email, {
        url: `${SITE_ORIGIN.value()}/app/`,
      });
      await deliver('reset', 'resetPassword', email, lang, generated);
    } catch (err) {
      logger.error('password reset failed', { err: String(err) });
      throw new HttpsError('internal', 'could not send');
    }
    return { ok: true };
  },
);

export const requestEmailVerification = onCall(
  { secrets: [SMTP_PASS], cors: true },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'sign in first');

    const user = await getAuth().getUser(uid);
    if (!user.email) throw new HttpsError('failed-precondition', 'no email');
    if (user.emailVerified) return { ok: true, alreadyVerified: true };

    if (!(await allow('verify', uid))) return { ok: true, throttled: true };

    const lang = asLocale(req.data?.lang);
    try {
      const generated = await getAuth().generateEmailVerificationLink(user.email, {
        url: `${SITE_ORIGIN.value()}/app/`,
      });
      await deliver('verify', 'verifyEmail', user.email, lang, generated);
    } catch (err) {
      logger.error('verification send failed', { uid, err: String(err) });
      throw new HttpsError('internal', 'could not send');
    }
    return { ok: true };
  },
);
