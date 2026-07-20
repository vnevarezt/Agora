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

  /// Program type ids this member can edit; [everyType] = all of them.
  final List<String> editTypes;

  /// Wildcard entry of [editTypes]. Also spelled out in firestore.rules
  /// (`editTypes.hasAny(['*', ...])`) — change both together.
  static const everyType = '*';

  static const founder =
      MemberCapabilities(admin: true, people: true, editTypes: [everyType]);

  bool get canEditAnything => admin || people || editTypes.isNotEmpty;

  bool canEditProgram(String programTypeId) =>
      admin ||
      editTypes.contains(everyType) ||
      editTypes.contains(programTypeId);

  /// Whether a synced item of this kind may be written — a MIRROR of the
  /// `items` create/update rule in firestore.rules. Keep the two in step:
  /// the client uses this to drop writes the server would reject, because a
  /// single rejected doc fails the whole push batch and would otherwise wedge
  /// the outbox behind it forever.
  bool canPush(String entity, String? programTypeId) => switch (entity) {
        'person' || 'personAbsence' => admin || people,
        // The rule also demands `programTypeId is string`, so admin alone is
        // not enough without one.
        'program' || 'assignment' =>
          programTypeId != null && (admin || canEditProgram(programTypeId)),
        'project' => admin || editTypes.isNotEmpty,
        'congregation' => admin,
        // An entity kind these rules don't know: let the server decide.
        _ => true,
      };

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
