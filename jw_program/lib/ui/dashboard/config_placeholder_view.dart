import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Placeholder de la sección Configuración. Se construye en una fase posterior.
class ConfigPlaceholderView extends StatelessWidget {
  const ConfigPlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_outlined, size: 40, color: t.textMute),
          const SizedBox(height: 14),
          Text('Configuración', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Próximamente',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: t.textMute,
            ),
          ),
        ],
      ),
    );
  }
}
