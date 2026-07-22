import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/sync/invite_code.dart';
import '../../i18n/strings.g.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/modal_shell.dart';

/// Shows a freshly minted invite code. This is the ONLY time it can be seen:
/// the secret half never reaches the server, so nothing can show it again.
Future<void> showInviteCode(BuildContext context, InviteCode code) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        InviteCodeModal(code: code, sheet: sheet, onClose: close),
  );
}

class InviteCodeModal extends StatefulWidget {
  const InviteCodeModal({
    super.key,
    required this.code,
    required this.sheet,
    required this.onClose,
  });

  final InviteCode code;
  final bool sheet;
  final VoidCallback onClose;

  @override
  State<InviteCodeModal> createState() => _InviteCodeModalState();
}

class _InviteCodeModalState extends State<InviteCodeModal> {
  bool _copied = false;

  late final String _text = widget.code.encode();

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text));
    if (mounted) setState(() => _copied = true);
  }

  Future<void> _share() =>
      SharePlus.instance.share(ShareParams(text: _text));

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.invite.codeTitle,
      desc: tr.invite.codeDesc,
      primaryLabel: tr.invite.done,
      onPrimary: widget.onClose,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: BorderRadius.circular(Dimens.rCard),
              border: Border.all(color: t.border2),
            ),
            child: SelectableText(
              _text,
              style: AppText.mono(size: 12.5, color: t.text),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AppButton(
                variant: AppButtonVariant.ghost,
                icon: _copied ? Icons.check : Icons.copy_all_outlined,
                label: _copied ? tr.invite.copied : tr.invite.copy,
                onPressed: _copy,
              ),
              const SizedBox(width: 8),
              AppButton(
                variant: AppButtonVariant.ghost,
                icon: Icons.ios_share,
                label: tr.invite.share,
                onPressed: _share,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
