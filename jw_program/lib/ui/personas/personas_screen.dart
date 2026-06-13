import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/hermano.dart';
import '../../state/hermanos_provider.dart';
import '../../state/import_export_provider.dart';
import '../responsive.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/labeled_field.dart';
import 'dialogos_io.dart';
import 'persona_form.dart';
import 'persona_row.dart';

/// Pantalla dedicada de gestión del directorio de hermanos (la
/// administración NO vive en el picker). Escritorio: lista + panel lateral
/// de edición; móvil: lista + FAB + bottom sheet.
class PersonasScreen extends ConsumerStatefulWidget {
  const PersonasScreen({super.key});

  @override
  ConsumerState<PersonasScreen> createState() => _PersonasScreenState();
}

class _PersonasScreenState extends ConsumerState<PersonasScreen> {
  String _query = '';
  Privilegio? _privilegio;
  String? _congregacion;
  bool _mostrarInactivos = false;
  bool _filtrosVisibles = false; // móvil: fila de filtros plegable

  /// Selección del panel lateral de escritorio. null + !_creando = cerrado.
  Hermano? _editando;
  bool _creando = false;

  void _abrirForm(Hermano? h) {
    if (context.isMobile) {
      final t = context.tokens;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: t.surface,
        barrierColor: const Color(0x47000000),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(Dimens.rSheet)),
        ),
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85),
            child: PersonaForm(
              key: ValueKey(h?.id ?? 'alta'),
              original: h,
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
          ),
        ),
      );
    } else {
      setState(() {
        _editando = h;
        _creando = h == null;
      });
    }
  }

  void _cerrarForm() => setState(() {
        _editando = null;
        _creando = false;
      });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isMobile = context.isMobile;
    final asyncTodos = ref.watch(hermanosTodosProvider);
    final todos = asyncTodos.asData?.value ?? const <Hermano>[];
    final activos = todos.where((h) => h.activo).length;
    final filtrados = filtrarHermanos(
      todos,
      query: _query,
      privilegio: _privilegio,
      congregacion: _congregacion,
      incluirInactivos: _mostrarInactivos,
    );
    final formAbierto = !isMobile && (_editando != null || _creando);

    return Scaffold(
      floatingActionButton: isMobile
          ? FloatingActionButton(
              backgroundColor: t.accent,
              foregroundColor: t.accentInk,
              onPressed: () => _abrirForm(null),
              child: const Icon(Icons.person_add_alt),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _cabecera(t, isMobile, activos),
            if (!isMobile || _filtrosVisibles) _filtros(t, isMobile),
            Expanded(
              child: asyncTodos.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _error(t, e),
                data: (_) => Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: filtrados.isEmpty
                          ? _vacio(t, todos.isEmpty)
                          : ListView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: filtrados.length,
                              itemBuilder: (context, i) => PersonaRow(
                                hermano: filtrados[i],
                                selected: _editando?.id == filtrados[i].id,
                                onTap: () => _abrirForm(filtrados[i]),
                              ),
                            ),
                    ),
                    if (formAbierto)
                      Container(
                        width: 360,
                        decoration: BoxDecoration(
                          color: t.surface,
                          border: Border(left: BorderSide(color: t.border)),
                        ),
                        child: PersonaForm(
                          key: ValueKey(_editando?.id ?? 'alta'),
                          original: _editando,
                          onClose: _cerrarForm,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecera(AppTokens t, bool isMobile, int activos) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 18, vertical: isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Volver al programa',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Hermanos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: t.text,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$activos activos',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: t.textMute,
            ),
          ),
          const Spacer(),
          if (isMobile) ...[
            AppIconButton(
              icon: Icons.filter_list,
              bordered: _filtrosVisibles,
              tooltip: 'Filtros',
              onPressed: () =>
                  setState(() => _filtrosVisibles = !_filtrosVisibles),
            ),
            const SizedBox(width: 8),
            _menuIo(t),
          ] else ...[
            _botonesIo(),
            const SizedBox(width: 8),
            AppButton(
              icon: Icons.person_add_alt,
              label: 'Añadir',
              onPressed: () => _abrirForm(null),
            ),
          ],
        ],
      ),
    );
  }

  /// Importar/Exportar en escritorio (botones ghost).
  Widget _botonesIo() {
    final busy = ref.watch(personasIoBusyProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          variant: AppButtonVariant.ghost,
          icon: Icons.file_open_outlined,
          label: 'Importar',
          busy: busy,
          onPressed:
              busy ? null : () => importarParticipantes(context, ref),
        ),
        const SizedBox(width: 8),
        AppButton(
          variant: AppButtonVariant.ghost,
          icon: Icons.file_upload_outlined,
          label: 'Exportar',
          onPressed:
              busy ? null : () => exportarParticipantes(context, ref),
        ),
      ],
    );
  }

  /// Importar/Exportar en móvil (menú ⋮).
  Widget _menuIo(AppTokens t) {
    final busy = ref.watch(personasIoBusyProvider);
    return PopupMenuButton<String>(
      enabled: !busy,
      icon: Icon(Icons.more_vert, size: 19, color: t.textDim),
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.rControl),
        side: BorderSide(color: t.border),
      ),
      onSelected: (v) => v == 'importar'
          ? importarParticipantes(context, ref)
          : exportarParticipantes(context, ref),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'importar', child: Text('Importar…')),
        PopupMenuItem(value: 'exportar', child: Text('Exportar…')),
      ],
    );
  }

  Widget _filtros(AppTokens t, bool isMobile) {
    final congregaciones = ref.watch(congregacionesProvider);
    final buscador = TextField(
      onChanged: (v) => setState(() => _query = v),
      style:
          TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: t.text),
      decoration: InputDecoration(
        hintText: 'Buscar hermano…',
        prefixIcon: Icon(Icons.search, size: 16, color: t.textMute),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 16),
      ),
    );

    final filtroPrivilegio = AppDropdown<Privilegio?>(
      value: _privilegio,
      items: [null, ...Privilegio.values],
      itemLabel: (p) => p?.etiqueta ?? 'Todos los privilegios',
      onChanged: (v) => setState(() => _privilegio = v),
    );
    final filtroCongregacion = AppDropdown<String?>(
      value: _congregacion,
      items: [null, ...congregaciones],
      itemLabel: (c) => c ?? 'Todas las congregaciones',
      onChanged: (v) => setState(() => _congregacion = v),
    );
    final inactivos = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _mostrarInactivos,
            onChanged: (v) => setState(() => _mostrarInactivos = v),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Inactivos',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _mostrarInactivos ? t.text : t.textDim,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border2)),
      ),
      child: isMobile
          ? Column(
              children: [
                buscador,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: filtroPrivilegio),
                    const SizedBox(width: 8),
                    Expanded(child: filtroCongregacion),
                  ],
                ),
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerLeft, child: inactivos),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: buscador),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: filtroPrivilegio),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: filtroCongregacion),
                const SizedBox(width: 12),
                inactivos,
              ],
            ),
    );
  }

  Widget _vacio(AppTokens t, bool sinDatos) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 40, color: t.textMute),
            const SizedBox(height: 12),
            Text(
              sinDatos
                  ? 'Aún no hay hermanos.\nAñade el primero o importa un archivo .jwpp.'
                  : 'Sin resultados con los filtros actuales.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: t.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(AppTokens t, Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No se pudo abrir la base de datos local.\n$e',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}
