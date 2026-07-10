import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/db_key_manager.dart';
import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../widgets/app_button.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import 'auth_card_layout.dart';
import 'widgets/auth_error_text.dart';
import 'widgets/auth_note.dart';
import 'widgets/back_link.dart';
import 'widgets/mode_pill.dart';

/// Local profile wizard: name + password wrap the DB key. [migration] keeps
/// the pre-existing key (and its data); [onBack] is null when the step is
/// forced (migration or direct navigation).
class LocalCreateScreen extends ConsumerStatefulWidget {
  const LocalCreateScreen({super.key, required this.migration, this.onBack});

  final bool migration;
  final VoidCallback? onBack;

  @override
  ConsumerState<LocalCreateScreen> createState() => _LocalCreateScreenState();
}

class _LocalCreateScreenState extends ConsumerState<LocalCreateScreen> {
  static const _minLength = 8;

  String _name = '';
  String _password = '';
  String _confirm = '';
  bool _busy = false;
  String? _error;

  bool get _canSubmit =>
      _name.trim().isNotEmpty &&
      _password.isNotEmpty &&
      _confirm.isNotEmpty &&
      !_busy;

  Future<void> _submit() async {
    final tr = context.t;
    if (_password.length < _minLength) {
      setState(() => _error = tr.auth.local.tooShort);
      return;
    }
    if (_password != _confirm) {
      setState(() => _error = tr.auth.local.mismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = ref.read(authSessionProvider.notifier);
      final name = _name.trim();
      if (widget.migration) {
        await session.migrate(name, _password);
      } else {
        await session.createLocalProfile(name, _password);
      }
      // Success: AuthGate swaps this screen out.
    } on DbKeyException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    return AuthCardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onBack != null) ...[
            BackLink(label: tr.auth.chooseOther, onTap: widget.onBack!),
            const SizedBox(height: 16),
          ],
          ModePill(icon: Icons.smartphone, label: tr.auth.local.pill),
          const SizedBox(height: 14),
          AuthTitle(widget.migration
              ? tr.auth.local.migrateTitle
              : tr.auth.local.createTitle),
          const SizedBox(height: 6),
          AuthSub(widget.migration
              ? tr.auth.local.migrateSub
              : tr.auth.local.createSub),
          const SizedBox(height: 22),
          LabeledField(
            label: tr.auth.local.name,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() => _name = v),
              hint: tr.auth.local.nameHint,
              autofocus: true,
            ),
          ),
          const SizedBox(height: 13),
          LabeledField(
            label: tr.auth.local.password,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() => _password = v),
              hint: tr.auth.local.passwordHint,
              obscureText: true,
            ),
          ),
          const SizedBox(height: 13),
          LabeledField(
            label: tr.auth.local.confirm,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() => _confirm = v),
              hint: tr.auth.local.confirmHint,
              obscureText: true,
              onSubmitted: (_) => _canSubmit ? _submit() : null,
            ),
          ),
          if (_error != null) AuthErrorText(_error!),
          const SizedBox(height: 13),
          AuthNote(
            icon: Icons.shield_outlined,
            spans: [
              TextSpan(text: tr.auth.local.note1),
              TextSpan(
                text: tr.auth.local.noteBold,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(text: tr.auth.local.note2),
            ],
          ),
          const SizedBox(height: 13),
          AppButton(
            label: _busy ? tr.auth.local.working : tr.auth.local.createButton,
            height: 46,
            expand: true,
            busy: _busy,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
