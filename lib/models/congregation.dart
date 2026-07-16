import 'congregation_settings.dart';

/// Congregation a project belongs to. The [color] (0xAARRGGBB) is its dot in
/// the filters/cards; the UI wraps it in a Color. [settings] carries the
/// meeting schedule/language parsed from the row's settingsJson.
class Congregation {
  final String id;
  final String name;
  final String number;
  final int color;
  final CongregationSettings settings;

  const Congregation({
    required this.id,
    required this.name,
    required this.number,
    required this.color,
    this.settings = const CongregationSettings(),
  });
}
