import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'danger_button.dart';

/// Shared structure for the app modals: handle (on sheet), header
/// (title + description + close), scrollable body and a button footer.
/// Used with [showAppModal], which chooses dialog vs bottom sheet.
class ModalShell extends StatelessWidget {
  const ModalShell({
    super.key,
    required this.sheet,
    required this.onClose,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.desc,
    this.primaryBusy = false,
    this.dangerLabel,
    this.onDanger,
  });

  final bool sheet;
  final VoidCallback onClose;
  final String title;
  final String? desc;
  final Widget body;

  final String primaryLabel;

  /// null = primary button disabled.
  final VoidCallback? onPrimary;
  final bool primaryBusy;

  final String? dangerLabel;
  final VoidCallback? onDanger;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final card = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sheet) _handle(t),
        _header(t),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: body,
          ),
        ),
        _footer(context, t),
      ],
    );

    if (sheet) return card;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 12)),
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: card,
    );
  }

  Widget _handle(AppTokens t) => Padding(
        padding: const EdgeInsets.only(top: 9),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: t.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      );

  Widget _header(AppTokens t) => Padding(
        padding: EdgeInsets.fromLTRB(18, sheet ? 12 : 18, 12, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: t.text,
                    ),
                  ),
                  if (desc != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      desc!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: t.textMute,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppIconButton(
              icon: Icons.close,
              bordered: true,
              tooltip: 'Cerrar',
              size: 32,
              onPressed: onClose,
            ),
          ],
        ),
      );

  Widget _footer(BuildContext context, AppTokens t) {
    final children = sheet
        ? [
            AppButton(
              label: primaryLabel,
              expand: true,
              busy: primaryBusy,
              height: Dimens.hExportMobile,
              onPressed: onPrimary,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    variant: AppButtonVariant.ghost,
                    label: 'Cancelar',
                    expand: true,
                    onPressed: onClose,
                  ),
                ),
                if (onDanger != null) ...[
                  const SizedBox(width: 8),
                  DangerButton(
                      onTap: onDanger!, label: dangerLabel ?? 'Eliminar'),
                ],
              ],
            ),
          ]
        : [
            Row(
              children: [
                if (onDanger != null)
                  DangerButton(
                      onTap: onDanger!, label: dangerLabel ?? 'Eliminar'),
                const Spacer(),
                AppButton(
                  variant: AppButtonVariant.ghost,
                  label: 'Cancelar',
                  onPressed: onClose,
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: primaryLabel,
                  busy: primaryBusy,
                  onPressed: onPrimary,
                ),
              ],
            ),
          ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        sheet ? 12 + MediaQuery.paddingOf(context).bottom : 12,
      ),
      decoration: BoxDecoration(
        color: t.surface2,
        border: Border(top: BorderSide(color: t.border2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
