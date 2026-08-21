// The printed sheet follows the congregation's MEETING language, not the app
// language. The form carries the printed congregation NAME, so the locale has
// to resolve through the open project: matching that name against an id always
// missed and printed Spanish, whatever language the congregation met in.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/data/db/app_database.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/congregation_settings.dart';
import 'package:agora/models/project.dart';
import 'package:agora/state/dashboard_provider.dart';
import 'package:agora/state/db_provider.dart';
import 'package:agora/state/editor_session.dart';
import 'package:agora/state/preview_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);
    // Riverpod 3 pauses unlistened providers, and the locale hangs off the
    // project and congregation streams.
    container.listen(programLocaleProvider, (_, _) {});
  });

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> openProjectMeetingIn(String meetingLanguage) async {
    final cong = await container.read(congregationsRepositoryProvider).create(
          name: 'Riverside',
          number: '104772',
          settings: CongregationSettings(meetingLanguage: meetingLanguage),
        );
    final projectId = await container.read(projectsRepositoryProvider).create(
      name: 'July',
      congregationId: cong.id,
      weeks: [(start: '', label: 'JULY 6-12')],
    );
    await settle();
    await container.read(editorOpenerProvider).open(Project(
          id: projectId,
          name: 'July',
          congregationId: cong.id,
          weeks: const [],
          done: 0,
          total: 0,
          status: ProjectStatus.draft,
          editedLabel: '',
          updatedAt: DateTime.utc(2026, 1, 1),
        ));
    // The project list is what carries the congregation id, and it lands a
    // stream tick after the editor opens.
    await settle();
  }

  test('an English congregation prints an English sheet', () async {
    await openProjectMeetingIn('english');
    expect(container.read(programLocaleProvider), AppLocale.en);
  });

  test('a Spanish congregation prints a Spanish sheet', () async {
    await openProjectMeetingIn('spanish');
    expect(container.read(programLocaleProvider), AppLocale.es);
  });

  test('no open project falls back to Spanish', () async {
    await settle();
    expect(container.read(programLocaleProvider), AppLocale.es);
  });
}
