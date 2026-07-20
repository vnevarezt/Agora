import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';
import '../widgets/dashed_border.dart';

/// Assignment button (`.assignee`): empty shows a dashed border and
/// "Asignar…"; filled shows avatar + name + X to clear (visible on hover, or
/// always on touch via [alwaysShowClear]).
class AssigneeButton extends StatelessWidget {
  const AssigneeButton({
    super.key,
    this.name,
    this.onTap,
    this.onClear,
    this.alwaysShowClear = false,
  });

  final String? name;

  /// Null renders the slot inert — how a member without `editTypes` for this
  /// program sees an assignment: readable, not editable.
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool alwaysShowClear;

  bool get _filled => name != null && name!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        final content = AnimatedContainer(
          duration: Dimens.dFast,
          height: Dimens.hAssignee,
          padding: const EdgeInsets.only(left: 8, right: 10),
          decoration: BoxDecoration(
            color: _filled ? t.surface : t.surface2,
            borderRadius: BorderRadius.circular(Dimens.rAssignee),
            border: _filled
                ? Border.all(
                    color: hovered ? t.accent : t.border, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              PersonAvatar(name: _filled ? name : null),
              const SizedBox(width: 9),
              Expanded(
                child: _filled
                    ? Text(
                        name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      )
                    : Text(
                        context.t.workspace.assignee,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: hovered ? t.textDim : t.textMute,
                        ),
                      ),
              ),
              if (_filled && onClear != null)
                AnimatedOpacity(
                  duration: Dimens.dFast,
                  opacity: hovered || alwaysShowClear ? 1 : 0,
                  child: _ClearButton(onClear: onClear!),
                ),
            ],
          ),
        );

        // The empty state uses a dashed border (not supported by Border).
        if (_filled) return content;
        return DashedBorder(
          color: hovered ? t.accent : t.border,
          radius: Dimens.rAssignee,
          child: content,
        );
      },
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onClear,
      tooltip: context.t.common.removeAssignment,
      builder: (context, hovered, _) {
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: hovered ? t.surface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.close,
              size: 14, color: hovered ? t.text : t.textMute),
        );
      },
    );
  }
}
