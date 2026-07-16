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
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: widget.style,
      obscureText: widget.obscureText,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        labelText: widget.label.isEmpty ? null : widget.label,
        hintText: widget.hint,
        counterText: '',
        isDense: widget.dense,
      ),
    );
  }
}
