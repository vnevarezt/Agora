import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/avatar.dart';

/// Fila de user con acceso (`.user-row`): avatar, name, email y un control
/// a la derecha (pill de role o selector). [first] omite el borde superior.
class UserRow extends StatelessWidget {
  const UserRow({
    super.key,
    required this.name,
    required this.email,
    this.trailing,
    this.first = false,
  });

  final String name;
  final String email;
  final Widget? trailing;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: t.border2)),
            ),
      child: Row(
        children: [
          PersonAvatar(name: name, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                  ),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Pill neutra de role (`.role-pill`): uppercase pequeña sobre `surface2`.
class RolePill extends StatelessWidget {
  const RolePill({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(Dimens.rPill),
        border: Border.all(color: t.border2),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: t.textDim,
        ),
      ),
    );
  }
}
