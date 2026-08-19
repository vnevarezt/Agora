import { createTransport, Transporter } from 'nodemailer';

import { Rendered } from './render.js';

export interface Smtp {
  host: string;
  port: number;
  user: string;
  pass: string;
}

let cached: Transporter | undefined;
let cachedFor = '';

/**
 * Spacemail rather than a transactional provider: the domain already carries a
 * mailbox, and at this volume — a handful of password resets a day — a second
 * service would buy nothing. The trade is real and worth remembering: Spacemail
 * caps outgoing mail per hour and reports no bounces, so anything that ever
 * mails the whole congregation at once needs a different transport, not a
 * bigger loop.
 *
 * Port 465 is implicit TLS. Google Cloud blocks outbound 25 but leaves 465 and
 * 587 open, which is the only reason SMTP works from a function at all.
 *
 * The transporter is cached across invocations on a warm instance: it pools the
 * connection, so a burst of resets does not re-handshake TLS every time.
 */
function transport(smtp: Smtp): Transporter {
  const key = `${smtp.host}:${smtp.port}:${smtp.user}`;
  if (!cached || cachedFor !== key) {
    cached = createTransport({
      host: smtp.host,
      port: smtp.port,
      secure: smtp.port === 465,
      auth: { user: smtp.user, pass: smtp.pass },
      pool: true,
      maxConnections: 1,
    });
    cachedFor = key;
  }
  return cached;
}

export async function send(
  smtp: Smtp,
  from: string,
  to: string,
  mail: Rendered,
): Promise<void> {
  // Spacemail refuses a From that is not the authenticated mailbox, so `from`
  // may only ever dress up the address in `smtp.user`, never replace it.
  await transport(smtp).sendMail({
    from,
    to,
    subject: mail.subject,
    html: mail.html,
    text: mail.text,
  });
}
