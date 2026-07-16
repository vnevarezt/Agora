// Person in a congregation's directory. Pure model (no drift); the table
// lives in `data/db/tables/people.dart` and maps to this class. Replaces
// the flat `Participant` (phase 1, docs/PHASE1_LOCAL_PERSISTENCE.md):
// the congregation is now a real FK and the name is split.
//
// IMPORTANT: program assignments are still plain strings in the form
// (FormModel.main) — this directory is NOT a foreign key until phase 2.

import '../i18n/strings.g.dart';

enum Gender { male, female, unspecified }

extension GenderX on Gender {
  String get label => switch (this) {
        Gender.male => t.gender.male,
        Gender.female => t.gender.female,
        Gender.unspecified => t.gender.unspecified,
      };
}

enum Role { elder, ministerialServant, publisher }

extension RoleX on Role {
  String get label => switch (this) {
        Role.elder => t.roles.elder,
        Role.ministerialServant => t.roles.ministerialServant,
        Role.publisher => t.roles.publisher,
      };

  /// Plural form used by the filter chips on the participants screen.
  String get plural => switch (this) {
        Role.elder => t.roles.elderPlural,
        Role.ministerialServant => t.roles.ministerialServantPlural,
        Role.publisher => t.roles.publisherPlural,
      };
}

class Person {
  final String id; // uuid v4, stable: merge key for imports and sync
  final String congregationId; // FK: the tenant that owns this record

  final String firstName;
  final String lastName;

  /// What programs print (S-140 uses short names, not legal names).
  final String displayName;

  final Gender gender;
  final Role privilege;

  /// Slot-kind ids this person can be assigned to (drives the phase-2
  /// picker, alongside [privilege]). Empty = not restricted yet.
  final List<String> qualifications;

  /// Free-text home congregation for visitors (e.g. an outside speaker).
  /// NOT the tenant: that is [congregationId]. Empty for local members.
  final String originCongregation;

  final bool active; // false = hidden from the picker without deleting
  final String notes;
  final DateTime createdAt; // UTC

  /// UTC. Only changes on user edits: decides the winner when merging
  /// imports (NOT touched when recording usage).
  final DateTime updatedAt;

  /// Last time assigned from the picker (persistent "recent" list).
  final DateTime? lastUsed;

  /// Soft-delete tombstone (docs/DATA_ARCHITECTURE.md §2). Alive = null.
  final DateTime? deletedAt;

  /// Hybrid logical clock stamp; null until phase 3 (sync scaffolding).
  final String? hlc;

  const Person({
    required this.id,
    required this.congregationId,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.gender,
    required this.privilege,
    required this.qualifications,
    required this.originCongregation,
    required this.active,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsed,
    this.deletedAt,
    this.hlc,
  });

  /// Minimal entry created from the picker: stays marked as incomplete.
  bool get isIncomplete => gender == Gender.unspecified;

  Person copyWith({
    String? congregationId,
    String? firstName,
    String? lastName,
    String? displayName,
    Gender? gender,
    Role? privilege,
    List<String>? qualifications,
    String? originCongregation,
    bool? active,
    String? notes,
    DateTime? updatedAt,
    DateTime? lastUsed,
  }) {
    return Person(
      id: id,
      congregationId: congregationId ?? this.congregationId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      privilege: privilege ?? this.privilege,
      qualifications: qualifications ?? this.qualifications,
      originCongregation: originCongregation ?? this.originCongregation,
      active: active ?? this.active,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsed: lastUsed ?? this.lastUsed,
      deletedAt: deletedAt,
      hlc: hlc,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Person && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);
}

const _diacritics = 'áàäâéèëêíìïîóòöôúùüûñÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÑ';
const _plain = 'aaaaeeeeiiiioooouuuunAAAAEEEEIIIIOOOOUUUUN';

/// Normalizes for accent-insensitive search and duplicate detection:
/// trim, collapse whitespace, lowercase and strip accents (ñ→n).
String normalizeName(String s) {
  final sb = StringBuffer();
  for (final ch in s.trim().replaceAll(RegExp(r'\s+'), ' ').split('')) {
    final i = _diacritics.indexOf(ch);
    sb.write(i >= 0 ? _plain[i] : ch);
  }
  return sb.toString().toLowerCase();
}
