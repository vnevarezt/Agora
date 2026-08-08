import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/strings.g.dart';

/// Locale persistence. The chosen language survives restarts; on first run we
/// follow the device locale (falling back to the base locale if unsupported).

const _localeKey = 'app_locale';
SharedPreferences? _prefs;

/// Languages offered to the user — NOT [AppLocale.values], which includes
/// catalogs too incomplete to ship. `fallback_strategy: base_locale` renders
/// their gaps in Spanish with no warning. See lib/i18n/README.md.
const List<AppLocale> shippedLocales = [AppLocale.es, AppLocale.en];

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
  // The device locale, or a value saved by a build that still offered it.
  if (!shippedLocales.contains(LocaleSettings.currentLocale)) {
    LocaleSettings.setLocaleSync(AppLocale.es);
  }
}

/// Persists the picked locale so it is restored on the next launch.
Future<void> persistLocale(AppLocale locale) async {
  _prefs ??= await SharedPreferences.getInstance();
  await _prefs!.setString(_localeKey, locale.languageTag);
}
