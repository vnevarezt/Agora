// Maps a congregation's meeting language onto the two things it drives: which
// workbook to download, and which language the printed program is in.
//
// The app language (Settings -> App language) is a separate axis: you can run
// the UI in English while a congregation meets in Spanish. Only the PDF and the
// workbook follow THIS setting.

import '../i18n/strings.g.dart';
import '../models/congregation_settings.dart';

/// jw.org `langwritten` code of the workbook for [meetingLanguage]
/// (one of [congregationLanguageCodes]).
///
/// Sign languages fall back to Spanish deliberately: jw.org publishes the
/// workbook for them as JWPUB and MP4 only — `GETPUBMEDIALINKS` answers 404 for
/// `fileformat=EPUB` on LSE and 400 on ASE — so there is nothing for
/// `epub_parser` to read. A signed meeting still prints its S-140 in the local
/// written language, so the written workbook is the right source anyway.
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

/// Every workbook language a set of congregations needs, deduplicated. The
/// catalog sync fetches exactly these — one congregation in English and two in
/// Spanish costs two downloads, not three.
Set<String> workbookLangsFor(Iterable<String> meetingLanguages) =>
    {for (final m in meetingLanguages) workbookLangFor(m)};
