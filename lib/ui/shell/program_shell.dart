import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project.dart';
import '../../state/editor_session.dart';
import '../../state/ui_state.dart';
import '../preview/preview_pane.dart';
import '../responsive.dart';
import '../workspace/workspace_panel.dart';
import 'mobile_bars.dart';
import 'project_bar.dart';

/// Editor root screen. The single place that decides the layout: desktop/
/// tablet in two panels (46/54) and mobile in one column with tabs; both
/// arrangements use the same [WorkspacePanel] and [PreviewPane].
///
/// Opening/closing the editor session lives here: the form hydrates from
/// the project's DB rows on entry and the programs stream stops on exit.
class ProgramShell extends ConsumerStatefulWidget {
  const ProgramShell({super.key, this.project});

  /// Project opened from the dashboard (bar identity). Optional.
  final Project? project;

  @override
  ConsumerState<ProgramShell> createState() => _ProgramShellState();
}

class _ProgramShellState extends ConsumerState<ProgramShell> {
  // `ref` is unsafe inside dispose (Riverpod): capture the opener up front.
  late final EditorOpener _opener = ref.read(editorOpenerProvider);

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    // Providers must not change during widget lifecycles: defer past the
    // current build (open/close flip editorProjectProvider).
    if (project != null) Future.microtask(() => _opener.open(project));
  }

  @override
  void dispose() {
    if (widget.project != null) Future.microtask(_opener.close);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final isMobile = context.isMobile;

    return Scaffold(
      body: SafeArea(
        bottom: false, // la bottom bar móvil gestiona su propio inset
        child: Column(
          children: [
            ProjectBar(project: project),
            if (isMobile) const MobileTabs(),
            Expanded(
              child: isMobile
                  ? const _MobileBody()
                  : const Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 46, child: WorkspacePanel()),
                        Expanded(
                          flex: 54,
                          child: PreviewPane(showLeftBorder: true),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile body: the tabs switch panels with [IndexedStack] (the preview
/// zoom survives tab changes) and the bottom bar floats above with its
/// frosted glass.
class _MobileBody extends ConsumerWidget {
  const _MobileBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(mobileTabProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: tab.index,
            children: const [WorkspacePanel(), PreviewPane()],
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MobileBottomBar(),
        ),
      ],
    );
  }
}
