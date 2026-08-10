// Maps a congregation's meeting language onto the workbook to download and the
// language the program prints in. The APP language is a separate axis — only
// these two follow this setting.

import '../i18n/strings.g.dart';
import '../models/congregation_settings.dart';

/// jw.org `langwritten` code of the workbook for [meetingLanguage], one of
/// [congregationLanguageCodes].
///
/// Sign languages fall back to Spanish deliberately: jw.org publishes their
/// workbook as JWPUB/MP4 only (GETPUBMEDIALINKS answers 404 for EPUB on LSE,
/// 400 on ASE), and a signed meeting still prints its S-140 in the local
/// written language.
String workbookLangFor(String meetingLanguage) => switch (meetingLanguage) {
      'english' => 'E',
      _ => 'S', // 'spanish', 'sign', and anything unrecognized
    };

/// Language the printed program (PDF) is rendered in for [meetingLanguage].
AppLocale programLocaleFor(String meetingLanguage) =>
    switch (meetingLanguage) {
      'english' => AppLocale.en,
      _ => AppLocale.es,
    };

/// Deduplicated workbook languages the sync must fetch.
Set<String> workbookLangsFor(Iterable<String> meetingLanguages) =>
    {for (final m in meetingLanguages) workbookLangFor(m)};
