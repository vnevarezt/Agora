import 'package:flutter/painting.dart';

import '../models/congregacion.dart';
import '../models/proyecto.dart';
import '../models/recordatorio.dart';

/// Datos de ejemplo del dashboard, portados de `dash-data.js` del prototipo.
/// Solo sirven para construir la UI; se reemplazarán por datos reales
/// (base de datos cifrada) en una fase posterior.

/// Usuario en sesión (saludo del topbar y tarjeta de la barra lateral).
const usuarioEjemplo = (nombre: 'Andrés Beltrán', rol: 'Administrador');

const congregacionesEjemplo = <Congregacion>[
  Congregacion(
    id: 'c1',
    nombre: 'Constitución J.A. Castro',
    numero: '152407',
    color: Color(0xFF7A2230),
  ),
  Congregacion(
    id: 'c2',
    nombre: 'Valle Verde',
    numero: '152411',
    color: Color(0xFF3E6651),
  ),
  Congregacion(
    id: 'c3',
    nombre: 'Lomas del Sur',
    numero: '152419',
    color: Color(0xFF3F6193),
  ),
];

const proyectosEjemplo = <Proyecto>[
  Proyecto(
    id: 'pr1',
    nombre: 'Mayo 2026',
    congregacionId: 'c1',
    semanas: ['4–10 MAY', '11–17 MAY', '18–24 MAY', '25–31 MAY'],
    done: 38,
    total: 56,
    estado: EstadoProyecto.borrador,
    editado: 'hace 2 horas',
  ),
  Proyecto(
    id: 'pr2',
    nombre: 'Abril 2026',
    congregacionId: 'c1',
    semanas: ['6–12 ABR', '13–19 ABR', '20–26 ABR', '27 ABR–3 MAY'],
    done: 56,
    total: 56,
    estado: EstadoProyecto.completo,
    editado: 'hace 3 semanas',
  ),
  Proyecto(
    id: 'pr3',
    nombre: 'Semana especial · Visita del superintendente',
    congregacionId: 'c1',
    semanas: ['18–24 MAY'],
    done: 9,
    total: 14,
    estado: EstadoProyecto.borrador,
    editado: 'ayer',
  ),
  Proyecto(
    id: 'pr4',
    nombre: 'Mayo 2026',
    congregacionId: 'c2',
    semanas: ['4–10 MAY', '11–17 MAY', '18–24 MAY', '25–31 MAY'],
    done: 12,
    total: 56,
    estado: EstadoProyecto.borrador,
    editado: 'hace 4 días',
  ),
  Proyecto(
    id: 'pr5',
    nombre: 'Marzo 2026',
    congregacionId: 'c1',
    semanas: ['2–8 MAR', '9–15 MAR', '16–22 MAR', '23–29 MAR', '30 MAR–5 ABR'],
    done: 70,
    total: 70,
    estado: EstadoProyecto.exportado,
    editado: 'hace 2 meses',
  ),
  Proyecto(
    id: 'pr6',
    nombre: 'Junio 2026',
    congregacionId: 'c3',
    semanas: ['1–7 JUN', '8–14 JUN', '15–21 JUN', '22–28 JUN'],
    done: 0,
    total: 56,
    estado: EstadoProyecto.borrador,
    editado: 'hace 1 semana',
  ),
];

const recordatoriosEjemplo = <Recordatorio>[
  Recordatorio(
    id: 'r1',
    tipo: TipoRecordatorio.alerta,
    titulo: 'Semana 11–17 MAY sin presidente',
    meta: 'Mayo 2026 · Constitución J.A. Castro',
    cta: 'Asignar',
  ),
  Recordatorio(
    id: 'r2',
    tipo: TipoRecordatorio.alerta,
    titulo: '6 partes sin asignar esta semana',
    meta: 'Mayo 2026 · Constitución J.A. Castro',
    cta: 'Completar',
  ),
  Recordatorio(
    id: 'r3',
    tipo: TipoRecordatorio.info,
    titulo: 'Joel Paredes lleva 3 asignaciones este mes',
    meta: 'Considera repartir la carga',
    cta: 'Revisar',
  ),
  Recordatorio(
    id: 'r4',
    tipo: TipoRecordatorio.tarea,
    titulo: 'Exportar y compartir el programa de mayo',
    meta: 'Vence el viernes',
    cta: 'Exportar',
  ),
  Recordatorio(
    id: 'r5',
    tipo: TipoRecordatorio.info,
    titulo: 'Nuevo cuaderno disponible: Julio–Agosto',
    meta: 'jw.org · hace 2 días',
    cta: 'Descargar',
  ),
];
