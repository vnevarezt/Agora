import 'package:agora/models/person.dart';
import 'package:agora/state/assignment_ops.dart';
import 'package:agora/state/editor_session.dart';
import 'package:agora/state/people_provider.dart';
import 'package:agora/ui/picker/person_picker_panel.dart';
import 'package:agora/ui/theme/dimens.dart';
import 'package:agora/ui/workspace/part_card.dart';
import 'package:agora/ui/workspace/part_presentation.dart';
import 'package:flutter/material.dart';
// Override is not on flutter_riverpod's main entrypoint.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog.dart';

/// The two surfaces the other golden files could not reach, because each reads
/// providers rather than taking everything as arguments. They are plain
/// `Provider`s, so a value override is the whole fixture — no database, no
/// workbook, no form.
void main() {
  setUpAll(loadAppFonts);

  final now = DateTime.utc(2026, 7, 6);
  Person person(String name, Role privilege, {Gender gender = Gender.male}) =>
      Person(
        id: name,
        congregationId: 'c1',
        firstName: name.split(' ').first,
        lastName: name.split(' ').last,
        displayName: name,
        gender: gender,
        privilege: privilege,
        qualifications: const [],
        originCongregation: '',
        active: true,
        notes: '',
        createdAt: now,
        updatedAt: now,
      );

  final people = [
    person('Ana Rodríguez', Role.publisher, gender: Gender.female),
    person('Bruno Silva', Role.elder),
    person('Carla Méndez', Role.publisher, gender: Gender.female),
    person('Diego Fuentes', Role.ministerialServant),
  ];

  List<Override> overrides() => [
    activePeopleKeyedProvider.overrideWithValue([
      for (final p in people) (key: p.displayName.toLowerCase(), person: p),
    ]),
    recentPeopleProvider.overrideWithValue(people.take(2).toList()),
    canEditOpenProgramProvider.overrideWithValue(true),
  ];

  /// A numbered ministry part, which is the shape with the most on it: a time,
  /// a duration, a title out of the workbook and two named slots.
  final part = PartView(
    id: 'p1',
    kind: PartKind.role,
    time: '19:35',
    title: 'Empiece conversaciones',
    durationLabel: '3 min',
    titleFromWorkbook: true,
    slots: const [
      SlotSpec(label: 'Estudiante', ref: ChairmanSlot(), maxLength: 40),
      SlotSpec(label: 'Ayudante', ref: ChairmanSlot(), maxLength: 40),
    ],
  );

  final fixedLine = PartView(
    id: 'p2',
    kind: PartKind.fixedLine,
    time: '19:00',
    title: 'Canción 12 y oración',
    fixedTag: 'Cántico',
  );

  for (final mode in [
    (name: 'light', brightness: Brightness.light),
    (name: 'dark', brightness: Brightness.dark),
  ]) {
    testWidgets('workspace · ${mode.name}', (tester) async {
      await expectGolden(
        tester,
        GoldenPage(
          brightness: mode.brightness,
          overrides: overrides(),
          children: [
            goldenRow('PartCard · fixed line', [
              SizedBox(width: 520, child: PartCard(view: fixedLine)),
            ]),
            goldenRow('PartCard · role, two slots, unassigned', [
              SizedBox(width: 520, child: PartCard(view: part)),
            ]),
          ],
        ),
        'workspace_${mode.name}',
        size: const Size(600, 420),
      );
    });

    testWidgets('picker · ${mode.name}', (tester) async {
      await expectGolden(
        tester,
        GoldenPage(
          brightness: mode.brightness,
          overrides: overrides(),
          children: [
            goldenRow('PersonPickerPanel', [
              SizedBox(
                width: Dimens.pickerW,
                height: Dimens.pickerMaxH,
                child: const PersonPickerPanel(
                  roleLabel: 'Estudiante',
                  current: '',
                  maxLength: 40,
                ),
              ),
            ]),
          ],
        ),
        'picker_${mode.name}',
        size: const Size(420, 560),
      );
    });
  }
}
