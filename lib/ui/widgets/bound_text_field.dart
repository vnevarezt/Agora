import 'package:flutter/material.dart';

/// Text field bound to state: seeded once with [initial] and
/// reports changes via [onChanged] (the provider is the source of truth).
class BoundTextField extends StatefulWidget {
  const BoundTextField({
    super.key,
    required this.initial,
    required this.onChanged,
    this.label = '',
    this.hint,
    this.style,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.onSubmitted,
    this.dense = false,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.autofillHints,
  });

  final String initial;
  final ValueChanged<String> onChanged;

  /// Material floating label; empty for fields with an external label
  /// (LabeledField in the settings panel).
  final String label;
  final String? hint;
  final TextStyle? style;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final bool dense;
  final bool obscureText;
  final bool autofocus;

  /// What this field is for, in the platform's own vocabulary — see
  /// [AutofillHints]. Without it the OS and the password manager have no way
  /// to tell an email box from a name box, which is both a filling problem
  /// and the reason WCAG 1.3.5 asks for it.
  final List<String>? autofillHints;

  /// False renders the field read-only (greyed, not focusable) — how a
  /// capability gate shows a member they may look but not edit.
  final bool enabled;

  @override
  State<BoundTextField> createState() => _BoundTextFieldState();
}

class _BoundTextFieldState extends State<BoundTextField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: widget.style,
      obscureText: widget.obscureText,
      autofocus: widget.autofocus,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label.isEmpty ? null : widget.label,
        hintText: widget.hint,
        counterText: '',
        isDense: widget.dense,
      ),
    );
  }
}
