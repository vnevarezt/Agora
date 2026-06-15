// Static options for the Settings dropdowns (UI-only). The real
// congregation/user/settings data lives in state (in memory for now); only the
// dropdown option lists remain here.
//
// They are getters (not const) so the labels follow the active app language;
// the selection itself is decorative and not persisted yet.

import '../i18n/strings.g.dart';

List<String> get daysOfWeek => [
      t.days.monday,
      t.days.tuesday,
      t.days.wednesday,
      t.days.thursday,
      t.days.friday,
      t.days.saturday,
      t.days.sunday,
    ];
List<String> get meetingLanguages => [
      t.options.meetingLangSpanish,
      t.options.meetingLangSign,
      t.options.meetingLangEnglish,
    ];
List<String> get accessRoles =>
    [t.options.accessAdmin, t.options.accessEditor, t.options.accessReader];
