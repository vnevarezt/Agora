import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

typedef Segment = ({IconData icon, String label});

/// Control segmentado (`.seg`): pestañas Asignar/Vista previa en móvil y el
/// chip estático de la barra de la vista previa ([onChanged] nulo).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.segments,
    this.index = 0,
    this.onChanged,
    this.expand = false,
  });

  final List<Segment> segments;
  final int index;
  final ValueChanged<int>? onChanged;

  /// En móvil los botones reparten el ancho disponible.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(Dimens.rControl),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _boton(t, esOscuro, i),
          ],
        ],
      ),
    );
  }

  Widget _boton(AppTokens t, bool esOscuro, int i) {
    final activo = i == index;
    final boton = Pressable(
      onTap: onChanged == null || activo ? null : () => onChanged!(i),
      builder: (context, hovered, _) {
        return AnimatedContainer(
          duration: Dimens.dFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: activo
                ? (esOscuro ? t.accentSoft : t.surface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimens.rChip),
            boxShadow: activo && !esOscuro
                ? const [
                    BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 2,
                        offset: Offset(0, 1)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(segments[i].icon,
                  size: 15, color: activo ? t.text : t.textDim),
              const SizedBox(width: 6),
              Text(
                segments[i].label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: activo ? t.text : t.textDim,
                ),
              ),
            ],
          ),
        );
      },
    );
    return expand ? Expanded(child: boton) : boton;
  }
}
