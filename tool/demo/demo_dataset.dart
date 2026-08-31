// Invented congregation used for store listings, the landing page and any
// other public capture. Nothing here belongs to a real congregation or a
// real person: names, numbers and workbook titles are all made up, so a
// screenshot can show the product without publishing anybody's data.
//
// Shared by `generate_demo_backup.dart` (seals it into a .agora file) and
// `integration_test/screenshots_test.dart` (seeds it straight into an
// in-memory database). One variant per shipped language — an English store
// listing must not show a Spanish program.

import 'dart:convert';

import 'package:agora/data/db/app_database.dart';
import 'package:agora/data/sync/hlc.dart';
import 'package:agora/domain/schedule_rules.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/congregation_settings.dart';
import 'package:agora/models/hall.dart';
import 'package:agora/models/person.dart';
import 'package:agora/models/program_row.dart';
import 'package:agora/models/program_type_ids.dart';
import 'package:agora/models/week.dart';
import 'package:agora/models/week_type.dart';
import 'package:drift/drift.dart';

// Fixed ids: re-importing the backup updates the demo rows instead of
// stacking a second copy next to them.
const demoCongregationId = 'de300000-0000-4000-8000-000000000001';

/// The project the editor screenshots open: the one with a week already
/// fully assigned, so the capture shows a finished program rather than gaps.
const demoProjectId = 'de3p-julio';

const demoCongregationNumber = '104772';

/// Local profile name behind the sidebar's user card and the greeting. The
/// sidebar hides that card when the session has none, which silently left a
/// hole at the bottom of every captured nav.
///
/// The one real name in this file, deliberately: it is the account holder's
/// own, not a congregation member's.
const demoProfileName = 'Vicente NT';
const demoStartTime = '19:00';
const demoDurationMinutes = 105;
const demoAuxRoom = true;
const demoCongregationColor = 0xFF4C5B9C;

const _settings = CongregationSettings(
  meetingLanguage: 'spanish',
  midweekDay: 2,
  midweekTime: demoStartTime,
  weekendDay: 6,
  weekendTime: '10:30',
  auxRoom: demoAuxRoom,
);

class DemoPerson {
  const DemoPerson(this.id, this.firstName, this.lastName, this.displayName,
      this.gender, this.privilege);

  final String id;
  final String firstName;
  final String lastName;
  final String displayName;
  final Gender gender;
  final Role privilege;
}

typedef DemoLocaleData = ({
  String congregationName,
  List<DemoPerson> people,
  List<Week> weeks,
  List<DemoProject> projects,
});

/// A planning project on the dashboard. [fill] is one fraction per week —
/// what share of that week's slots carry a name — which is what drives the
/// derived status, the progress rings and the pending-work reminders.
typedef DemoProject = ({
  String id,
  String name,
  List<String> weekDates,
  List<double> fill,
  bool exported,
  WeekType weekType,
  Duration editedAgo,
});

DemoLocaleData demoDataFor(AppLocale locale) =>
    locale == AppLocale.en ? _english() : _spanish();

const _elder = Role.elder;
const _servant = Role.ministerialServant;
const _publisher = Role.publisher;
const _m = Gender.male;
const _f = Gender.female;

DemoLocaleData _spanish() => (
      congregationName: 'VILLA AURORA',
      projects: _projects(
        july: 'Programas Julio 2026',
        august: 'Programas Agosto 2026',
        june: 'Programas Junio 2026',
        may: 'Programas Mayo 2026',
        overseer: 'Visita del superintendente',
        weeks: const {
          'may': ['4-10 DE MAYO', '11-17 DE MAYO', '18-24 DE MAYO', '25-31 DE MAYO'],
          'june': ['1-7 DE JUNIO', '8-14 DE JUNIO', '15-21 DE JUNIO', '22-28 DE JUNIO'],
          'july': ['6-12 DE JULIO', '13-19 DE JULIO', '20-26 DE JULIO'],
          'august': ['3-9 DE AGOSTO', '10-16 DE AGOSTO', '17-23 DE AGOSTO', '24-30 DE AGOSTO'],
          'overseer': ['27 DE JULIO A 2 DE AGOSTO'],
        },
      ),
      people: const [
        DemoPerson('de301', 'Andrés', 'Belmonte', 'Andrés B.', _m, _elder),
        DemoPerson('de302', 'Rafael', 'Quintana', 'Rafael Q.', _m, _elder),
        DemoPerson('de303', 'Damián', 'Solís', 'Damián S.', _m, _elder),
        DemoPerson('de304', 'Gonzalo', 'Ferrer', 'Gonzalo F.', _m, _elder),
        DemoPerson('de305', 'Marcos', 'Alcázar', 'Marcos A.', _m, _elder),
        DemoPerson('de306', 'Iván', 'Peralta', 'Iván P.', _m, _servant),
        DemoPerson('de307', 'Nicolás', 'Arriaga', 'Nicolás A.', _m, _servant),
        DemoPerson('de308', 'Tomás', 'Escudero', 'Tomás E.', _m, _servant),
        DemoPerson('de309', 'Julián', 'Ordóñez', 'Julián O.', _m, _servant),
        DemoPerson('de310', 'Emilio', 'Cárdenas', 'Emilio C.', _m, _publisher),
        DemoPerson('de311', 'Sebastián', 'Rivas', 'Sebastián R.', _m, _publisher),
        DemoPerson('de312', 'Matías', 'Cordero', 'Matías C.', _m, _publisher),
        DemoPerson('de313', 'Hugo', 'Valdivia', 'Hugo V.', _m, _publisher),
        DemoPerson('de314', 'Lucía', 'Menéndez', 'Lucía M.', _f, _publisher),
        DemoPerson('de315', 'Elena', 'Castaño', 'Elena C.', _f, _publisher),
        DemoPerson('de316', 'Paula', 'Arenas', 'Paula A.', _f, _publisher),
        DemoPerson('de317', 'Miriam', 'Cifuentes', 'Miriam C.', _f, _publisher),
        DemoPerson('de318', 'Noelia', 'Prat', 'Noelia P.', _f, _publisher),
        DemoPerson('de319', 'Ariadna', 'Solano', 'Ariadna S.', _f, _publisher),
      ],
      weeks: [
        _week('6-12 DE JULIO', 'PROVERBIOS 3', ['104', '58', '127'], const [
          'Confíe en la guía que Jehová le da',
          'Busquemos perlas escondidas',
          'Lectura de la Biblia',
          'Empiece conversaciones',
          'Haga revisitas',
          'Discurso',
          'Cómo animar a quien se siente solo',
          'Estudio bíblico de la congregación',
        ]),
        _week('13-19 DE JULIO', 'SALMO 34', ['82', '139', '45'], const [
          'Jehová está cerca de los que sufren',
          'Busquemos perlas escondidas',
          'Lectura de la Biblia',
          'Empiece conversaciones',
          'Haga discípulos',
          'Explique sus creencias',
          'Necesidades de la congregación',
          'Estudio bíblico de la congregación',
        ], talkIndex: null),
        _week('20-26 DE JULIO', '1 SAMUEL 24', ['17', '111', '150'], const [
          'Un ejemplo de dominio propio',
          'Busquemos perlas escondidas',
          'Lectura de la Biblia',
          'Empiece conversaciones',
          'Haga revisitas',
          'Discurso',
          'Mantengamos la paz en la familia',
          'Estudio bíblico de la congregación',
        ]),
      ],
    );

DemoLocaleData _english() => (
      congregationName: 'RIVERSIDE',
      projects: _projects(
        july: 'Programs July 2026',
        august: 'Programs August 2026',
        june: 'Programs June 2026',
        may: 'Programs May 2026',
        overseer: 'Circuit overseer visit',
        weeks: const {
          'may': ['MAY 4-10', 'MAY 11-17', 'MAY 18-24', 'MAY 25-31'],
          'june': ['JUNE 1-7', 'JUNE 8-14', 'JUNE 15-21', 'JUNE 22-28'],
          'july': ['JULY 6-12', 'JULY 13-19', 'JULY 20-26'],
          'august': ['AUGUST 3-9', 'AUGUST 10-16', 'AUGUST 17-23', 'AUGUST 24-30'],
          'overseer': ['JULY 27 - AUGUST 2'],
        },
      ),
      people: const [
        DemoPerson('de301', 'Andrew', 'Whitfield', 'Andrew W.', _m, _elder),
        DemoPerson('de302', 'Robert', 'Kingsley', 'Robert K.', _m, _elder),
        DemoPerson('de303', 'Daniel', 'Ashcroft', 'Daniel A.', _m, _elder),
        DemoPerson('de304', 'Gordon', 'Fairlie', 'Gordon F.', _m, _elder),
        DemoPerson('de305', 'Mark', 'Alderton', 'Mark A.', _m, _elder),
        DemoPerson('de306', 'Ivan', 'Prescott', 'Ivan P.', _m, _servant),
        DemoPerson('de307', 'Nathan', 'Arrowood', 'Nathan A.', _m, _servant),
        DemoPerson('de308', 'Thomas', 'Escott', 'Thomas E.', _m, _servant),
        DemoPerson('de309', 'Julian', 'Ordway', 'Julian O.', _m, _servant),
        DemoPerson('de310', 'Emil', 'Cardwell', 'Emil C.', _m, _publisher),
        DemoPerson('de311', 'Sebastian', 'Reeves', 'Sebastian R.', _m, _publisher),
        DemoPerson('de312', 'Matthew', 'Corden', 'Matthew C.', _m, _publisher),
        DemoPerson('de313', 'Hugh', 'Waldron', 'Hugh W.', _m, _publisher),
        DemoPerson('de314', 'Lucy', 'Menzies', 'Lucy M.', _f, _publisher),
        DemoPerson('de315', 'Ellen', 'Castleton', 'Ellen C.', _f, _publisher),
        DemoPerson('de316', 'Paula', 'Arden', 'Paula A.', _f, _publisher),
        DemoPerson('de317', 'Miriam', 'Cliffe', 'Miriam C.', _f, _publisher),
        DemoPerson('de318', 'Noelle', 'Pratt', 'Noelle P.', _f, _publisher),
        DemoPerson('de319', 'Ariadne', 'Sloane', 'Ariadne S.', _f, _publisher),
      ],
      weeks: [
        _week('JULY 6-12', 'PROVERBS 3', ['104', '58', '127'], const [
          'Trust the Guidance Jehovah Gives You',
          'Digging for Spiritual Gems',
          'Bible Reading',
          'Starting a Conversation',
          'Following Up',
          'Talk',
          'How to Encourage Someone Who Feels Alone',
          'Congregation Bible Study',
        ]),
        _week('JULY 13-19', 'PSALM 34', ['82', '139', '45'], const [
          'Jehovah Is Close to Those Who Suffer',
          'Digging for Spiritual Gems',
          'Bible Reading',
          'Starting a Conversation',
          'Making Disciples',
          'Explaining Your Beliefs',
          'Local Needs',
          'Congregation Bible Study',
        ], talkIndex: null),
        _week('JULY 20-26', '1 SAMUEL 24', ['17', '111', '150'], const [
          'An Example of Self-Control',
          'Digging for Spiritual Gems',
          'Bible Reading',
          'Starting a Conversation',
          'Following Up',
          'Talk',
          'Keeping Peace in the Family',
          'Congregation Bible Study',
        ]),
      ],
    );

/// Five projects covering every state the dashboard can show: a draft in
/// progress (the hero card and its reminders), a barely-started draft, a
/// finished-but-unexported one, and two exported months.
List<DemoProject> _projects({
  required String july,
  required String august,
  required String june,
  required String may,
  required String overseer,
  required Map<String, List<String>> weeks,
}) =>
    [
      (
        id: demoProjectId,
        name: july,
        weekDates: weeks['july']!,
        // First week complete: that is the one the editor screenshots open.
        fill: const [1.0, 1.0, 0.55],
        exported: false,
        weekType: WeekType.normal,
        editedAgo: const Duration(minutes: 35),
      ),
      (
        id: 'de3p-agosto',
        name: august,
        weekDates: weeks['august']!,
        fill: const [0.8, 0.35, 0.0, 0.0],
        exported: false,
        weekType: WeekType.normal,
        editedAgo: const Duration(hours: 4),
      ),
      (
        id: 'de3p-so',
        name: overseer,
        weekDates: weeks['overseer']!,
        fill: const [1.0],
        exported: false,
        weekType: WeekType.circuitOverseerVisit,
        editedAgo: const Duration(days: 1),
      ),
      (
        id: 'de3p-junio',
        name: june,
        weekDates: weeks['june']!,
        fill: const [1.0, 1.0, 1.0, 1.0],
        exported: true,
        weekType: WeekType.normal,
        editedAgo: const Duration(days: 6),
      ),
      (
        id: 'de3p-mayo',
        name: may,
        weekDates: weeks['may']!,
        fill: const [1.0, 1.0, 1.0, 1.0],
        exported: true,
        weekType: WeekType.normal,
        editedAgo: const Duration(days: 21),
      ),
    ];

/// Eight titles in form order: three Treasures parts, three ministry parts,
/// then the Christian Life part and the Bible study. [talkIndex] marks which
/// ministry part is a student talk rather than a demonstration.
Week _week(String date, String reading, List<String> songs, List<String> titles,
    {int? talkIndex = 5}) {
  const minutes = [10, 10, 4, 3, 4, 5, 15, 30];
  const sections = [
    Section.treasures,
    Section.treasures,
    Section.treasures,
    Section.ministry,
    Section.ministry,
    Section.ministry,
    Section.christianLife,
    Section.christianLife,
  ];
  return Week(
    date: date,
    reading: reading,
    openingSong: songs[0],
    middleSong: songs[1],
    closingSong: songs[2],
    parts: [
      for (var i = 0; i < titles.length; i++)
        Part(
          section: sections[i],
          number: i + 1,
          title: titles[i],
          minutes: minutes[i],
          isTalk: i == talkIndex,
        ),
    ],
  );
}


/// One filled slot, in the order the form fills them. Emitting a flat ordered
/// list (rather than a map) is what lets a project be seeded partially: keep
/// the first N and the dashboard's progress rings, statuses and reminders all
/// follow from the rows that exist.
typedef DemoSlot = ({String slotKey, Hall hall, int position, String name});

List<DemoPerson> _by(List<DemoPerson> people, Set<Role> roles,
        {Gender? gender}) =>
    [
      for (final p in people)
        if (roles.contains(p.privilege) &&
            (gender == null || p.gender == gender))
          p,
    ];

/// Round-robin over a pool, offset per week so consecutive weeks never show
/// the same rotation.
class _Rotor {
  _Rotor(this.offset);

  final int offset;
  int _n = 0;

  String next(List<DemoPerson> pool) =>
      pool[(offset * 3 + _n++) % pool.length].displayName;
}

/// Every slot of one week, keyed exactly like the editor keys them
/// (`ProgramRow.id`), so slot keys can never drift from [buildSchedule].
List<DemoSlot> demoSlotsFor(
    List<DemoPerson> people, ProgramSchedule schedule, int weekIndex,
    {required bool auxRoom}) {
  final elders = _by(people, {Role.elder});
  final qualified = _by(people, {Role.elder, Role.ministerialServant});
  final servants = _by(people, {Role.ministerialServant});
  final brothers =
      _by(people, {Role.ministerialServant, Role.publisher}, gender: _m);
  final sisters = _by(people, {Role.publisher}, gender: _f);

  final rot = _Rotor(weekIndex);
  final slots = <DemoSlot>[
    (
      slotKey: 'chairman',
      hall: Hall.main,
      position: 0,
      name: elders[weekIndex % elders.length].displayName,
    ),
  ];

  void add(String slotKey, Hall hall, List<String> names) {
    for (var i = 0; i < names.length; i++) {
      slots.add((slotKey: slotKey, hall: hall, position: i, name: names[i]));
    }
  }

  for (final row in schedule.opening) {
    if (row.slots > 0) add(row.id, Hall.main, [rot.next(qualified)]);
  }

  for (final row in schedule.treasures) {
    if (row.slots == 0) continue;
    // Bible reading: brothers only.
    final pool = row.role == SlotRole.student ? brothers : qualified;
    add(row.id, Hall.main, [for (var i = 0; i < row.slots; i++) rot.next(pool)]);
    if (auxRoom && row.auxSlots > 0) {
      add(row.id, Hall.aux,
          [for (var i = 0; i < row.auxSlots; i++) rot.next(brothers)]);
    }
  }

  for (var i = 0; i < schedule.ministry.length; i++) {
    final row = schedule.ministry[i];
    if (row.slots == 0) continue;
    // Alternate which room gets the sisters, so both columns look lived-in.
    final main = i.isEven ? sisters : brothers;
    add(row.id, Hall.main,
        [for (var n = 0; n < row.slots; n++) rot.next(main)]);
    if (auxRoom && row.auxSlots > 0) {
      final aux = i.isEven ? brothers : sisters;
      add(row.id, Hall.aux,
          [for (var n = 0; n < row.auxSlots; n++) rot.next(aux)]);
    }
  }

  for (final row in schedule.christianLife) {
    if (row.slots == 0) continue;
    add(
      row.id,
      Hall.main,
      switch (row.role) {
        SlotRole.conductorReader => [rot.next(elders), rot.next(servants)],
        SlotRole.speaker => [rot.next(elders)],
        _ => [for (var i = 0; i < row.slots; i++) rot.next(qualified)],
      },
    );
  }

  return slots;
}

/// Writes the whole demo congregation into [db]: congregation, directory and
/// every project with its programs and assignments.
Future<void> seedDemoData(AppDatabase db,
    {AppLocale locale = AppLocale.es}) async {
  final data = demoDataFor(locale);
  final clock = HlcClock('demoSeed');
  final now = DateTime.now().toUtc();
  String stamp() => clock.next().encode();

  final settings = _settings.copyWith(
      meetingLanguage: locale == AppLocale.en ? 'english' : 'spanish');

  await db.into(db.congregations).insertOnConflictUpdate(
        CongregationsCompanion.insert(
          id: demoCongregationId,
          name: data.congregationName,
          number: const Value(demoCongregationNumber),
          color: demoCongregationColor,
          settingsJson: Value(settings.toJson()),
          createdAt: now,
          updatedAt: now,
          hlc: Value(stamp()),
        ),
      );

  for (final person in data.people) {
    await db.into(db.people).insertOnConflictUpdate(
          PeopleCompanion.insert(
            id: person.id,
            congregationId: demoCongregationId,
            firstName: Value(person.firstName),
            lastName: Value(person.lastName),
            displayName: person.displayName,
            gender: person.gender,
            privilege: person.privilege,
            createdAt: now,
            updatedAt: now,
            hlc: Value(stamp()),
          ),
        );
  }

  final startMinutes = _minutesOf(demoStartTime);

  for (final project in data.projects) {
    // Relative "edited 35 minutes ago" labels are computed against the real
    // clock, so the captures have to be seeded against it too.
    final edited = now.subtract(project.editedAgo);
    await db.into(db.projects).insertOnConflictUpdate(
          ProjectsCompanion.insert(
            id: project.id,
            congregationId: demoCongregationId,
            name: project.name,
            exportedAt: Value(project.exported ? edited : null),
            createdAt: edited,
            updatedAt: edited,
            hlc: Value(stamp()),
          ),
        );

    for (var i = 0; i < project.weekDates.length; i++) {
      final week = _dated(data.weeks[i % data.weeks.length],
          project.weekDates[i]);
      final programId = '${project.id}-p$i';
      await db.into(db.programs).insertOnConflictUpdate(
            ProgramsCompanion.insert(
              id: programId,
              projectId: project.id,
              programTypeId: ProgramTypeIds.mwbS140,
              weekType: Value(project.weekType),
              date: week.date,
              sortIndex: Value(i),
              contentJson: Value(jsonEncode(week.toJson())),
              startTime: const Value(demoStartTime),
              durationMinutes: const Value(demoDurationMinutes),
              auxRoom: const Value(demoAuxRoom),
              createdAt: edited,
              updatedAt: edited,
              hlc: Value(stamp()),
            ),
          );

      final schedule = buildSchedule(week, startMinutes, demoDurationMinutes,
          circuitOverseer: project.weekType == WeekType.circuitOverseerVisit);
      final slots =
          demoSlotsFor(data.people, schedule, i, auxRoom: demoAuxRoom);
      final filled = (slots.length * project.fill[i]).round();

      for (var n = 0; n < filled; n++) {
        final slot = slots[n];
        await db.into(db.assignmentRows).insertOnConflictUpdate(
              AssignmentRowsCompanion.insert(
                id: '$programId-a${n.toString().padLeft(3, '0')}',
                programId: programId,
                slotKey: slot.slotKey,
                hall: slot.hall,
                position: slot.position,
                displayName: slot.name,
                createdAt: edited,
                updatedAt: edited,
                hlc: Value(stamp()),
              ),
            );
      }
    }
  }
}

Week _dated(Week base, String date) => Week(
      date: date,
      reading: base.reading,
      openingSong: base.openingSong,
      middleSong: base.middleSong,
      closingSong: base.closingSong,
      introMinutes: base.introMinutes,
      conclusionMinutes: base.conclusionMinutes,
      parts: base.parts,
    );

int _minutesOf(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}
