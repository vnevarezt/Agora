import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import 'assignment_ops.dart';
import 'locale_boot.dart';

/// Ephemeral UI state (doesn't affect the PDF or the form).

/// Active app language. Mirrors slang's [LocaleSettings] so the Settings
/// dropdown can read/set it like any other provider; the actual translation
/// switch + rebuild is driven by [TranslationProvider]. Persisted across
/// restarts (see [persistLocale]).
final localeProvider =
    NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

class LocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() => LocaleSettings.currentLocale;

  void set(AppLocale locale) {
    LocaleSettings.setLocaleSync(locale);
    state = locale;
    persistLocale(locale);
  }
}

/// Active shell section (sidebar): dashboard, participants or settings.
enum AppSection { home, participants, settings }

final appSectionProvider =
    NotifierProvider<AppSectionController, AppSection>(AppSectionController.new);

class AppSectionController extends Notifier<AppSection> {
  @override
  AppSection build() => AppSection.home;

  void select(AppSection section) => state = section;
}

// themeModeProvider moved to app_settings.dart (persisted now).

/// Active tab in the mobile layout.
enum MobileTab { assign, preview }

final mobileTabProvider =
    NotifierProvider<MobileTabController, MobileTab>(MobileTabController.new);

class MobileTabController extends Notifier<MobileTab> {
  @override
  MobileTab build() => MobileTab.assign;

  void select(MobileTab tab) => state = tab;
}

/// Slot whose picker is open; its card is highlighted with the accent ring.
final activeSlotProvider =
    NotifierProvider<ActiveSlotController, SlotRef?>(ActiveSlotController.new);

class ActiveSlotController extends Notifier<SlotRef?> {
  @override
  SlotRef? build() => null;

  void set(SlotRef? slot) => state = slot;
}

/// PDF export in progress: disables every export button (project bar and
/// mobile bottom bar) at once.
final exportBusyProvider =
    NotifierProvider<ExportBusyController, bool>(ExportBusyController.new);

class ExportBusyController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}
