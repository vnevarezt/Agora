import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/strings.g.dart';

/// Locale persistence. The chosen language survives restarts; on first run we
/// follow the device locale (falling back to the base locale if unsupported).

const _localeKey = 'app_locale';
SharedPreferences? _prefs;

/// Restores the saved locale, or follows the device locale on first run.
/// Call once in `main()` before `runApp`.
Future<void> initLocale() async {
  _prefs = await SharedPreferences.getInstance();
  final saved = _prefs!.getString(_localeKey);
  if (saved != null) {
    LocaleSettings.setLocaleRawSync(saved);
  } else {
    LocaleSettings.useDeviceLocaleSync();
  }
}

/// Persists the picked locale so it is restored on the next launch.
Future<void> persistLocale(AppLocale locale) async {
  _prefs ??= await SharedPreferences.getInstance();
  await _prefs!.setString(_localeKey, locale.languageTag);
}
