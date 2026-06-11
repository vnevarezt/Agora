import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/segmented_control.dart';
import 'pdf_preview_view.dart';

/// Panel de vista previa (`.preview-pane`): barra superior con el chip
/// "Vista previa" y el % de zoom, y el visor del PDF real debajo.
class PreviewPane extends StatefulWidget {
  const PreviewPane({super.key, this.showLeftBorder = false});

  final bool showLeftBorder;

  @override
  State<PreviewPane> createState() => _PreviewPaneState();
}

class _PreviewPaneState extends State<PreviewPane> {
  final _tc = TransformationController();

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface2,
        border: widget.showLeftBorder
            ? Border(left: BorderSide(color: t.border))
            : null,
      ),
      child: Column(
        children: [
          Container(
            height: Dimens.hPreviewBar,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: t.surface,
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                const SegmentedTabs(
                  segments: [
                    (icon: Icons.description_outlined, label: 'Vista previa'),
                  ],
                ),
                const Spacer(),
                ValueListenableBuilder<Matrix4>(
                  valueListenable: _tc,
                  builder: (context, m, _) => Text(
                    '${(m.getMaxScaleOnAxis() * 100).round()}%',
                    style: AppText.mono(
                        size: 12, weight: FontWeight.w700, color: t.textMute),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: PdfPreviewView(controller: _tc)),
        ],
      ),
    );
  }
}
