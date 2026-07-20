import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../models/congregation_member.dart';
import '../../models/member_capabilities.dart';
import '../../state/sync_provider.dart';
import '../theme/tokens.dart';
import '../widgets/app_modal.dart';
import '../widgets/filter_pill.dart';
import '../widgets/modal_shell.dart';
import 'invite_user_modal.dart' show sharingMessage;

/// Edits one member's capabilities, or removes them entirely.
///
/// Removal is the only action that rotates the key — a downgrade doesn't
/// need to (the member keeps a keyring for history they already hold, and
/// the rules stop their writes from here on).
Future<void> showMemberAccess(
  BuildContext context, {
  required String congregationId,
  required CongregationMember member,
  required int adminCount,
}) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) => MemberAccessModal(
      congregationId: congregationId,
      member: member,
      adminCount: adminCount,
      sheet: sheet,
      onClose: close,
    ),
  );
}

class MemberAccessModal extends ConsumerStatefulWidget {
  const MemberAccessModal({
    super.key,
    required this.congregationId,
    required this.member,
    required this.adminCount,
    required this.sheet,
    required this.onClose,
  });

  final String congregationId;
  final CongregationMember member;

  /// How many admins the congregation has right now — the "last admin"
  /// guard lives on the client because the rules cannot aggregate.
  final int adminCount;

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<MemberAccessModal> createState() => _MemberAccessModalState();
}

class _MemberAccessModalState extends ConsumerState<MemberAccessModal> {
  late MemberCapabilities _capabilities = widget.member.capabilities;
  bool _busy = false;
  String? _error;

  /// Removing this member's admin (by downgrade or by ejection) would leave
  /// the congregation with nobody who can invite, rotate or fix anything.
  bool get _isLastAdmin =>
      widget.member.capabilities.admin && widget.adminCount <= 1;

  bool get _wouldStrandCongregation => _isLastAdmin && !_capabilities.admin;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) widget.onClose();
    } catch (e) {
      if (mounted) setState(() => _error = sharingMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _run(() async {
        final cck = ref.read(cckServiceProvider);
        if (cck == null) return;
        await cck.setMemberCapabilities(
            widget.congregationId, widget.member.uid, _capabilities);
      });

  Future<void> _revoke() async {
    final tr = context.t;
    final name = widget.member.displayName ??
        widget.member.email ??
        widget.member.uid;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.congregation.revokeTitle),
        content: Text(tr.congregation.revokeConfirm(name: name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr.congregation.revoke,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      final cck = ref.read(cckServiceProvider);
      if (cck == null) return;
      await cck.rotateAndRevoke(widget.congregationId,
          removeUids: [widget.member.uid]);
    });
  }

  void _toggle({bool? admin, bool? people, bool? programs}) =>
      setState(() => _capabilities = MemberCapabilities(
            admin: admin ?? _capabilities.admin,
            people: people ?? _capabilities.people,
            editTypes: programs == null
                ? _capabilities.editTypes
                : (programs ? const [MemberCapabilities.everyType] : const []),
          ));

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final name =
        widget.member.displayName ?? widget.member.email ?? widget.member.uid;
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.congregation.editAccess,
      desc: name,
      primaryLabel: tr.common.saveChanges,
      primaryBusy: _busy,
      onPrimary: (_busy || _wouldStrandCongregation) ? null : _save,
      dangerLabel: tr.congregation.revoke,
      onDanger: (_busy || _isLastAdmin) ? null : _revoke,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterPill(
                label: tr.invite.capAdmin,
                active: _capabilities.admin,
                onTap: () => _toggle(admin: !_capabilities.admin),
              ),
              FilterPill(
                label: tr.invite.capPeople,
                active: _capabilities.people,
                onTap: () => _toggle(people: !_capabilities.people),
              ),
              FilterPill(
                label: tr.invite.capPrograms,
                active: _capabilities.editTypes.isNotEmpty,
                onTap: () =>
                    _toggle(programs: _capabilities.editTypes.isEmpty),
              ),
            ],
          ),
          if (_isLastAdmin) ...[
            const SizedBox(height: 14),
            Text(
              tr.congregation.lastAdmin,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: t.textMute),
            ),
          ],
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
