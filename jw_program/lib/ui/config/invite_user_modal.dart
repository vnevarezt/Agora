import 'package:flutter/material.dart';

import '../../data/config_options.dart';
import '../../i18n/strings.g.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';

/// Opens the modal to invite a user to the congregation (UI-only).
Future<void> showInviteUser(BuildContext context) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        InviteUserModal(sheet: sheet, onClose: close),
  );
}

class InviteUserModal extends StatefulWidget {
  const InviteUserModal({
    super.key,
    required this.sheet,
    required this.onClose,
  });

  final bool sheet;
  final VoidCallback onClose;

  @override
  State<InviteUserModal> createState() => _InviteUserModalState();
}

class _InviteUserModalState extends State<InviteUserModal> {
  String _email = '';
  String _rol = accessRoles[1]; // Editor

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.invite.title,
      desc: tr.invite.desc,
      primaryLabel: tr.invite.send,
      onPrimary: _email.trim().isEmpty ? null : widget.onClose,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: tr.invite.email,
            child: BoundTextField(
              initial: _email,
              hint: tr.invite.emailHint,
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => setState(() => _email = v),
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: tr.invite.role,
            child: AppDropdown<String>(
              value: accessRoles.contains(_rol) ? _rol : accessRoles.first,
              items: accessRoles,
              itemLabel: (s) => s,
              onChanged: (v) => setState(() => _rol = v),
            ),
          ),
        ],
      ),
    );
  }
}
