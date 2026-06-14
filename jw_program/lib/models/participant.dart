// Directorio local de participants de la congregación. Modelo puro (sin drift);
// la tabla está en `data/db/tables.dart` y mapea a esta clase.
//
// IMPORTANTE: las asignaciones del programa siguen siendo strings planos en
// el formulario (FormModel.main) — este directorio NO es una FK.

enum Gender { male, female, unspecified }

extension GenderX on Gender {
  String get label => switch (this) {
        Gender.male => 'Hombre',
        Gender.female => 'Mujer',
        Gender.unspecified => 'No especificado',
      };
}

enum Role { elder, ministerialServant, publisher }

extension RoleX on Role {
  String get label => switch (this) {
        Role.elder => 'Anciano',
        Role.ministerialServant => 'Siervo ministerial',
        Role.publisher => 'Publicador',
      };

  /// Plural para los chips de filtro de la pantalla de participants.
  String get plural => switch (this) {
        Role.elder => 'Ancianos',
        Role.ministerialServant => 'Siervos ministeriales',
        Role.publisher => 'Publicadores',
      };
}

class Participant {
  final String id; // uuid v4, estable: clave de la fusión de imports
  final String name;
  final Gender gender;
  final Role role;
  final String congregation;
  final bool active; // false = oculto del picker sin borrar
  final String notes;
  final DateTime createdAt; // UTC

  /// UTC. Solo cambia con ediciones de user: decide quién gana al
  /// fusionar imports (NO se toca al registrar uso).
  final DateTime updatedAt;

  /// Última vez asignado desde el picker (recent persistentes).
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

  /// Alta mínima desde el picker: queda marcado como incompleto.
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

/// Normaliza para búsqueda y detección de duplicados en español:
/// trim, espacios colapsados, minúsculas y sin acentos (ñ→n).
String normalizeName(String s) {
  final sb = StringBuffer();
  for (final ch in s.trim().replaceAll(RegExp(r'\s+'), ' ').split('')) {
    final i = _diacritics.indexOf(ch);
    sb.write(i >= 0 ? _plain[i] : ch);
  }
  return sb.toString().toLowerCase();
}
