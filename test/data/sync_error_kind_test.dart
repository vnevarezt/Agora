// How a Firestore failure is read, for the two places that have to read one:
// a request that threw, and a snapshot listener that died.
//
// The listener half is what this exists for. Every pull the controller makes
// is triggered by a heartbeat delivery, so a listener error used to end that
// congregation's syncing silently — an initial restore stuck at "1 of 3" with
// a healthy-looking status. Classifying it the same way a read is classified
// is what lets a refusal be told apart from a blip: one is permanent and must
// stop asking, the other must be retried.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/data/sync/firestore_transport.dart';

void main() {
  FirebaseException firestore(String code) =>
      FirebaseException(plugin: 'cloud_firestore', code: code);

  test('a refusal is permanent, and says so', () {
    expect(
      syncErrorKindOf(firestore('permission-denied')),
      SyncTransportErrorKind.permissionDenied,
    );
  });

  test('unavailable is the network, not a verdict', () {
    expect(
      syncErrorKindOf(firestore('unavailable')),
      SyncTransportErrorKind.offline,
    );
  });

  test('anything else stays unknown rather than being guessed at', () {
    expect(
      syncErrorKindOf(firestore('resource-exhausted')),
      SyncTransportErrorKind.unknown,
    );
    // A listener can hand back something that is not a FirebaseException at
    // all; it must still classify rather than throw on the way.
    expect(syncErrorKindOf(StateError('nope')), SyncTransportErrorKind.unknown);
  });
}
