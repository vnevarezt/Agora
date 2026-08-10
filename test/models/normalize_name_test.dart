import 'package:agora/models/person.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('folds accents and ñ', () {
    expect(normalizeName('José'), 'jose');
    expect(normalizeName('ÑOÑO'), 'nono');
    expect(normalizeName('Ángel Núñez'), 'angel nunez');
    expect(normalizeName('ÀÈÌÒÙ àèìòù'), 'aeiou aeiou');
  });

  test('trims and collapses whitespace', () {
    expect(normalizeName('  José   Pérez  '), 'jose perez');
    expect(normalizeName('Jean\tPierre'), 'jean pierre');
    expect(normalizeName('linea\nsalto'), 'linea salto');
    expect(normalizeName(''), '');
    expect(normalizeName('   '), '');
  });

  test('lowercases characters the fold table does not cover', () {
    expect(normalizeName('Gonçalves'), 'gonçalves');
    expect(normalizeName('FRANÇA'), 'frança');
    expect(normalizeName('ÅSA'), 'åsa');
    expect(normalizeName('ΣΟΦΙΑ'), 'σοφια');
    expect(normalizeName('İ'), 'İ'.toLowerCase());
  });

  // trim and `\s` disagree on these two, in opposite directions.
  test('whitespace boundary matches trim/RegExp exactly', () {
    expect(normalizeName('x\u0085y'), 'x\u0085y'); // `\s` misses U+0085
    expect(normalizeName('\u0085\u0085x\u0085'), 'x'); // trim catches it
    expect(normalizeName('a\u00a0b'), 'a b'); // `\s` catches U+00A0
  });

  test('is idempotent', () {
    for (final s in ['  José   Pérez ', 'ÑOÑO Ábc', 'Gonçalves', 'a\u00a0b']) {
      expect(normalizeName(normalizeName(s)), normalizeName(s), reason: s);
    }
  });
}
