import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/models/congregation_settings.dart';

void main() {
  test('toJson/fromJson roundtrip', () {
    const s = CongregationSettings(
      meetingLanguage: 'english',
      midweekDay: 3,
      midweekTime: '20:15',
      weekendDay: 5,
      weekendTime: '09:30',
      auxRoom: true,
    );
    final back = CongregationSettings.fromJson(s.toJson());
    expect(back.meetingLanguage, 'english');
    expect(back.midweekDay, 3);
    expect(back.midweekTime, '20:15');
    expect(back.weekendDay, 5);
    expect(back.weekendTime, '09:30');
    expect(back.auxRoom, true);
  });

  test('tolerant parse: corrupt or partial JSON falls back to defaults', () {
    const defaults = CongregationSettings();

    for (final bad in ['', 'not json', '[]', '42']) {
      final s = CongregationSettings.fromJson(bad);
      expect(s.midweekDay, defaults.midweekDay, reason: 'input: $bad');
      expect(s.auxRoom, defaults.auxRoom);
    }

    // Old M3 rows: no auxRoom key, valid schedule.
    final legacy = CongregationSettings.fromJson(
        '{"meetingLanguage":"sign","midweek":{"weekday":0,"time":"19:30"},'
        '"weekend":{"weekday":6,"time":"10:00"}}');
    expect(legacy.meetingLanguage, 'sign');
    expect(legacy.midweekDay, 0);
    expect(legacy.midweekTime, '19:30');
    expect(legacy.auxRoom, false);

    // Out-of-range weekday and unknown language are rejected.
    final garbage = CongregationSettings.fromJson(
        '{"meetingLanguage":"klingon","midweek":{"weekday":9,"time":"19:30"}}');
    expect(garbage.meetingLanguage, defaults.meetingLanguage);
    expect(garbage.midweekDay, defaults.midweekDay);
    expect(garbage.midweekTime, '19:30');
  });
}
