import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../state/preview_provider.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'export_actions.dart';

/// Format picker (PDF / Imagen) + the two export actions (Guardar / Compartir)
/// for the current sheet. Shared by the desktop export menu and the mobile
/// export sheet so both offer the same choices. Holds the selected format;
/// [onExport] fires with (format, action, shareOrigin).
class ExportPanel extends StatefulWidget {
  const ExportPanel({
    super.key,
    required this.enabled,
    required this.onExport,
  });

  final bool enabled;
  final void Function(ExportFormat format, ExportAction action, Rect? origin)
      onExport;

  @override
  State<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends State<ExportPanel> {
  ExportFormat _format = ExportFormat.pdf;

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormatSelector(
          value: _format,
          onChanged: (f) => setState(() => _format = f),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppButton(
                variant: AppButtonVariant.ghost,
                icon: Icons.download_outlined,
                label: tr.export.saveAction,
                expand: true,
                onPressed: widget.enabled
                    ? () => widget.onExport(
                        _format, ExportAction.saveAs, null)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              // Builder so the share button has its own context → global rect
              // to anchor the iPad/macOS share popover.
              child: Builder(
                builder: (btnContext) => AppButton(
                  icon: Icons.ios_share,
                  label: tr.export.shareAction,
                  expand: true,
                  onPressed: widget.enabled
                      ? () => widget.onExport(_format, ExportAction.share,
                          originRectOf(btnContext))
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormatSelector extends StatelessWidget {
  const _FormatSelector({required this.value, required this.onChanged});

  final ExportFormat value;
  final ValueChanged<ExportFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          _Segment(
            icon: Icons.picture_as_pdf_outlined,
            label: tr.export.formatPdf,
            selected: value == ExportFormat.pdf,
            onTap: () => onChanged(ExportFormat.pdf),
          ),
          _Segment(
            icon: Icons.image_outlined,
            label: tr.export.formatImage,
            selected: value == ExportFormat.png,
            onTap: () => onChanged(ExportFormat.png),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Expanded(
      child: Pressable(
        onTap: onTap,
        builder: (context, hovered, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? t.surface
                : (hovered ? t.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: t.border) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15, color: selected ? t.accentStrong : t.textMute),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? t.text : t.textMute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
