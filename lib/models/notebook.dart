/// Workbook (issue) of the Christian Life and Ministry: a period with its
/// weeks. Feeds the project modal to offer the available weeks.
class Notebook {
  final String id;
  final String label;
  final List<String> weeks;

  const Notebook({
    required this.id,
    required this.label,
    required this.weeks,
  });
}
