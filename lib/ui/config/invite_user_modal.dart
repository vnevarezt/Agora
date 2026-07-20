import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/cck_service.dart';
import '../../data/sync/invite_code.dart';
import '../../i18n/strings.g.dart';
import '../../models/member_capabilities.dart';
import '../../state/sync_provider.dart';
import '../theme/tokens.dart';
import '../widgets/app_modal.dart';
import '../widgets/filter_pill.dart';
import '../widgets/modal_shell.dart';
import 'invite_code_modal.dart';

/// Opens the "invite someone" modal for [congregationId]. On success it
/// hands straight over to [showInviteCode] — the code is the deliverable,
/// and it is shown ONCE (nothing stores the secret).
Future<void> showInviteUser(BuildContext context, String congregationId) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) => InviteUserModal(
      congregationId: congregationId,
      sheet: sheet,
      onClose: close,
    ),
  );
}

class InviteUserModal extends ConsumerStatefulWidget {
  const InviteUserModal({
    super.key,
    required this.congregationId,
    required this.sheet,
    required this.onClose,
  });

  final String congregationId;
  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<InviteUserModal> createState() => _InviteUserModalState();
}

class _InviteUserModalState extends ConsumerState<InviteUserModal> {
  // Deliberately NOT an email: the data model has no way to invite one, and
  // asking for it promised something the rules never delivered.
  var _capabilities = const MemberCapabilities(people: true);
  bool _busy = false;
  String? _error;

  bool get _hasAny => _capabilities.canEditAnything;

  Future<void> _create() async {
    final cck = ref.read(cckServiceProvider);
    if (cck == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    InviteCode? code;
    try {
      code = await cck.createInvite(widget.congregationId,
          capabilities: _capabilities);
    } on SharingException catch (e) {
      if (mounted) setState(() => _error = _messageFor(context, e.reason));
    } catch (_) {
      if (mounted) setState(() => _error = context.t.invite.errorUnknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (code == null || !mounted) return;
    widget.onClose();
    await showInviteCode(context, code);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.invite.title,
      desc: tr.invite.desc,
      primaryLabel: tr.invite.create,
      primaryBusy: _busy,
      onPrimary: (_hasAny && !_busy) ? _create : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr.invite.capabilitiesDesc,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: t.textMute),
          ),
          const SizedBox(height: 12),
          // Toggling FilterPills rather than a new multi-select primitive:
          // three independent switches don't warrant one.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterPill(
                label: tr.invite.capAdmin,
                active: _capabilities.admin,
                onTap: () => setState(() => _capabilities = MemberCapabilities(
                      admin: !_capabilities.admin,
                      people: _capabilities.people,
                      editTypes: _capabilities.editTypes,
                    )),
              ),
              FilterPill(
                label: tr.invite.capPeople,
                active: _capabilities.people,
                onTap: () => setState(() => _capabilities = MemberCapabilities(
                      admin: _capabilities.admin,
                      people: !_capabilities.people,
                      editTypes: _capabilities.editTypes,
                    )),
              ),
              FilterPill(
                label: tr.invite.capPrograms,
                active: _capabilities.editTypes.isNotEmpty,
                onTap: () => setState(() => _capabilities = MemberCapabilities(
                      admin: _capabilities.admin,
                      people: _capabilities.people,
                      // '*' = every program type. Per-type invitations wait
                      // for the program type registry (out of scope here).
                      editTypes: _capabilities.editTypes.isEmpty
                          ? const [MemberCapabilities.everyType]
                          : const [],
                    )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CapabilityHint(capabilities: _capabilities),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Spells out what the picked capabilities actually allow, so an admin never
/// hands out `admin` by accident.
class _CapabilityHint extends StatelessWidget {
  const _CapabilityHint({required this.capabilities});

  final MemberCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final lines = [
      if (capabilities.admin) tr.invite.capAdminDesc,
      if (capabilities.people) tr.invite.capPeopleDesc,
      if (capabilities.editTypes.isNotEmpty) tr.invite.capProgramsDesc,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '· $line',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: t.textDim),
            ),
          ),
      ],
    );
  }
}

/// Maps a [SharingException] reason onto a localized message. Shared by
/// every sharing surface so the wording stays in one place.
String _messageFor(BuildContext context, String reason) {
  final tr = context.t.invite;
  return switch (reason) {
    'inviteMissing' => tr.errorMissing,
    'inviteExpired' => tr.errorExpired,
    'alreadyMember' => tr.errorAlreadyMember,
    'keysUnavailable' => tr.errorKeys,
    _ => tr.errorUnknown,
  };
}

String sharingMessage(BuildContext context, Object error) => switch (error) {
      SharingException(:final reason) => _messageFor(context, reason),
      InviteCodeException() => context.t.invite.errorInvalid,
      _ => context.t.invite.errorUnknown,
    };
