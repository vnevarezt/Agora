import 'package:flutter/material.dart';

import '../responsive.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'person_picker_panel.dart';

/// Result of the person picker.
sealed class PickResult {
  const PickResult();
}

/// Assign [name] to the slot.
class PickName extends PickResult {
  const PickName(this.name);

  final String name;
}

/// Remove the current assignment.
class PickRemove extends PickResult {
  const PickRemove();
}

const _scrim = Color(0x47000000); // rgba(0,0,0,.28) del mock

/// Opens the picker: popover anchored to [anchorContext] on desktop/tablet,
/// bottom sheet on mobile. Returns null if closed without choosing.
Future<PickResult?> showPersonPicker(
  BuildContext anchorContext, {
  required String roleLabel,
  required String current,
  required int maxLength,
}) {
  final panel = PersonPickerPanel(
    roleLabel: roleLabel,
    current: current,
    maxLength: maxLength,
  );

  if (anchorContext.isMobile) {
    final t = anchorContext.tokens;
    return showModalBottomSheet<PickResult>(
      context: anchorContext,
      isScrollControlled: true,
      backgroundColor: t.surface,
      barrierColor: _scrim,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimens.rSheet)),
      ),
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height;
        return Padding(
          // Keeps the search box visible when the keyboard appears.
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height * 0.78),
            child: PersonPickerPanel(
              roleLabel: roleLabel,
              current: current,
              maxLength: maxLength,
              mobile: true,
            ),
          ),
        );
      },
    );
  }

  final box = anchorContext.findRenderObject() as RenderBox;
  final anchor = box.localToGlobal(Offset.zero) & box.size;
  return Navigator.of(anchorContext).push(
    _PickerPopupRoute(anchor: anchor, panel: panel),
  );
}

/// Desktop popover: soft scrim + panel anchored to the button with the
/// "pop" animation (scale 0.96 -> 1 over 160 ms).
class _PickerPopupRoute extends PopupRoute<PickResult> {
  _PickerPopupRoute({required this.anchor, required this.panel});

  final Rect anchor;
  final PersonPickerPanel panel;

  @override
  Color get barrierColor => _scrim;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Cerrar selector';

  @override
  Duration get transitionDuration => Dimens.dPop;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final t = context.tokens;
    return CustomSingleChildLayout(
      delegate: _PopoverLayout(anchor: anchor),
      child: Material(
        color: t.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.rPicker),
          side: BorderSide(color: t.border),
        ),
        elevation: 18,
        shadowColor: const Color(0x47000000),
        child: panel,
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curva =
        CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curva),
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }
}

/// Positions the popover under the anchor, clamped to the window edges;
/// if it does not fit below, places it above.
class _PopoverLayout extends SingleChildLayoutDelegate {
  _PopoverLayout({required this.anchor});

  final Rect anchor;

  static const _margen = 12.0;
  static const _gap = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: Dimens.pickerW,
      maxHeight: Dimens.pickerMaxH,
    ).enforce(constraints.loosen());
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var left = anchor.left;
    var top = anchor.bottom + _gap;
    if (left + childSize.width > size.width - _margen) {
      left = size.width - childSize.width - _margen;
    }
    if (left < _margen) left = _margen;
    if (top + childSize.height > size.height - _margen) {
      top = (anchor.top - childSize.height - _gap)
          .clamp(_margen, size.height - childSize.height - _margen);
    }
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_PopoverLayout old) => old.anchor != anchor;
}
