import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/models/week.dart';
import 'package:agora/state/program_form.dart';
import 'package:agora/state/progress_provider.dart';
import 'package:agora/state/weeks_provider.dart';

class _FixedWeeks extends WeeksController {
  @override
  Future<List<Week>> build() async => [
        for (var i = 0; i < 3; i++)
          Week(
            date: 'SEMANA $i',
            parts: [
              const Part(
                  section: Section.treasures,
                  number: 1,
                  title: 'Lectura de la Biblia',
                  minutes: 4),
            ],
          ),
      ];
}

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = ProviderContainer(overrides: [
      weeksProvider.overrideWith(_FixedWeeks.new),
    ]);
    addTearDown(container.dispose);
    await container.read(weeksProvider.future);
  });

  test('per-week progress counts every week', () {
    expect(container.read(progressPerWeekProvider),
        [(done: 0, total: 2), (done: 0, total: 2), (done: 0, total: 2)]);

    container.read(formProvider.notifier).setMainNames('te0', ['Ana']);
    expect(container.read(progressPerWeekProvider).first, (done: 1, total: 2));
    expect(container.read(progressProvider), (done: 1, total: 2));
  });

  // A Provider that does not re-run hands back the very same instance, so
  // identity is what tells a skipped rebuild from an equal-valued one.
  test('switching week does not recompute the per-week progress', () {
    final before = container.read(progressPerWeekProvider);

    container.read(formProvider.notifier).selectWeek(1);
    container.read(formProvider.notifier).selectWeek(2);
    expect(identical(container.read(progressPerWeekProvider), before), isTrue);

    container.read(formProvider.notifier).setTitleOverride('te0', 'Otro');
    expect(identical(container.read(progressPerWeekProvider), before), isTrue);

    container.read(formProvider.notifier).setMainNames('te0', ['Ana']);
    expect(identical(container.read(progressPerWeekProvider), before), isFalse);
  });

  test('the active-week progress follows the selected week', () {
    container.read(formProvider.notifier).setMainNames('te0', ['Ana']);
    expect(container.read(progressProvider), (done: 1, total: 2));

    container.read(formProvider.notifier).selectWeek(1);
    expect(container.read(progressProvider), (done: 0, total: 2));

    container.read(formProvider.notifier).selectWeek(0);
    expect(container.read(progressProvider), (done: 1, total: 2));
  });
}
