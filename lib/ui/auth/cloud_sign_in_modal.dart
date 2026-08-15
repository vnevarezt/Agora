import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../widgets/modal_shell.dart';
import '../widgets/segmented_control.dart';
import 'cloud_auth_screen.dart';
import 'password_reset_screen.dart';

/// Settings entry point for local-mode users adding a cloud identity: wraps
/// the shared [CloudAuthForm] in a modal. Signing in here never changes the
/// session gate.
class CloudSignInModal extends StatefulWidget {
  const CloudSignInModal({
    super.key,
    required this.sheet,
    required this.onClose,
  });

  final bool sheet;
  final VoidCallback onClose;

  @override
  State<CloudSignInModal> createState() => _CloudSignInModalState();
}

class _CloudSignInModalState extends State<CloudSignInModal> {
  CloudFormMode _mode = CloudFormMode.login;
  bool _resetting = false;
  String _email = '';

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.account.title,
      desc: tr.account.desc,
      primaryLabel: tr.common.close,
      onPrimary: widget.onClose,
      body: _resetting
          ? PasswordResetPanel(
              initialEmail: _email,
              onBack: (email) => setState(() {
                _email = email;
                _resetting = false;
              }),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedTabs(
                  segments: [
                    (icon: null, label: tr.auth.cloud.loginTitle),
                    (icon: null, label: tr.auth.cloud.registerTitle),
                  ],
                  index: _mode == CloudFormMode.login ? 0 : 1,
                  onChanged: (i) => setState(
                    () => _mode =
                        i == 0 ? CloudFormMode.login : CloudFormMode.register,
                  ),
                ),
                const SizedBox(height: 16),
                CloudAuthForm(
                  mode: _mode,
                  initialEmail: _email,
                  onSuccess: widget.onClose,
                  onForgotPassword: (email) => setState(() {
                    _email = email;
                    _resetting = true;
                  }),
                ),
              ],
            ),
    );
  }
}
