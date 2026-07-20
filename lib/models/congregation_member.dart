import 'member_capabilities.dart';

/// A row of the members admin screen: `congregations/{cid}/members/{uid}` as
/// seen by an admin listing the whole collection.
///
/// Deliberately NOT [Membership]: that one comes from the collection-group
/// "my congregations" query, lives in an always-open listener and is read on
/// every device. Putting `pubKey`/`email` there would make every device
/// stream those fields forever for the sake of one admin screen.
class CongregationMember {
  const CongregationMember({
    required this.uid,
    required this.pubKey,
    required this.capabilities,
    required this.wrappedVersions,
    required this.addedBy,
    required this.status,
    this.displayName,
    this.email,
    this.inviteId,
    this.createdAt,
  });

  final String uid;
  final String? displayName;
  final String? email;

  /// base64 X25519 public key — rotation seals the new CCK to it.
  final String pubKey;

  final MemberCapabilities capabilities;

  /// Which CCK versions this member currently holds. The SET, not a max:
  /// reconciliation repairs a hole like `{1, 3}`, which a max of 3 hides.
  final Set<int> wrappedVersions;

  final String? inviteId;
  final String addedBy;

  /// 'active' today; the rules already tolerate other values (see plan).
  final String status;

  final DateTime? createdAt;

  bool get isActive => status == 'active';

  factory CongregationMember.fromDoc(Map<String, dynamic> data) =>
      CongregationMember(
        uid: data['uid'] as String,
        displayName: data['displayName'] as String?,
        email: data['email'] as String?,
        pubKey: (data['pubKey'] as String?) ?? '',
        capabilities: MemberCapabilities.fromMap(
            (data['capabilities'] as Map?)?.cast<String, dynamic>() ??
                const {}),
        wrappedVersions: {
          for (final k in ((data['wrappedCcks'] as Map?) ?? const {}).keys)
            ?int.tryParse('$k'),
        },
        inviteId: data['inviteId'] as String?,
        addedBy: (data['addedBy'] as String?) ?? '',
        status: (data['status'] as String?) ?? 'active',
        // Timestamps arrive already normalized to DateTime — that conversion
        // is the gateway's job, so models stay free of cloud_firestore.
        createdAt: data['createdAt'] as DateTime?,
      );
}
