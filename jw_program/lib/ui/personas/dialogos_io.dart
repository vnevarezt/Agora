import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/participantes_codec.dart';
import '../../state/import_export_provider.dart';
import '../theme/tokens.dart';

/// Flujos completos de import/export de participantes (.jwpp): diálogos de
/// contraseña, selección de archivo (escritorio) u hoja de compartir
/// (móvil), preview Fusionar/Reemplazar y aplicación.

const _grupoJwpp = XTypeGroup(
  label: 'JW Program Participantes',
  extensions: ['jwpp'],
  // macOS/iOS filtran por UTI (declarado en Info.plist).
  uniformTypeIdentifiers: ['com.vicentcodes.jwprogram.jwpp'],
);

bool get _esMovil => Platform.isIOS || Platform.isAndroid;

String _nombreSugerido() {
  final d = DateTime.now();
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return 'participantes-${d.year}$mm$dd.jwpp';
}

enum ModoImport { fusionar, reemplazar }

// ---------------------------------------------------------------------------
// Exportar
// ---------------------------------------------------------------------------

Future<void> exportarParticipantes(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final password = await _pedirPasswordExport(context);
  if (password == null) return; // cancelado

  ref.read(personasIoBusyProvider.notifier).set(true);
  try {
    final (bytes, total) = await ref
        .read(participantesIoProvider)
        .exportarBytes(password: password.isEmpty ? null : password);

    if (_esMovil) {
      final dir = await getTemporaryDirectory();
      final ruta =
          '${dir.path}${Platform.pathSeparator}${_nombreSugerido()}';
      await File(ruta).writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(ruta)]));
    } else {
      final destino = await getSaveLocation(
        suggestedName: _nombreSugerido(),
        acceptedTypeGroups: const [_grupoJwpp],
      );
      if (destino == null) return; // cancelado
      // El panel de macOS no fuerza la extensión: añadirla a mano.
      var ruta = destino.path;
      if (!ruta.toLowerCase().endsWith('.jwpp')) ruta += '.jwpp';
      await File(ruta).writeAsBytes(bytes);
    }
    messenger.showSnackBar(SnackBar(
        content: Text(
            'Exportados $total hermanos${password.isEmpty ? '' : ' (cifrado)'}.')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
  } finally {
    ref.read(personasIoBusyProvider.notifier).set(false);
  }
}

/// Devuelve la contraseña ('' = exportar sin cifrar) o null si se cancela.
Future<String?> _pedirPasswordExport(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      final t = context.tokens;
      var pass = '';
      var confirmacion = '';
      return StatefulBuilder(
        builder: (context, setState) {
          final coinciden = pass == confirmacion;
          return AlertDialog(
            title: const Text('Exportar hermanos'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  autofocus: true,
                  obscureText: true,
                  decoration: const InputDecoration(
                      hintText: 'Contraseña (opcional)'),
                  onChanged: (v) => setState(() => pass = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  obscureText: true,
                  enabled: pass.isNotEmpty,
                  decoration: InputDecoration(
                    hintText: 'Confirmar contraseña',
                    errorText: pass.isNotEmpty && !coinciden
                        ? 'Las contraseñas no coinciden.'
                        : null,
                  ),
                  onChanged: (v) => setState(() => confirmacion = v),
                ),
                const SizedBox(height: 12),
                Text(
                  'Déjala vacía para exportar sin cifrar. Si la olvidas, '
                  'el archivo no se podrá recuperar.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: pass.isEmpty || coinciden
                    ? () => Navigator.of(context).pop(pass)
                    : null,
                child: const Text('Exportar'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Importar
// ---------------------------------------------------------------------------

Future<void> importarParticipantes(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final archivo = await openFile(acceptedTypeGroups: const [
    _grupoJwpp,
    XTypeGroup(label: 'Todos los archivos'),
  ]);
  if (archivo == null || !context.mounted) return;

  final io = ref.read(participantesIoProvider);
  ref.read(personasIoBusyProvider.notifier).set(true);
  try {
    final bytes = await archivo.readAsBytes();
    final info = leerCabeceraJwpp(bytes);

    ImportPreparado? prep;
    if (!info.cifrado) {
      prep = await io.prepararImport(bytes);
    } else {
      var reintento = false;
      while (prep == null) {
        if (!context.mounted) return;
        final password =
            await _pedirPasswordImport(context, reintento: reintento);
        if (password == null) return; // cancelado
        try {
          prep = await io.prepararImport(bytes, password: password);
        } on JwppPasswordException {
          reintento = true;
        }
      }
    }

    final actuales = await io.contarLocales();
    if (!context.mounted) return;
    final modo = await _mostrarPreviewImport(context,
        prep: prep, actuales: actuales);
    if (modo == null) return;

    switch (modo) {
      case ModoImport.fusionar:
        await io.aplicarFusion(prep);
        messenger.showSnackBar(SnackBar(
            content: Text('Importado: ${prep.plan.nuevos} nuevos, '
                '${prep.plan.actualizados} actualizados, '
                '${prep.plan.iguales} sin cambios.')));
      case ModoImport.reemplazar:
        await io.aplicarReemplazo(prep);
        messenger.showSnackBar(SnackBar(
            content: Text(
                'Directorio reemplazado: ${prep.decodificado.hermanos.length} hermanos.')));
    }
  } on JwppVersionException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$e')));
  } on JwppFormatoException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$e')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Error al importar: $e')));
  } finally {
    ref.read(personasIoBusyProvider.notifier).set(false);
  }
}

Future<String?> _pedirPasswordImport(BuildContext context,
    {required bool reintento}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      var pass = '';
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Archivo cifrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reintento)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Contraseña incorrecta. Inténtalo de nuevo.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextField(
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Contraseña'),
                onChanged: (v) => setState(() => pass = v),
                onSubmitted: (v) => Navigator.of(context).pop(v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed:
                  pass.isEmpty ? null : () => Navigator.of(context).pop(pass),
              child: const Text('Abrir'),
            ),
          ],
        ),
      );
    },
  );
}

Future<ModoImport?> _mostrarPreviewImport(
  BuildContext context, {
  required ImportPreparado prep,
  required int actuales,
}) async {
  final t = context.tokens;
  final dec = prep.decodificado;
  final plan = prep.plan;

  Widget linea(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(k,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textDim)),
            ),
            Text(v,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: t.text)),
          ],
        ),
      );

  final modo = await showDialog<ModoImport>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Importar hermanos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          linea('En el archivo', '${dec.hermanos.length}'),
          if (dec.omitidos > 0)
            linea('Registros ilegibles (omitidos)', '${dec.omitidos}'),
          const Divider(height: 18),
          linea('Nuevos', '${plan.nuevos}'),
          linea('Actualizados', '${plan.actualizados}'),
          linea('Sin cambios', '${plan.iguales}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ModoImport.reemplazar),
          child: Text('Reemplazar todo…',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(ModoImport.fusionar),
          child: const Text('Fusionar'),
        ),
      ],
    ),
  );

  if (modo != ModoImport.reemplazar) return modo;
  if (!context.mounted) return null;

  // Confirmación destructiva del reemplazo.
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Reemplazar todo el directorio?'),
      content: Text(
          'Se eliminarán los $actuales hermanos actuales de este dispositivo '
          'y se cargarán los ${dec.hermanos.length} del archivo. '
          'Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Reemplazar',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    ),
  );
  return confirmado == true ? ModoImport.reemplazar : null;
}
