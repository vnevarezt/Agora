/// Capabilities of a congregation member (DATA_ARCHITECTURE.md §5), stored
/// as a map — not `edit:<type>` strings — because Firestore rules CEL can
/// check `editTypes.hasAny(['*', type])` but has no prefix matching.
/// 'view' is implied by the member doc existing at all.
class MemberCapabilities {
  const MemberCapabilities({
    this.admin = false,
    this.people = false,
    this.editTypes = const [],
  });

  /// Manage members, invites, congregation settings and key rotation.
  final bool admin;

  /// Edit the people directory (person + absences).
  final bool people;

  /// Program type ids this member can edit; `'*'` = every type.
  final List<String> editTypes;

  static const founder =
      MemberCapabilities(admin: true, people: true, editTypes: ['*']);

  bool get canEditAnything => admin || people || editTypes.isNotEmpty;

  bool canEditProgram(String programTypeId) =>
      admin || editTypes.contains('*') || editTypes.contains(programTypeId);

  Map<String, Object> toMap() => {
        'admin': admin,
        'people': people,
        'editTypes': editTypes,
      };

  factory MemberCapabilities.fromMap(Map<String, dynamic> map) =>
      MemberCapabilities(
        admin: map['admin'] == true,
        people: map['people'] == true,
        editTypes: ((map['editTypes'] as List?) ?? const []).cast<String>(),
      );
}
