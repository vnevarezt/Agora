// Local directory of meeting participants. Pure model (no drift); the table
// lives in `data/db/tables.dart` and maps to this class.
//
// IMPORTANT: program assignments are still plain strings in the form
// (FormModel.main) — this directory is NOT a foreign key.

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

class Participant {
  final String id; // uuid v4, stable: merge key for imports
  final String name;
  final Gender gender;
  final Role role;
  final String congregation;
  final bool active; // false = hidden from the picker without deleting
  final String notes;
  final DateTime createdAt; // UTC

  /// UTC. Only changes on user edits: decides the winner when merging
  /// imports (NOT touched when recording usage).
  final DateTime updatedAt;

  /// Last time assigned from the picker (persistent "recent" list).
  final DateTime? lastUsed;

  const Participant({
    required this.id,
    required this.name,
    required this.gender,
    required this.role,
    required this.congregation,
    required this.active,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsed,
  });

  /// Minimal entry created from the picker: stays marked as incomplete.
  bool get isIncomplete => gender == Gender.unspecified;

  Participant copyWith({
    String? name,
    Gender? gender,
    Role? role,
    String? congregation,
    bool? active,
    String? notes,
    DateTime? updatedAt,
    DateTime? lastUsed,
  }) {
    return Participant(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      congregation: congregation ?? this.congregation,
      active: active ?? this.active,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Participant && other.id == id && other.updatedAt == updatedAt;

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
