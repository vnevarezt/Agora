import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/sync/content_crypto.dart';
import 'package:jw_program/data/sync/invite_code.dart';

CongregationKeyring keyring([int versions = 2]) => CongregationKeyring({
      for (var v = 1; v <= versions; v++) v: CongregationKeyring.newKey(),
    });

void main() {
  test('a minted code round-trips through the shared text', () {
    final code = InviteCode.mint('cid-1');
    final text = code.encode();

    // Short enough to paste into any chat without wrapping surprises.
    expect(text.length, lessThan(160));

    final parsed = InviteCode.parse(text);
    expect(parsed.congregationId, 'cid-1');
    expect(parsed.tokenId, code.tokenId);
    expect(parsed.secret, code.secret);
  });

  test('surrounding whitespace and a shouty prefix still parse', () {
    final code = InviteCode.mint('cid-1');
    final mangled = '  ${code.encode().replaceFirst('agora-inv', 'AGORA-INV')}\n';
    expect(InviteCode.parse(mangled).secret, code.secret);
  });

  test('a truncated or mistyped code is caught by the check digits', () {
    final text = InviteCode.mint('cid-1').encode();

    expect(() => InviteCode.parse(text.substring(0, text.length - 1)),
        throwsA(isA<InviteCodeException>()));
    // One flipped character inside the secret.
    final parts = text.split(':');
    parts[4] = 'A${parts[4].substring(1)}';
    expect(() => InviteCode.parse(parts.join(':')),
        throwsA(isA<InviteCodeException>()));
    expect(() => InviteCode.parse('hello world'),
        throwsA(isA<InviteCodeException>()));
    // A future code version must fail loudly, not half-parse.
    expect(() => InviteCode.parse(text.replaceFirst(':1:', ':2:')),
        throwsA(isA<InviteCodeException>()));
  });

  test('the wrapped keyring round-trips every version', () async {
    final code = InviteCode.mint('cid-1');
    final original = keyring(3);

    final box = await InviteKeyringBox.seal(original, code);
    final opened = await InviteKeyringBox.open(box, code);

    expect(opened.keys.keys.toSet(), {1, 2, 3});
    for (final v in original.keys.keys) {
      expect(opened.keys[v], original.keys[v]);
    }
  });

  test('a different secret does not open the box', () async {
    final code = InviteCode.mint('cid-1');
    final box = await InviteKeyringBox.seal(keyring(), code);

    final wrongSecret = InviteCode(
      congregationId: code.congregationId,
      tokenId: code.tokenId,
      secret: InviteCode.mint('cid-1').secret,
    );
    expect(() => InviteKeyringBox.open(box, wrongSecret),
        throwsA(isA<InviteCodeException>()));
  });

  test('a wrapped keyring copied to another congregation fails the AAD',
      () async {
    final code = InviteCode.mint('cid-A');
    final box = await InviteKeyringBox.seal(keyring(), code);

    // Same secret, same token — only the congregation moved. Without the
    // binding this would happily decrypt into the wrong tenant.
    final replayed = InviteCode(
      congregationId: 'cid-B',
      tokenId: code.tokenId,
      secret: code.secret,
    );
    expect(() => InviteKeyringBox.open(box, replayed),
        throwsA(isA<InviteCodeException>()));
  });

  test('a wrapped keyring replayed under another token fails the AAD',
      () async {
    final code = InviteCode.mint('cid-A');
    final box = await InviteKeyringBox.seal(keyring(), code);

    final otherToken = InviteCode(
      congregationId: code.congregationId,
      tokenId: InviteCode.mint('cid-A').tokenId,
      secret: code.secret,
    );
    expect(() => InviteKeyringBox.open(box, otherToken),
        throwsA(isA<InviteCodeException>()));
  });

  test('a tampered ciphertext is rejected', () async {
    final code = InviteCode.mint('cid-1');
    final box = await InviteKeyringBox.seal(keyring(), code);
    final ct = box['ct']!;
    box['ct'] = ct[0] == 'A' ? 'B${ct.substring(1)}' : 'A${ct.substring(1)}';

    expect(() => InviteKeyringBox.open(box, code),
        throwsA(isA<InviteCodeException>()));
  });
}
