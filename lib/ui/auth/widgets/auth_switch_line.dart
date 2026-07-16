import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/app_button.dart';

/// `.auth-switch`: centered muted line with an inline accent action
/// ("¿No tienes cuenta? Regístrate").
class AuthSwitchLine extends StatelessWidget {
  const AuthSwitchLine({
    super.key,
    required this.text,
    required this.actionLabel,
    required this.onTap,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.textMute,
            ),
          ),
        ),
        Pressable(
          onTap: onTap,
          builder: (context, hovered, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: t.accentStrong,
                decoration: hovered ? TextDecoration.underline : null,
                decorationColor: t.accentStrong,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
