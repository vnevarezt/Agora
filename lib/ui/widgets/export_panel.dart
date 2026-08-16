import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../state/preview_provider.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'export_actions.dart';
import 'motion.dart';

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
    final selectedIndex = value == ExportFormat.pdf ? 0 : 1;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      // One pill that slides between slots, instead of each segment
      // independently flipping its own background — that's what read as
      // abrupt: two unrelated fades landing in the same 150ms window
      // instead of one piece of UI moving.
      //
      // Alignment + a fractional width, not LayoutBuilder: this panel is
      // measured inside MenuAnchor's IntrinsicWidth pass, which never calls
      // layout() on a LayoutBuilder — it only asks for intrinsic size, so
      // the builder never fires and the render tree comes up sizeless.
      //
      // The pill is Positioned.fill, not a plain Stack child: a Stack sizes
      // itself from its non-positioned children only (the Row here), so a
      // non-positioned sibling asking to fill "the rest" has no finite
      // height to fill in this unbounded-height context and demands an
      // infinite one instead. A positioned child is excluded from that
      // sizing pass and is laid out afterwards, against the Stack's already
      // finite resolved size.
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: Motion.of(context, Motion.fast),
              curve: Motion.curve,
              alignment: selectedIndex == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.border),
                    boxShadow: Elevation.control,
                  ),
                ),
              ),
            ),
          ),
          Row(
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
          duration: Motion.of(context, Motion.instant),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            // The sliding pill already carries the selected look; hover
            // only needs to read on the *other* segment, and as an outline
            // rather than a fill so it never reads as "also selected".
            border: !selected && hovered ? Border.all(color: t.border) : null,
            borderRadius: BorderRadius.circular(8),
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
                  fontSize: AppText.small,
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
