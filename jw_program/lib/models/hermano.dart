// Directorio local de hermanos de la congregación. Modelo puro (sin drift);
// la tabla está en `data/db/tablas.dart` y mapea a esta clase.
//
// IMPORTANTE: las asignaciones del programa siguen siendo strings planos en
// el formulario (FormModel.principal) — este directorio NO es una FK.

enum Sexo { hombre, mujer, noEspecificado }

extension SexoX on Sexo {
  String get etiqueta => switch (this) {
        Sexo.hombre => 'Hombre',
        Sexo.mujer => 'Mujer',
        Sexo.noEspecificado => 'No especificado',
      };
}

enum Privilegio { anciano, siervoMinisterial, publicador }

extension PrivilegioX on Privilegio {
  String get etiqueta => switch (this) {
        Privilegio.anciano => 'Anciano',
        Privilegio.siervoMinisterial => 'Siervo ministerial',
        Privilegio.publicador => 'Publicador',
      };
}

class Hermano {
  final String id; // uuid v4, estable: clave de la fusión de imports
  final String nombre;
  final Sexo sexo;
  final Privilegio privilegio;
  final String congregacion;
  final bool activo; // false = oculto del picker sin borrar
  final String notas;
  final DateTime createdAt; // UTC

  /// UTC. Solo cambia con ediciones de usuario: decide quién gana al
  /// fusionar imports (NO se toca al registrar uso).
  final DateTime updatedAt;

  /// Última vez asignado desde el picker (recientes persistentes).
  final DateTime? ultimoUso;

  const Hermano({
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
  bool get incompleto => sexo == Sexo.noEspecificado;

  Hermano copyWith({
    String? nombre,
    Sexo? sexo,
    Privilegio? privilegio,
    String? congregacion,
    bool? activo,
    String? notas,
    DateTime? updatedAt,
    DateTime? ultimoUso,
  }) {
    return Hermano(
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
      other is Hermano && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);
}

const _diacriticos = 'áàäâéèëêíìïîóòöôúùüûñÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÑ';
const _planos = 'aaaaeeeeiiiioooouuuunAAAAEEEEIIIIOOOOUUUUN';

/// Normaliza para búsqueda y detección de duplicados en español:
/// trim, espacios colapsados, minúsculas y sin acentos (ñ→n).
String normalizarNombre(String s) {
  final sb = StringBuffer();
  for (final ch in s.trim().replaceAll(RegExp(r'\s+'), ' ').split('')) {
    final i = _diacriticos.indexOf(ch);
    sb.write(i >= 0 ? _planos[i] : ch);
  }
  return sb.toString().toLowerCase();
}
