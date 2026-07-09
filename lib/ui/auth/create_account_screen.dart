import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/db_key_manager.dart';
import '../../i18n/strings.g.dart';
import '../../state/local_auth.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import 'auth_scaffold.dart';

/// Create the local account that wraps the DB key. [migration] switches the
/// copy: same flow, but the key (and the data) already exist and get
/// protected instead of created.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key, required this.migration});

  final bool migration;

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  static const _minLength = 8;

  String _password = '';
  String _confirm = '';
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final tr = context.t;
    if (_password.length < _minLength) {
      setState(() => _error = tr.auth.create.tooShort);
      return;
    }
    if (_password != _confirm) {
      setState(() => _error = tr.auth.create.mismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(localAuthProvider.notifier);
      if (widget.migration) {
        await auth.migrate(_password);
      } else {
        await auth.createAccount(_password);
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
    final t = context.tokens;
    final canSubmit = _password.isNotEmpty && _confirm.isNotEmpty && !_busy;

    return AuthScaffold(
      icon: widget.migration ? Icons.shield_outlined : Icons.person_add_alt,
      title: widget.migration
          ? tr.auth.create.migrateTitle
          : tr.auth.create.title,
      subtitle: widget.migration
          ? tr.auth.create.migrateSubtitle
          : tr.auth.create.subtitle,
      children: [
        LabeledField(
          label: tr.auth.create.password,
          child: BoundTextField(
            initial: '',
            onChanged: (v) => setState(() => _password = v),
            obscureText: true,
            autofocus: true,
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: tr.auth.create.confirm,
          child: BoundTextField(
            initial: '',
            onChanged: (v) => setState(() => _confirm = v),
            obscureText: true,
            onSubmitted: (_) => canSubmit ? _submit() : null,
          ),
        ),
        if (_error != null) AuthErrorText(_error!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.border2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 17, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr.auth.create.noRecoveryWarning,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: t.textDim,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppButton(
          label: _busy
              ? tr.auth.create.working
              : widget.migration
                  ? tr.auth.create.migrateButton
                  : tr.auth.create.button,
          expand: true,
          busy: _busy,
          onPressed: canSubmit ? _submit : null,
        ),
      ],
    );
  }
}
