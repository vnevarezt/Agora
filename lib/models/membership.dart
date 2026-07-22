import 'member_capabilities.dart';

/// A member doc as seen through the collection-group "my congregations"
/// query: which congregation, and this user's role in it. The congregation's
/// name/number live E2E inside the synced `congregation` item, not here.
class Membership {
  const Membership({
    required this.congregationId,
    required this.uid,
    required this.capabilities,
    required this.keyVersion,
  });

  final String congregationId;
  final String uid;
  final MemberCapabilities capabilities;

  /// Highest wrappedCck version this member holds (rotation staleness hint).
  final int keyVersion;

  factory Membership.fromDoc(String congregationId, Map<String, dynamic> data) {
    final wrapped = (data['wrappedCcks'] as Map?)?.keys ?? const [];
    final maxVersion = wrapped.isEmpty
        ? 0
        : wrapped
            .map((k) => int.tryParse('$k') ?? 0)
            .reduce((a, b) => a > b ? a : b);
    return Membership(
      congregationId: congregationId,
      uid: data['uid'] as String,
      capabilities: MemberCapabilities.fromMap(
          (data['capabilities'] as Map?)?.cast<String, dynamic>() ?? const {}),
      keyVersion: maxVersion,
    );
  }
}
