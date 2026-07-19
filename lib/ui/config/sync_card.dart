import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/sync/link_service.dart';
import '../../i18n/strings.g.dart';
import '../../state/dashboard_provider.dart' show relativeEditedLabel;
import '../../state/sync_controller.dart';
import '../../state/sync_keys.dart';
import '../../state/sync_provider.dart' show linkServiceProvider;
import '../auth/widgets/auth_error_text.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';
import 'settings_card.dart';

/// Settings card for cloud sync. There is no passphrase to manage: the first
/// device mints the E2E identity silently and further devices are authorised
/// from one that already syncs. Only rendered when signed in.
class SyncCard extends ConsumerWidget {
  const SyncCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.t;
    final keys = ref.watch(syncKeysProvider);

    return SettingsCard(
      title: tr.cloudSync.title,
      desc: tr.cloudSync.desc,
      children: switch (keys) {
        SyncKeysUnavailable() => [
            SettingRow(first: true, title: tr.cloudSync.signedOut),
          ],
        SyncKeysLoading() => [
            const SettingRow(first: true, title: '…'),
          ],
        SyncKeysNeedsLink() => [
            SettingRow(
              first: true,
              title: tr.cloudSync.needsLinkTitle,
              subtitle: tr.cloudSync.needsLinkDesc,
              trailing: AppButton(
                icon: Icons.link,
                label: tr.cloudSync.linkThisDevice,
                onPressed: () => showAppModal<void>(
                  context,
                  builder: (ctx, sheet, close) =>
                      _LinkThisDeviceModal(sheet: sheet, onClose: close),
                ),
              ),
            ),
          ],
        SyncKeysError(:final messageKey) => [
            SettingRow(
              first: true,
              title: tr.cloudSync.statusError,
              subtitle: switch (messageKey) {
                'identityMismatch' => tr.cloudSync.identityMismatch,
                'badCode' => tr.cloudSync.badCode,
                _ => tr.cloudSync.unknownError,
              },
            ),
          ],
        SyncKeysReady() => _readyRows(context, ref, tr),
      },
    );
  }

  List<Widget> _readyRows(BuildContext context, WidgetRef ref, Translations tr) {
    final (label, sub) = _statusText(tr, ref.watch(syncControllerProvider));
    return [
      // Purely informational: sync runs itself (pushes retry on reconnect,
      // pulls follow the activity heartbeat), so there is nothing to press.
      SettingRow(first: true, title: label, subtitle: sub),
      SettingRow(
        title: tr.cloudSync.linkOther,
        subtitle: tr.cloudSync.linkOtherDesc,
        trailing: AppButton(
          variant: AppButtonVariant.ghost,
          icon: Icons.add_link,
          label: tr.cloudSync.approve,
          onPressed: () => showAppModal<void>(
            context,
            builder: (ctx, sheet, close) =>
                _ApproveDeviceModal(sheet: sheet, onClose: close),
          ),
        ),
      ),
    ];
  }

  (String, String) _statusText(Translations tr, SyncStatus s) {
    final when = s.lastSyncAt == null
        ? tr.cloudSync.neverSynced
        : tr.cloudSync.lastSync(when: relativeEditedLabel(s.lastSyncAt!));
    return switch (s.phase) {
      SyncPhase.syncing => (tr.cloudSync.statusSyncing, when),
      SyncPhase.offline => (tr.cloudSync.statusOffline, tr.cloudSync.errorOffline),
      SyncPhase.error => (
          tr.cloudSync.statusError,
          switch (s.errorKey) {
            'permissionDenied' => tr.cloudSync.errorPermission,
            'offline' => tr.cloudSync.errorOffline,
            _ => tr.cloudSync.errorUnknown,
          }
        ),
      _ => (tr.cloudSync.ready, when),
    };
  }
}

/// NEW device: shows the linking code and waits for another device to
/// approve it. The code carries the ephemeral public key out of band — that
/// is what stops the server from substituting its own.
class _LinkThisDeviceModal extends ConsumerStatefulWidget {
  const _LinkThisDeviceModal({required this.sheet, required this.onClose});

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<_LinkThisDeviceModal> createState() =>
      _LinkThisDeviceModalState();
}

class _LinkThisDeviceModalState extends ConsumerState<_LinkThisDeviceModal> {
  LinkSession? _session;
  bool _expired = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    // Don't leave a mailbox dangling if the user walks away.
    final session = _session;
    if (session != null) {
      ref.read(linkServiceProvider)?.cancel(session);
    }
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _expired = false;
      _session = null;
    });
    try {
      final session = await ref.read(syncKeysProvider.notifier).startLink();
      if (!mounted) return;
      setState(() => _session = session);

      final linked =
          await ref.read(syncKeysProvider.notifier).completeLink(session);
      if (!mounted) return;
      if (linked) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.t.cloudSync.linked)));
        widget.onClose();
      } else {
        setState(() => _expired = true);
      }
    } catch (reason) {
      if (!mounted) return;
      final tr = context.t;
      setState(() => _error = reason == 'identityMismatch'
          ? tr.cloudSync.identityMismatch
          : tr.cloudSync.unknownError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final t = context.tokens;
    final session = _session;

    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.cloudSync.linkModalTitle,
      desc: tr.cloudSync.linkModalDesc,
      primaryLabel: _expired ? tr.cloudSync.regenerate : tr.common.close,
      onPrimary: _expired ? _start : widget.onClose,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (session == null && _error == null)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (session != null) ...[
            // The QR is the convenient path (the other device scans it); the
            // text below is the universal one — desktop can't scan.
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border),
                ),
                child: QrImageView(
                  data: session.code,
                  size: 180,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: tr.cloudSync.linkCode,
              child: SelectableText(
                session.code,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11.5,
                  height: 1.5,
                  color: t.text,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                variant: AppButtonVariant.ghost,
                icon: Icons.copy_all_outlined,
                label: tr.cloudSync.copyCode,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: session.code));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr.cloudSync.codeCopied)));
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr.cloudSync.shareWarning,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: t.textMute,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _expired
                  ? tr.cloudSync.linkExpired
                  : tr.cloudSync.waitingApproval,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _expired ? t.textMute : t.accentStrong,
              ),
            ),
          ],
          AuthErrorText(_error),
        ],
      ),
    );
  }
}

/// EXISTING device: paste the code the new device shows and hand over the
/// identity, sealed to the key that came in the code.
class _ApproveDeviceModal extends ConsumerStatefulWidget {
  const _ApproveDeviceModal({required this.sheet, required this.onClose});

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<_ApproveDeviceModal> createState() =>
      _ApproveDeviceModalState();
}

class _ApproveDeviceModalState extends ConsumerState<_ApproveDeviceModal> {
  String _code = '';
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final tr = context.t;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(syncKeysProvider.notifier).approveLink(_code.trim());
      if (!mounted) return;
      widget.onClose();
      messenger.showSnackBar(SnackBar(content: Text(tr.cloudSync.approved)));
    } catch (reason) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = reason == 'badCode'
            ? tr.cloudSync.badCode
            : tr.cloudSync.unknownError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.cloudSync.approveTitle,
      desc: tr.cloudSync.approveDesc,
      primaryLabel: tr.cloudSync.approve,
      primaryBusy: _busy,
      onPrimary: _code.trim().isEmpty || _busy ? null : _submit,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: tr.cloudSync.linkCode,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _code = v;
                _error = null;
              }),
              hint: 'agora-link:1:…',
              autofocus: true,
              onSubmitted: (_) =>
                  _code.trim().isEmpty || _busy ? null : _submit(),
            ),
          ),
          AuthErrorText(_error),
        ],
      ),
    );
  }
}
