import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Device-local UI preferences persisted in SharedPreferences (same pattern
/// as locale_boot.dart). NOT synced data: this never goes to the DB or,
/// later, the cloud — it is how THIS device likes to look.
///
/// `initAppSettings()` must run once in `main()` before `runApp` so the
/// providers read synchronously on first build (no flash of defaults).

const _themeKey = 'theme_mode';
const _timeFormat24Key = 'time_format_24h';
const _weekStartMondayKey = 'week_start_monday';
const _pdfNameFormatKey = 'pdf_name_format';
const _notifPrefix = 'notif_';

SharedPreferences? _prefs;

Future<void> initAppSettings() async {
  _prefs = await SharedPreferences.getInstance();
}

const _deviceIdKey = 'device_id';
String? _deviceId;

/// Stable 8-char id of THIS device, created on first use: identifies the
/// device inside HLC stamps (phase 3) and later `srcDevice` on sync docs.
/// Not secret. In-memory fallback when prefs are absent (unit tests).
String deviceId() {
  var id = _deviceId ??= _prefs?.getString(_deviceIdKey);
  if (id == null) {
    id = const Uuid().v4().replaceAll('-', '').substring(0, 8);
    _deviceId = id;
    _prefs?.setString(_deviceIdKey, id);
  }
  return id;
}

/// How participant names are printed on the PDF (consumed in phase 2 when
/// the PDF renders from Person rows; the preference persists already).
enum PdfNameFormat { full, lastFirst, firstOnly }

/// Notification toggles, by stable key (the UI shows them in this order).
enum NotifPref { unassigned, load, newNotebooks, exports }

const _notifDefaults = {
  NotifPref.unassigned: true,
  NotifPref.load: true,
  NotifPref.newNotebooks: true,
  NotifPref.exports: false,
};

class AppSettings {
  final bool timeFormat24;
  final bool weekStartMonday;
  final PdfNameFormat pdfNameFormat;
  final Map<NotifPref, bool> notifications;

  const AppSettings({
    this.timeFormat24 = true,
    this.weekStartMonday = true,
    this.pdfNameFormat = PdfNameFormat.full,
    this.notifications = _notifDefaults,
  });

  AppSettings copyWith({
    bool? timeFormat24,
    bool? weekStartMonday,
    PdfNameFormat? pdfNameFormat,
    Map<NotifPref, bool>? notifications,
  }) {
    return AppSettings(
      timeFormat24: timeFormat24 ?? this.timeFormat24,
      weekStartMonday: weekStartMonday ?? this.weekStartMonday,
      pdfNameFormat: pdfNameFormat ?? this.pdfNameFormat,
      notifications: notifications ?? this.notifications,
    );
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
        AppSettingsController.new);

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final p = _prefs;
    if (p == null) return const AppSettings();
    return AppSettings(
      timeFormat24: p.getBool(_timeFormat24Key) ?? true,
      weekStartMonday: p.getBool(_weekStartMondayKey) ?? true,
      pdfNameFormat: _enumFromName(
          PdfNameFormat.values, p.getString(_pdfNameFormatKey),
          fallback: PdfNameFormat.full),
      notifications: {
        for (final n in NotifPref.values)
          n: p.getBool('$_notifPrefix${n.name}') ?? _notifDefaults[n]!,
      },
    );
  }

  void setTimeFormat24(bool v) {
    state = state.copyWith(timeFormat24: v);
    _prefs?.setBool(_timeFormat24Key, v);
  }

  void setWeekStartMonday(bool v) {
    state = state.copyWith(weekStartMonday: v);
    _prefs?.setBool(_weekStartMondayKey, v);
  }

  void setPdfNameFormat(PdfNameFormat v) {
    state = state.copyWith(pdfNameFormat: v);
    _prefs?.setString(_pdfNameFormatKey, v.name);
  }

  void setNotification(NotifPref pref, bool v) {
    state = state
        .copyWith(notifications: {...state.notifications, pref: v});
    _prefs?.setBool('$_notifPrefix${pref.name}', v);
  }
}

/// Theme mode, persisted. Kept as its own provider because the MaterialApp
/// watches it directly (moved here from ui_state.dart).
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _enumFromName(
      ThemeMode.values, _prefs?.getString(_themeKey),
      fallback: ThemeMode.light);

  void toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  /// Sets the mode explicitly (Light / Dark / System in Settings).
  void set(ThemeMode mode) {
    state = mode;
    _prefs?.setString(_themeKey, mode.name);
  }
}

T _enumFromName<T extends Enum>(List<T> values, String? name,
    {required T fallback}) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
