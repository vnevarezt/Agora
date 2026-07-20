import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config_options.dart';
import '../../i18n/strings.g.dart';
import '../../models/congregation.dart';
import '../../models/congregation_invite.dart';
import '../../models/congregation_member.dart';
import '../../models/congregation_settings.dart';
import '../../models/member_capabilities.dart';
import '../../state/dashboard_provider.dart';
import '../../state/sync_provider.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/dashed_border.dart';
import '../widgets/labeled_field.dart';
import 'invite_user_modal.dart';
import 'join_congregation_modal.dart';
import 'member_access_modal.dart';
import 'new_congregation_modal.dart';
import 'settings_card.dart';
import 'user_row.dart';

/// Settings "Congregación" tab. Congregation selector + details and
/// schedule, seeded from the DB row and persisted on edit (debounced).
class CongregationTab extends ConsumerStatefulWidget {
  const CongregationTab({super.key});

  @override
  ConsumerState<CongregationTab> createState() => _CongregationTabState();
}

class _CongregationTabState extends ConsumerState<CongregationTab> {
  String? _congregationId;
  String _name = '';
  String _number = '';
  String _language = meetingLanguages.first;
  String _weekdayDay = daysOfWeek[1]; // Tuesday
  String _weekdayTime = '19:00';
  String _weekendDay = daysOfWeek[6]; // Sunday
  String _weekendTime = '10:00';
  bool _auxRoom = false;

  Timer? _saveDebounce;

  @override
  void dispose() {
    // Flush a pending save so the last keystroke is never lost.
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce!.cancel();
      _persist();
    }
    super.dispose();
  }

  /// Selects a congregation and seeds the fields from its stored row
  /// (schedule/language live in settingsJson).
  void _select(Congregation congregation, {bool notify = true}) {
    // Switching away flushes edits of the previous congregation.
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce!.cancel();
      _persist();
    }

    void apply() {
      final s = congregation.settings;
      final languageIndex =
          congregationLanguageCodes.indexOf(s.meetingLanguage);
      _congregationId = congregation.id;
      _name = congregation.name;
      _number = congregation.number;
      _language = meetingLanguages[languageIndex < 0 ? 0 : languageIndex];
      _weekdayDay = daysOfWeek[s.midweekDay];
      _weekdayTime = s.midweekTime;
      _weekendDay = daysOfWeek[s.weekendDay];
      _weekendTime = s.weekendTime;
      _auxRoom = s.auxRoom;
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  /// Persists the current fields (debounced: text fields fire per
  /// keystroke). Captured id guards against saving onto a new selection.
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), _persist);
  }

  void _persist() {
    final id = _congregationId;
    if (id == null || _name.trim().isEmpty) return;
    // Re-checked here, not only on the widgets: this also runs from a
    // debounce timer and from dispose(), either of which can fire after the
    // capabilities changed under us.
    if (!ref.read(rightsProvider(id)).admin) return;
    final languageIndex = meetingLanguages.indexOf(_language);
    // indexOf is -1 if the app locale changed under us (localized labels):
    // fall back to the schema defaults rather than storing garbage.
    final midweekDay = daysOfWeek.indexOf(_weekdayDay);
    final weekendDay = daysOfWeek.indexOf(_weekendDay);
    ref.read(congregationActionsProvider).update(
          id,
          name: _name.trim(),
          number: _number.trim(),
          settings: CongregationSettings(
            meetingLanguage: congregationLanguageCodes[
                languageIndex < 0 ? 0 : languageIndex],
            midweekDay: midweekDay < 0 ? 1 : midweekDay,
            midweekTime: _weekdayTime.trim(),
            weekendDay: weekendDay < 0 ? 6 : weekendDay,
            weekendTime: _weekendTime.trim(),
            auxRoom: _auxRoom,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final congregations = ref.watch(congregationsProvider);

    // Keep a valid selection (the list changes in memory).
    if (congregations.isEmpty) {
      _congregationId = null;
    } else if (_congregationId == null || !congregations.any((c) => c.id == _congregationId)) {
      _select(congregations.first, notify: false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _congregationSelector(congregations),
        const SizedBox(height: 16),
        if (congregations.isEmpty)
          _empty(context)
        else
          SettingsColumns(
            left: [_dataCard(), _scheduleCard()],
            right: [_usersCard()],
          ),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return EmptyState(
      icon: Icons.apartment_outlined,
      message: context.t.congregation.empty,
    );
  }

  Widget _congregationSelector(List<Congregation> congregations) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in congregations)
          _CongregationChip(
            congregation: c,
            acceso: '',
            active: _congregationId == c.id,
            onTap: () => _select(c),
          ),
        _AddChip(onTap: () => showNewCongregation(context)),
      ],
    );
  }

  /// Whether this user may edit the congregation row itself.
  ///
  /// The most dangerous gate in the app: every keystroke here auto-saves,
  /// which enqueues a `congregation` item, which the rules only accept from
  /// an admin. Ungated, a non-admin typing in this card would fail the whole
  /// push batch and block their legitimate people/program writes behind it.
  bool get _canEditCongregation {
    final cid = _congregationId;
    return cid == null || ref.watch(rightsProvider(cid)).admin;
  }

  Widget _dataCard() {
    final t = context.tokens;
    final tr = context.t;
    final editable = _canEditCongregation;
    return SettingsCard(
      title: tr.congregation.dataTitle,
      desc: tr.congregation.dataDesc,
      children: [
        SettingsGrid(
          children: [
            LabeledField(
              label: tr.congregation.name,
              child: BoundTextField(
                key: ValueKey('$_congregationId-name'),
                initial: _name,
                enabled: editable,
                onChanged: (v) {
                  _name = v;
                  _scheduleSave();
                },
              ),
            ),
            LabeledField(
              label: tr.congregation.number,
              child: BoundTextField(
                key: ValueKey('$_congregationId-number'),
                initial: _number,
                enabled: editable,
                style: AppText.mono(size: 13.5, color: t.text),
                onChanged: (v) {
                  _number = v;
                  _scheduleSave();
                },
              ),
            ),
            LabeledField(
              label: tr.congregation.meetingLanguage,
              child: AppDropdown<String>(
                value: meetingLanguages.contains(_language)
                    ? _language
                    : meetingLanguages.first,
                items: meetingLanguages,
                itemLabel: (s) => s,
                onChanged: !editable
                    ? null
                    : (v) {
                        setState(() => _language = v);
                        _scheduleSave();
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _scheduleCard() {
    final t = context.tokens;
    final tr = context.t;
    final mono = AppText.mono(size: 13.5, color: t.text);
    // Same `congregation` item as _dataCard, same admin gate.
    final editable = _canEditCongregation;
    return SettingsCard(
      title: tr.congregation.scheduleTitle,
      desc: tr.congregation.scheduleDesc,
      children: [
        SettingsGrid(
          children: [
            LabeledField(
              label: tr.congregation.weekdayDay,
              child: AppDropdown<String>(
                value:
                    daysOfWeek.contains(_weekdayDay) ? _weekdayDay : daysOfWeek[1],
                items: daysOfWeek,
                itemLabel: (s) => s,
                onChanged: !editable
                    ? null
                    : (v) {
                        setState(() => _weekdayDay = v);
                        _scheduleSave();
                      },
              ),
            ),
            LabeledField(
              label: tr.congregation.weekdayTime,
              child: BoundTextField(
                key: ValueKey('$_congregationId-he'),
                initial: _weekdayTime,
                enabled: editable,
                style: mono,
                onChanged: (v) {
                  _weekdayTime = v;
                  _scheduleSave();
                },
              ),
            ),
            LabeledField(
              label: tr.congregation.weekendDay,
              child: AppDropdown<String>(
                value:
                    daysOfWeek.contains(_weekendDay) ? _weekendDay : daysOfWeek[6],
                items: daysOfWeek,
                itemLabel: (s) => s,
                onChanged: !editable
                    ? null
                    : (v) {
                        setState(() => _weekendDay = v);
                        _scheduleSave();
                      },
              ),
            ),
            LabeledField(
              label: tr.congregation.weekendTime,
              child: BoundTextField(
                key: ValueKey('$_congregationId-hf'),
                initial: _weekendTime,
                enabled: editable,
                style: mono,
                onChanged: (v) {
                  _weekendTime = v;
                  _scheduleSave();
                },
              ),
            ),
          ],
        ),
        SettingRow(
          title: tr.congregation.auxRoom,
          subtitle: tr.congregation.auxRoomDesc,
          trailing: Transform.scale(
            scale: 0.85,
            child: Switch(
              value: _auxRoom,
              onChanged: !editable
                  ? null
                  : (v) {
                      setState(() => _auxRoom = v);
                      _scheduleSave();
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _usersCard() {
    final t = context.tokens;
    final tr = context.t;
    final cid = _congregationId;
    // Putting a congregation in the cloud is not a per-congregation decision
    // the user takes: SyncController enables every local congregation once
    // the sync keys are ready. You can only invite into a space that exists,
    // and only as an admin.
    final synced = cid != null && ref.watch(isCongregationSyncedProvider(cid));
    final canInvite = synced && ref.watch(rightsProvider(cid)).admin;

    final isAdmin = canInvite;
    final members = cid == null
        ? const AsyncValue<List<CongregationMember>>.data([])
        : ref.watch(congregationMembersProvider(cid));
    // Only an admin may list invites (the rules deny everyone else), so
    // don't even open that listener for the rest.
    final invites = (cid == null || !isAdmin)
        ? const AsyncValue<List<CongregationInvite>>.data([])
        : ref.watch(congregationInvitesProvider(cid));
    final myUid = ref.watch(syncUidProvider);
    final adminCount =
        (members.value ?? const []).where((m) => m.capabilities.admin).length;

    return SettingsCard(
      title: tr.congregation.usersTitle,
      desc: tr.congregation.usersDesc,
      children: [
        switch (members) {
          AsyncError() => _hint(t, tr.congregation.membersError),
          AsyncValue(value: final rows?) when rows.isNotEmpty =>
            Column(
              children: [
                for (final (i, m) in rows.indexed)
                  UserRow(
                    first: i == 0,
                    name: _memberName(m, tr, isMe: m.uid == myUid),
                    email: m.email ?? '',
                    trailing: RolePill(role: _roleLabel(m.capabilities, tr)),
                    // Editing your own row is allowed on purpose: it is how
                    // a departing admin hands over and leaves.
                    onTap: !isAdmin
                        ? null
                        : () => showMemberAccess(
                              context,
                              congregationId: cid,
                              member: m,
                              adminCount: adminCount,
                            ),
                  ),
              ],
            ),
          _ => _hint(t, tr.congregation.noUsers),
        },
        if ((invites.value ?? const []).isNotEmpty) ...[
          const SizedBox(height: 14),
          _hint(t, tr.congregation.pendingLabel),
          for (final invite in invites.value!)
            _PendingInvite(
              invite: invite,
              onCancel: () => ref
                  .read(cckServiceProvider)
                  ?.cancelInvite(cid!, invite.tokenId),
            ),
        ],
        if (!isAdmin && cid != null && synced) ...[
          const SizedBox(height: 10),
          _hint(t, tr.congregation.readOnly),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton(
              variant: AppButtonVariant.ghost,
              icon: Icons.person_add_alt,
              label: tr.congregation.inviteUser,
              onPressed: canInvite ? () => showInviteUser(context, cid) : null,
            ),
            AppButton(
              variant: AppButtonVariant.ghost,
              icon: Icons.vpn_key_outlined,
              label: tr.congregation.joinWithCode,
              onPressed: () => showJoinCongregation(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hint(AppTokens t, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: t.textMute),
        ),
      );

  String _memberName(
    CongregationMember m,
    Translations tr, {
    required bool isMe,
  }) {
    final name = m.displayName ?? m.email ?? m.uid;
    return isMe ? '$name (${tr.congregation.you})' : name;
  }

  /// One pill for what is really three independent switches — the row is a
  /// summary; the modal shows the actual capabilities.
  String _roleLabel(MemberCapabilities caps, Translations tr) {
    if (caps.admin) return tr.congregation.roleAdmin;
    if (caps.canEditAnything) return tr.congregation.roleEditor;
    return tr.congregation.roleViewer;
  }
}

/// A pending invite: nobody has redeemed it yet, and an admin can cancel it.
class _PendingInvite extends StatelessWidget {
  const _PendingInvite({required this.invite, required this.onCancel});

  final CongregationInvite invite;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final expiresAt = invite.expiresAt;
    final label = expiresAt == null
        ? ''
        : invite.isExpired(DateTime.now().toUtc())
            ? tr.invite.expired
            : tr.invite.expiresOn(
                date: MaterialLocalizations.of(context)
                    .formatShortDate(expiresAt.toLocal()));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.mail_outline, size: 16, color: t.textMute),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: t.textMute),
            ),
          ),
          AppButton(
            variant: AppButtonVariant.ghost,
            icon: Icons.close,
            label: tr.invite.cancel,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

/// Congregation selector chip: color dot + name + role pill.
class _CongregationChip extends StatelessWidget {
  const _CongregationChip({
    required this.congregation,
    required this.acceso,
    required this.active,
    required this.onTap,
  });

  final Congregation congregation;
  final String acceso;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        final fg = active ? t.accentInk : (hovered ? t.text : t.textDim);
        return AnimatedContainer(
          duration: Dimens.dFast,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: active ? t.accent : t.surface,
            borderRadius: BorderRadius.circular(Dimens.rPill),
            border: Border.all(
              color: active ? t.accent : (hovered ? t.accent : t.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(congregation.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                congregation.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (acceso.isNotEmpty) ...[
                const SizedBox(width: 8),
                RolePill(role: acceso),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Dashed "Nueva congregación" chip (`.chip--add`).
class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        final fg = t.accentStrong;
        return DashedBorder(
          color: hovered ? t.accent : t.border,
          radius: Dimens.rPill,
          child: AnimatedContainer(
            duration: Dimens.dFast,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: hovered ? t.accentTint : Colors.transparent,
              borderRadius: BorderRadius.circular(Dimens.rPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 15, color: fg),
                const SizedBox(width: 6),
                Text(
                  context.t.congregation.newCongregation,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
