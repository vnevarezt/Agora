import 'package:flutter/material.dart';

/// Campo de texto ligado al status: se siembra una vez con [initial] y
/// notifica cambios con [onChanged] (la fuente de la verdad es el provider).
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
  });

  final String initial;
  final ValueChanged<String> onChanged;

  /// Etiqueta flotante de Material; vacía para campos con label externo
  /// (LabeledField del panel de configuración).
  final String label;
  final String? hint;
  final TextStyle? style;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final bool dense;

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
      decoration: InputDecoration(
        labelText: widget.label.isEmpty ? null : widget.label,
        hintText: widget.hint,
        counterText: '',
        isDense: widget.dense,
      ),
    );
  }
}
