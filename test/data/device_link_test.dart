import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/crypto/passphrase_envelope.dart';
import 'package:jw_program/data/sync/device_link.dart';
import 'package:jw_program/data/sync/sealed_box.dart';

/// Stands in for the NEW device: makes an ephemeral pair and its payload.
Future<(List<int> seed, LinkPayload payload)> newDevice() async {
  final (seed, pub) = await DeviceLinkBox.newEphemeral();
  return (seed, LinkPayload.generate(pub));
}

void main() {
  const uid = 'user-1';

  test('payload survives encode → decode', () {
    final payload = LinkPayload(
      sessionId: 'abc123',
      ephemeralPublicKey: List<int>.generate(32, (i) => i),
      linkSecret: List<int>.generate(32, (i) => 255 - i),
    );
    final decoded = LinkPayload.decode(payload.encode());
    expect(decoded.sessionId, payload.sessionId);
    expect(decoded.ephemeralPublicKey, payload.ephemeralPublicKey);
    expect(decoded.linkSecret, payload.linkSecret);
  });

  test('payload parse failures are distinguishable', () {
    final good = LinkPayload.generate(List<int>.filled(32, 3)).encode();
    LinkPayloadError errorOf(String raw) {
      try {
        LinkPayload.decode(raw);
      } on LinkPayloadException catch (e) {
        return e.error;
      }
      fail('expected a LinkPayloadException for: $raw');
    }

    expect(errorOf(good.replaceFirst('agora-link', 'other-app')),
        LinkPayloadError.badPrefix);
    expect(errorOf(good.replaceFirst('agora-link:1', 'agora-link:2')),
        LinkPayloadError.badVersion);
    expect(errorOf(good.split(':').take(4).join(':')),
        LinkPayloadError.truncated);
    // A mangled body the checksum should catch.
    final parts = good.split(':');
    parts[2] = '${parts[2]}x';
    expect(errorOf(parts.join(':')), LinkPayloadError.badChecksum);
  });

  test('seal → open hands the seed to the new device', () async {
    final identitySeed = PassphraseEnvelope.randomBytes(32);
    final (ephemeralSeed, payload) = await newDevice();

    // Existing device seals using ONLY what the payload carried.
    final response = await DeviceLinkBox.seal(
        seed: identitySeed, payload: LinkPayload.decode(payload.encode()), uid: uid);
    final got = await DeviceLinkBox.open(
        response: response,
        ephemeralSeed: ephemeralSeed,
        payload: payload,
        uid: uid);

    expect(got, identitySeed);
    // The response carries no plaintext seed.
    expect(response.values.join(), isNot(contains(payload.sessionId)));
  });

  test('a box for another account cannot be opened (uid is bound in)',
      () async {
    final identitySeed = PassphraseEnvelope.randomBytes(32);
    final (ephemeralSeed, payload) = await newDevice();
    final response = await DeviceLinkBox.seal(
        seed: identitySeed, payload: payload, uid: 'user-A');

    expect(
      () => DeviceLinkBox.open(
          response: response,
          ephemeralSeed: ephemeralSeed,
          payload: payload,
          uid: 'user-B'),
      throwsA(isA<DeviceLinkException>()),
    );
  });

  test('a box from another session cannot be replayed', () async {
    final identitySeed = PassphraseEnvelope.randomBytes(32);
    final (ephemeralSeed, payload) = await newDevice();
    final response = await DeviceLinkBox.seal(
        seed: identitySeed, payload: payload, uid: uid);

    // Same keys, different sessionId → the KDF and AAD no longer match.
    final otherSession = LinkPayload(
      sessionId: 'someone-elses-session',
      ephemeralPublicKey: payload.ephemeralPublicKey,
      linkSecret: payload.linkSecret,
    );
    expect(
      () => DeviceLinkBox.open(
          response: response,
          ephemeralSeed: ephemeralSeed,
          payload: otherSession,
          uid: uid),
      throwsA(isA<DeviceLinkException>()),
    );
  });

  test('the out-of-band secret is required: a swapped one fails', () async {
    final identitySeed = PassphraseEnvelope.randomBytes(32);
    final (ephemeralSeed, payload) = await newDevice();
    final response = await DeviceLinkBox.seal(
        seed: identitySeed, payload: payload, uid: uid);

    final wrongSecret = LinkPayload(
      sessionId: payload.sessionId,
      ephemeralPublicKey: payload.ephemeralPublicKey,
      linkSecret: PassphraseEnvelope.randomBytes(32),
    );
    expect(
      () => DeviceLinkBox.open(
          response: response,
          ephemeralSeed: ephemeralSeed,
          payload: wrongSecret,
          uid: uid),
      throwsA(isA<DeviceLinkException>()),
    );
  });

  test('another device\'s ephemeral key cannot open the box', () async {
    final identitySeed = PassphraseEnvelope.randomBytes(32);
    final (_, payload) = await newDevice();
    final (otherSeed, _) = await newDevice();
    final response = await DeviceLinkBox.seal(
        seed: identitySeed, payload: payload, uid: uid);

    expect(
      () => DeviceLinkBox.open(
          response: response,
          ephemeralSeed: otherSeed,
          payload: payload,
          uid: uid),
      throwsA(isA<DeviceLinkException>()),
    );
  });

  test('tampered ciphertext is rejected', () async {
    final identitySeed = PassphraseEnvelope.randomBytes(32);
    final (ephemeralSeed, payload) = await newDevice();
    final response = Map<String, String>.of(await DeviceLinkBox.seal(
        seed: identitySeed, payload: payload, uid: uid));
    final ct = response['ct']!;
    response['ct'] = ct.replaceRange(0, 1, ct[0] == 'A' ? 'B' : 'A');

    expect(
      () => DeviceLinkBox.open(
          response: response,
          ephemeralSeed: ephemeralSeed,
          payload: payload,
          uid: uid),
      throwsA(isA<DeviceLinkException>()),
    );
  });

  test('a malformed response throws instead of crashing', () async {
    final (ephemeralSeed, payload) = await newDevice();
    expect(
      () => DeviceLinkBox.open(
          response: const {'epk': '!!'},
          ephemeralSeed: ephemeralSeed,
          payload: payload,
          uid: uid),
      throwsA(isA<DeviceLinkException>()),
    );
  });

  test('the transferred seed reproduces the account identity key', () async {
    // What LinkService verifies against users/{uid}.pubKey: a forged seed
    // would open fine but derive the wrong public key.
    final identitySeed = PassphraseEnvelope.randomBytes(32);
    final published = await SealedBox.publicKeyOf(identitySeed);
    final (ephemeralSeed, payload) = await newDevice();

    final got = await DeviceLinkBox.open(
      response: await DeviceLinkBox.seal(
          seed: identitySeed, payload: payload, uid: uid),
      ephemeralSeed: ephemeralSeed,
      payload: payload,
      uid: uid,
    );
    expect(await SealedBox.publicKeyOf(got), published);

    final forged = PassphraseEnvelope.randomBytes(32);
    expect(await SealedBox.publicKeyOf(forged), isNot(published));
  });
}
