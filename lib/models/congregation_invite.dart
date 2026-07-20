import 'member_capabilities.dart';

/// A pending invite (`congregations/{cid}/invites/{tokenId}`) as an admin
/// sees it in the members screen. The `wrappedKeyring` is deliberately NOT
/// here: only the redeemer's code opens it, and no admin screen needs it.
class CongregationInvite {
  const CongregationInvite({
    required this.tokenId,
    required this.capabilities,
    required this.createdBy,
    this.createdAt,
    this.expiresAt,
  });

  /// The invite document's id — also the token that travels in the code.
  final String tokenId;

  /// Copied verbatim onto the member doc at redemption (the rules check it).
  final MemberCapabilities capabilities;

  final String createdBy;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  bool isExpired(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);

  factory CongregationInvite.fromDoc(
          String tokenId, Map<String, dynamic> data) =>
      CongregationInvite(
        tokenId: tokenId,
        capabilities: MemberCapabilities.fromMap(
            (data['capabilities'] as Map?)?.cast<String, dynamic>() ??
                const {}),
        createdBy: (data['createdBy'] as String?) ?? '',
        createdAt: data['createdAt'] as DateTime?,
        expiresAt: data['expiresAt'] as DateTime?,
      );
}
