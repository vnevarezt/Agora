import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/mwb_calendar.dart';
import '../../i18n/strings.g.dart';
import '../../models/notebook.dart';
import '../../state/mwb_sync.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'app_modal.dart';
import 'dashed_border.dart';
import 'modal_shell.dart';
import 'motion.dart';
import 'notebook_drop.dart';

/// Whether this build has to be handed its notebooks rather than fetching them.
///
/// True on web only: jw.org's lookup API sends `access-control-allow-origin:
/// *`, but every file it points at comes from a host that sends no CORS header
/// at all and answers 403 to a preflight, so the browser cannot read the
/// workbook whatever the page's policy says.
bool get notebooksMustBeImported => kIsWeb;

/// The two steps, in an app modal: fetch the file from jw.org, then hand it
/// back.
///
/// Both halves are one tap because the app knows exactly which file is wanted —
/// the lookup API is reachable from the browser even though the file is not, so
/// the download button goes straight to `mwb_S_202607.epub` rather than leaving
/// someone to find it on jw.org themselves.
Future<void> showNotebookImportDialog(BuildContext context) =>
    showAppModal<void>(
      context,
      builder: (_, sheet, close) =>
          _NotebookImportModal(sheet: sheet, onClose: close),
    );

class _NotebookImportModal extends ConsumerStatefulWidget {
  const _NotebookImportModal({required this.sheet, required this.onClose});

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<_NotebookImportModal> createState() => _ModalState();
}

class _ModalState extends ConsumerState<_NotebookImportModal> {
  bool _importing = false;

  Future<void> _pick() => _fileIn(() => importNotebook(context, ref));

  Future<void> _fileIn(Future<bool> Function() take) async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      if (await take() && mounted) widget.onClose();
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needed = ref.watch(offerableNotebooksProvider);
    // Only worth naming the language when two of them want the same period.
    final showLang = needed.map((n) => n.lang).toSet().length > 1;

    return NotebookDropTarget(
      onFile: (bytes) => unawaited(
          _fileIn(() => importNotebookBytes(context, ref, bytes))),
      builder: (context, hovering) => _shell(context, needed, showLang, hovering),
    );
  }

  Widget _shell(
      BuildContext context,
      List<({String issue, String lang, bool have})> needed,
      bool showLang,
      bool hovering) {
    final t = context.tokens;
    final tr = context.t;
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.workspace.importTitle,
      desc: tr.workspace.importIntro,
      primaryLabel: tr.workspace.importPick,
      primaryBusy: _importing,
      onPrimary: _importing ? null : _pick,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Step(n: '1', label: tr.workspace.importStepDownload),
          const SizedBox(height: Space.s10),
          for (final target in needed)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s8),
              child: _NotebookRow(target: target, showLang: showLang),
            ),
          const SizedBox(height: Space.s6),
          _Step(n: '2', label: tr.workspace.importStepOpen),
          const SizedBox(height: Space.s8),
          if (notebookDropSupported)
            _DropZone(hovering: hovering)
          else
            Padding(
              padding: const EdgeInsets.only(left: Space.s24 + Space.s6),
              child: Text(
                tr.workspace.importStepOpenHint,
                style: TextStyle(
                  fontSize: AppText.small,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: t.textMute,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One required workbook: which period it is, whether it is already loaded,
/// and the button that fetches it from jw.org.
///
/// The link is resolved while the row builds rather than when it is tapped.
/// Looking it up on tap puts an await between the click and the navigation,
/// which is what a popup blocker stops, and it let the button offer a download
/// for an issue jw.org has not published yet — whose only answer was an error
/// after the fact.
class _NotebookRow extends ConsumerWidget {
  const _NotebookRow({required this.target, required this.showLang});

  final ({String issue, String lang, bool have}) target;
  final bool showLang;

  /// A navigation, not a fetch: the browser takes the file exactly as it would
  /// from jw.org's own page, so the host's missing CORS header — the reason
  /// the app cannot read it itself — never comes into it.
  void _download(String url) =>
      launchUrl(Uri.parse(url), webOnlyWindowName: '_self');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tr = context.t;
    final link = ref.watch(
        notebookLinkProvider((issue: target.issue, lang: target.lang)));
    final label = labelForIssue(target.issue, tr.monthNames);

    final (String status, Color tone, IconData mark) = switch (target) {
      _ when target.have => (
          tr.workspace.importLoaded,
          t.successStrong,
          Icons.check_circle_rounded,
        ),
      _ when link.hasError => (
          tr.workspace.importUnavailable,
          t.textMute,
          Icons.remove_circle_outline_rounded,
        ),
      _ => (
          tr.workspace.importMissing,
          t.warningStrong,
          Icons.radio_button_unchecked_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(
          Space.s12, Space.s10, Space.s10, Space.s10),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(Dimens.rControl),
        border: Border.all(color: t.border2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showLang ? '$label · ${target.lang}' : label,
                  style: TextStyle(
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: Space.s2),
                Row(
                  children: [
                    Icon(mark, size: AppIcon.inline, color: tone),
                    const SizedBox(width: Space.s6),
                    Flexible(
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: AppText.caption,
                          fontWeight: FontWeight.w600,
                          color: tone,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.s10),
          AppButton(
            variant: AppButtonVariant.ghost,
            icon: Icons.file_download_outlined,
            label: tr.workspace.importDownload,
            busy: link.isLoading,
            onPressed:
                link.hasValue ? () => _download(link.requireValue) : null,
          ),
        ],
      ),
    );
  }
}

/// Where the downloaded file lands. Dashed, because the border is an
/// invitation rather than an edge — the same shape the empty avatar and the
/// unassigned slot use to say "put something here".
class _DropZone extends StatelessWidget {
  const _DropZone({required this.hovering});

  final bool hovering;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final tone = hovering ? t.accentStrong : t.textMute;

    return DashedBorder(
      color: hovering ? t.accent : t.border,
      radius: Dimens.rControl,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.instant),
        curve: Motion.curve,
        padding: const EdgeInsets.symmetric(vertical: Space.s18),
        decoration: BoxDecoration(
          color: hovering ? t.accentTint : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimens.rControl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_download_outlined,
                size: AppIcon.control, color: tone),
            const SizedBox(height: Space.s6),
            Text(
              tr.workspace.importDropHere,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppText.small,
                fontWeight: FontWeight.w700,
                color: hovering ? t.accentStrong : t.textDim,
              ),
            ),
            const SizedBox(height: Space.s2),
            Text(
              tr.workspace.importDropOr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppText.caption,
                fontWeight: FontWeight.w600,
                color: t.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.label});

  final String n;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Container(
          width: Space.s24,
          height: Space.s24,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: t.accentTint, shape: BoxShape.circle),
          child: Text(n,
              style: TextStyle(
                  fontSize: AppText.micro,
                  fontWeight: FontWeight.w800,
                  color: t.accentStrong)),
        ),
        const SizedBox(width: Space.s6),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: AppText.body,
                  fontWeight: FontWeight.w700,
                  color: t.text)),
        ),
      ],
    );
  }
}

/// Picks a workbook EPUB and files it. Returns true when one was imported.
///
/// Lives here rather than in either caller because there are two places a
/// person can be standing when they find out no notebook is available — the
/// dashboard's catalog card and the editor's empty program — and an answer
/// offered in only one of them is an answer nobody finds.
Future<bool> importNotebook(BuildContext context, WidgetRef ref) async {
  final file = await openFile(acceptedTypeGroups: [
    const XTypeGroup(label: 'EPUB', extensions: ['epub']),
  ]);
  if (file == null) return false;
  final bytes = await file.readAsBytes();
  if (!context.mounted) return false;
  return importNotebookBytes(context, ref, bytes);
}

/// Files a workbook already in hand — picked, or dropped on the page — and
/// says what it turned out to be. Returns true when one was imported.
Future<bool> importNotebookBytes(
    BuildContext context, WidgetRef ref, Uint8List bytes) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final tr = context.t;
  try {
    final imported = await ref.read(notebookImportProvider).run(bytes);
    messenger?.showSnackBar(SnackBar(
      content: Text(
          tr.workspace.importDone(issue: imported.issue, n: imported.weeks)),
    ));
    return true;
  } on FormatException {
    messenger?.showSnackBar(
        SnackBar(content: Text(tr.workspace.importNotWorkbook)));
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text('$e')));
  }
  return false;
}
