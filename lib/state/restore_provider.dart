import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_provider.dart';
import 'sync_provider.dart';

/// Progress of the first-time data restore on a freshly signed-in device.
/// [total] 0 means we are still discovering how much there is (memberships
/// not loaded yet). [done] rises as each congregation's first pull page lands.
typedef InitialRestore = ({int done, int total});

/// Whether this device is still restoring cloud data it has never seen, and
/// how far along it is — or null when there is nothing to restore.
///
/// "Missing" is measured against the LOCAL congregation rows, not the pull
/// cursor: a founder's own device keeps a null cursor forever (it never needs
/// to pull), so cursor-based detection would show the banner permanently.
/// A congregation leaves [pending] the moment its first pull page applies,
/// since `congregation` is applied first in the engine's order.
final initialRestoreProvider = Provider<InitialRestore?>((ref) {
  final uid = ref.watch(syncUidProvider);
  if (uid == null) return null;

  final congregations = ref.watch(congregationsStreamProvider);
  // Until the local stream emits we can't tell an empty device from a
  // still-loading one; the dashboard skeleton already covers this frame.
  if (!congregations.hasValue) return null;
  final localCids = {for (final c in congregations.requireValue) c.id};

  final memberships = ref.watch(myMembershipsProvider);
  if (memberships.isLoading || memberships.hasError) {
    // Login done, memberships not in yet: only a device with no local data is
    // plausibly mid-restore, so an established device never flashes the banner.
    return localCids.isEmpty ? (done: 0, total: 0) : null;
  }

  final cloudCids = {
    for (final m in memberships.value ?? const []) m.congregationId,
  };
  final pending = cloudCids.difference(localCids);
  if (pending.isEmpty) return null;
  final total = cloudCids.length;
  return (done: total - pending.length, total: total);
});
