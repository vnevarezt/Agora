# Changelog

All notable changes to Agora are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Entries are written for someone using the app to plan a meeting program, not for someone reading
the diff. Use only these headings: Added, Changed, Deprecated, Removed, Fixed, Security.

## [Unreleased]

Nothing has been released yet. The first tagged version will be `v1.0.0`; see `docs/RELEASE.md`
for the procedure.

### Added

- Agora now works with a screen reader. Navigation says which section you are in, headings can be
  jumped between, buttons that were only an icon now have a name, and the app tells you when
  something finished or failed instead of leaving you to find out.
- Week headings and part titles are announced in the language of the meeting, not the language you
  run the app in. A Spanish program read aloud on an English interface now sounds Spanish.

### Changed

- A message confirming something worked and a message reporting a failure no longer look the same:
  each carries its own mark and colour, so you can tell them apart without reading.

### Fixed

- Badges no longer overflow the participant card at the largest system text sizes.
