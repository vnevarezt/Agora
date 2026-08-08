import 'package:agora/domain/meeting_language.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/congregation_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every stored code maps to a workbook and a program locale', () {
    // Guards the enum drifting apart from the mapping: a new code added to
    // congregationLanguageCodes without a mapping would fall through silently.
    for (final code in congregationLanguageCodes) {
      expect(workbookLangFor(code), isNotEmpty, reason: code);
      expect(programLocaleFor(code), isNotNull, reason: code);
    }
  });

  test('spanish and english map to their own workbooks', () {
    expect(workbookLangFor('spanish'), 'S');
    expect(workbookLangFor('english'), 'E');
    expect(programLocaleFor('spanish'), AppLocale.es);
    expect(programLocaleFor('english'), AppLocale.en);
  });

  test('sign language falls back to Spanish', () {
    // jw.org publishes the workbook for sign languages as JWPUB/MP4 only —
    // there is no EPUB to parse — and a signed meeting still prints its S-140
    // in the local written language. See the note in meeting_language.dart.
    expect(workbookLangFor('sign'), 'S');
    expect(programLocaleFor('sign'), AppLocale.es);
  });

  test('an unrecognized code degrades to Spanish rather than throwing', () {
    expect(workbookLangFor('klingon'), 'S');
    expect(programLocaleFor('klingon'), AppLocale.es);
  });

  group('workbookLangsFor', () {
    test('deduplicates, so N Spanish congregations cost one download', () {
      expect(workbookLangsFor(['spanish', 'spanish', 'sign']), {'S'});
    });

    test('covers every language in use', () {
      expect(workbookLangsFor(['spanish', 'english']), {'S', 'E'});
    });

    test('no congregations means nothing to fetch', () {
      expect(workbookLangsFor(const []), isEmpty);
    });
  });
}
