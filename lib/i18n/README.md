# Internationalization (i18n)

The app uses [**slang**](https://pub.dev/packages/slang) for translations. UI text
is type-safe and accessed without `BuildContext` where needed.

## Files

- `es.i18n.json` — **base locale** (Spanish). Source of truth for the key tree.
- `en.i18n.json` — English (complete).
- `pt.i18n.json` — Portuguese **template** (13 of 465 keys; missing keys fall
  back to Spanish via `fallback_strategy: base_locale` in `slang.yaml`).
  **Not offered to users** — see `shippedLocales` below.
- `strings.g.dart` (+ `strings_*.g.dart`) — **generated**. Do not edit by hand.

## Using translations in code

```dart
import '../i18n/strings.g.dart';

// In a widget — ALWAYS `context.t`:
final tr = context.t;
Text(tr.dashboard.subtitle);

// With parameters / plurals:
tr.projectModal.deleteConfirm(name: project.name);
tr.projectBar.weeks(n: weekCount);
```

### Why widgets must use `context.t`

The two accessors are **not** interchangeable:

| | subscribes the widget? |
|---|---|
| `context.t` | yes — reads the `InheritedLocaleData` |
| global `t` | no — a plain getter over the current translations |

The global `t` returns the correct strings, but registers no dependency. The
widget tree is insulated by `const` barriers (`main.dart` passes a
`const ProviderScope`, `app.dart` a `const AuthGate`), so on a locale change
`Element.updateChild` short-circuits on those identical widgets and never walks
the subtree — only registered dependents get rebuilt. A widget reading the
global `t` therefore keeps showing the previous language until something
unrelated happens to dirty it. That was issue #10.

`test/i18n_guard_test.dart` fails the build if the global `t` reappears under
`lib/ui/`.

### Outside the widget layer

Providers, models and pure helpers have no `BuildContext`. Rather than reading
the global `t` there, **take a `Translations` parameter** so the caller — a
widget holding a `context.t` — stays the one subscribed:

```dart
// models/person.dart
String label(Translations tr) => switch (this) { ... };

// call site, in a build method:
Text(role.label(context.t));
```

Reading the global `t` directly is reserved for places with genuinely no
context and no caller to thread it through (e.g. `ModalRoute.barrierLabel`);
those are listed in the guard's allowlist.

## Adding a new language

1. Copy `en.i18n.json` to `<locale>.i18n.json` (e.g. `fr.i18n.json` for French).
2. Translate the values (keep the keys unchanged). Keys you omit fall back to
   Spanish automatically.
3. Regenerate: `dart run slang`
4. Check for gaps: `dart run slang analyze`.
5. Once the catalog is **complete**, add the locale to `shippedLocales` in
   `lib/state/locale_boot.dart`. Until then it stays hidden.

`shippedLocales` — not `AppLocale.values` — drives the **Settings → App
language** selector, `MaterialApp.supportedLocales` and the first-run device
detection. This is deliberate: because `fallback_strategy: base_locale` renders
missing keys in Spanish with no warning, offering a half-translated language is
worse than not offering it at all (Portuguese sat at 13 of 465 keys).

To show the language's native name in the selector (instead of the uppercased
language code), add an entry to `_localeNames` in
`lib/ui/config/application_tab.dart`, e.g. `'fr': 'Français'`.

## Regenerating after editing any `*.i18n.json`

```bash
dart run slang            # generate once
dart run slang watch      # or watch + regenerate on save
dart run slang analyze     # report missing / unused keys per locale
```

## Notes

- Locale is detected from the device on first run and then persisted
  (`shared_preferences`); see `lib/state/locale_boot.dart`.
- Meeting **content** that comes from the downloaded workbook (part titles,
  times, etc.) stays in the meeting's own language and is intentionally not
  translated here.
