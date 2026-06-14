import 'package:flutter/material.dart';

import '../responsive.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'person_picker_panel.dart';

/// Resultado del picker de personas.
sealed class PickResult {
  const PickResult();
}

/// Asignar [name] al slot.
class PickNombre extends PickResult {
  const PickNombre(this.name);

  final String name;
}

/// Quitar la asignación actual.
class PickQuitar extends PickResult {
  const PickQuitar();
}

const _scrim = Color(0x47000000); // rgba(0,0,0,.28) del mock

/// Abre el picker: popover anclado a [anchorContext] en escritorio/tablet,
/// bottom sheet en móvil. Devuelve null si se cierra sin elegir.
Future<PickResult?> showPersonPicker(
  BuildContext anchorContext, {
  required String roleLabel,
  required String actual,
  required int maxLength,
}) {
  final panel = PersonPickerPanel(
    roleLabel: roleLabel,
    actual: actual,
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
        final alto = MediaQuery.sizeOf(context).height;
        return Padding(
          // Deja el buscador visible cuando aparece el teclado.
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: alto * 0.78),
            child: PersonPickerPanel(
              roleLabel: roleLabel,
              actual: actual,
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

/// Popover de escritorio: scrim suave + panel anclado al botón con la
/// animación "pop" del mock (escala 0.96 → 1 en 160 ms).
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

/// Posiciona el popover bajo el ancla, sujeto a los bordes de la ventana;
/// si no cabe abajo, lo coloca encima (igual que el cálculo del mock).
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
