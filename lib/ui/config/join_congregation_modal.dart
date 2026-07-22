import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/invite_code.dart';
import '../../i18n/strings.g.dart';
import '../../state/sync_provider.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';
import 'invite_user_modal.dart' show sharingMessage;

/// Opens the "join with a code" modal — the entry point for the invited
/// side, which had none before.
Future<void> showJoinCongregation(BuildContext context) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        JoinCongregationModal(sheet: sheet, onClose: close),
  );
}

class JoinCongregationModal extends ConsumerStatefulWidget {
  const JoinCongregationModal({
    super.key,
    required this.sheet,
    required this.onClose,
  });

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<JoinCongregationModal> createState() =>
      _JoinCongregationModalState();
}

class _JoinCongregationModalState
    extends ConsumerState<JoinCongregationModal> {
  String _raw = '';
  bool _busy = false;
  String? _error;

  /// Rebuilds the field when we paste into it for the user.
  int _seed = 0;

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    setState(() {
      _raw = text;
      _seed++;
      _error = null;
    });
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Parse first: a mistyped code should say so without a round trip.
      final code = InviteCode.parse(_raw);
      await ref.read(redeemInviteProvider)(code);
      if (!mounted) return;
      widget.onClose();
    } catch (e) {
      if (mounted) setState(() => _error = sharingMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.invite.joinTitle,
      desc: tr.invite.joinDesc,
      primaryLabel: tr.invite.join,
      primaryBusy: _busy,
      onPrimary: (_raw.trim().isEmpty || _busy) ? null : _join,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: tr.invite.codeLabel,
            child: BoundTextField(
              key: ValueKey('invite-code-$_seed'),
              initial: _raw,
              hint: tr.invite.codeHint,
              maxLines: 2,
              style: AppText.mono(size: 12.5, color: t.text),
              onChanged: (v) => setState(() {
                _raw = v;
                _error = null;
              }),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              variant: AppButtonVariant.ghost,
              icon: Icons.content_paste_go,
              label: tr.invite.paste,
              onPressed: _pasteFromClipboard,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
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
