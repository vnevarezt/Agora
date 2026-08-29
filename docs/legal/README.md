# Legal documents

Drafts of the two user-facing legal texts. **Nothing here is published yet.**

| File | What it is |
|---|---|
| [privacy.es.md](privacy.es.md) | Aviso de Privacidad — governing text (LFPDPPP 2025, Mexico) |
| [privacy.en.md](privacy.en.md) | English translation, for the App Store and non-Spanish users |
| [terms.es.md](terms.es.md) | Términos y Condiciones — governing text |
| [terms.en.md](terms.en.md) | English translation |

The Spanish versions govern; the English ones are convenience translations. Any
edit to a Spanish file must be mirrored in its English pair, or the two start
lying about each other.

## Placeholders to fill before publishing

Grep for backtick-wrapped `[BRACKETS]` across all four files.

- `[DOMICILIO]` / `[ADDRESS]` — the address published as the controller's. A
  private home address becomes public the moment this ships; a fiscal or
  virtual-office address is the usual answer.
- `[CIUDAD, ESTADO]` / `[CITY, STATE]` — venue for disputes.
- `[FECHA DE PUBLICACIÓN]`, `[FECHA]` — effective and last-updated dates.
- `[REGIÓN]` / `[REGION]` — Firestore and Authentication locations. Confirm in
  the Firebase console; do not guess.
- `[PROVEEDOR SMTP]` / `[SMTP PROVIDER]` — currently Spacemail, per the default
  in `functions/src/index.ts`.
- `[PROCESADOR DE PAGOS]` / `[PAYMENT PROCESSOR]` — only if donations ship.
- Mail addresses `privacidad@agora.mobi` and `soporte@agora.mobi` must exist and
  be monitored. ARCO requests carry a 20-business-day deadline.

## Blockers: the documents describe behaviour the code does not have yet

Both of these are marked inline as "draft status notes". Publishing before
fixing them turns an honest document into a false statement.

1. **Consent-first telemetry.** `lib/state/cloud_auth.dart` enables Crashlytics
   and Analytics in every release build, and `lib/ui/auth/auth_gate.dart`
   initialises Firebase at startup — so local-mode users are covered too. The
   notice promises both stay off until accepted, with a toggle in Settings.
2. **Web account-deletion page.** `agora.mobi/cuenta/eliminar` does not exist.
   Google Play requires a web-accessible deletion path for any app offering
   account creation, reachable without reinstalling the app.

## Turning these into site pages

The landing already links a "Tus datos" section. Full pages would go through
`tool/build_site.py`: add entries to `PAGES` (template + subdirectory) and the
copy to `site/copy/{es,en}.json`, following how `auth/action` is laid out. Note
that the locale prefix convention is default locale at `/`, others under
`/<code>/`, and that `functions/src/index.ts` hard-codes that convention for the
auth action links.

The App Store and Play both need a **publicly reachable URL** for the privacy
notice before the first submission, so these pages ship before the app does.
