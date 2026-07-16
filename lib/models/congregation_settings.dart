import 'dart:convert';

/// Language codes stored in settings, index-aligned with the localized
/// `meetingLanguages` display list (config_options.dart).
const congregationLanguageCodes = ['spanish', 'sign', 'english'];

/// Congregation-level settings persisted in `congregations.settingsJson`
/// (docs/DATA_ARCHITECTURE.md §2). JSON so template-driven settings can
/// grow without schema migrations. Weekdays are Monday-first indexes
/// (0 = Monday … 6 = Sunday), stable across locales; times are 'HH:MM'.
/// The phase-2 program templates consume these.
class CongregationSettings {
  final String meetingLanguage; // see [congregationLanguageCodes]
  final int midweekDay;
  final String midweekTime;
  final int weekendDay;
  final String weekendTime;

  /// Second student room enabled by default for new programs.
  final bool auxRoom;

  const CongregationSettings({
    this.meetingLanguage = 'spanish',
    this.midweekDay = 1, // Tuesday
    this.midweekTime = '19:00',
    this.weekendDay = 6, // Sunday
    this.weekendTime = '10:00',
    this.auxRoom = false,
  });

  /// Tolerant parse: any missing/corrupt field falls back to its default,
  /// so old rows (or hand-edited JSON) never crash the settings screen.
  factory CongregationSettings.fromJson(String json) {
    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      return const CongregationSettings();
    }
    if (decoded is! Map<String, dynamic>) return const CongregationSettings();
    const defaults = CongregationSettings();
    final midweek = decoded['midweek'];
    final weekend = decoded['weekend'];
    return CongregationSettings(
      meetingLanguage: decoded['meetingLanguage'] is String &&
              congregationLanguageCodes.contains(decoded['meetingLanguage'])
          ? decoded['meetingLanguage'] as String
          : defaults.meetingLanguage,
      midweekDay: _day(midweek, defaults.midweekDay),
      midweekTime: _time(midweek, defaults.midweekTime),
      weekendDay: _day(weekend, defaults.weekendDay),
      weekendTime: _time(weekend, defaults.weekendTime),
      auxRoom: decoded['auxRoom'] is bool
          ? decoded['auxRoom'] as bool
          : defaults.auxRoom,
    );
  }

  static int _day(Object? section, int fallback) {
    if (section is Map<String, dynamic> && section['weekday'] is int) {
      final day = section['weekday'] as int;
      if (day >= 0 && day <= 6) return day;
    }
    return fallback;
  }

  static String _time(Object? section, String fallback) {
    if (section is Map<String, dynamic> && section['time'] is String) {
      return section['time'] as String;
    }
    return fallback;
  }

  String toJson() => jsonEncode({
        'meetingLanguage': meetingLanguage,
        'midweek': {'weekday': midweekDay, 'time': midweekTime},
        'weekend': {'weekday': weekendDay, 'time': weekendTime},
        'auxRoom': auxRoom,
      });

  CongregationSettings copyWith({
    String? meetingLanguage,
    int? midweekDay,
    String? midweekTime,
    int? weekendDay,
    String? weekendTime,
    bool? auxRoom,
  }) {
    return CongregationSettings(
      meetingLanguage: meetingLanguage ?? this.meetingLanguage,
      midweekDay: midweekDay ?? this.midweekDay,
      midweekTime: midweekTime ?? this.midweekTime,
      weekendDay: weekendDay ?? this.weekendDay,
      weekendTime: weekendTime ?? this.weekendTime,
      auxRoom: auxRoom ?? this.auxRoom,
    );
  }
}
