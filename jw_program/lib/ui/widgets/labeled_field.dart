import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';

/// Settings-panel field (`.field`): small uppercase label above any
/// control ([child]: input, dropdown, switch, readonly…).
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppText.label(size: 11, color: t.textMute)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Dropdown styled like `.field__input` (notebook week).
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: Dimens.hField,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(Dimens.rControl),
        border: Border.all(color: t.border),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.expand_more, size: 18, color: t.textMute),
        borderRadius: BorderRadius.circular(Dimens.rControl),
        dropdownColor: t.surface,
        style: TextStyle(
          fontFamily: AppText.family,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: t.text,
        ),
        items: [
          for (final item in items)
            DropdownMenuItem(
              value: item,
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
        ],
        // Pass the value as-is: with nullable T, null is a valid option
        // (e.g. the "Todos" filter on the participants screen).
        onChanged: onChanged == null ? null : (v) => onChanged!(v as T),
      ),
    );
  }
}

/// Read-only computed value styled like an input (total duration).
class ReadonlyField extends StatelessWidget {
  const ReadonlyField({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: Dimens.hField,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(Dimens.rControl),
        border: Border.all(color: t.border2),
      ),
      child: Text(
        texto,
        style: TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: t.textDim),
      ),
    );
  }
}
