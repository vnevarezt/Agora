import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reminder.dart';
import '../../state/dashboard_provider.dart';
import '../../state/ui_state.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';

/// Ítems de navegación del shell (mismo orden en barra lateral y barra
/// inferior).
const _items = <({AppSection section, IconData icon, String label})>[
  (section: AppSection.home, icon: Icons.home_outlined, label: 'Inicio'),
  (section: AppSection.participants, icon: Icons.people_outline, label: 'Participantes'),
  (
    section: AppSection.settings,
    icon: Icons.settings_outlined,
    label: 'Configuración'
  ),
];

/// Nº de reminders urgentes; se muestra como badge en "Inicio".
final _alertsProvider = Provider<int>((ref) => ref
    .watch(remindersProvider)
    .where((r) => r.type == ReminderType.alert)
    .length);

/// Barra lateral (`.sidebar`): marca, navegación y tarjeta de user.
/// Con [compact] queda en modo solo-iconos (64px) para tablet.
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final section = ref.watch(appSectionProvider);
    final user = ref.watch(sessionUserProvider);
    final alerts = ref.watch(_alertsProvider);

    return Container(
      width: compact ? 64 : 232,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(right: BorderSide(color: t.border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Brand(compact: compact),
          const SizedBox(height: 6),
          for (final it in _items) ...[
            _NavItem(
              section: it.section,
              icon: it.icon,
              label: it.label,
              compact: compact,
              active: section == it.section,
              badge: it.section == AppSection.home ? alerts : 0,
            ),
            const SizedBox(height: 2),
          ],
          const Spacer(),
          _UserCard(
            name: user.name,
            role: user.role,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final mark = Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.accent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        'JW',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: t.accentInk,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 0 : 4, 4, 4, 10),
      child: Row(
        mainAxisAlignment:
            compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          mark,
          if (!compact) ...[
            const SizedBox(width: 10),
            Text(
              'Programa',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: t.text,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  const _NavItem({
    required this.section,
    required this.icon,
    required this.label,
    required this.compact,
    required this.active,
    required this.badge,
  });

  final AppSection section;
  final IconData icon;
  final String label;
  final bool compact;
  final bool active;
  final int badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return Pressable(
      onTap: () => ref.read(appSectionProvider.notifier).seleccionar(section),
      tooltip: compact ? label : null,
      builder: (context, hovered, _) {
        final fg = active ? t.accentStrong : (hovered ? t.text : t.textDim);
        final bg = active
            ? t.accentSoft
            : (hovered ? t.surface2 : Colors.transparent);
        final ic = Icon(icon, size: 18, color: fg);

        return AnimatedContainer(
          duration: Dimens.dFast,
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 12, vertical: compact ? 11 : 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: compact
              ? (badge > 0
                  ? Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        ic,
                        Positioned(top: -7, right: -9, child: _badge(t)),
                      ],
                    )
                  : Center(child: ic))
              : Row(
                  children: [
                    ic,
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                    if (badge > 0) _badge(t),
                  ],
                ),
        );
      },
    );
  }

  Widget _badge(AppTokens t) => Container(
        constraints: const BoxConstraints(minWidth: 19),
        height: 19,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$badge',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: t.accentInk,
          ),
        ),
      );
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.name,
    required this.role,
    required this.compact,
  });

  final String name;
  final String role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Sin user en sesión (sin backend) no se muestra la tarjeta.
    if (name.isEmpty) return const SizedBox.shrink();
    if (compact) {
      return Center(child: PersonAvatar(name: name, size: 32));
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border2),
      ),
      child: Row(
        children: [
          PersonAvatar(name: name, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: t.text,
                  ),
                ),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de navegación inferior para móvil (`.bottom-nav`).
class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final section = ref.watch(appSectionProvider);
    final alerts = ref.watch(_alertsProvider);

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Row(
            children: [
              for (final it in _items)
                Expanded(
                  child: _BottomItem(
                    section: it.section,
                    icon: it.icon,
                    label: it.label,
                    active: section == it.section,
                    badge: it.section == AppSection.home ? alerts : 0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends ConsumerWidget {
  const _BottomItem({
    required this.section,
    required this.icon,
    required this.label,
    required this.active,
    required this.badge,
  });

  final AppSection section;
  final IconData icon;
  final String label;
  final bool active;
  final int badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final fg = active ? t.accentStrong : t.textMute;

    return Pressable(
      onTap: () => ref.read(appSectionProvider.notifier).seleccionar(section),
      builder: (context, hovered, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 21, color: fg),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: t.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
