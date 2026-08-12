// The promise that makes this app local-first: a local account never reaches
// the cloud. Every sync service hangs off syncUidProvider, so pinning it to
// null outside cloud mode is what enforces it — the mode migration wizard signs
// in while the session is still local, and nothing may upload until it flips.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agora/state/auth_session.dart';
import 'package:agora/state/cloud_auth.dart';
import 'package:agora/state/sync_provider.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _StubSession extends SessionController {
  _StubSession(this._state);

  final SessionState _state;

  @override
  SessionState build() => _state;
}

void main() {
  Future<ProviderContainer> build(SessionState session) async {
    final c = ProviderContainer(overrides: [
      authSessionProvider.overrideWith(() => _StubSession(session)),
      cloudUserProvider.overrideWith((ref) => Stream.value(_FakeUser('u1'))),
    ]);
    c.listen(cloudUserProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    return c;
  }

  test('local mode has no uid even with a live Firebase session', () async {
    final c = await build(const SessionUnlocked('ab', AccountMode.local));
    addTearDown(c.dispose);
    expect(c.read(syncUidProvider), isNull);
  });

  test('cloud mode passes the uid through', () async {
    final c = await build(const SessionUnlocked('ab', AccountMode.cloud));
    addTearDown(c.dispose);
    expect(c.read(syncUidProvider), 'u1');
  });

  test('a locked session has no uid', () async {
    final c = await build(const SessionLocalLocked('Ana'));
    addTearDown(c.dispose);
    expect(c.read(syncUidProvider), isNull);
  });
}
