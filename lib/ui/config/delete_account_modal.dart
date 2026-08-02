import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/cloud_auth.dart';
import '../../state/dashboard_provider.dart';
import '../../state/sync_provider.dart';
import '../auth/widgets/auth_error_text.dart';
import '../theme/tokens.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';

/// Cancels the cloud account: reauthenticates (Firebase requires a recent
/// login to delete), then tears down every congregation, the identity doc, the
/// Firebase account and ALL local data — back to the Portada.
///
/// Blocking congregations (sole admin with other members) are shown upfront so
/// the user isn't asked to reauthenticate for a delete that would be refused.
class DeleteAccountModal extends ConsumerStatefulWidget {
  const DeleteAccountModal({
    super.key,
    required this.sheet,
    required this.onClose,
  });

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<DeleteAccountModal> createState() => _DeleteAccountModalState();
}

class _DeleteAccountModalState extends ConsumerState<DeleteAccountModal> {
  String _password = '';
  bool _busy = false;
  String? _error;

  bool get _isGoogle =>
      ref.read(cloudAuthProvider).value?.currentProviderId == 'google.com';

  Future<void> _delete() async {
    final auth = ref.read(cloudAuthProvider).value;
    if (auth == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isGoogle) {
        await auth.reauthenticateWithGoogle();
      } else {
        await auth.reauthenticateWithEmail(_password);
      }
      // On success this wipes local data and returns to the Portada, which
      // unmounts the modal — no close/setState needed here.
      await ref.read(deleteMyAccountProvider)();
    } on AccountDeletionBlocked {
      // The upfront check missed a race: refresh it and stop.
      ref.invalidate(accountDeletionBlockersProvider);
      if (mounted) setState(() => _busy = false);
    } on CloudAuthException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          // A cancelled Google reauth is not an error, just a no-op.
          _error = e.code == CloudAuthErrorCode.canceled
              ? null
              : _authError(context, e.code);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = context.t.account.deleteError;
        });
      }
    }
  }

  static String _authError(BuildContext context, CloudAuthErrorCode code) {
    final e = context.t.account.errors;
    return switch (code) {
      CloudAuthErrorCode.wrongPassword => e.wrongPassword,
      CloudAuthErrorCode.requiresRecentLogin => e.requiresRecentLogin,
      CloudAuthErrorCode.network => e.network,
      _ => e.unknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final blockers = ref.watch(accountDeletionBlockersProvider);
    final blocked = blockers.value ?? const <String>[];
    final loading = blockers.isLoading;

    final canDelete = !_busy &&
        !loading &&
        blocked.isEmpty &&
        (_isGoogle || _password.isNotEmpty);

    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.account.deleteTitle,
      desc: tr.account.deleteWarning,
      primaryLabel: tr.account.deleteConfirm,
      primaryBusy: _busy,
      onPrimary: canDelete ? _delete : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (blocked.isNotEmpty)
            _BlockedNotice(congregationIds: blocked)
          else if (_isGoogle)
            Text(
              tr.account.deleteReauthGoogle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.tokens.textMute,
              ),
            )
          else
            LabeledField(
              label: tr.account.deleteReauthEmail,
              child: BoundTextField(
                initial: '',
                obscureText: true,
                autofocus: true,
                onChanged: (v) => setState(() {
                  _password = v;
                  _error = null;
                }),
                onSubmitted: (_) => canDelete ? _delete() : null,
              ),
            ),
          AuthErrorText(_error),
        ],
      ),
    );
  }
}

/// Lists the congregations the user must hand over or empty before deleting.
class _BlockedNotice extends ConsumerWidget {
  const _BlockedNotice({required this.congregationIds});

  final List<String> congregationIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final congregations = ref.watch(congregationsProvider);
    final names = [
      for (final cid in congregationIds)
        congregations
            .where((c) => c.id == cid)
            .map((c) => c.name)
            .firstOrNull ??
            cid,
    ].join(', ');
    return Text(
      context.t.account.deleteBlocked(congregations: names),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
