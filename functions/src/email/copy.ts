export type Locale = 'es' | 'en';
export type Kind = 'reset' | 'verify';

export const LOCALES: readonly Locale[] = ['es', 'en'];

export function asLocale(value: unknown): Locale {
  return LOCALES.includes(value as Locale) ? (value as Locale) : 'es';
}

interface Strings {
  subject: string;
  preheader: string;
  title: string;
  body: string;
  cta: string;
  fallback: string;
  expiry: string;
  ignore: string;
  legal: string;
}

const COPY: Record<Locale, Record<Kind, Strings>> = {
  es: {
    reset: {
      subject: 'Restablece tu contraseña de Agora',
      preheader: 'El enlace caduca en una hora.',
      title: 'Restablece tu contraseña',
      body: 'Pediste una contraseña nueva para tu cuenta de Agora. Pulsa el botón y elige una.',
      cta: 'Elegir contraseña nueva',
      fallback: 'Si el botón no funciona, copia esta dirección en tu navegador:',
      expiry: 'El enlace caduca en una hora y solo sirve una vez.',
      ignore: 'Si no pediste esto, puedes ignorar el correo: tu contraseña no cambia hasta que abras el enlace.',
      legal: 'Agora — programas de la reunión de entresemana.',
    },
    verify: {
      subject: 'Confirma tu correo en Agora',
      preheader: 'Un paso y terminas.',
      title: 'Confirma tu correo',
      body: 'Confirma que esta dirección es tuya para que podamos avisarte de lo que pasa en tu congregación.',
      cta: 'Confirmar mi correo',
      fallback: 'Si el botón no funciona, copia esta dirección en tu navegador:',
      expiry: 'El enlace caduca en una hora y solo sirve una vez.',
      ignore: 'Si no creaste esta cuenta, ignora el correo y no se activará nada.',
      legal: 'Agora — programas de la reunión de entresemana.',
    },
  },
  en: {
    reset: {
      subject: 'Reset your Agora password',
      preheader: 'The link expires in one hour.',
      title: 'Reset your password',
      body: 'You asked for a new password for your Agora account. Press the button and pick one.',
      cta: 'Choose a new password',
      fallback: 'If the button does not work, copy this address into your browser:',
      expiry: 'The link expires in one hour and works only once.',
      ignore: 'If you did not ask for this, ignore this email: your password does not change until you open the link.',
      legal: 'Agora — midweek meeting programs.',
    },
    verify: {
      subject: 'Confirm your email on Agora',
      preheader: 'One step and you are done.',
      title: 'Confirm your email',
      body: 'Confirm this address is yours so we can tell you what happens in your congregation.',
      cta: 'Confirm my email',
      fallback: 'If the button does not work, copy this address into your browser:',
      expiry: 'The link expires in one hour and works only once.',
      ignore: 'If you did not create this account, ignore this email and nothing will be activated.',
      legal: 'Agora — midweek meeting programs.',
    },
  },
};

export function strings(locale: Locale, kind: Kind): Strings {
  return COPY[locale][kind];
}
