import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/dashboard_provider.dart' show relativeEditedLabel;
import '../../state/sync_controller.dart';
import '../../state/sync_keys.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';
import '../auth/widgets/auth_error_text.dart';
import 'settings_card.dart';

/// Settings card for cloud sync (phase 4b). Drives the sync passphrase
/// lifecycle and shows the engine status. Only rendered when the cloud is
/// configured and a user is signed in (the caller gates on that).
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
        SyncKeysNotSetUp() => [
            SettingRow(
              first: true,
              title: tr.cloudSync.setupTitle,
              subtitle: tr.cloudSync.setupDesc,
              trailing: AppButton(
                icon: Icons.cloud_sync_outlined,
                label: tr.cloudSync.create,
                onPressed: () => _openPassphrase(context, setup: true),
              ),
            ),
          ],
        SyncKeysLocked() => [
            SettingRow(
              first: true,
              title: tr.cloudSync.unlockTitle,
              subtitle: tr.cloudSync.unlockDesc,
              trailing: AppButton(
                icon: Icons.lock_open_outlined,
                label: tr.cloudSync.unlock,
                onPressed: () => _openPassphrase(context, setup: false),
              ),
            ),
          ],
        SyncKeysError() => [
            SettingRow(
              first: true,
              title: tr.cloudSync.unlockTitle,
              subtitle: tr.cloudSync.unknownError,
              trailing: AppButton(
                icon: Icons.lock_open_outlined,
                label: tr.cloudSync.unlock,
                onPressed: () => _openPassphrase(context, setup: false),
              ),
            ),
          ],
        SyncKeysReady() => _readyRows(context, ref, tr),
      },
    );
  }

  List<Widget> _readyRows(BuildContext context, WidgetRef ref, Translations tr) {
    final status = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);
    final (label, sub) = _statusText(tr, status);

    return [
      SettingRow(
        first: true,
        title: label,
        subtitle: sub,
        trailing: AppButton(
          variant: AppButtonVariant.ghost,
          icon: Icons.sync,
          label: tr.cloudSync.syncNow,
          busy: status.phase == SyncPhase.syncing,
          onPressed: status.phase == SyncPhase.syncing
              ? null
              : controller.syncNow,
        ),
      ),
      SettingRow(
        title: tr.cloudSync.change,
        subtitle: tr.cloudSync.changePassphrase,
        trailing: AppButton(
          variant: AppButtonVariant.ghost,
          icon: Icons.key_outlined,
          label: tr.cloudSync.change,
          onPressed: () => showAppModal<void>(
            context,
            builder: (ctx, sheet, close) =>
                _ChangePassphraseModal(sheet: sheet, onClose: close),
          ),
        ),
      ),
    ];
  }

  (String, String) _statusText(Translations tr, SyncStatus s) {
    final when = s.lastSyncAt == null
        ? tr.cloudSync.neverSynced
        : tr.cloudSync.lastSync(when: relativeEditedLabel(s.lastSyncAt!));
    final pending =
        s.pendingOutbox > 0 ? ' · ${tr.cloudSync.pending(n: s.pendingOutbox)}' : '';
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
      _ => (tr.cloudSync.ready, '$when$pending'),
    };
  }

  void _openPassphrase(BuildContext context, {required bool setup}) {
    showAppModal<void>(
      context,
      builder: (ctx, sheet, close) =>
          _PassphraseModal(sheet: sheet, onClose: close, setup: setup),
    );
  }
}

/// Create (setup) or enter (unlock) the sync passphrase.
class _PassphraseModal extends ConsumerStatefulWidget {
  const _PassphraseModal({
    required this.sheet,
    required this.onClose,
    required this.setup,
  });

  final bool sheet;
  final VoidCallback onClose;
  final bool setup;

  @override
  ConsumerState<_PassphraseModal> createState() => _PassphraseModalState();
}

class _PassphraseModalState extends ConsumerState<_PassphraseModal> {
  static const _minLength = 8;

  String _passphrase = '';
  String _confirm = '';
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final tr = context.t;
    if (widget.setup) {
      if (_passphrase.length < _minLength) {
        setState(() => _error = tr.cloudSync.tooShort);
        return;
      }
      if (_passphrase != _confirm) {
        setState(() => _error = tr.cloudSync.mismatch);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final notifier = ref.read(syncKeysProvider.notifier);
    try {
      if (widget.setup) {
        await notifier.createPassphrase(_passphrase);
      } else {
        await notifier.enterPassphrase(_passphrase);
      }
      if (mounted) widget.onClose();
    } catch (reason) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = reason == 'wrongPassphrase'
              ? tr.cloudSync.wrongPassphrase
              : tr.cloudSync.unknownError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final canSubmit = _passphrase.isNotEmpty &&
        (!widget.setup || _confirm.isNotEmpty) &&
        !_busy;

    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: widget.setup ? tr.cloudSync.setupTitle : tr.cloudSync.unlockTitle,
      desc: widget.setup ? tr.cloudSync.setupDesc : tr.cloudSync.unlockDesc,
      primaryLabel: widget.setup ? tr.cloudSync.create : tr.cloudSync.unlock,
      primaryBusy: _busy,
      onPrimary: canSubmit ? _submit : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: tr.cloudSync.passphrase,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _passphrase = v;
                _error = null;
              }),
              hint: tr.cloudSync.passphraseHint,
              obscureText: true,
              autofocus: true,
              onSubmitted: (_) => canSubmit ? _submit() : null,
            ),
          ),
          if (widget.setup) ...[
            const SizedBox(height: 14),
            LabeledField(
              label: tr.cloudSync.confirmPassphrase,
              child: BoundTextField(
                initial: '',
                onChanged: (v) => setState(() {
                  _confirm = v;
                  _error = null;
                }),
                obscureText: true,
                onSubmitted: (_) => canSubmit ? _submit() : null,
              ),
            ),
          ],
          AuthErrorText(_error),
        ],
      ),
    );
  }
}

class _ChangePassphraseModal extends ConsumerStatefulWidget {
  const _ChangePassphraseModal({required this.sheet, required this.onClose});

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<_ChangePassphraseModal> createState() =>
      _ChangePassphraseModalState();
}

class _ChangePassphraseModalState
    extends ConsumerState<_ChangePassphraseModal> {
  static const _minLength = 8;

  String _current = '';
  String _next = '';
  String _confirm = '';
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final tr = context.t;
    if (_next.length < _minLength) {
      setState(() => _error = tr.cloudSync.tooShort);
      return;
    }
    if (_next != _confirm) {
      setState(() => _error = tr.cloudSync.mismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(syncKeysProvider.notifier).changePassphrase(_current, _next);
      if (mounted) widget.onClose();
    } catch (reason) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = reason == 'wrongPassphrase'
              ? tr.cloudSync.wrongPassphrase
              : tr.cloudSync.unknownError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final canSubmit = _current.isNotEmpty &&
        _next.isNotEmpty &&
        _confirm.isNotEmpty &&
        !_busy;

    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.cloudSync.changePassphrase,
      primaryLabel: tr.cloudSync.change,
      primaryBusy: _busy,
      onPrimary: canSubmit ? _submit : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: tr.cloudSync.currentPassphrase,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _current = v;
                _error = null;
              }),
              obscureText: true,
              autofocus: true,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: tr.cloudSync.newPassphrase,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _next = v;
                _error = null;
              }),
              obscureText: true,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: tr.cloudSync.confirmPassphrase,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _confirm = v;
                _error = null;
              }),
              obscureText: true,
              onSubmitted: (_) => canSubmit ? _submit() : null,
            ),
          ),
          AuthErrorText(_error),
        ],
      ),
    );
  }
}
