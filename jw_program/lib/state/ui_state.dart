import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assignment_ops.dart';

/// Estado efímero de la UI (no afecta al PDF ni al formulario).

/// Sección activa del shell (barra lateral): dashboard, hermanos o config.
enum AppSeccion { inicio, hermanos, config }

final appSeccionProvider =
    NotifierProvider<AppSeccionController, AppSeccion>(AppSeccionController.new);

class AppSeccionController extends Notifier<AppSeccion> {
  @override
  AppSeccion build() => AppSeccion.inicio;

  void seleccionar(AppSeccion seccion) => state = seccion;
}

/// Modo claro/oscuro, alternado desde la barra de contexto. Solo en memoria.
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void alternar() =>
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

  /// Fija el modo explícitamente (Claro / Oscuro / Sistema en Configuración).
  void set(ThemeMode modo) => state = modo;
}

/// Pestaña activa en el layout móvil.
enum MobileTab { asignar, vista }

final mobileTabProvider =
    NotifierProvider<MobileTabController, MobileTab>(MobileTabController.new);

class MobileTabController extends Notifier<MobileTab> {
  @override
  MobileTab build() => MobileTab.asignar;

  void seleccionar(MobileTab tab) => state = tab;
}

/// Panel de configuración (cuaderno/semana/inicio/congregación) expandido.
final configExpandedProvider =
    NotifierProvider<ConfigExpandedController, bool>(
        ConfigExpandedController.new);

class ConfigExpandedController extends Notifier<bool> {
  @override
  bool build() => false;

  void alternar() => state = !state;
  void cerrar() => state = false;
}

/// Slot cuyo picker está abierto; su tarjeta se resalta con el ring accent.
final activeSlotProvider =
    NotifierProvider<ActiveSlotController, SlotRef?>(ActiveSlotController.new);

class ActiveSlotController extends Notifier<SlotRef?> {
  @override
  SlotRef? build() => null;

  void set(SlotRef? slot) => state = slot;
}

/// Exportación de PDF en curso: deshabilita todos los botones de exportar
/// (barra de contexto y bottom bar móvil) a la vez.
final exportBusyProvider =
    NotifierProvider<ExportBusyController, bool>(ExportBusyController.new);

class ExportBusyController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}
