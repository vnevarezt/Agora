# Internationalization (i18n)

The app uses [**slang**](https://pub.dev/packages/slang) for translations. UI text
is type-safe and accessed without `BuildContext` where needed.

## Files

- `es.i18n.json` — **base locale** (Spanish). Source of truth for the key tree.
- `en.i18n.json` — English (complete).
- `pt.i18n.json` — Portuguese **template** (partial; missing keys fall back to
  Spanish via `fallback_strategy: base_locale` in `slang.yaml`).
- `strings.g.dart` (+ `strings_*.g.dart`) — **generated**. Do not edit by hand.

## Using translations in code

```dart
import '../i18n/strings.g.dart';

// In a widget (rebuilds automatically when the language changes):
final tr = context.t;
Text(tr.dashboard.subtitle);

// Outside a widget (providers, models, helpers) — global getter:
Text(t.status.draft);

// With parameters / plurals:
t.projectModal.deleteConfirm(name: project.name);
t.projectBar.weeks(n: weekCount);
```

## Adding a new language

No code changes are needed — just add a file:

1. Copy `en.i18n.json` to `<locale>.i18n.json` (e.g. `fr.i18n.json` for French).
2. Translate the values (keep the keys unchanged). Keys you omit fall back to
   Spanish automatically.
3. Regenerate: `dart run slang`
4. Done. The language now appears in `AppLocaleUtils.supportedLocales`, in the
   **Settings → App language** selector, and in `MaterialApp`.

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
