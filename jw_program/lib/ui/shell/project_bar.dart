import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/congregation.dart';
import '../../models/project.dart';
import '../../state/dashboard_provider.dart';
import '../../state/preview_provider.dart';
import '../../state/program_form.dart';
import '../../state/progress_provider.dart';
import '../../state/ui_state.dart';
import '../../state/weeks_provider.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/progress_meter.dart';
import '../widgets/progress_ring.dart';

/// Barra del editor (`.projbar`): identidad del proyecto, progreso, selector
/// de semanas y exportar. Reemplaza a la antigua barra de contexto.
class ProjectBar extends ConsumerWidget {
  const ProjectBar({super.key, this.proyecto});

  final Proyecto? proyecto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 10),
        child: isMobile ? _mobile(context, ref, t) : _desktop(context, ref, t),
      ),
    );
  }

  Widget _desktop(BuildContext context, WidgetRef ref, AppTokens t) {
    final progreso = ref.watch(progresoProyectoProvider);
    return Row(
      children: [
        _back(context),
        const SizedBox(width: 14),
        Flexible(child: _ProjId(proyecto: proyecto)),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: t.border2)),
          ),
          child: ProgressRing(
            done: progreso.done,
            total: progreso.total,
            showLabel: true,
          ),
        ),
        const Spacer(),
        const _WeekNav(),
        const SizedBox(width: 12),
        const _ExportMenu(),
      ],
    );
  }

  Widget _mobile(BuildContext context, WidgetRef ref, AppTokens t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _back(context),
            const SizedBox(width: 10),
            Expanded(child: _ProjId(proyecto: proyecto)),
            const SizedBox(width: 10),
            const _ExportMenu(compact: true),
          ],
        ),
        const SizedBox(height: 8),
        const _WeekNav(expand: true),
      ],
    );
  }

  Widget _back(BuildContext context) => AppIconButton(
        icon: Icons.arrow_back,
        bordered: true,
        tooltip: 'Volver al panel',
        onPressed: () => Navigator.of(context).maybePop(),
      );
}

/// Identidad del proyecto: nombre + congregación + nº de semanas.
class _ProjId extends ConsumerWidget {
  const _ProjId({this.proyecto});

  final Proyecto? proyecto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final congs = ref.watch(congregacionesDashProvider);
    final nSemanas = ref.watch(weeksProvider).asData?.value.length ?? 0;

    final Congregacion? cong = proyecto == null
        ? null
        : congs.where((c) => c.id == proyecto!.congregacionId).firstOrNull;
    final nombre = proyecto?.nombre ?? 'Programa';
    final congNombre =
        cong?.nombre ?? (proyecto == null ? ref.watch(formProvider).cong : '');
    final congColor = cong == null ? t.accent : Color(cong.color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.34,
            color: t.text,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: congColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      congNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: t.textMute,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (nSemanas > 0) ...[
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.only(left: 9),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: t.border2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers_outlined, size: 13, color: t.textMute),
                    const SizedBox(width: 4),
                    Text(
                      '$nSemanas ${nSemanas == 1 ? 'semana' : 'semanas'}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: t.textMute,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Selector de semanas (`.week-nav`): flechas + botón central con popover
/// "Ir a la semana".
class _WeekNav extends ConsumerStatefulWidget {
  const _WeekNav({this.expand = false});

  final bool expand;

  @override
  ConsumerState<_WeekNav> createState() => _WeekNavState();
}

class _WeekNavState extends ConsumerState<_WeekNav> {
  final MenuController _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final weeks = ref.watch(weeksProvider).asData?.value ?? const [];
    final idx = ref.watch(formProvider.select((f) => f.semanaIdx));
    final progreso = ref.watch(progressProvider);
    final notifier = ref.read(formProvider.notifier);

    final n = weeks.length;
    final activo = n == 0 ? 0 : idx.clamp(0, n - 1);
    final fecha = n == 0 ? '—' : weeks[activo].fecha;
    final done = progreso.done == progreso.total && progreso.total > 0;

    void go(int d) {
      if (n == 0) return;
      notifier.seleccionarSemana((activo + d).clamp(0, n - 1));
    }

    final current = MenuAnchor(
      controller: _menu,
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      menuChildren: [
        _WeekMenu(
          weeks: weeks,
          activo: activo,
          onPick: (i) {
            notifier.seleccionarSemana(i);
            _menu.close();
          },
        ),
      ],
      builder: (context, controller, _) {
        return Pressable(
          onTap: n == 0 ? null : () => controller.isOpen
              ? controller.close()
              : controller.open(),
          builder: (context, hovered, _) {
            final open = controller.isOpen;
            return Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(Dimens.rControl),
                border: Border.all(
                  color: open ? t.accent : (hovered ? t.textMute : t.border),
                ),
                boxShadow: open
                    ? [
                        BoxShadow(
                            color: t.accentSoft,
                            blurRadius: 0,
                            spreadRadius: 3),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Expanded(
                    flex: widget.expand ? 1 : 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: 'Semana ${n == 0 ? '—' : activo + 1}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: t.textMute,
                            ),
                            children: [
                              TextSpan(
                                text: ' / $n',
                                style: TextStyle(
                                    color: t.textMute.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          fecha,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.mono(
                              size: 14, weight: FontWeight.w800, color: t.text),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _PctBadge(
                      done: done, label: '${progreso.done}/${progreso.total}'),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: Dimens.dFast,
                    child: Icon(Icons.expand_more, size: 16, color: t.textMute),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _Arrow(icon: Icons.chevron_left, onTap: activo == 0 ? null : () => go(-1)),
        const SizedBox(width: 6),
        widget.expand ? Expanded(child: current) : current,
        const SizedBox(width: 6),
        _Arrow(
            icon: Icons.chevron_right,
            onTap: (n == 0 || activo >= n - 1) ? null : () => go(1)),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final habilitado = onTap != null;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hovered && habilitado ? t.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimens.rControl),
        ),
        child: Icon(
          icon,
          size: 20,
          color: habilitado ? t.textDim : t.textMute.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _PctBadge extends StatelessWidget {
  const _PctBadge({required this.done, required this.label});

  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: done
          ? const EdgeInsets.all(3)
          : const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: done ? t.accent : t.surface2,
        borderRadius: BorderRadius.circular(Dimens.rPill),
        border: done ? null : Border.all(color: t.border2),
      ),
      child: done
          ? Icon(Icons.check, size: 13, color: t.accentInk)
          : Text(
              label,
              style: AppText.mono(
                  size: 11, weight: FontWeight.w700, color: t.textDim),
            ),
    );
  }
}

/// Contenido del popover "Ir a la semana" (`.week-menu`) + toggle Sala auxiliar.
class _WeekMenu extends ConsumerWidget {
  const _WeekMenu({
    required this.weeks,
    required this.activo,
    required this.onPick,
  });

  final List weeks;
  final int activo;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final aux = ref.watch(formProvider.select((f) => f.aux));
    final progresos = ref.watch(progresoPorSemanaProvider);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
            child: Text(
              'IR A LA SEMANA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: t.textMute,
              ),
            ),
          ),
          for (var i = 0; i < weeks.length; i++)
            Builder(builder: (context) {
              final pr = i < progresos.length
                  ? progresos[i]
                  : (done: 0, total: 0);
              final completo = pr.total > 0 && pr.done == pr.total;
              return Pressable(
                onTap: () => onPick(i),
                builder: (context, hovered, _) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: i == activo
                        ? t.accentTint
                        : (hovered ? t.surface2 : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: Text(
                          'SEM ${i + 1}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: i == activo ? t.accentStrong : t.textMute,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 76,
                        child: Text(
                          weeks[i].fecha as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.mono(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: t.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ProgressMeter(
                          value: pr.total == 0 ? 0 : pr.done / pr.total,
                          height: 4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: completo
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: t.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check,
                                      size: 12, color: t.accentInk),
                                ),
                              )
                            : Text(
                                '${pr.done}/${pr.total}',
                                textAlign: TextAlign.right,
                                style: AppText.mono(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: t.textMute),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: t.border2,
          ),
          _AuxToggle(
            aux: aux,
            onChanged: (v) => ref.read(formProvider.notifier).setAux(v),
          ),
        ],
      ),
    );
  }
}

class _AuxToggle extends StatelessWidget {
  const _AuxToggle({required this.aux, required this.onChanged});

  final bool aux;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: () => onChanged(!aux),
      builder: (context, hovered, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: hovered ? t.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.apartment_outlined,
                size: 16, color: aux ? t.accentStrong : t.textMute),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sala auxiliar',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.text)),
                  Text('Segunda sala para estudiantes',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: t.textMute)),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(value: aux, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón Exportar con menú (`.menu`): semana actual (real), proyecto y hojas
/// (UI por ahora).
class _ExportMenu extends ConsumerWidget {
  const _ExportMenu({this.compact = false});

  final bool compact;

  Future<void> _exportarSemana(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    ref.read(exportBusyProvider.notifier).set(true);
    try {
      final ruta = await ref.read(previewProvider.notifier).exportar();
      messenger.showSnackBar(SnackBar(content: Text('PDF exportado: $ruta')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
    } finally {
      ref.read(exportBusyProvider.notifier).set(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(exportBusyProvider);
    final haySemana = ref.watch(scheduleProvider) != null;
    final menu = MenuController();

    return MenuAnchor(
      controller: menu,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      menuChildren: [
        _ExportCard(
          haySemana: haySemana,
          onSemana: () {
            menu.close();
            _exportarSemana(context, ref);
          },
        ),
      ],
      builder: (context, controller, _) {
        return AppButton(
          icon: Icons.ios_share,
          label: compact ? null : 'Exportar',
          busy: busy,
          onPressed: busy
              ? null
              : () => controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.haySemana, required this.onSemana});

  final bool haySemana;
  final VoidCallback onSemana;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 268,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExportItem(
            icon: Icons.description_outlined,
            titulo: 'Semana actual',
            sub: 'Una hoja PDF',
            onTap: haySemana ? onSemana : null,
          ),
          _ExportItem(
            icon: Icons.layers_outlined,
            titulo: 'Proyecto completo',
            sub: 'Todas las semanas en un PDF',
            onTap: null, // próximamente
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: t.border2,
          ),
          _ExportItem(
            icon: Icons.list_alt_outlined,
            titulo: 'Hojas de participación',
            sub: 'Una por hermano asignado',
            onTap: null, // próximamente
          ),
        ],
      ),
    );
  }
}

class _ExportItem extends StatelessWidget {
  const _ExportItem({
    required this.icon,
    required this.titulo,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final habilitado = onTap != null;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => Opacity(
        opacity: habilitado ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: hovered && habilitado ? t.surface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: t.textMute),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: t.text)),
                    Text(sub,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: t.textMute)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
