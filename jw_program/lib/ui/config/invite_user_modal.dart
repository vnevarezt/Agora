import 'package:flutter/material.dart';

import '../../data/config_options.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';

/// Abre el modal para invitar a un user a la congregación (solo UI).
Future<void> showInviteUser(BuildContext context) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        InvitarUsuarioModal(sheet: sheet, onClose: close),
  );
}

class InvitarUsuarioModal extends StatefulWidget {
  const InvitarUsuarioModal({
    super.key,
    required this.sheet,
    required this.onClose,
  });

  final bool sheet;
  final VoidCallback onClose;

  @override
  State<InvitarUsuarioModal> createState() => _InvitarUsuarioModalState();
}

class _InvitarUsuarioModalState extends State<InvitarUsuarioModal> {
  String _email = '';
  String _rol = 'Editor';

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: 'Invitar usuario',
      desc: 'Le llegará una invitación por correo para acceder a esta '
          'congregación.',
      primaryLabel: 'Enviar invitación',
      onPrimary: _email.trim().isEmpty ? null : widget.onClose,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: 'Correo electrónico',
            child: BoundTextField(
              initial: _email,
              hint: 'name@correo.com',
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => setState(() => _email = v),
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Rol',
            child: AppDropdown<String>(
              value: _rol,
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
