// Persisted app settings (SharedPreferences mocked): defaults on first run,
// restore on boot, and setters that survive a "restart" (fresh container).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/state/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('first run: defaults', () async {
    SharedPreferences.setMockInitialValues({});
    await initAppSettings();
    final c = container();
    final s = c.read(appSettingsProvider);
    expect(s.timeFormat24, true);
    expect(s.weekStartMonday, true);
    expect(s.pdfNameFormat, PdfNameFormat.full);
    expect(s.notifications[NotifPref.exports], false);
    expect(c.read(themeModeProvider), ThemeMode.light);
  });

  test('setters persist and are restored by a fresh container', () async {
    SharedPreferences.setMockInitialValues({});
    await initAppSettings();

    final c1 = container();
    c1.read(appSettingsProvider.notifier)
      ..setTimeFormat24(false)
      ..setPdfNameFormat(PdfNameFormat.lastFirst)
      ..setNotification(NotifPref.exports, true);
    c1.read(themeModeProvider.notifier).set(ThemeMode.dark);

    // A new container simulates a restart: providers rebuild from prefs.
    final c2 = container();
    final s = c2.read(appSettingsProvider);
    expect(s.timeFormat24, false);
    expect(s.pdfNameFormat, PdfNameFormat.lastFirst);
    expect(s.notifications[NotifPref.exports], true);
    expect(s.notifications[NotifPref.unassigned], true); // untouched default
    expect(c2.read(themeModeProvider), ThemeMode.dark);
  });

  test('corrupt stored enum falls back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'neon',
      'pdf_name_format': 'nope',
    });
    await initAppSettings();
    final c = container();
    expect(c.read(themeModeProvider), ThemeMode.light);
    expect(c.read(appSettingsProvider).pdfNameFormat, PdfNameFormat.full);
  });
}
