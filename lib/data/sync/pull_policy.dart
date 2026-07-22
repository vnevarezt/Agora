/// When to react to a heartbeat delivery (docs/PHASE4_CLOUD_SYNC.md, 4b-3).
/// Pure so the whole decision table is unit-testable without Firestore.
enum PullUrgency {
  /// Nothing newer than the cursor (or it was this device's own push).
  none,

  /// The change affects what's on screen right now: pull immediately.
  immediate,

  /// Something changed off-screen: mark stale and coalesce (the deferred
  /// pull downloads only each doc's FINAL state — intermediate versions
  /// are free).
  lazy,
}

/// [scopes] is the heartbeat map (scope → encoded serverTs string, same
/// sortable form as the pull cursor). Scope keys: a project id, 'people' or
/// 'congregation'. [cursor] is this congregation's local pull cursor (null =
/// never pulled). [heartbeatExists] is false when the activity doc was never
/// written (pre-4b-3 data): with no cursor either, the first sync must still
/// happen.
PullUrgency decidePull({
  required Map<String, String> scopes,
  required String? cursor,
  required String? openProjectId,
  required bool participantsVisible,
  required bool fromOwnDevice,
  bool heartbeatExists = true,
}) {
  if (!heartbeatExists) {
    // No signal doc yet: pull once if we've never pulled, else wait for the
    // first real push to create it.
    return cursor == null ? PullUrgency.immediate : PullUrgency.none;
  }
  if (fromOwnDevice) return PullUrgency.none;
  // Never pulled this congregation: it is 100% out of date, "what's on screen"
  // included, so deferring saves no useful reads. This is the initial-restore
  // path on a fresh device — pull now instead of trickling in minutes later.
  if (cursor == null) return PullUrgency.immediate;

  final newer = [
    for (final MapEntry(key: scope, value: ts) in scopes.entries)
      if (ts.compareTo(cursor) > 0) scope,
  ];
  if (newer.isEmpty) return PullUrgency.none;
  if (openProjectId != null && newer.contains(openProjectId)) {
    return PullUrgency.immediate;
  }
  if (participantsVisible && newer.contains('people')) {
    return PullUrgency.immediate;
  }
  return PullUrgency.lazy;
}
