# Agora

Flutter app for planning meeting programs and scheduling participants. **Local-first**: every
feature works offline against a local drift/SQLite database. Firebase cloud sync is opt-in,
end-to-end encrypted, and must never become a hard dependency of a code path.

`.fvmrc` pins Flutter to **3.47.0** and **everything goes through fvm** — `fvm flutter test`, not
`flutter test`. Nothing else enforces the pin, and the toolchain is not cosmetic: the formatter's
output and the golden images both move between SDK releases.
State is Riverpod, persistence is drift, translations are slang, print output is the `pdf` package.

## First run

```sh
dart pub global activate fvm
export PATH="$PATH:$HOME/.pub-cache/bin"   # put this in ~/.zshrc; pub's bin is not on it by default
fvm install            # reads .fvmrc, installs Flutter 3.47.0
sh tool/bootstrap.sh   # copies every committed .example config to its gitignored real path
fvm flutter pub get
```

Without `bootstrap.sh` the build fails on missing `firebase_options.dart` / `cloud_secrets.dart`.
Every script under `tool/` sources `tool/sdk.sh`, which finds fvm on PATH or in `~/.pub-cache/bin`
and refuses outright if the toolchain is neither fvm nor the pinned version.

## Commands

```sh
fvm flutter analyze              # must be clean before committing
fvm flutter test                 # must be green before committing
fvm dart run slang               # after editing lib/i18n/*.i18n.json
fvm dart run build_runner build --delete-conflicting-outputs   # after changing drift tables
sh tool/build_web_assets.sh      # after bumping drift or sqlite3 in pubspec.yaml
sh tool/format.sh                # the only sanctioned way to run dart format
fvm flutter test --update-goldens test/ui/golden   # after an intended visual change
```

The component catalogue is a screen: run a debug build and open `/gallery`. It and the golden
images are composed from the same file (`lib/ui/dev/gallery.dart`), so adding a widget to one adds
it to the other. `kDebugMode` keeps the whole thing out of release builds.

Goldens are rendered by the engine, so they are pinned twice over: regenerate them under **fvm**
(a different SDK redraws every one of them) on **macOS**, and **look at the diff before accepting
it** — an updated golden is a claim that the new appearance is the intended one.

There is no CI. `flutter analyze` and `flutter test` are the only gate, so run both yourself.

**Never run `dart format` directly.** dart_style's output moves between SDK releases, and 207 of
295 sources disagree between Flutter 3.44 and the pinned 3.47 — formatting off-pin rewrites most
of the repo and buries the change it came with. `tool/format.sh` uses fvm when it is there and
refuses outright when the running Flutter is not the pinned one.

## Rules

### Secrets never enter a commit

`lib/firebase_options.dart`, `lib/firebase_options_dev.dart` and `lib/cloud_secrets.dart` are
gitignored and each has a committed `.example` twin. Edit the real file to configure, edit the
`.example` twin to change its *shape*. Keys have leaked from this repo before — when adding any
credential, check `git status` before staging and prefer a restricted key scoped to one purpose.

### In widgets use `context.t`, never the global `t`

slang exposes both. Only `context.t` subscribes the widget to `InheritedLocaleData`. The tree is
insulated by `const` barriers (`const ProviderScope` in `main.dart`, `const AuthGate` in
`app.dart`), so a widget reading the global `t` keeps rendering the previous language after a
locale switch — that was issue #10. Outside the widget layer (providers, models, pure helpers)
the global `t` is correct; those helpers take a `Translations` parameter so the caller keeps the
subscription. `test/i18n_guard_test.dart` enforces this.

### Never hand-edit generated files

`*.g.dart` (drift, slang, Firebase options) and `test/drift/generated/` are build output. Change
the source and regenerate. `lib/i18n/*.i18n.json` is the translation source; `es` is the base
locale and other locales fall back to it, so a missing key is a silent Spanish string, not a crash.

### A drift schema change is a three-step change

Bump `schemaVersion`, write the migration, then regenerate the fixtures:

```sh
dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
flutter test test/drift/migration_test.dart
```

`drift_schemas/drift_schema_vN.json` is the committed record of every shipped schema. Dates are
stored as ISO-8601 text (`build.yaml`), not integers.

### Web builds carry version-coupled binaries

`web/drift_worker.js` and `sqlite3.wasm` speak a wire protocol to the drift version compiled into
the app. Bumping `drift` or `sqlite3` without running `sh tool/build_web_assets.sh` produces a
protocol mismatch that only appears in the browser, never in native builds.

## Conventions

- **The repo is English-only** — code, comments, commit messages, docs. The product UI is
  translated; the source is not. Conversation with the maintainer happens in Spanish.
- **Comment only what the code cannot say.** No narration of obvious statements. Reserve comments
  for rationale, coupling, and traps — the existing comments in `tool/` and `test/` are the model.
- **UI color always comes from `context.tokens.<role>`** — `AppTokens` is a `ThemeExtension` in
  `lib/ui/theme/tokens.dart`. A literal `Color(0x…)` in `lib/ui/` outside `tokens.dart` and
  `dimens.dart` is drift; the few legitimate exceptions are enumerated in `docs/DESIGN_SYSTEM.md`
  §2. Only the `pizarra` palette ships.

## Git

The repo already follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
Match what is there rather than inventing a variant.

```
type(scope): imperative summary
```

- **Types in use**, by frequency: `feat` `fix` `refactor` `docs` `perf` `chore` `test` `build`
  `style`. A breaking change is `type(scope)!:` with a `BREAKING CHANGE:` footer.
- **Scopes in use**: `ui` `sync` `auth` `web` `pdf` `mwb` `cloud` `dashboard` `site` `deps`
  `editor` `naming`. Reuse one; add a new scope only for a genuinely new area.
- **Subject: aim for 50 characters, never exceed 72** (the git 50/72 rule — `git log` pads by 4
  and terminals wrap at 80). Imperative mood, lowercase after the colon, no trailing period.
- **A body is the exception, not the rule** — roughly one commit in ten here has one, and that is
  correct. Add one only when the *why* is not evident from the diff: a constraint you worked
  around, a rejected alternative, a bug the change prevents. Blank line after the subject, wrap
  at 72. Never restate what the diff already shows.
- **Never add AI attribution.** No `Co-Authored-By: Claude`, no "Generated with Claude Code", in
  commits, PR descriptions or issues.

### Branches, PRs and issues

- Branch: `type/kebab-summary` using the same type vocabulary — `feat/printed-sheet-layout`,
  `fix/cloud-restore`. Branch off `main`; `main` is never committed to directly.
- PRs merge into `main` as merge commits. The PR title follows the commit convention.
- **Issue titles state the observable symptom as a sentence**, not a conventional-commit line:
  "A dashboard with no congregation shows a skeleton and never says why". Describe what the user
  sees, not the suspected cause.
- **Labels mirror the commit types**, so a PR is labelled with the type it carries: `bug` (fix),
  `enhancement` (feat), `documentation` (docs), `refactor`, `perf`, `test`, `chore`, `build`, plus
  `breaking-change` and `security`. Apply the one that matches; don't invent new labels.

### Releases

- `x.y.z` is [SemVer](https://semver.org/) and the commit log since the last tag decides the bump:
  a `!`/`BREAKING CHANGE` is MAJOR, any `feat` is MINOR, everything else is PATCH.
- `+build` in `pubspec.yaml` is a monotonic counter — increment on every store upload, never reset.
- Tags are annotated and `v`-prefixed: `v1.0.0`. The existing `backup/*` tags are not releases.
- `CHANGELOG.md` follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) — six
  headings only, written for a congregation using the app, not for a developer.
- Full procedure and the per-platform build steps: `docs/RELEASE.md`.

## Design work

When touching `lib/ui/`, the design skills are there to be used — reach for them instead of
improvising. `docs/DESIGN_SYSTEM.md` and the token contract always win over a skill's default
aesthetic; the skills are for judgment (hierarchy, motion, states, critique), not for overriding
the system. The per-skill routing is in `.claude/rules/ui.md`.

## Deeper references

Read these on demand rather than assuming their contents:

- `docs/DATA_ARCHITECTURE.md` — domain model, layering, LWW sync engine, E2E encryption model
- `docs/DESIGN_SYSTEM.md` — token contract, color roles, type scale, motion, print artifact
- `docs/UX_PATTERNS.md` — navigation, the loading/empty/error state matrix, flows, voice
- `docs/COMPONENTS.md` — per-widget variants, states, a11y contract and what each is not for
- `docs/ACCESSIBILITY.md` — the adopted standard (WCAG 2.2 AA), the criterion matrix, open failures
- `docs/A11Y_MANUAL_PASS.md` — the screen-reader walk nobody has run yet, and the form it fills in
- `docs/FIREBASE_SETUP.md` — enabling the optional cloud
- `docs/RELEASE.md` — release process

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
