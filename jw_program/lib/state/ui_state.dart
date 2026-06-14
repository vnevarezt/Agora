import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assignment_ops.dart';

/// Ephemeral UI state (doesn't affect the PDF or the form).

/// Active shell section (sidebar): dashboard, participants or settings.
enum AppSection { home, participants, settings }

final appSectionProvider =
    NotifierProvider<AppSectionController, AppSection>(AppSectionController.new);

class AppSectionController extends Notifier<AppSection> {
  @override
  AppSection build() => AppSection.home;

  void select(AppSection section) => state = section;
}

/// Light/dark mode. In-memory only.
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() =>
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

  /// Sets the mode explicitly (Light / Dark / System in Settings).
  void set(ThemeMode mode) => state = mode;
}

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
