import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/crypto/passphrase_envelope.dart';
import 'package:jw_program/data/sync/sealed_box.dart';

void main() {
  test('seal → open roundtrips with the recipient seed', () async {
    final seed = PassphraseEnvelope.randomBytes(32);
    final pub = await SealedBox.publicKeyOf(seed);
    final secret = PassphraseEnvelope.randomBytes(32);

    final box = await SealedBox.seal(secret, pub);
    expect(await SealedBox.open(box, seed), secret);
    // The box carries no plaintext material.
    expect(box.keys, containsAll(['v', 'epk', 'nonce', 'ct', 'mac']));
  });

  test('a different recipient cannot open the box', () async {
    final seed = PassphraseEnvelope.randomBytes(32);
    final other = PassphraseEnvelope.randomBytes(32);
    final box = await SealedBox.seal(
        List<int>.filled(32, 7), await SealedBox.publicKeyOf(seed));
    expect(() => SealedBox.open(box, other),
        throwsA(isA<SealedBoxException>()));
  });

  test('tampered ciphertext is rejected', () async {
    final seed = PassphraseEnvelope.randomBytes(32);
    final box = Map<String, String>.of(await SealedBox.seal(
        List<int>.filled(32, 7), await SealedBox.publicKeyOf(seed)));
    box['ct'] = box['ct']!.replaceRange(0, 1, box['ct']![0] == 'A' ? 'B' : 'A');
    expect(() => SealedBox.open(box, seed),
        throwsA(isA<SealedBoxException>()));
  });

  test('malformed box map throws, not crashes', () async {
    expect(() => SealedBox.open({'epk': '!!'}, List<int>.filled(32, 1)),
        throwsA(isA<SealedBoxException>()));
  });

  test('two seals of the same secret differ (fresh ephemeral + nonce)',
      () async {
    final seed = PassphraseEnvelope.randomBytes(32);
    final pub = await SealedBox.publicKeyOf(seed);
    final a = await SealedBox.seal(List<int>.filled(32, 7), pub);
    final b = await SealedBox.seal(List<int>.filled(32, 7), pub);
    expect(a['ct'] == b['ct'], isFalse);
    expect(a['epk'] == b['epk'], isFalse);
  });
}
