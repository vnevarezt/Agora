import '../domain/mwb_calendar.dart';
import '../i18n/strings.g.dart';

/// A week as the catalog offers it: what it IS, and how this workbook prints
/// it. The two are separate because only the first survives a change of
/// meeting language — [start] is the same date in every language, [label] is
/// not. [start] is empty only when a heading could not be resolved.
typedef WeekRef = ({String start, String label});

/// Workbook (issue) of the Christian Life and Ministry: a period with its
/// weeks. Feeds the project modal to offer the available weeks.
class Notebook {
  /// Issue id, `YYYYMM` (see `domain/mwb_calendar.dart`). This is the identity
  /// AND the source of the display label — see [NotebookX.label].
  final String id;
  final List<WeekRef> weeks;

  const Notebook({required this.id, required this.weeks});
}

extension NotebookX on Notebook {
  /// Display label ('Mayo–Junio 2026'), resolved at render time from [tr].
  ///
  /// Deliberately NOT a stored field: the catalog is built once at startup by
  /// `state/mwb_sync.dart`, so a label baked in there would keep the language
  /// it was built with until the next restart.
  String label(Translations tr) => labelForIssue(id, tr.monthNames);
}

/// The 12 month names, January first — the shape [labelForIssue] expects.
///
/// Declared on the base-locale class, which every other locale's generated
/// class extends, so this resolves for whichever [Translations] is passed in.
extension MonthNamesX on Translations {
  List<String> get monthNames => [
    months.january,
    months.february,
    months.march,
    months.april,
    months.may,
    months.june,
    months.july,
    months.august,
    months.september,
    months.october,
    months.november,
    months.december,
  ];
}
