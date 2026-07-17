import 'dart:convert';

import 'package:drift/drift.dart';

/// `List<String>` ⇄ JSON array TEXT column (readable in exports/debug,
/// same rationale as storing enums as TEXT).
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
