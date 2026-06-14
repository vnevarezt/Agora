// Directorio local de hermanos de la congregación. Modelo puro (sin drift);
// la tabla está en `data/db/tables.dart` y mapea a esta clase.
//
// IMPORTANTE: las asignaciones del programa siguen siendo strings planos en
// el formulario (FormModel.principal) — este directorio NO es una FK.

enum Gender { hombre, mujer, noEspecificado }

extension GenderX on Gender {
  String get etiqueta => switch (this) {
        Gender.hombre => 'Hombre',
        Gender.mujer => 'Mujer',
        Gender.noEspecificado => 'No especificado',
      };
}

enum Role { anciano, siervoMinisterial, publicador }

extension RoleX on Role {
  String get etiqueta => switch (this) {
        Role.anciano => 'Anciano',
        Role.siervoMinisterial => 'Siervo ministerial',
        Role.publicador => 'Publicador',
      };

  /// Plural para los chips de filtro de la pantalla de hermanos.
  String get plural => switch (this) {
        Role.anciano => 'Ancianos',
        Role.siervoMinisterial => 'Siervos ministeriales',
        Role.publicador => 'Publicadores',
      };
}

class Participant {
  final String id; // uuid v4, estable: clave de la fusión de imports
  final String nombre;
  final Gender sexo;
  final Role privilegio;
  final String congregacion;
  final bool activo; // false = oculto del picker sin borrar
  final String notas;
  final DateTime createdAt; // UTC

  /// UTC. Solo cambia con ediciones de usuario: decide quién gana al
  /// fusionar imports (NO se toca al registrar uso).
  final DateTime updatedAt;

  /// Última vez asignado desde el picker (recientes persistentes).
  final DateTime? ultimoUso;

  const Participant({
    required this.id,
    required this.nombre,
    required this.sexo,
    required this.privilegio,
    required this.congregacion,
    required this.activo,
    required this.notas,
    required this.createdAt,
    required this.updatedAt,
    this.ultimoUso,
  });

  /// Alta mínima desde el picker: queda marcado como incompleto.
  bool get incompleto => sexo == Gender.noEspecificado;

  Participant copyWith({
    String? nombre,
    Gender? sexo,
    Role? privilegio,
    String? congregacion,
    bool? activo,
    String? notas,
    DateTime? updatedAt,
    DateTime? ultimoUso,
  }) {
    return Participant(
      id: id,
      nombre: nombre ?? this.nombre,
      sexo: sexo ?? this.sexo,
      privilegio: privilegio ?? this.privilegio,
      congregacion: congregacion ?? this.congregacion,
      activo: activo ?? this.activo,
      notas: notas ?? this.notas,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ultimoUso: ultimoUso ?? this.ultimoUso,
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
