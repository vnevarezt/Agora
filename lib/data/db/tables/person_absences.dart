import 'package:drift/drift.dart';

import 'people.dart';
import 'sync_columns.dart';

/// "Time away" period: the assignment picker (phase 2) excludes people
/// absent on the program date. Dates are ISO `yyyy-MM-dd` TEXT — they are
/// calendar days, not instants, so no timezone math applies.
@DataClassName('PersonAbsenceRecord')
@TableIndex(name: 'person_absences_person_idx', columns: {#personId})
class PersonAbsences extends Table with SyncColumns {
  TextColumn get personId => text().references(People, #id)();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  TextColumn get comment => text().withDefault(const Constant(''))();
}
