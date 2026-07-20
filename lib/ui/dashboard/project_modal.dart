import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../domain/mwb_calendar.dart';
import '../../models/congregation.dart';
import '../../models/notebook.dart';
import '../../models/project.dart';
import '../../state/dashboard_provider.dart';
import '../../state/program_content.dart';
import '../../state/sync_provider.dart';
import '../responsive.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/modal_shell.dart';
import '../widgets/filter_pill.dart';
import '../widgets/labeled_field.dart';

/// Opens the create/edit project modal. [project] null = new.
Future<void> showProjectModal(BuildContext context, {Project? project}) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        ProjectModal(original: project, sheet: sheet, onClose: close),
  );
}

/// Project modal content. Reads/writes via Riverpod.
class ProjectModal extends ConsumerStatefulWidget {
  const ProjectModal({
    super.key,
    this.original,
    required this.onClose,
    this.sheet = false,
  });

  /// null = new project.
  final Project? original;
  final VoidCallback onClose;

  /// true when presented as a bottom sheet (mobile).
  final bool sheet;

  @override
  ConsumerState<ProjectModal> createState() => _ProjectModalState();
}

class _ProjectModalState extends ConsumerState<ProjectModal> {
  late String _name = widget.original?.name ?? '';
  late String _congregationId;
  late String _notebookId;
  late List<String> _weeks = List.of(widget.original?.weeks ?? const []);

  bool get _isNew => widget.original == null;

  /// A project doc needs `admin` or ANY edit type — the same condition the
  /// `items` rule applies to entity 'project'.
  bool get _canEdit {
    if (_congregationId.isEmpty) return true;
    final rights = ref.watch(rightsProvider(_congregationId));
    return rights.admin || rights.editTypes.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    final congregations = ref.read(congregationsProvider);
    final notebooks = ref.read(notebooksProvider);
    _congregationId = widget.original?.congregationId ??
        (congregations.isNotEmpty ? congregations.first.id : '');
    // New project: starts at the current notebook (the one covering today), not
    // the oldest cached one. When editing, keep the first in the catalog.
    final current = issueForDate(DateTime.now());
    _notebookId = _isNew && notebooks.any((n) => n.id == current)
        ? current
        : (notebooks.isNotEmpty ? notebooks.first.id : '');
  }

  /// Toggles a notebook week, preserving the notebook order and the "extra"
  /// weeks (from other notebooks) at the end.
  void _toggle(String w, Notebook notebook) {
    setState(() {
      if (_weeks.contains(w)) {
        _weeks = _weeks.where((x) => x != w).toList();
      } else {
        final extra =
            _weeks.where((x) => !notebook.weeks.contains(x)).toList();
        _weeks = [
          ...notebook.weeks.where((x) => _weeks.contains(x) || x == w),
          ...extra,
        ];
      }
    });
  }

  void _remove(String w) =>
      setState(() => _weeks = _weeks.where((x) => x != w).toList());

  /// Default name when the field is empty.
  String _autoName(Notebook notebook) {
    if (_name.trim().isNotEmpty) return _name.trim();
    if (_weeks.isEmpty) return '';
    final base = notebook.label.split('–').first.trim();
    return t.projectModal.autoName(n: _weeks.length, base: base);
  }

  Future<void> _save(Notebook notebook) async {
    final name = _autoName(notebook);
    final actions = ref.read(projectActionsProvider);
    final String projectId;
    if (_isNew) {
      projectId = await actions.create(
          name: name, congregationId: _congregationId, weeks: _weeks);
    } else {
      projectId = widget.original!.id;
      await actions.update(projectId,
          name: name, congregationId: _congregationId, weeks: _weeks);
    }
    // Fire-and-forget: snapshots the picked weeks' content onto the
    // programs (retried on editor open if a notebook wasn't cached yet).
    unawaited(ref
        .read(programContentServiceProvider)
        .ensureProjectContent(projectId));
    widget.onClose();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t.projectModal.deleteTitle),
        content: Text(
          context.t.projectModal.deleteConfirm(name: widget.original!.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.t.common.delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(projectActionsProvider).delete(widget.original!.id);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final tr = context.t;
    final congregations = ref.watch(congregationsProvider);
    final notebooks = ref.watch(notebooksProvider);

    final desc = tr.projectModal.desc;
    final title = _isNew ? tr.projectModal.newTitle : tr.projectModal.editTitle;

    if (notebooks.isEmpty) {
      return ModalShell(
        sheet: widget.sheet,
        onClose: widget.onClose,
        title: title,
        desc: desc,
        body: EmptyState(
          icon: Icons.menu_book_outlined,
          message: tr.projectModal.noNotebooks,
        ),
        primaryLabel: tr.common.understood,
        onPrimary: widget.onClose,
      );
    }

    final notebook = notebooks.firstWhere((c) => c.id == _notebookId,
        orElse: () => notebooks.first);
    final extra = _weeks.where((x) => !notebook.weeks.contains(x)).toList();
    final autoName = _autoName(notebook);

    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: title,
      desc: desc,
      body: _body(context.tokens, tr, isMobile, congregations, notebooks,
          notebook, extra, autoName),
      primaryLabel: _isNew ? tr.projectModal.create : tr.common.saveChanges,
      onPrimary:
          (_canEdit && _weeks.isNotEmpty) ? () => _save(notebook) : null,
      onDanger: (_isNew || !_canEdit) ? null : _delete,
    );
  }

  Widget _body(
    AppTokens t,
    Translations tr,
    bool isMobile,
    List<Congregation> congregations,
    List<Notebook> notebooks,
    Notebook notebook,
    List<String> extra,
    String autoName,
  ) {
    final congField = LabeledField(
      label: tr.projectModal.congregation,
      child: AppDropdown<String>(
        value: _congregationId,
        items: [for (final c in congregations) c.id],
        itemLabel: (id) => congregations.firstWhere((c) => c.id == id).name,
        onChanged: (v) => setState(() => _congregationId = v),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        congField,
        const SizedBox(height: 14),
        LabeledField(
          label: tr.projectModal.weeksToInclude(n: _weeks.length),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notebooks as tabs: picking one changes the week chips below. Weeks
              // already picked from OTHER notebooks stay as "extra" chips (marked, at
              // the end).
              if (notebooks.length > 1) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in notebooks)
                      FilterPill(
                        label: c.label,
                        active: c.id == _notebookId,
                        onTap: () => setState(() => _notebookId = c.id),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final w in notebook.weeks)
                    _WeekToggle(
                      label: w,
                      active: _weeks.contains(w),
                      onTap: () => _toggle(w, notebook),
                    ),
                  for (final w in extra)
                    _WeekToggle(
                      label: w,
                      active: true,
                      extra: true,
                      onTap: () => _remove(w),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: tr.projectModal.projectName,
          child: BoundTextField(
            initial: _name,
            hint: autoName.isNotEmpty ? autoName : tr.projectModal.nameHint,
            onChanged: (v) => setState(() => _name = v),
          ),
        ),
      ],
    );
  }

}

/// Week toggle (`.week-toggle`): rectangular, 1.5 border, tabular figures.
class _WeekToggle extends StatelessWidget {
  const _WeekToggle({
    required this.label,
    required this.active,
    required this.onTap,
    this.extra = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  /// Week from another notebook: tap removes it.
  final bool extra;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      tooltip: extra ? context.t.projectModal.fromOtherNotebook : null,
      builder: (context, hovered, _) {
        final fg = active ? t.accentInk : (hovered ? t.text : t.textDim);
        return AnimatedContainer(
          duration: Dimens.dFast,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: active ? t.accent : t.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: active ? t.accent : (hovered ? t.accent : t.border),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
      },
    );
  }
}
