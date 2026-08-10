import '../domain/mwb_calendar.dart';
import '../i18n/strings.g.dart';

class Notebook {
  /// Issue id, `YYYYMM` — identity and source of the label ([NotebookX.label]).
  final String id;
  final List<String> weeks;

  const Notebook({required this.id, required this.weeks});
}

extension NotebookX on Notebook {
  /// Display label ('Mayo–Junio 2026'). NOT a stored field: the catalog is
  /// built once at startup, so a baked-in label would keep the language it was
  /// built with until the next restart.
  String label(Translations tr) => labelForIssue(id, tr.monthNames);
}

/// The 12 month names, January first. Declared on the base-locale class, which
/// every other locale's generated class extends.
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
