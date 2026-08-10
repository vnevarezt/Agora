// Mide EN EL DISPOSITIVO REAL el coste de las operaciones del camino caliente,
// para saber dónde está el tiempo en vez de deducirlo del código.
//
// Ejecutar en profile mode (los números en debug no representan nada):
//   flutter test integration_test/perf_bench_test.dart -d macos --profile
//
// Imprime líneas "BENCH <nombre> <ms>" para poder compararlas entre corridas.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:agora/domain/schedule_rules.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/person.dart';
import 'package:agora/models/program_row.dart';
import 'package:agora/models/week.dart';
import 'package:agora/pdf/pdf_rasterizer.dart';
import 'package:agora/data/crypto/passphrase_envelope.dart';
import 'package:agora/pdf/pdf_theme.dart';
import 'package:agora/pdf/program_document.dart';

Week _week([String date = '18-24 DE MAYO']) => Week(
      date: date,
      reading: 'ISAÍAS 62-64',
      openingSong: '44',
      middleSong: '115',
      closingSong: '151',
      parts: const [
        Part(
            section: Section.treasures,
            number: 1,
            title: 'Disfrute al máximo de la bendición de Jehová',
            minutes: 10),
        Part(
            section: Section.treasures,
            number: 2,
            title: 'Busquemos perlas escondidas',
            minutes: 10),
        Part(
            section: Section.treasures,
            number: 3,
            title: 'Lectura de la Biblia',
            minutes: 4),
        Part(
            section: Section.ministry,
            number: 4,
            title: 'Empiece conversaciones',
            minutes: 3),
        Part(
            section: Section.ministry,
            number: 5,
            title: 'Haga revisitas',
            minutes: 4),
        Part(section: Section.ministry, number: 6, title: 'Discurso', minutes: 5),
        Part(
            section: Section.christianLife,
            number: 7,
            title: 'Sean siempre hospitalarios',
            minutes: 15),
        Part(
            section: Section.christianLife,
            number: 8,
            title: 'Estudio bíblico de la congregación',
            minutes: 30),
      ],
    );

WeekEntry _entry(String date, {bool auxRoom = false}) {
  final w = _week(date);
  final schedule = buildSchedule(w, 18 * 60, 105);
  final main = <String, List<String>>{};
  final aux = <String, List<String>>{};
  for (final row in schedule.rows) {
    if (row.slots == 0) continue;
    main[row.id] = [
      for (var i = 0; i < row.slots; i++) 'Maximiliano Vargas H'
    ];
    if (auxRoom && row.auxSlots > 0) {
      aux[row.id] = [for (var i = 0; i < row.auxSlots; i++) 'Ernesto Salas R'];
    }
  }
  return (
    week: w,
    schedule: schedule,
    assignments: Assignments(main, aux),
    chairman: 'Rafael G',
  );
}

void _report(String name, Stopwatch sw, int reps) {
  // ignore: avoid_print
  print('BENCH $name ${(sw.elapsedMicroseconds / reps / 1000)
      .toStringAsFixed(2)}');
}

Future<void> _timeAsync(
    String name, int reps, Future<void> Function() body) async {
  final sw = Stopwatch()..start();
  for (var i = 0; i < reps; i++) {
    await body();
  }
  sw.stop();
  _report(name, sw, reps);
}

void _timeSync(String name, int reps, void Function() body) {
  final sw = Stopwatch()..start();
  for (var i = 0; i < reps; i++) {
    body();
  }
  sw.stop();
  _report(name, sw, reps);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('preview del PDF: lo que corre tras cada debounce',
      (tester) async {
    final one = [_entry('18-24 DE MAYO')];
    final twoAux = [
      _entry('18-24 DE MAYO', auxRoom: true),
      _entry('25-31 DE MAYO', auxRoom: true),
    ];

    // Primera vez de todo: incluye init de pdfium y carga de fuentes. Es lo
    // que cuesta ABRIR el preview, no lo que cuesta editar con él abierto.
    final coldSw = Stopwatch()..start();
    await pdfrxFlutterInitialize();
    final coldPdf = await buildProgramSheetPdf(
        locale: AppLocale.es, congregation: 'CONGREGACIÓN', entries: one);
    (await rasterizePage(coldPdf, scale: 3)).dispose();
    coldSw.stop();
    _report('preview_primera_apertura_total', coldSw, 1);

    await _timeAsync('pdf_1_semana', 8, () async {
      await buildProgramSheetPdf(
          locale: AppLocale.es, congregation: 'CONGREGACIÓN', entries: one);
    });

    await _timeAsync('pdf_2_semanas_aux', 8, () async {
      await buildProgramSheetPdf(
          locale: AppLocale.es,
          congregation: 'CONGREGACIÓN',
          entries: twoAux,
          auxRoom: true,
          twoPerSheet: true);
    });

    final pdf = await buildProgramSheetPdf(
        locale: AppLocale.es, congregation: 'CONGREGACIÓN', entries: one);

    await _timeAsync('raster_scale_3_default', 8, () async {
      (await rasterizePage(pdf, scale: 3)).dispose();
    });

    await _timeAsync('raster_scale_6_zoom_max', 4, () async {
      (await rasterizePage(pdf, scale: 6)).dispose();
    });

    // El ciclo completo: es lo que dispara CADA cambio en un slot.
    await _timeAsync('preview_ciclo_completo', 6, () async {
      final p = await buildProgramSheetPdf(
          locale: AppLocale.es, congregation: 'CONGREGACIÓN', entries: one);
      (await rasterizePage(p, scale: 3)).dispose();
    });
  });

  testWidgets('coste de las fuentes en cada render', (tester) async {
    final bytes = await carlitoFontBytes();
    final total = bytes.regular.lengthInBytes +
        bytes.bold.lengthInBytes +
        bytes.italic.lengthInBytes +
        bytes.boldItalic.lengthInBytes;
    // ignore: avoid_print
    print('BENCH fuentes_KB ${(total / 1024).toStringAsFixed(0)}');

    // Esto corre DENTRO del isolate en cada build del PDF, y el isolate muere
    // al terminar, asi que nunca se reaprovecha.
    _timeSync('carlito_parseo_por_render', 8, () {
      carlitoFromBytes(bytes);
    });
  });

  // El desbloqueo con contrasena. En nativo va en isolate (el usuario espera,
  // la UI no se congela); en web corre inline en el hilo de UI.
  testWidgets('KDF del desbloqueo', (tester) async {
    const envelope = PassphraseEnvelope();
    const pass = 'correcta-caballo-bateria';
    final blob = await envelope.wrap([for (var i = 0; i < 32; i++) i], pass);
    await _timeAsync('kdf_desbloqueo', 3, () async {
      await envelope.unwrap(blob, pass);
    });
  });

  testWidgets('capa de estado: para escala comparativa', (tester) async {
    final names = [
      for (var i = 0; i < 150; i++) 'Hermano Ejemplo $i Martínez Núñez',
    ];

    // El sort de participantes, ya optimizado (clave precomputada).
    _timeSync('sort_participantes_150_optimizado', 200, () {
      final keyed = [for (final n in names) (key: normalizeName(n), v: n)]
        ..sort((a, b) => a.key.compareTo(b.key));
      keyed.length;
    });

    // Cómo estaba antes, para ver qué se ahorró.
    _timeSync('sort_participantes_150_antes', 50, () {
      final copy = [...names]
        ..sort((a, b) => normalizeName(a).compareTo(normalizeName(b)));
      copy.length;
    });

    // Las tarjetas del dashboard, ahora cacheadas: esto es lo que YA NO corre
    // en cada nombre asignado.
    final snapshots = [
      for (var i = 0; i < 90; i++) jsonEncode(_week('SEMANA $i').toJson()),
    ];
    var sink = 0;
    _timeSync('dashboard_90_programas_sin_cache', 50, () {
      for (final s in snapshots) {
        final w = Week.fromJson(jsonDecode(s) as Map<String, dynamic>);
        final sched = buildSchedule(w, 18 * 60, 105);
        for (final row in sched.rows) {
          sink += row.slots;
        }
      }
    });
    expect(sink, greaterThan(0));
  });
}
