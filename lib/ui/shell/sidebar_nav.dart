import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../models/reminder.dart';
import '../../state/auth_session.dart';
import '../../state/dashboard_provider.dart';
import '../../state/sync_provider.dart';
import '../../state/ui_state.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';
import '../widgets/motion.dart';

/// Shell navigation items (same order in the side bar and the bottom
/// bar). Labels follow the active language. Each item pairs an outline icon
/// (inactive) with a filled variant (active) for the MD3 selection change.
List<({AppSection section, IconData icon, IconData activeIcon, String label})>
    _items(Translations tr) => [
      (
        section: AppSection.home,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: tr.nav.home,
      ),
      (
        section: AppSection.participants,
        icon: Icons.people_outline,
        activeIcon: Icons.people_rounded,
        label: tr.nav.participants,
      ),
      (
        section: AppSection.settings,
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: tr.nav.settings,
      ),
    ];

/// Number of urgent reminders; shown as a badge on "Inicio".
final _alertsProvider = Provider<int>((ref) => ref
    .watch(remindersProvider)
    .where((r) => r.type == ReminderType.alert)
    .length);

/// Icon that cross-fades (with a small scale pop) between its outline and
/// filled variants when the item selection changes — the MD3 destination cue.
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.color,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.fast,
      switchInCurve: Motion.curve,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.82, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: Icon(
        active ? activeIcon : icon,
        key: ValueKey(active),
        size: 21,
        color: color,
      ),
    );
  }
}

/// Side bar (`.sidebar`): brand, navigation and user card.
/// With [compact] it goes icon-only (64px) for tablet.
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final section = ref.watch(appSectionProvider);
    final user = ref.watch(sessionUserProvider);
    final alerts = ref.watch(_alertsProvider);
    final items = _items(context.t);

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
          for (final it in items) ...[
            _NavItem(
              section: it.section,
              icon: it.icon,
              activeIcon: it.activeIcon,
              label: it.label,
              compact: compact,
              active: section == it.section,
              badge: it.section == AppSection.home ? alerts : 0,
            ),
            const SizedBox(height: 2),
          ],
          const Spacer(),
          _UserCard(user: user, compact: compact),
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
              context.t.app.brand,
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

/// Navigation rail item (MD3): a rounded active-indicator surface that fades
/// in behind the selected destination, real ink ripple + state layers, and
/// the outline→filled icon transition.
class _NavItem extends ConsumerWidget {
  const _NavItem({
    required this.section,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.compact,
    required this.active,
    required this.badge,
  });

  final AppSection section;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool compact;
  final bool active;
  final int badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final fg = active ? t.accentStrong : t.textDim;
    final radius = BorderRadius.circular(12);

    final navIcon =
        _NavIcon(icon: icon, activeIcon: activeIcon, active: active, color: fg);

    final content = compact
        ? Center(
            child: badge > 0
                ? Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [navIcon, Positioned(top: -7, right: -9, child: _badge(t))],
                  )
                : navIcon,
          )
        : Row(
            children: [
              navIcon,
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
          );

    // Material animates its color (indicator fade in/out) and hosts the ink;
    // the InkWell overlay is a proper MD3 state layer tinted with the accent.
    Widget item = Material(
      color: active ? t.accentSoft : Colors.transparent,
      animationDuration: Motion.med,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(appSectionProvider.notifier).select(section),
        borderRadius: radius,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return t.accent.withValues(alpha: 0.13);
          }
          if (states.contains(WidgetState.hovered)) {
            return t.accent.withValues(alpha: 0.07);
          }
          return null;
        }),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 0 : 12,
            vertical: compact ? 11 : 10,
          ),
          child: content,
        ),
      ),
    );

    if (compact) item = Tooltip(message: label, child: item);
    return item;
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

/// User card at the bottom of the sidebar: avatar + name + account subtitle
/// ("Perfil local" / cloud email). Clicking it opens the session menu
/// (settings, lock, sign out); [compact] keeps just the avatar as the anchor.
class _UserCard extends ConsumerStatefulWidget {
  const _UserCard({required this.user, required this.compact});

  final ({String name, String email, AccountMode? mode}) user;
  final bool compact;

  @override
  ConsumerState<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<_UserCard> {
  // State-held so an open menu survives sidebar rebuilds (badge counts,
  // section changes…); a per-build controller would orphan it.
  final _menu = MenuController();

  void _toggle() => _menu.isOpen ? _menu.close() : _menu.open();

  Future<void> _signOut() async {
    await ref.read(cloudSignOutProvider)();
    // authStateChanges routes the session to CloudSignedOut.
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final user = widget.user;
    // No session user (locked or cloud identity still loading): hidden.
    if (user.name.isEmpty) return const SizedBox.shrink();

    final session = ref.watch(authSessionProvider);
    final unlocked = session is SessionUnlocked ? session : null;
    final localMode = unlocked?.mode == AccountMode.local;
    final cloudMode = unlocked?.mode == AccountMode.cloud;
    // Locking a cloud session only means something with the device gate on.
    final canLock =
        localMode || (cloudMode && (unlocked?.deviceUnlockEnabled ?? false));
    final subtitle = localMode
        ? tr.userMenu.localProfile
        : (user.email.isNotEmpty ? user.email : tr.userMenu.cloudAccount);

    return MenuAnchor(
      controller: _menu,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      menuChildren: [
        _UserMenu(
          items: [
            (
              icon: Icons.settings_outlined,
              label: tr.nav.settings,
              divider: false,
              onTap: () =>
                  ref.read(appSectionProvider.notifier).select(AppSection.settings),
            ),
            if (canLock)
              (
                icon: Icons.lock_outline,
                label: tr.security.lock,
                divider: true,
                onTap: ref.read(authSessionProvider.notifier).lock,
              ),
            if (cloudMode)
              (
                icon: Icons.logout,
                label: tr.account.signOut,
                divider: !canLock,
                onTap: _signOut,
              ),
          ],
          onPicked: _menu.close,
        ),
      ],
      builder: (context, controller, _) {
        if (widget.compact) {
          return Center(
            child: Tooltip(
              message: user.name,
              child: Pressable(
                onTap: _toggle,
                builder: (context, hovered, _) =>
                    PersonAvatar(name: user.name, size: 32),
              ),
            ),
          );
        }
        return Pressable(
          onTap: _toggle,
          builder: (context, hovered, _) {
            final open = controller.isOpen;
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: open ? t.accent : (hovered ? t.textMute : t.border2),
                ),
              ),
              child: Row(
                children: [
                  PersonAvatar(name: user.name, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
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
                          subtitle,
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
                  const SizedBox(width: 6),
                  Icon(Icons.unfold_more, size: 16, color: t.textMute),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

typedef _UserMenuEntry = ({
  IconData icon,
  String label,
  bool divider,
  VoidCallback onTap,
});

/// Menu surface for the user card (same look as the export menu).
class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.items, required this.onPicked});

  final List<_UserMenuEntry> items;
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 210,
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
          for (final it in items) ...[
            if (it.divider)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                color: t.border2,
              ),
            Pressable(
              onTap: () {
                onPicked();
                it.onTap();
              },
              builder: (context, hovered, _) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: hovered ? t.surface2 : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(it.icon, size: 17, color: t.textMute),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        it.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mobile bottom navigation (`.bottom-nav`): the Material 3 [NavigationBar],
/// themed to the app tokens. It brings the sliding pill indicator, the ink
/// ripple and the outline→filled icon change for free — and animates the same
/// way on every platform (the hand-rolled version stuttered on Windows).
class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final section = ref.watch(appSectionProvider);
    final alerts = ref.watch(_alertsProvider);
    final items = _items(context.t);
    final selected = items.indexWhere((e) => e.section == section);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: t.surface,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          indicatorColor: t.accentSoft,
          indicatorShape: const StadiumBorder(),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected)
                  ? t.accentStrong
                  : t.textMute,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: states.contains(WidgetState.selected)
                  ? t.accentStrong
                  : t.textMute,
            ),
          ),
        ),
        child: NavigationBar(
          height: 72,
          selectedIndex: selected < 0 ? 0 : selected,
          onDestinationSelected: (i) =>
              ref.read(appSectionProvider.notifier).select(items[i].section),
          destinations: [
            for (final it in items)
              NavigationDestination(
                icon: _navBadge(t, it.section, alerts, Icon(it.icon)),
                selectedIcon:
                    _navBadge(t, it.section, alerts, Icon(it.activeIcon)),
                label: it.label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _navBadge(AppTokens t, AppSection section, int alerts, Widget icon) =>
      (section == AppSection.home && alerts > 0)
          ? Badge(backgroundColor: t.accent, child: icon)
          : icon;
}
