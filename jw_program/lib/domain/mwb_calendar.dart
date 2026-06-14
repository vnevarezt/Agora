/// Pure helpers for the bimonthly Meeting Workbook (mwb) calendar.
///
/// Each issue is identified by `YYYYMM`, where MM is the **odd** starting month
/// of a two-month period: 01 (Jan–Feb), 03 (Mar–Apr), 05 (May–Jun),
/// 07 (Jul–Aug), 09 (Sep–Oct), 11 (Nov–Dec). An issue covers its month and the
/// following one. No Flutter / network dependencies: testable in isolation, like
/// `schedule_rules.dart`.
library;

const List<String> _monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

/// Odd starting month of the period that contains [month] (1..12).
int _oddMonth(int month) => month - ((month - 1) % 2);

String _pad4(int v) => v.toString().padLeft(4, '0');
String _pad2(int v) => v.toString().padLeft(2, '0');

int _year(String issue) => int.parse(issue.substring(0, 4));
int _month(String issue) => int.parse(issue.substring(4, 6));

/// Issue (`YYYYMM`) that contains date [d]. E.g. 2026-06-14 -> '202605'.
String issueForDate(DateTime d) => '${_pad4(d.year)}${_pad2(_oddMonth(d.month))}';

/// First day of the issue's period: (year, oddMonth, 1).
DateTime issueStart(String issue) => DateTime(_year(issue), _month(issue), 1);

/// First day **after** the issue's period (== start of the next issue).
DateTime issueEnd(String issue) => DateTime(_year(issue), _month(issue) + 2, 1);

/// Issue of the following two-month period (rolls the year over: 11 -> 01).
String nextIssue(String issue) {
  final m = _month(issue);
  return m == 11 ? '${_pad4(_year(issue) + 1)}01' : '${_pad4(_year(issue))}${_pad2(m + 2)}';
}

/// Issue of the previous two-month period (rolls the year back: 01 -> 11).
String prevIssue(String issue) {
  final m = _month(issue);
  return m == 1 ? '${_pad4(_year(issue) - 1)}11' : '${_pad4(_year(issue))}${_pad2(m - 2)}';
}

/// Ordered list of issues needed to cover from [from] through
/// [from] + [monthsAhead] months. Always includes the current issue and adds
/// following issues until coverage reaches the horizon.
///
/// E.g. `requiredIssues(2026-06-14, monthsAhead: 2) == ['202605', '202607']`.
List<String> requiredIssues(DateTime from, {int monthsAhead = 2}) {
  final horizon = DateTime(from.year, from.month + monthsAhead, from.day);
  final issues = <String>[issueForDate(from)];
  while (!issueEnd(issues.last).isAfter(horizon)) {
    issues.add(nextIssue(issues.last));
  }
  return issues;
}

/// Human label for an issue, e.g. '202605' -> 'Mayo–Junio 2026'. The second
/// month is always within the same year (odd month + 1 is at most December).
String labelForIssue(String issue) {
  final m = _month(issue);
  return '${_monthNames[m - 1]}–${_monthNames[m]} ${_year(issue)}';
}
