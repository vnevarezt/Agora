import 'congregation_settings.dart';

/// [color] is 0xAARRGGBB; [settings] is parsed from the row's settingsJson.
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
