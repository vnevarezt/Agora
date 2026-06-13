import '../models/hermano.dart';

/// Resultado de planear un import en modo fusionar (lógica pura, testeable).
class PlanFusion {
  /// Estado final del directorio si se aplica la fusión.
  final List<Hermano> resultado;
  final int nuevos;
  final int actualizados;
  final int iguales;

  const PlanFusion({
    required this.resultado,
    required this.nuevos,
    required this.actualizados,
    required this.iguales,
  });
}

/// Fusión por uuid estable: ausente = nuevo; si existe gana el `updatedAt`
/// más reciente (las ediciones de usuario sellan updatedAt; `ultimoUso` NO,
/// por eso siempre se conserva el máximo de ambos lados).
///
/// Limitación aceptada: el mismo hermano creado en dos dispositivos tiene
/// dos uuids → queda duplicado (la advertencia de nombre duplicado de la
/// pantalla de gestión lo delata; se limpia a mano).
PlanFusion planFusion(List<Hermano> locales, List<Hermano> entrantes) {
  final porId = {for (final h in locales) h.id: h};
  var nuevos = 0, actualizados = 0, iguales = 0;

  DateTime? maxUso(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  for (final entrante in entrantes) {
    final local = porId[entrante.id];
    if (local == null) {
      porId[entrante.id] = entrante;
      nuevos++;
      continue;
    }
    final uso = maxUso(local.ultimoUso, entrante.ultimoUso);
    if (entrante.updatedAt.isAfter(local.updatedAt)) {
      porId[entrante.id] = entrante.copyWith(ultimoUso: uso);
      actualizados++;
    } else {
      porId[entrante.id] = local.copyWith(ultimoUso: uso);
      iguales++;
    }
  }

  return PlanFusion(
    resultado: porId.values.toList(),
    nuevos: nuevos,
    actualizados: actualizados,
    iguales: iguales,
  );
}
