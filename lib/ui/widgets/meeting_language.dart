import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/dashboard_provider.dart';
import '../../state/editor_session.dart';

/// Marks its subtree as content in the congregation's MEETING language rather
/// than the interface's.
///
/// The two are deliberately independent — someone runs the app in English for
/// a congregation that meets in Spanish — so a workbook heading or a part
/// title sits inside a screen written in another language. Sighted readers see
/// the switch; a screen reader does not, and reads Spanish text with an
/// English voice until something tells it otherwise. That is WCAG 3.1.2, and
/// `localeForSubtree` is what tells it.
///
/// Wrap only text that actually comes from the workbook. Everything the app
/// translates itself — slot labels, section titles, the song line — is in the
/// interface's language and marking it would be the same error inverted.
class MeetingLanguage extends ConsumerWidget {
  const MeetingLanguage({super.key, required this.child, this.congregationId});

  /// [child] wrapped only when [on] — for a call site that renders both kinds
  /// of string through the same widget and knows which one it has.
  static Widget maybe({
    required bool on,
    required Widget child,
    String? congregationId,
  }) => on
      ? MeetingLanguage(congregationId: congregationId, child: child)
      : child;

  final Widget child;

  /// Whose meeting language this is. Defaults to the congregation of the open
  /// editor, which is right for anything inside the workspace; the dashboard
  /// shows several congregations at once and has to say which.
  final String? congregationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = congregationId ?? ref.watch(editorCongregationIdProvider);
    // No congregation, no meeting language to declare; the subtree keeps the
    // interface's, which is the only thing known about it.
    if (id == null || id.isEmpty) return child;
    return Semantics(
      localeForSubtree: ref.watch(meetingLocaleProvider(id)).flutterLocale,
      child: child,
    );
  }
}
