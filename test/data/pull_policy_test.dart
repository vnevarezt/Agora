import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/sync/pull_policy.dart';

void main() {
  PullUrgency decide({
    Map<String, String> scopes = const {},
    String? cursor,
    String? openProjectId,
    bool participantsVisible = false,
    bool fromOwnDevice = false,
    bool heartbeatExists = true,
  }) =>
      decidePull(
        scopes: scopes,
        cursor: cursor,
        openProjectId: openProjectId,
        participantsVisible: participantsVisible,
        fromOwnDevice: fromOwnDevice,
        heartbeatExists: heartbeatExists,
      );

  test('own device pushes never trigger a pull', () {
    expect(
      decide(scopes: {'p1': '9'}, cursor: '1', fromOwnDevice: true),
      PullUrgency.none,
    );
  });

  test('nothing newer than the cursor → none', () {
    expect(decide(scopes: {'p1': '5', 'people': '3'}, cursor: '5'),
        PullUrgency.none);
  });

  test('open project changed → immediate', () {
    expect(
      decide(scopes: {'p1': '9'}, cursor: '5', openProjectId: 'p1'),
      PullUrgency.immediate,
    );
  });

  test('people changed while the directory is visible → immediate', () {
    expect(
      decide(scopes: {'people': '9'}, cursor: '5', participantsVisible: true),
      PullUrgency.immediate,
    );
  });

  test('off-screen changes → lazy (coalescing window)', () {
    expect(decide(scopes: {'p2': '9'}, cursor: '5', openProjectId: 'p1'),
        PullUrgency.lazy);
    expect(decide(scopes: {'people': '9'}, cursor: '5'), PullUrgency.lazy);
    expect(decide(scopes: {'congregation': '9'}, cursor: '5'),
        PullUrgency.lazy);
  });

  test('null cursor treats every scope as newer', () {
    expect(decide(scopes: {'p1': '1'}, openProjectId: 'p1'),
        PullUrgency.immediate);
    expect(decide(scopes: {'p2': '1'}), PullUrgency.lazy);
  });

  test('missing heartbeat doc: first-ever sync pulls, an already-synced '
      'device waits', () {
    expect(decide(heartbeatExists: false), PullUrgency.immediate);
    expect(decide(heartbeatExists: false, cursor: '5'), PullUrgency.none);
  });
}
