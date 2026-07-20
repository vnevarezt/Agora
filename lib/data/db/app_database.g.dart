// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CongregationsTable extends Congregations
    with TableInfo<$CongregationsTable, CongregationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CongregationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingsJsonMeta = const VerificationMeta(
    'settingsJson',
  );
  @override
  late final GeneratedColumn<String> settingsJson = GeneratedColumn<String>(
    'settings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    name,
    number,
    color,
    settingsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'congregations';
  @override
  VerificationContext validateIntegrity(
    Insertable<CongregationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('settings_json')) {
      context.handle(
        _settingsJsonMeta,
        settingsJson.isAcceptableOrUnknown(
          data['settings_json']!,
          _settingsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CongregationRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CongregationRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      settingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings_json'],
      )!,
    );
  }

  @override
  $CongregationsTable createAlias(String alias) {
    return $CongregationsTable(attachedDatabase, alias);
  }
}

class CongregationRecord extends DataClass
    implements Insertable<CongregationRecord> {
  final String id;
  final DateTime createdAt;

  /// UTC. Only changes on user edits (never on bookkeeping like `lastUsed`):
  /// it decides the winner when merging imports, and later LWW sync.
  final DateTime updatedAt;

  /// Tombstone. Non-null = deleted (kept for sync replication + FK safety).
  final DateTime? deletedAt;

  /// Hybrid logical clock stamp. Unused until phase 3; present so adding
  /// sync never needs an ALTER on data tables.
  final String? hlc;
  final String name;
  final String number;

  /// 0xAARRGGBB dot shown in filters/cards (same semantics as the old
  /// in-memory model; the UI wraps it in a Color).
  final int color;

  /// Meeting weekday/time, aux-class count, circuit + CO name… consumed by
  /// the program templates (phase 2). JSON so template-driven settings can
  /// grow without schema migrations.
  final String settingsJson;
  const CongregationRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.hlc,
    required this.name,
    required this.number,
    required this.color,
    required this.settingsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || hlc != null) {
      map['hlc'] = Variable<String>(hlc);
    }
    map['name'] = Variable<String>(name);
    map['number'] = Variable<String>(number);
    map['color'] = Variable<int>(color);
    map['settings_json'] = Variable<String>(settingsJson);
    return map;
  }

  CongregationsCompanion toCompanion(bool nullToAbsent) {
    return CongregationsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      hlc: hlc == null && nullToAbsent ? const Value.absent() : Value(hlc),
      name: Value(name),
      number: Value(number),
      color: Value(color),
      settingsJson: Value(settingsJson),
    );
  }

  factory CongregationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CongregationRecord(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      hlc: serializer.fromJson<String?>(json['hlc']),
      name: serializer.fromJson<String>(json['name']),
      number: serializer.fromJson<String>(json['number']),
      color: serializer.fromJson<int>(json['color']),
      settingsJson: serializer.fromJson<String>(json['settingsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'hlc': serializer.toJson<String?>(hlc),
      'name': serializer.toJson<String>(name),
      'number': serializer.toJson<String>(number),
      'color': serializer.toJson<int>(color),
      'settingsJson': serializer.toJson<String>(settingsJson),
    };
  }

  CongregationRecord copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> hlc = const Value.absent(),
    String? name,
    String? number,
    int? color,
    String? settingsJson,
  }) => CongregationRecord(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    hlc: hlc.present ? hlc.value : this.hlc,
    name: name ?? this.name,
    number: number ?? this.number,
    color: color ?? this.color,
    settingsJson: settingsJson ?? this.settingsJson,
  );
  CongregationRecord copyWithCompanion(CongregationsCompanion data) {
    return CongregationRecord(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      name: data.name.present ? data.name.value : this.name,
      number: data.number.present ? data.number.value : this.number,
      color: data.color.present ? data.color.value : this.color,
      settingsJson: data.settingsJson.present
          ? data.settingsJson.value
          : this.settingsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CongregationRecord(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('name: $name, ')
          ..write('number: $number, ')
          ..write('color: $color, ')
          ..write('settingsJson: $settingsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    name,
    number,
    color,
    settingsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CongregationRecord &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.hlc == this.hlc &&
          other.name == this.name &&
          other.number == this.number &&
          other.color == this.color &&
          other.settingsJson == this.settingsJson);
}

class CongregationsCompanion extends UpdateCompanion<CongregationRecord> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> hlc;
  final Value<String> name;
  final Value<String> number;
  final Value<int> color;
  final Value<String> settingsJson;
  final Value<int> rowid;
  const CongregationsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    this.name = const Value.absent(),
    this.number = const Value.absent(),
    this.color = const Value.absent(),
    this.settingsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CongregationsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    required String name,
    this.number = const Value.absent(),
    required int color,
    this.settingsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       color = Value(color);
  static Insertable<CongregationRecord> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? hlc,
    Expression<String>? name,
    Expression<String>? number,
    Expression<int>? color,
    Expression<String>? settingsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (hlc != null) 'hlc': hlc,
      if (name != null) 'name': name,
      if (number != null) 'number': number,
      if (color != null) 'color': color,
      if (settingsJson != null) 'settings_json': settingsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CongregationsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? hlc,
    Value<String>? name,
    Value<String>? number,
    Value<int>? color,
    Value<String>? settingsJson,
    Value<int>? rowid,
  }) {
    return CongregationsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      hlc: hlc ?? this.hlc,
      name: name ?? this.name,
      number: number ?? this.number,
      color: color ?? this.color,
      settingsJson: settingsJson ?? this.settingsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (settingsJson.present) {
      map['settings_json'] = Variable<String>(settingsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CongregationsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('name: $name, ')
          ..write('number: $number, ')
          ..write('color: $color, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _congregationIdMeta = const VerificationMeta(
    'congregationId',
  );
  @override
  late final GeneratedColumn<String> congregationId = GeneratedColumn<String>(
    'congregation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES congregations (id)',
    ),
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Gender, String> gender =
      GeneratedColumn<String>(
        'gender',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Gender>($PeopleTable.$convertergender);
  @override
  late final GeneratedColumnWithTypeConverter<Role, String> privilege =
      GeneratedColumn<String>(
        'privilege',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Role>($PeopleTable.$converterprivilege);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  qualifications = GeneratedColumn<String>(
    'qualifications',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<String>>($PeopleTable.$converterqualifications);
  static const VerificationMeta _originCongregationMeta =
      const VerificationMeta('originCongregation');
  @override
  late final GeneratedColumn<String> originCongregation =
      GeneratedColumn<String>(
        'origin_congregation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastUsedMeta = const VerificationMeta(
    'lastUsed',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsed = GeneratedColumn<DateTime>(
    'last_used',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    congregationId,
    firstName,
    lastName,
    displayName,
    gender,
    privilege,
    qualifications,
    originCongregation,
    active,
    notes,
    lastUsed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('congregation_id')) {
      context.handle(
        _congregationIdMeta,
        congregationId.isAcceptableOrUnknown(
          data['congregation_id']!,
          _congregationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_congregationIdMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('origin_congregation')) {
      context.handle(
        _originCongregationMeta,
        originCongregation.isAcceptableOrUnknown(
          data['origin_congregation']!,
          _originCongregationMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('last_used')) {
      context.handle(
        _lastUsedMeta,
        lastUsed.isAcceptableOrUnknown(data['last_used']!, _lastUsedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      congregationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}congregation_id'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      gender: $PeopleTable.$convertergender.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}gender'],
        )!,
      ),
      privilege: $PeopleTable.$converterprivilege.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}privilege'],
        )!,
      ),
      qualifications: $PeopleTable.$converterqualifications.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}qualifications'],
        )!,
      ),
      originCongregation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_congregation'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      ),
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Gender, String, String> $convertergender =
      const EnumNameConverter<Gender>(Gender.values);
  static JsonTypeConverter2<Role, String, String> $converterprivilege =
      const EnumNameConverter<Role>(Role.values);
  static TypeConverter<List<String>, String> $converterqualifications =
      const StringListConverter();
}

class PeopleCompanion extends UpdateCompanion<Person> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> hlc;
  final Value<String> congregationId;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> displayName;
  final Value<Gender> gender;
  final Value<Role> privilege;
  final Value<List<String>> qualifications;
  final Value<String> originCongregation;
  final Value<bool> active;
  final Value<String> notes;
  final Value<DateTime?> lastUsed;
  final Value<int> rowid;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    this.congregationId = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.gender = const Value.absent(),
    this.privilege = const Value.absent(),
    this.qualifications = const Value.absent(),
    this.originCongregation = const Value.absent(),
    this.active = const Value.absent(),
    this.notes = const Value.absent(),
    this.lastUsed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    required String congregationId,
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    required String displayName,
    required Gender gender,
    required Role privilege,
    this.qualifications = const Value.absent(),
    this.originCongregation = const Value.absent(),
    this.active = const Value.absent(),
    this.notes = const Value.absent(),
    this.lastUsed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       congregationId = Value(congregationId),
       displayName = Value(displayName),
       gender = Value(gender),
       privilege = Value(privilege);
  static Insertable<Person> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? hlc,
    Expression<String>? congregationId,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? displayName,
    Expression<String>? gender,
    Expression<String>? privilege,
    Expression<String>? qualifications,
    Expression<String>? originCongregation,
    Expression<bool>? active,
    Expression<String>? notes,
    Expression<DateTime>? lastUsed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (hlc != null) 'hlc': hlc,
      if (congregationId != null) 'congregation_id': congregationId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (displayName != null) 'display_name': displayName,
      if (gender != null) 'gender': gender,
      if (privilege != null) 'privilege': privilege,
      if (qualifications != null) 'qualifications': qualifications,
      if (originCongregation != null) 'origin_congregation': originCongregation,
      if (active != null) 'active': active,
      if (notes != null) 'notes': notes,
      if (lastUsed != null) 'last_used': lastUsed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? hlc,
    Value<String>? congregationId,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<String>? displayName,
    Value<Gender>? gender,
    Value<Role>? privilege,
    Value<List<String>>? qualifications,
    Value<String>? originCongregation,
    Value<bool>? active,
    Value<String>? notes,
    Value<DateTime?>? lastUsed,
    Value<int>? rowid,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      hlc: hlc ?? this.hlc,
      congregationId: congregationId ?? this.congregationId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      privilege: privilege ?? this.privilege,
      qualifications: qualifications ?? this.qualifications,
      originCongregation: originCongregation ?? this.originCongregation,
      active: active ?? this.active,
      notes: notes ?? this.notes,
      lastUsed: lastUsed ?? this.lastUsed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (congregationId.present) {
      map['congregation_id'] = Variable<String>(congregationId.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(
        $PeopleTable.$convertergender.toSql(gender.value),
      );
    }
    if (privilege.present) {
      map['privilege'] = Variable<String>(
        $PeopleTable.$converterprivilege.toSql(privilege.value),
      );
    }
    if (qualifications.present) {
      map['qualifications'] = Variable<String>(
        $PeopleTable.$converterqualifications.toSql(qualifications.value),
      );
    }
    if (originCongregation.present) {
      map['origin_congregation'] = Variable<String>(originCongregation.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (lastUsed.present) {
      map['last_used'] = Variable<DateTime>(lastUsed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('congregationId: $congregationId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('displayName: $displayName, ')
          ..write('gender: $gender, ')
          ..write('privilege: $privilege, ')
          ..write('qualifications: $qualifications, ')
          ..write('originCongregation: $originCongregation, ')
          ..write('active: $active, ')
          ..write('notes: $notes, ')
          ..write('lastUsed: $lastUsed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$PersonInsertable implements Insertable<Person> {
  Person _object;
  _$PersonInsertable(this._object);
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(_object.id),
      createdAt: Value(_object.createdAt),
      updatedAt: Value(_object.updatedAt),
      deletedAt: Value(_object.deletedAt),
      hlc: Value(_object.hlc),
      congregationId: Value(_object.congregationId),
      firstName: Value(_object.firstName),
      lastName: Value(_object.lastName),
      displayName: Value(_object.displayName),
      gender: Value(_object.gender),
      privilege: Value(_object.privilege),
      qualifications: Value(_object.qualifications),
      originCongregation: Value(_object.originCongregation),
      active: Value(_object.active),
      notes: Value(_object.notes),
      lastUsed: Value(_object.lastUsed),
    ).toColumns(false);
  }
}

extension PersonToInsertable on Person {
  _$PersonInsertable toInsertable() {
    return _$PersonInsertable(this);
  }
}

class $PersonAbsencesTable extends PersonAbsences
    with TableInfo<$PersonAbsencesTable, PersonAbsenceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonAbsencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    personId,
    startDate,
    endDate,
    comment,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'person_absences';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonAbsenceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonAbsenceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonAbsenceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      )!,
    );
  }

  @override
  $PersonAbsencesTable createAlias(String alias) {
    return $PersonAbsencesTable(attachedDatabase, alias);
  }
}

class PersonAbsenceRecord extends DataClass
    implements Insertable<PersonAbsenceRecord> {
  final String id;
  final DateTime createdAt;

  /// UTC. Only changes on user edits (never on bookkeeping like `lastUsed`):
  /// it decides the winner when merging imports, and later LWW sync.
  final DateTime updatedAt;

  /// Tombstone. Non-null = deleted (kept for sync replication + FK safety).
  final DateTime? deletedAt;

  /// Hybrid logical clock stamp. Unused until phase 3; present so adding
  /// sync never needs an ALTER on data tables.
  final String? hlc;
  final String personId;
  final String startDate;
  final String endDate;
  final String comment;
  const PersonAbsenceRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.hlc,
    required this.personId,
    required this.startDate,
    required this.endDate,
    required this.comment,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || hlc != null) {
      map['hlc'] = Variable<String>(hlc);
    }
    map['person_id'] = Variable<String>(personId);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['comment'] = Variable<String>(comment);
    return map;
  }

  PersonAbsencesCompanion toCompanion(bool nullToAbsent) {
    return PersonAbsencesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      hlc: hlc == null && nullToAbsent ? const Value.absent() : Value(hlc),
      personId: Value(personId),
      startDate: Value(startDate),
      endDate: Value(endDate),
      comment: Value(comment),
    );
  }

  factory PersonAbsenceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonAbsenceRecord(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      hlc: serializer.fromJson<String?>(json['hlc']),
      personId: serializer.fromJson<String>(json['personId']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      comment: serializer.fromJson<String>(json['comment']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'hlc': serializer.toJson<String?>(hlc),
      'personId': serializer.toJson<String>(personId),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'comment': serializer.toJson<String>(comment),
    };
  }

  PersonAbsenceRecord copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> hlc = const Value.absent(),
    String? personId,
    String? startDate,
    String? endDate,
    String? comment,
  }) => PersonAbsenceRecord(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    hlc: hlc.present ? hlc.value : this.hlc,
    personId: personId ?? this.personId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    comment: comment ?? this.comment,
  );
  PersonAbsenceRecord copyWithCompanion(PersonAbsencesCompanion data) {
    return PersonAbsenceRecord(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      personId: data.personId.present ? data.personId.value : this.personId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      comment: data.comment.present ? data.comment.value : this.comment,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonAbsenceRecord(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('personId: $personId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('comment: $comment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    personId,
    startDate,
    endDate,
    comment,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonAbsenceRecord &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.hlc == this.hlc &&
          other.personId == this.personId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.comment == this.comment);
}

class PersonAbsencesCompanion extends UpdateCompanion<PersonAbsenceRecord> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> hlc;
  final Value<String> personId;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<String> comment;
  final Value<int> rowid;
  const PersonAbsencesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    this.personId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.comment = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonAbsencesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    required String personId,
    required String startDate,
    required String endDate,
    this.comment = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       personId = Value(personId),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<PersonAbsenceRecord> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? hlc,
    Expression<String>? personId,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? comment,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (hlc != null) 'hlc': hlc,
      if (personId != null) 'person_id': personId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (comment != null) 'comment': comment,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonAbsencesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? hlc,
    Value<String>? personId,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<String>? comment,
    Value<int>? rowid,
  }) {
    return PersonAbsencesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      hlc: hlc ?? this.hlc,
      personId: personId ?? this.personId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      comment: comment ?? this.comment,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonAbsencesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('personId: $personId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('comment: $comment, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects
    with TableInfo<$ProjectsTable, ProjectRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _congregationIdMeta = const VerificationMeta(
    'congregationId',
  );
  @override
  late final GeneratedColumn<String> congregationId = GeneratedColumn<String>(
    'congregation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES congregations (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _exportedAtMeta = const VerificationMeta(
    'exportedAt',
  );
  @override
  late final GeneratedColumn<DateTime> exportedAt = GeneratedColumn<DateTime>(
    'exported_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    congregationId,
    name,
    notes,
    exportedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('congregation_id')) {
      context.handle(
        _congregationIdMeta,
        congregationId.isAcceptableOrUnknown(
          data['congregation_id']!,
          _congregationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_congregationIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('exported_at')) {
      context.handle(
        _exportedAtMeta,
        exportedAt.isAcceptableOrUnknown(data['exported_at']!, _exportedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      ),
      congregationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}congregation_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      exportedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}exported_at'],
      ),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class ProjectRecord extends DataClass implements Insertable<ProjectRecord> {
  final String id;
  final DateTime createdAt;

  /// UTC. Only changes on user edits (never on bookkeeping like `lastUsed`):
  /// it decides the winner when merging imports, and later LWW sync.
  final DateTime updatedAt;

  /// Tombstone. Non-null = deleted (kept for sync replication + FK safety).
  final DateTime? deletedAt;

  /// Hybrid logical clock stamp. Unused until phase 3; present so adding
  /// sync never needs an ALTER on data tables.
  final String? hlc;
  final String congregationId;
  final String name;
  final String notes;
  final DateTime? exportedAt;
  const ProjectRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.hlc,
    required this.congregationId,
    required this.name,
    required this.notes,
    this.exportedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || hlc != null) {
      map['hlc'] = Variable<String>(hlc);
    }
    map['congregation_id'] = Variable<String>(congregationId);
    map['name'] = Variable<String>(name);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || exportedAt != null) {
      map['exported_at'] = Variable<DateTime>(exportedAt);
    }
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      hlc: hlc == null && nullToAbsent ? const Value.absent() : Value(hlc),
      congregationId: Value(congregationId),
      name: Value(name),
      notes: Value(notes),
      exportedAt: exportedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(exportedAt),
    );
  }

  factory ProjectRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectRecord(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      hlc: serializer.fromJson<String?>(json['hlc']),
      congregationId: serializer.fromJson<String>(json['congregationId']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String>(json['notes']),
      exportedAt: serializer.fromJson<DateTime?>(json['exportedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'hlc': serializer.toJson<String?>(hlc),
      'congregationId': serializer.toJson<String>(congregationId),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String>(notes),
      'exportedAt': serializer.toJson<DateTime?>(exportedAt),
    };
  }

  ProjectRecord copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> hlc = const Value.absent(),
    String? congregationId,
    String? name,
    String? notes,
    Value<DateTime?> exportedAt = const Value.absent(),
  }) => ProjectRecord(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    hlc: hlc.present ? hlc.value : this.hlc,
    congregationId: congregationId ?? this.congregationId,
    name: name ?? this.name,
    notes: notes ?? this.notes,
    exportedAt: exportedAt.present ? exportedAt.value : this.exportedAt,
  );
  ProjectRecord copyWithCompanion(ProjectsCompanion data) {
    return ProjectRecord(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      congregationId: data.congregationId.present
          ? data.congregationId.value
          : this.congregationId,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      exportedAt: data.exportedAt.present
          ? data.exportedAt.value
          : this.exportedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectRecord(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('congregationId: $congregationId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('exportedAt: $exportedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    congregationId,
    name,
    notes,
    exportedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectRecord &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.hlc == this.hlc &&
          other.congregationId == this.congregationId &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.exportedAt == this.exportedAt);
}

class ProjectsCompanion extends UpdateCompanion<ProjectRecord> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> hlc;
  final Value<String> congregationId;
  final Value<String> name;
  final Value<String> notes;
  final Value<DateTime?> exportedAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    this.congregationId = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.exportedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    required String congregationId,
    required String name,
    this.notes = const Value.absent(),
    this.exportedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       congregationId = Value(congregationId),
       name = Value(name);
  static Insertable<ProjectRecord> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? hlc,
    Expression<String>? congregationId,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<DateTime>? exportedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (hlc != null) 'hlc': hlc,
      if (congregationId != null) 'congregation_id': congregationId,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (exportedAt != null) 'exported_at': exportedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? hlc,
    Value<String>? congregationId,
    Value<String>? name,
    Value<String>? notes,
    Value<DateTime?>? exportedAt,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      hlc: hlc ?? this.hlc,
      congregationId: congregationId ?? this.congregationId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      exportedAt: exportedAt ?? this.exportedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (congregationId.present) {
      map['congregation_id'] = Variable<String>(congregationId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (exportedAt.present) {
      map['exported_at'] = Variable<DateTime>(exportedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('congregationId: $congregationId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('exportedAt: $exportedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgramsTable extends Programs
    with TableInfo<$ProgramsTable, ProgramRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id)',
    ),
  );
  static const VerificationMeta _programTypeIdMeta = const VerificationMeta(
    'programTypeId',
  );
  @override
  late final GeneratedColumn<String> programTypeId = GeneratedColumn<String>(
    'program_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WeekType, String> weekType =
      GeneratedColumn<String>(
        'week_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(WeekType.normal.name),
      ).withConverter<WeekType>($ProgramsTable.$converterweekType);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentJsonMeta = const VerificationMeta(
    'contentJson',
  );
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
    'content_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleOverridesJsonMeta =
      const VerificationMeta('titleOverridesJson');
  @override
  late final GeneratedColumn<String> titleOverridesJson =
      GeneratedColumn<String>(
        'title_overrides_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _auxRoomMeta = const VerificationMeta(
    'auxRoom',
  );
  @override
  late final GeneratedColumn<bool> auxRoom = GeneratedColumn<bool>(
    'aux_room',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("aux_room" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    projectId,
    programTypeId,
    weekType,
    date,
    sortIndex,
    label,
    contentJson,
    titleOverridesJson,
    startTime,
    durationMinutes,
    auxRoom,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgramRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('program_type_id')) {
      context.handle(
        _programTypeIdMeta,
        programTypeId.isAcceptableOrUnknown(
          data['program_type_id']!,
          _programTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_programTypeIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('content_json')) {
      context.handle(
        _contentJsonMeta,
        contentJson.isAcceptableOrUnknown(
          data['content_json']!,
          _contentJsonMeta,
        ),
      );
    }
    if (data.containsKey('title_overrides_json')) {
      context.handle(
        _titleOverridesJsonMeta,
        titleOverridesJson.isAcceptableOrUnknown(
          data['title_overrides_json']!,
          _titleOverridesJsonMeta,
        ),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('aux_room')) {
      context.handle(
        _auxRoomMeta,
        auxRoom.isAcceptableOrUnknown(data['aux_room']!, _auxRoomMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgramRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      programTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_type_id'],
      )!,
      weekType: $ProgramsTable.$converterweekType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}week_type'],
        )!,
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_index'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      contentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_json'],
      ),
      titleOverridesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_overrides_json'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      auxRoom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}aux_room'],
      ),
    );
  }

  @override
  $ProgramsTable createAlias(String alias) {
    return $ProgramsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WeekType, String, String> $converterweekType =
      const EnumNameConverter<WeekType>(WeekType.values);
}

class ProgramRecord extends DataClass implements Insertable<ProgramRecord> {
  final String id;
  final DateTime createdAt;

  /// UTC. Only changes on user edits (never on bookkeeping like `lastUsed`):
  /// it decides the winner when merging imports, and later LWW sync.
  final DateTime updatedAt;

  /// Tombstone. Non-null = deleted (kept for sync replication + FK safety).
  final DateTime? deletedAt;

  /// Hybrid logical clock stamp. Unused until phase 3; present so adding
  /// sync never needs an ALTER on data tables.
  final String? hlc;
  final String projectId;

  /// Stable id from the code registry ('mwb-s140'); never an enum in data
  /// so new program types don't require migrations.
  final String programTypeId;
  final WeekType weekType;

  /// Week identifier as the notebook catalog exposes it (the parsed week
  /// heading, e.g. "7-13 DE JULIO"). TEXT label, NOT sortable — display
  /// order lives in [sortIndex].
  final String date;

  /// Position within the project (notebook order picked in the modal).
  final int sortIndex;

  /// Optional user-facing override ("Visita del superintendente").
  final String label;

  /// Parsed MWB week snapshotted from the notebook cache (Week.toJson).
  /// Null until the snapshot service fills it (phase-1 skeleton rows).
  final String? contentJson;

  /// Per-row title edits, JSON map slotKey → title (coarse: they ride the
  /// program row; assignments are the fine-grained ones).
  final String titleOverridesJson;

  /// Per-program meeting config. Null = inherit the congregation settings
  /// (start time / aux room) or the app default (duration 105).
  final String? startTime;
  final int? durationMinutes;
  final bool? auxRoom;
  const ProgramRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.hlc,
    required this.projectId,
    required this.programTypeId,
    required this.weekType,
    required this.date,
    required this.sortIndex,
    required this.label,
    this.contentJson,
    required this.titleOverridesJson,
    this.startTime,
    this.durationMinutes,
    this.auxRoom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || hlc != null) {
      map['hlc'] = Variable<String>(hlc);
    }
    map['project_id'] = Variable<String>(projectId);
    map['program_type_id'] = Variable<String>(programTypeId);
    {
      map['week_type'] = Variable<String>(
        $ProgramsTable.$converterweekType.toSql(weekType),
      );
    }
    map['date'] = Variable<String>(date);
    map['sort_index'] = Variable<int>(sortIndex);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || contentJson != null) {
      map['content_json'] = Variable<String>(contentJson);
    }
    map['title_overrides_json'] = Variable<String>(titleOverridesJson);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || auxRoom != null) {
      map['aux_room'] = Variable<bool>(auxRoom);
    }
    return map;
  }

  ProgramsCompanion toCompanion(bool nullToAbsent) {
    return ProgramsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      hlc: hlc == null && nullToAbsent ? const Value.absent() : Value(hlc),
      projectId: Value(projectId),
      programTypeId: Value(programTypeId),
      weekType: Value(weekType),
      date: Value(date),
      sortIndex: Value(sortIndex),
      label: Value(label),
      contentJson: contentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contentJson),
      titleOverridesJson: Value(titleOverridesJson),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      auxRoom: auxRoom == null && nullToAbsent
          ? const Value.absent()
          : Value(auxRoom),
    );
  }

  factory ProgramRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramRecord(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      hlc: serializer.fromJson<String?>(json['hlc']),
      projectId: serializer.fromJson<String>(json['projectId']),
      programTypeId: serializer.fromJson<String>(json['programTypeId']),
      weekType: $ProgramsTable.$converterweekType.fromJson(
        serializer.fromJson<String>(json['weekType']),
      ),
      date: serializer.fromJson<String>(json['date']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
      label: serializer.fromJson<String>(json['label']),
      contentJson: serializer.fromJson<String?>(json['contentJson']),
      titleOverridesJson: serializer.fromJson<String>(
        json['titleOverridesJson'],
      ),
      startTime: serializer.fromJson<String?>(json['startTime']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      auxRoom: serializer.fromJson<bool?>(json['auxRoom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'hlc': serializer.toJson<String?>(hlc),
      'projectId': serializer.toJson<String>(projectId),
      'programTypeId': serializer.toJson<String>(programTypeId),
      'weekType': serializer.toJson<String>(
        $ProgramsTable.$converterweekType.toJson(weekType),
      ),
      'date': serializer.toJson<String>(date),
      'sortIndex': serializer.toJson<int>(sortIndex),
      'label': serializer.toJson<String>(label),
      'contentJson': serializer.toJson<String?>(contentJson),
      'titleOverridesJson': serializer.toJson<String>(titleOverridesJson),
      'startTime': serializer.toJson<String?>(startTime),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'auxRoom': serializer.toJson<bool?>(auxRoom),
    };
  }

  ProgramRecord copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> hlc = const Value.absent(),
    String? projectId,
    String? programTypeId,
    WeekType? weekType,
    String? date,
    int? sortIndex,
    String? label,
    Value<String?> contentJson = const Value.absent(),
    String? titleOverridesJson,
    Value<String?> startTime = const Value.absent(),
    Value<int?> durationMinutes = const Value.absent(),
    Value<bool?> auxRoom = const Value.absent(),
  }) => ProgramRecord(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    hlc: hlc.present ? hlc.value : this.hlc,
    projectId: projectId ?? this.projectId,
    programTypeId: programTypeId ?? this.programTypeId,
    weekType: weekType ?? this.weekType,
    date: date ?? this.date,
    sortIndex: sortIndex ?? this.sortIndex,
    label: label ?? this.label,
    contentJson: contentJson.present ? contentJson.value : this.contentJson,
    titleOverridesJson: titleOverridesJson ?? this.titleOverridesJson,
    startTime: startTime.present ? startTime.value : this.startTime,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    auxRoom: auxRoom.present ? auxRoom.value : this.auxRoom,
  );
  ProgramRecord copyWithCompanion(ProgramsCompanion data) {
    return ProgramRecord(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      programTypeId: data.programTypeId.present
          ? data.programTypeId.value
          : this.programTypeId,
      weekType: data.weekType.present ? data.weekType.value : this.weekType,
      date: data.date.present ? data.date.value : this.date,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      label: data.label.present ? data.label.value : this.label,
      contentJson: data.contentJson.present
          ? data.contentJson.value
          : this.contentJson,
      titleOverridesJson: data.titleOverridesJson.present
          ? data.titleOverridesJson.value
          : this.titleOverridesJson,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      auxRoom: data.auxRoom.present ? data.auxRoom.value : this.auxRoom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramRecord(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('projectId: $projectId, ')
          ..write('programTypeId: $programTypeId, ')
          ..write('weekType: $weekType, ')
          ..write('date: $date, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('label: $label, ')
          ..write('contentJson: $contentJson, ')
          ..write('titleOverridesJson: $titleOverridesJson, ')
          ..write('startTime: $startTime, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('auxRoom: $auxRoom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    projectId,
    programTypeId,
    weekType,
    date,
    sortIndex,
    label,
    contentJson,
    titleOverridesJson,
    startTime,
    durationMinutes,
    auxRoom,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramRecord &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.hlc == this.hlc &&
          other.projectId == this.projectId &&
          other.programTypeId == this.programTypeId &&
          other.weekType == this.weekType &&
          other.date == this.date &&
          other.sortIndex == this.sortIndex &&
          other.label == this.label &&
          other.contentJson == this.contentJson &&
          other.titleOverridesJson == this.titleOverridesJson &&
          other.startTime == this.startTime &&
          other.durationMinutes == this.durationMinutes &&
          other.auxRoom == this.auxRoom);
}

class ProgramsCompanion extends UpdateCompanion<ProgramRecord> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> hlc;
  final Value<String> projectId;
  final Value<String> programTypeId;
  final Value<WeekType> weekType;
  final Value<String> date;
  final Value<int> sortIndex;
  final Value<String> label;
  final Value<String?> contentJson;
  final Value<String> titleOverridesJson;
  final Value<String?> startTime;
  final Value<int?> durationMinutes;
  final Value<bool?> auxRoom;
  final Value<int> rowid;
  const ProgramsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    this.projectId = const Value.absent(),
    this.programTypeId = const Value.absent(),
    this.weekType = const Value.absent(),
    this.date = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.label = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.titleOverridesJson = const Value.absent(),
    this.startTime = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.auxRoom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgramsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    required String projectId,
    required String programTypeId,
    this.weekType = const Value.absent(),
    required String date,
    this.sortIndex = const Value.absent(),
    this.label = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.titleOverridesJson = const Value.absent(),
    this.startTime = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.auxRoom = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       projectId = Value(projectId),
       programTypeId = Value(programTypeId),
       date = Value(date);
  static Insertable<ProgramRecord> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? hlc,
    Expression<String>? projectId,
    Expression<String>? programTypeId,
    Expression<String>? weekType,
    Expression<String>? date,
    Expression<int>? sortIndex,
    Expression<String>? label,
    Expression<String>? contentJson,
    Expression<String>? titleOverridesJson,
    Expression<String>? startTime,
    Expression<int>? durationMinutes,
    Expression<bool>? auxRoom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (hlc != null) 'hlc': hlc,
      if (projectId != null) 'project_id': projectId,
      if (programTypeId != null) 'program_type_id': programTypeId,
      if (weekType != null) 'week_type': weekType,
      if (date != null) 'date': date,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (label != null) 'label': label,
      if (contentJson != null) 'content_json': contentJson,
      if (titleOverridesJson != null)
        'title_overrides_json': titleOverridesJson,
      if (startTime != null) 'start_time': startTime,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (auxRoom != null) 'aux_room': auxRoom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgramsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? hlc,
    Value<String>? projectId,
    Value<String>? programTypeId,
    Value<WeekType>? weekType,
    Value<String>? date,
    Value<int>? sortIndex,
    Value<String>? label,
    Value<String?>? contentJson,
    Value<String>? titleOverridesJson,
    Value<String?>? startTime,
    Value<int?>? durationMinutes,
    Value<bool?>? auxRoom,
    Value<int>? rowid,
  }) {
    return ProgramsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      hlc: hlc ?? this.hlc,
      projectId: projectId ?? this.projectId,
      programTypeId: programTypeId ?? this.programTypeId,
      weekType: weekType ?? this.weekType,
      date: date ?? this.date,
      sortIndex: sortIndex ?? this.sortIndex,
      label: label ?? this.label,
      contentJson: contentJson ?? this.contentJson,
      titleOverridesJson: titleOverridesJson ?? this.titleOverridesJson,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      auxRoom: auxRoom ?? this.auxRoom,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (programTypeId.present) {
      map['program_type_id'] = Variable<String>(programTypeId.value);
    }
    if (weekType.present) {
      map['week_type'] = Variable<String>(
        $ProgramsTable.$converterweekType.toSql(weekType.value),
      );
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (titleOverridesJson.present) {
      map['title_overrides_json'] = Variable<String>(titleOverridesJson.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (auxRoom.present) {
      map['aux_room'] = Variable<bool>(auxRoom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('projectId: $projectId, ')
          ..write('programTypeId: $programTypeId, ')
          ..write('weekType: $weekType, ')
          ..write('date: $date, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('label: $label, ')
          ..write('contentJson: $contentJson, ')
          ..write('titleOverridesJson: $titleOverridesJson, ')
          ..write('startTime: $startTime, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('auxRoom: $auxRoom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssignmentRowsTable extends AssignmentRows
    with TableInfo<$AssignmentRowsTable, AssignmentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssignmentRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES programs (id)',
    ),
  );
  static const VerificationMeta _slotKeyMeta = const VerificationMeta(
    'slotKey',
  );
  @override
  late final GeneratedColumn<String> slotKey = GeneratedColumn<String>(
    'slot_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Hall, String> hall =
      GeneratedColumn<String>(
        'hall',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Hall>($AssignmentRowsTable.$converterhall);
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    programId,
    slotKey,
    hall,
    position,
    displayName,
    personId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssignmentRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('slot_key')) {
      context.handle(
        _slotKeyMeta,
        slotKey.isAcceptableOrUnknown(data['slot_key']!, _slotKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_slotKeyMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssignmentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssignmentRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      ),
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      slotKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot_key'],
      )!,
      hall: $AssignmentRowsTable.$converterhall.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}hall'],
        )!,
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      ),
    );
  }

  @override
  $AssignmentRowsTable createAlias(String alias) {
    return $AssignmentRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Hall, String, String> $converterhall =
      const EnumNameConverter<Hall>(Hall.values);
}

class AssignmentRecord extends DataClass
    implements Insertable<AssignmentRecord> {
  final String id;
  final DateTime createdAt;

  /// UTC. Only changes on user edits (never on bookkeeping like `lastUsed`):
  /// it decides the winner when merging imports, and later LWW sync.
  final DateTime updatedAt;

  /// Tombstone. Non-null = deleted (kept for sync replication + FK safety).
  final DateTime? deletedAt;

  /// Hybrid logical clock stamp. Unused until phase 3; present so adding
  /// sync never needs an ALTER on data tables.
  final String? hlc;
  final String programId;
  final String slotKey;
  final Hall hall;
  final int position;
  final String displayName;

  /// Link into the person directory; null = free text (visitors, or picks
  /// made before the picker returns ids — phase-2 default).
  final String? personId;
  const AssignmentRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.hlc,
    required this.programId,
    required this.slotKey,
    required this.hall,
    required this.position,
    required this.displayName,
    this.personId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || hlc != null) {
      map['hlc'] = Variable<String>(hlc);
    }
    map['program_id'] = Variable<String>(programId);
    map['slot_key'] = Variable<String>(slotKey);
    {
      map['hall'] = Variable<String>(
        $AssignmentRowsTable.$converterhall.toSql(hall),
      );
    }
    map['position'] = Variable<int>(position);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<String>(personId);
    }
    return map;
  }

  AssignmentRowsCompanion toCompanion(bool nullToAbsent) {
    return AssignmentRowsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      hlc: hlc == null && nullToAbsent ? const Value.absent() : Value(hlc),
      programId: Value(programId),
      slotKey: Value(slotKey),
      hall: Value(hall),
      position: Value(position),
      displayName: Value(displayName),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
    );
  }

  factory AssignmentRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssignmentRecord(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      hlc: serializer.fromJson<String?>(json['hlc']),
      programId: serializer.fromJson<String>(json['programId']),
      slotKey: serializer.fromJson<String>(json['slotKey']),
      hall: $AssignmentRowsTable.$converterhall.fromJson(
        serializer.fromJson<String>(json['hall']),
      ),
      position: serializer.fromJson<int>(json['position']),
      displayName: serializer.fromJson<String>(json['displayName']),
      personId: serializer.fromJson<String?>(json['personId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'hlc': serializer.toJson<String?>(hlc),
      'programId': serializer.toJson<String>(programId),
      'slotKey': serializer.toJson<String>(slotKey),
      'hall': serializer.toJson<String>(
        $AssignmentRowsTable.$converterhall.toJson(hall),
      ),
      'position': serializer.toJson<int>(position),
      'displayName': serializer.toJson<String>(displayName),
      'personId': serializer.toJson<String?>(personId),
    };
  }

  AssignmentRecord copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> hlc = const Value.absent(),
    String? programId,
    String? slotKey,
    Hall? hall,
    int? position,
    String? displayName,
    Value<String?> personId = const Value.absent(),
  }) => AssignmentRecord(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    hlc: hlc.present ? hlc.value : this.hlc,
    programId: programId ?? this.programId,
    slotKey: slotKey ?? this.slotKey,
    hall: hall ?? this.hall,
    position: position ?? this.position,
    displayName: displayName ?? this.displayName,
    personId: personId.present ? personId.value : this.personId,
  );
  AssignmentRecord copyWithCompanion(AssignmentRowsCompanion data) {
    return AssignmentRecord(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      programId: data.programId.present ? data.programId.value : this.programId,
      slotKey: data.slotKey.present ? data.slotKey.value : this.slotKey,
      hall: data.hall.present ? data.hall.value : this.hall,
      position: data.position.present ? data.position.value : this.position,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      personId: data.personId.present ? data.personId.value : this.personId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssignmentRecord(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('programId: $programId, ')
          ..write('slotKey: $slotKey, ')
          ..write('hall: $hall, ')
          ..write('position: $position, ')
          ..write('displayName: $displayName, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    hlc,
    programId,
    slotKey,
    hall,
    position,
    displayName,
    personId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssignmentRecord &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.hlc == this.hlc &&
          other.programId == this.programId &&
          other.slotKey == this.slotKey &&
          other.hall == this.hall &&
          other.position == this.position &&
          other.displayName == this.displayName &&
          other.personId == this.personId);
}

class AssignmentRowsCompanion extends UpdateCompanion<AssignmentRecord> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> hlc;
  final Value<String> programId;
  final Value<String> slotKey;
  final Value<Hall> hall;
  final Value<int> position;
  final Value<String> displayName;
  final Value<String?> personId;
  final Value<int> rowid;
  const AssignmentRowsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    this.programId = const Value.absent(),
    this.slotKey = const Value.absent(),
    this.hall = const Value.absent(),
    this.position = const Value.absent(),
    this.displayName = const Value.absent(),
    this.personId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssignmentRowsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.hlc = const Value.absent(),
    required String programId,
    required String slotKey,
    required Hall hall,
    required int position,
    required String displayName,
    this.personId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       programId = Value(programId),
       slotKey = Value(slotKey),
       hall = Value(hall),
       position = Value(position),
       displayName = Value(displayName);
  static Insertable<AssignmentRecord> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? hlc,
    Expression<String>? programId,
    Expression<String>? slotKey,
    Expression<String>? hall,
    Expression<int>? position,
    Expression<String>? displayName,
    Expression<String>? personId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (hlc != null) 'hlc': hlc,
      if (programId != null) 'program_id': programId,
      if (slotKey != null) 'slot_key': slotKey,
      if (hall != null) 'hall': hall,
      if (position != null) 'position': position,
      if (displayName != null) 'display_name': displayName,
      if (personId != null) 'person_id': personId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssignmentRowsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? hlc,
    Value<String>? programId,
    Value<String>? slotKey,
    Value<Hall>? hall,
    Value<int>? position,
    Value<String>? displayName,
    Value<String?>? personId,
    Value<int>? rowid,
  }) {
    return AssignmentRowsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      hlc: hlc ?? this.hlc,
      programId: programId ?? this.programId,
      slotKey: slotKey ?? this.slotKey,
      hall: hall ?? this.hall,
      position: position ?? this.position,
      displayName: displayName ?? this.displayName,
      personId: personId ?? this.personId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (slotKey.present) {
      map['slot_key'] = Variable<String>(slotKey.value);
    }
    if (hall.present) {
      map['hall'] = Variable<String>(
        $AssignmentRowsTable.$converterhall.toSql(hall.value),
      );
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssignmentRowsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hlc: $hlc, ')
          ..write('programId: $programId, ')
          ..write('slotKey: $slotKey, ')
          ..write('hall: $hall, ')
          ..write('position: $position, ')
          ..write('displayName: $displayName, ')
          ..write('personId: $personId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, entity, entityId, hlc, queuedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  final int id;

  /// Entity kind, the table it points into ('person', 'program'…).
  final String entity;
  final String entityId;

  /// Stamp given to the row by this mutation (mirrors the row's hlc).
  final String hlc;
  final DateTime queuedAt;
  const OutboxEntry({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.hlc,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['hlc'] = Variable<String>(hlc);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      entity: Value(entity),
      entityId: Value(entityId),
      hlc: Value(hlc),
      queuedAt: Value(queuedAt),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      id: serializer.fromJson<int>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'hlc': serializer.toJson<String>(hlc),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
    };
  }

  OutboxEntry copyWith({
    int? id,
    String? entity,
    String? entityId,
    String? hlc,
    DateTime? queuedAt,
  }) => OutboxEntry(
    id: id ?? this.id,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    hlc: hlc ?? this.hlc,
    queuedAt: queuedAt ?? this.queuedAt,
  );
  OutboxEntry copyWithCompanion(OutboxCompanion data) {
    return OutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('hlc: $hlc, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entity, entityId, hlc, queuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.hlc == this.hlc &&
          other.queuedAt == this.queuedAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<int> id;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> hlc;
  final Value<DateTime> queuedAt;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.queuedAt = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.id = const Value.absent(),
    required String entity,
    required String entityId,
    required String hlc,
    required DateTime queuedAt,
  }) : entity = Value(entity),
       entityId = Value(entityId),
       hlc = Value(hlc),
       queuedAt = Value(queuedAt);
  static Insertable<OutboxEntry> custom({
    Expression<int>? id,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? hlc,
    Expression<DateTime>? queuedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (hlc != null) 'hlc': hlc,
      if (queuedAt != null) 'queued_at': queuedAt,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? hlc,
    Value<DateTime>? queuedAt,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      hlc: hlc ?? this.hlc,
      queuedAt: queuedAt ?? this.queuedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('hlc: $hlc, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _congregationIdMeta = const VerificationMeta(
    'congregationId',
  );
  @override
  late final GeneratedColumn<String> congregationId = GeneratedColumn<String>(
    'congregation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pullCursorMeta = const VerificationMeta(
    'pullCursor',
  );
  @override
  late final GeneratedColumn<String> pullCursor = GeneratedColumn<String>(
    'pull_cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pushedThroughMeta = const VerificationMeta(
    'pushedThrough',
  );
  @override
  late final GeneratedColumn<int> pushedThrough = GeneratedColumn<int>(
    'pushed_through',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missingKeyVersionMeta = const VerificationMeta(
    'missingKeyVersion',
  );
  @override
  late final GeneratedColumn<int> missingKeyVersion = GeneratedColumn<int>(
    'missing_key_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    congregationId,
    pullCursor,
    pushedThrough,
    missingKeyVersion,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('congregation_id')) {
      context.handle(
        _congregationIdMeta,
        congregationId.isAcceptableOrUnknown(
          data['congregation_id']!,
          _congregationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_congregationIdMeta);
    }
    if (data.containsKey('pull_cursor')) {
      context.handle(
        _pullCursorMeta,
        pullCursor.isAcceptableOrUnknown(data['pull_cursor']!, _pullCursorMeta),
      );
    }
    if (data.containsKey('pushed_through')) {
      context.handle(
        _pushedThroughMeta,
        pushedThrough.isAcceptableOrUnknown(
          data['pushed_through']!,
          _pushedThroughMeta,
        ),
      );
    }
    if (data.containsKey('missing_key_version')) {
      context.handle(
        _missingKeyVersionMeta,
        missingKeyVersion.isAcceptableOrUnknown(
          data['missing_key_version']!,
          _missingKeyVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {congregationId};
  @override
  SyncStateRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRecord(
      congregationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}congregation_id'],
      )!,
      pullCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pull_cursor'],
      ),
      pushedThrough: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pushed_through'],
      ),
      missingKeyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}missing_key_version'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRecord extends DataClass implements Insertable<SyncStateRecord> {
  final String congregationId;

  /// Server timestamp watermark of the last completed pull.
  final String? pullCursor;

  /// Outbox id this congregation's pusher has completed through.
  final int? pushedThrough;

  /// Lowest CCK version this device gave up on decrypting, after which the
  /// cursor was allowed past those docs (see [SyncEngine.pullOnce]). Once the
  /// version reaches us, the cursor rewinds to null and the history is
  /// re-pulled. Null = nothing was ever skipped.
  final int? missingKeyVersion;
  final DateTime updatedAt;
  const SyncStateRecord({
    required this.congregationId,
    this.pullCursor,
    this.pushedThrough,
    this.missingKeyVersion,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['congregation_id'] = Variable<String>(congregationId);
    if (!nullToAbsent || pullCursor != null) {
      map['pull_cursor'] = Variable<String>(pullCursor);
    }
    if (!nullToAbsent || pushedThrough != null) {
      map['pushed_through'] = Variable<int>(pushedThrough);
    }
    if (!nullToAbsent || missingKeyVersion != null) {
      map['missing_key_version'] = Variable<int>(missingKeyVersion);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      congregationId: Value(congregationId),
      pullCursor: pullCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(pullCursor),
      pushedThrough: pushedThrough == null && nullToAbsent
          ? const Value.absent()
          : Value(pushedThrough),
      missingKeyVersion: missingKeyVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(missingKeyVersion),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncStateRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRecord(
      congregationId: serializer.fromJson<String>(json['congregationId']),
      pullCursor: serializer.fromJson<String?>(json['pullCursor']),
      pushedThrough: serializer.fromJson<int?>(json['pushedThrough']),
      missingKeyVersion: serializer.fromJson<int?>(json['missingKeyVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'congregationId': serializer.toJson<String>(congregationId),
      'pullCursor': serializer.toJson<String?>(pullCursor),
      'pushedThrough': serializer.toJson<int?>(pushedThrough),
      'missingKeyVersion': serializer.toJson<int?>(missingKeyVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncStateRecord copyWith({
    String? congregationId,
    Value<String?> pullCursor = const Value.absent(),
    Value<int?> pushedThrough = const Value.absent(),
    Value<int?> missingKeyVersion = const Value.absent(),
    DateTime? updatedAt,
  }) => SyncStateRecord(
    congregationId: congregationId ?? this.congregationId,
    pullCursor: pullCursor.present ? pullCursor.value : this.pullCursor,
    pushedThrough: pushedThrough.present
        ? pushedThrough.value
        : this.pushedThrough,
    missingKeyVersion: missingKeyVersion.present
        ? missingKeyVersion.value
        : this.missingKeyVersion,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncStateRecord copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRecord(
      congregationId: data.congregationId.present
          ? data.congregationId.value
          : this.congregationId,
      pullCursor: data.pullCursor.present
          ? data.pullCursor.value
          : this.pullCursor,
      pushedThrough: data.pushedThrough.present
          ? data.pushedThrough.value
          : this.pushedThrough,
      missingKeyVersion: data.missingKeyVersion.present
          ? data.missingKeyVersion.value
          : this.missingKeyVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRecord(')
          ..write('congregationId: $congregationId, ')
          ..write('pullCursor: $pullCursor, ')
          ..write('pushedThrough: $pushedThrough, ')
          ..write('missingKeyVersion: $missingKeyVersion, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    congregationId,
    pullCursor,
    pushedThrough,
    missingKeyVersion,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRecord &&
          other.congregationId == this.congregationId &&
          other.pullCursor == this.pullCursor &&
          other.pushedThrough == this.pushedThrough &&
          other.missingKeyVersion == this.missingKeyVersion &&
          other.updatedAt == this.updatedAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRecord> {
  final Value<String> congregationId;
  final Value<String?> pullCursor;
  final Value<int?> pushedThrough;
  final Value<int?> missingKeyVersion;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.congregationId = const Value.absent(),
    this.pullCursor = const Value.absent(),
    this.pushedThrough = const Value.absent(),
    this.missingKeyVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String congregationId,
    this.pullCursor = const Value.absent(),
    this.pushedThrough = const Value.absent(),
    this.missingKeyVersion = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : congregationId = Value(congregationId),
       updatedAt = Value(updatedAt);
  static Insertable<SyncStateRecord> custom({
    Expression<String>? congregationId,
    Expression<String>? pullCursor,
    Expression<int>? pushedThrough,
    Expression<int>? missingKeyVersion,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (congregationId != null) 'congregation_id': congregationId,
      if (pullCursor != null) 'pull_cursor': pullCursor,
      if (pushedThrough != null) 'pushed_through': pushedThrough,
      if (missingKeyVersion != null) 'missing_key_version': missingKeyVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? congregationId,
    Value<String?>? pullCursor,
    Value<int?>? pushedThrough,
    Value<int?>? missingKeyVersion,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      congregationId: congregationId ?? this.congregationId,
      pullCursor: pullCursor ?? this.pullCursor,
      pushedThrough: pushedThrough ?? this.pushedThrough,
      missingKeyVersion: missingKeyVersion ?? this.missingKeyVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (congregationId.present) {
      map['congregation_id'] = Variable<String>(congregationId.value);
    }
    if (pullCursor.present) {
      map['pull_cursor'] = Variable<String>(pullCursor.value);
    }
    if (pushedThrough.present) {
      map['pushed_through'] = Variable<int>(pushedThrough.value);
    }
    if (missingKeyVersion.present) {
      map['missing_key_version'] = Variable<int>(missingKeyVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('congregationId: $congregationId, ')
          ..write('pullCursor: $pullCursor, ')
          ..write('pushedThrough: $pushedThrough, ')
          ..write('missingKeyVersion: $missingKeyVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CongregationsTable congregations = $CongregationsTable(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $PersonAbsencesTable personAbsences = $PersonAbsencesTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $ProgramsTable programs = $ProgramsTable(this);
  late final $AssignmentRowsTable assignmentRows = $AssignmentRowsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final Index peopleCongregationIdx = Index(
    'people_congregation_idx',
    'CREATE INDEX people_congregation_idx ON people (congregation_id)',
  );
  late final Index personAbsencesPersonIdx = Index(
    'person_absences_person_idx',
    'CREATE INDEX person_absences_person_idx ON person_absences (person_id)',
  );
  late final Index projectsCongregationIdx = Index(
    'projects_congregation_idx',
    'CREATE INDEX projects_congregation_idx ON projects (congregation_id)',
  );
  late final Index programsProjectIdx = Index(
    'programs_project_idx',
    'CREATE INDEX programs_project_idx ON programs (project_id)',
  );
  late final Index assignmentsProgramIdx = Index(
    'assignments_program_idx',
    'CREATE INDEX assignments_program_idx ON assignments (program_id)',
  );
  late final PeopleDao peopleDao = PeopleDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    congregations,
    people,
    personAbsences,
    projects,
    programs,
    assignmentRows,
    outbox,
    syncState,
    peopleCongregationIdx,
    personAbsencesPersonIdx,
    projectsCongregationIdx,
    programsProjectIdx,
    assignmentsProgramIdx,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CongregationsTableCreateCompanionBuilder =
    CongregationsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      required String name,
      Value<String> number,
      required int color,
      Value<String> settingsJson,
      Value<int> rowid,
    });
typedef $$CongregationsTableUpdateCompanionBuilder =
    CongregationsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      Value<String> name,
      Value<String> number,
      Value<int> color,
      Value<String> settingsJson,
      Value<int> rowid,
    });

final class $$CongregationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CongregationsTable, CongregationRecord> {
  $$CongregationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PeopleTable, List<Person>> _peopleRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.people,
    aliasName: 'congregations__id__people__congregation_id',
  );

  $$PeopleTableProcessedTableManager get peopleRefs {
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.congregationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_peopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProjectsTable, List<ProjectRecord>>
  _projectsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.projects,
    aliasName: 'congregations__id__projects__congregation_id',
  );

  $$ProjectsTableProcessedTableManager get projectsRefs {
    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.congregationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_projectsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CongregationsTableFilterComposer
    extends Composer<_$AppDatabase, $CongregationsTable> {
  $$CongregationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> peopleRefs(
    Expression<bool> Function($$PeopleTableFilterComposer f) f,
  ) {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.congregationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> projectsRefs(
    Expression<bool> Function($$ProjectsTableFilterComposer f) f,
  ) {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.congregationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CongregationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CongregationsTable> {
  $$CongregationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CongregationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CongregationsTable> {
  $$CongregationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => column,
  );

  Expression<T> peopleRefs<T extends Object>(
    Expression<T> Function($$PeopleTableAnnotationComposer a) f,
  ) {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.congregationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> projectsRefs<T extends Object>(
    Expression<T> Function($$ProjectsTableAnnotationComposer a) f,
  ) {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.congregationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CongregationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CongregationsTable,
          CongregationRecord,
          $$CongregationsTableFilterComposer,
          $$CongregationsTableOrderingComposer,
          $$CongregationsTableAnnotationComposer,
          $$CongregationsTableCreateCompanionBuilder,
          $$CongregationsTableUpdateCompanionBuilder,
          (CongregationRecord, $$CongregationsTableReferences),
          CongregationRecord,
          PrefetchHooks Function({bool peopleRefs, bool projectsRefs})
        > {
  $$CongregationsTableTableManager(_$AppDatabase db, $CongregationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CongregationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CongregationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CongregationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String> settingsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CongregationsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                name: name,
                number: number,
                color: color,
                settingsJson: settingsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                required String name,
                Value<String> number = const Value.absent(),
                required int color,
                Value<String> settingsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CongregationsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                name: name,
                number: number,
                color: color,
                settingsJson: settingsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CongregationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({peopleRefs = false, projectsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (peopleRefs) db.people,
                if (projectsRefs) db.projects,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (peopleRefs)
                    await $_getPrefetchedData<
                      CongregationRecord,
                      $CongregationsTable,
                      Person
                    >(
                      currentTable: table,
                      referencedTable: $$CongregationsTableReferences
                          ._peopleRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CongregationsTableReferences(
                            db,
                            table,
                            p0,
                          ).peopleRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.congregationId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (projectsRefs)
                    await $_getPrefetchedData<
                      CongregationRecord,
                      $CongregationsTable,
                      ProjectRecord
                    >(
                      currentTable: table,
                      referencedTable: $$CongregationsTableReferences
                          ._projectsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CongregationsTableReferences(
                            db,
                            table,
                            p0,
                          ).projectsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.congregationId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CongregationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CongregationsTable,
      CongregationRecord,
      $$CongregationsTableFilterComposer,
      $$CongregationsTableOrderingComposer,
      $$CongregationsTableAnnotationComposer,
      $$CongregationsTableCreateCompanionBuilder,
      $$CongregationsTableUpdateCompanionBuilder,
      (CongregationRecord, $$CongregationsTableReferences),
      CongregationRecord,
      PrefetchHooks Function({bool peopleRefs, bool projectsRefs})
    >;
typedef $$PeopleTableCreateCompanionBuilder =
    PeopleCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      required String congregationId,
      Value<String> firstName,
      Value<String> lastName,
      required String displayName,
      required Gender gender,
      required Role privilege,
      Value<List<String>> qualifications,
      Value<String> originCongregation,
      Value<bool> active,
      Value<String> notes,
      Value<DateTime?> lastUsed,
      Value<int> rowid,
    });
typedef $$PeopleTableUpdateCompanionBuilder =
    PeopleCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      Value<String> congregationId,
      Value<String> firstName,
      Value<String> lastName,
      Value<String> displayName,
      Value<Gender> gender,
      Value<Role> privilege,
      Value<List<String>> qualifications,
      Value<String> originCongregation,
      Value<bool> active,
      Value<String> notes,
      Value<DateTime?> lastUsed,
      Value<int> rowid,
    });

final class $$PeopleTableReferences
    extends BaseReferences<_$AppDatabase, $PeopleTable, Person> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CongregationsTable _congregationIdTable(_$AppDatabase db) => db
      .congregations
      .createAlias('people__congregation_id__congregations__id');

  $$CongregationsTableProcessedTableManager get congregationId {
    final $_column = $_itemColumn<String>('congregation_id')!;

    final manager = $$CongregationsTableTableManager(
      $_db,
      $_db.congregations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_congregationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PersonAbsencesTable, List<PersonAbsenceRecord>>
  _personAbsencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.personAbsences,
    aliasName: 'people__id__person_absences__person_id',
  );

  $$PersonAbsencesTableProcessedTableManager get personAbsencesRefs {
    final manager = $$PersonAbsencesTableTableManager(
      $_db,
      $_db.personAbsences,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_personAbsencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AssignmentRowsTable, List<AssignmentRecord>>
  _assignmentRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assignmentRows,
    aliasName: 'people__id__assignments__person_id',
  );

  $$AssignmentRowsTableProcessedTableManager get assignmentRowsRefs {
    final manager = $$AssignmentRowsTableTableManager(
      $_db,
      $_db.assignmentRows,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assignmentRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Gender, Gender, String> get gender =>
      $composableBuilder(
        column: $table.gender,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Role, Role, String> get privilege =>
      $composableBuilder(
        column: $table.privilege,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get qualifications => $composableBuilder(
    column: $table.qualifications,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get originCongregation => $composableBuilder(
    column: $table.originCongregation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsed => $composableBuilder(
    column: $table.lastUsed,
    builder: (column) => ColumnFilters(column),
  );

  $$CongregationsTableFilterComposer get congregationId {
    final $$CongregationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableFilterComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> personAbsencesRefs(
    Expression<bool> Function($$PersonAbsencesTableFilterComposer f) f,
  ) {
    final $$PersonAbsencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personAbsences,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonAbsencesTableFilterComposer(
            $db: $db,
            $table: $db.personAbsences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assignmentRowsRefs(
    Expression<bool> Function($$AssignmentRowsTableFilterComposer f) f,
  ) {
    final $$AssignmentRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assignmentRows,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssignmentRowsTableFilterComposer(
            $db: $db,
            $table: $db.assignmentRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privilege => $composableBuilder(
    column: $table.privilege,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualifications => $composableBuilder(
    column: $table.qualifications,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originCongregation => $composableBuilder(
    column: $table.originCongregation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsed => $composableBuilder(
    column: $table.lastUsed,
    builder: (column) => ColumnOrderings(column),
  );

  $$CongregationsTableOrderingComposer get congregationId {
    final $$CongregationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableOrderingComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Gender, String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Role, String> get privilege =>
      $composableBuilder(column: $table.privilege, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get qualifications =>
      $composableBuilder(
        column: $table.qualifications,
        builder: (column) => column,
      );

  GeneratedColumn<String> get originCongregation => $composableBuilder(
    column: $table.originCongregation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsed =>
      $composableBuilder(column: $table.lastUsed, builder: (column) => column);

  $$CongregationsTableAnnotationComposer get congregationId {
    final $$CongregationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableAnnotationComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> personAbsencesRefs<T extends Object>(
    Expression<T> Function($$PersonAbsencesTableAnnotationComposer a) f,
  ) {
    final $$PersonAbsencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personAbsences,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonAbsencesTableAnnotationComposer(
            $db: $db,
            $table: $db.personAbsences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> assignmentRowsRefs<T extends Object>(
    Expression<T> Function($$AssignmentRowsTableAnnotationComposer a) f,
  ) {
    final $$AssignmentRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assignmentRows,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssignmentRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.assignmentRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleTable,
          Person,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (Person, $$PeopleTableReferences),
          Person,
          PrefetchHooks Function({
            bool congregationId,
            bool personAbsencesRefs,
            bool assignmentRowsRefs,
          })
        > {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                Value<String> congregationId = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<Gender> gender = const Value.absent(),
                Value<Role> privilege = const Value.absent(),
                Value<List<String>> qualifications = const Value.absent(),
                Value<String> originCongregation = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> lastUsed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                congregationId: congregationId,
                firstName: firstName,
                lastName: lastName,
                displayName: displayName,
                gender: gender,
                privilege: privilege,
                qualifications: qualifications,
                originCongregation: originCongregation,
                active: active,
                notes: notes,
                lastUsed: lastUsed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                required String congregationId,
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                required String displayName,
                required Gender gender,
                required Role privilege,
                Value<List<String>> qualifications = const Value.absent(),
                Value<String> originCongregation = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> lastUsed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                congregationId: congregationId,
                firstName: firstName,
                lastName: lastName,
                displayName: displayName,
                gender: gender,
                privilege: privilege,
                qualifications: qualifications,
                originCongregation: originCongregation,
                active: active,
                notes: notes,
                lastUsed: lastUsed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PeopleTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                congregationId = false,
                personAbsencesRefs = false,
                assignmentRowsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (personAbsencesRefs) db.personAbsences,
                    if (assignmentRowsRefs) db.assignmentRows,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (congregationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.congregationId,
                                    referencedTable: $$PeopleTableReferences
                                        ._congregationIdTable(db),
                                    referencedColumn: $$PeopleTableReferences
                                        ._congregationIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (personAbsencesRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          PersonAbsenceRecord
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._personAbsencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).personAbsencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assignmentRowsRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          AssignmentRecord
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._assignmentRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).assignmentRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleTable,
      Person,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (Person, $$PeopleTableReferences),
      Person,
      PrefetchHooks Function({
        bool congregationId,
        bool personAbsencesRefs,
        bool assignmentRowsRefs,
      })
    >;
typedef $$PersonAbsencesTableCreateCompanionBuilder =
    PersonAbsencesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      required String personId,
      required String startDate,
      required String endDate,
      Value<String> comment,
      Value<int> rowid,
    });
typedef $$PersonAbsencesTableUpdateCompanionBuilder =
    PersonAbsencesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      Value<String> personId,
      Value<String> startDate,
      Value<String> endDate,
      Value<String> comment,
      Value<int> rowid,
    });

final class $$PersonAbsencesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PersonAbsencesTable,
          PersonAbsenceRecord
        > {
  $$PersonAbsencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('person_absences__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PersonAbsencesTableFilterComposer
    extends Composer<_$AppDatabase, $PersonAbsencesTable> {
  $$PersonAbsencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonAbsencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonAbsencesTable> {
  $$PersonAbsencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonAbsencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonAbsencesTable> {
  $$PersonAbsencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonAbsencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonAbsencesTable,
          PersonAbsenceRecord,
          $$PersonAbsencesTableFilterComposer,
          $$PersonAbsencesTableOrderingComposer,
          $$PersonAbsencesTableAnnotationComposer,
          $$PersonAbsencesTableCreateCompanionBuilder,
          $$PersonAbsencesTableUpdateCompanionBuilder,
          (PersonAbsenceRecord, $$PersonAbsencesTableReferences),
          PersonAbsenceRecord,
          PrefetchHooks Function({bool personId})
        > {
  $$PersonAbsencesTableTableManager(
    _$AppDatabase db,
    $PersonAbsencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonAbsencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonAbsencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonAbsencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<String> comment = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonAbsencesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                personId: personId,
                startDate: startDate,
                endDate: endDate,
                comment: comment,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                required String personId,
                required String startDate,
                required String endDate,
                Value<String> comment = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonAbsencesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                personId: personId,
                startDate: startDate,
                endDate: endDate,
                comment: comment,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonAbsencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$PersonAbsencesTableReferences
                                    ._personIdTable(db),
                                referencedColumn:
                                    $$PersonAbsencesTableReferences
                                        ._personIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PersonAbsencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonAbsencesTable,
      PersonAbsenceRecord,
      $$PersonAbsencesTableFilterComposer,
      $$PersonAbsencesTableOrderingComposer,
      $$PersonAbsencesTableAnnotationComposer,
      $$PersonAbsencesTableCreateCompanionBuilder,
      $$PersonAbsencesTableUpdateCompanionBuilder,
      (PersonAbsenceRecord, $$PersonAbsencesTableReferences),
      PersonAbsenceRecord,
      PrefetchHooks Function({bool personId})
    >;
typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      required String congregationId,
      required String name,
      Value<String> notes,
      Value<DateTime?> exportedAt,
      Value<int> rowid,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      Value<String> congregationId,
      Value<String> name,
      Value<String> notes,
      Value<DateTime?> exportedAt,
      Value<int> rowid,
    });

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, ProjectRecord> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CongregationsTable _congregationIdTable(_$AppDatabase db) => db
      .congregations
      .createAlias('projects__congregation_id__congregations__id');

  $$CongregationsTableProcessedTableManager get congregationId {
    final $_column = $_itemColumn<String>('congregation_id')!;

    final manager = $$CongregationsTableTableManager(
      $_db,
      $_db.congregations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_congregationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProgramsTable, List<ProgramRecord>>
  _programsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.programs,
    aliasName: 'projects__id__programs__project_id',
  );

  $$ProgramsTableProcessedTableManager get programsRefs {
    final manager = $$ProgramsTableTableManager(
      $_db,
      $_db.programs,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_programsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get exportedAt => $composableBuilder(
    column: $table.exportedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CongregationsTableFilterComposer get congregationId {
    final $$CongregationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableFilterComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> programsRefs(
    Expression<bool> Function($$ProgramsTableFilterComposer f) f,
  ) {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableFilterComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get exportedAt => $composableBuilder(
    column: $table.exportedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CongregationsTableOrderingComposer get congregationId {
    final $$CongregationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableOrderingComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get exportedAt => $composableBuilder(
    column: $table.exportedAt,
    builder: (column) => column,
  );

  $$CongregationsTableAnnotationComposer get congregationId {
    final $$CongregationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableAnnotationComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> programsRefs<T extends Object>(
    Expression<T> Function($$ProgramsTableAnnotationComposer a) f,
  ) {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableAnnotationComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          ProjectRecord,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (ProjectRecord, $$ProjectsTableReferences),
          ProjectRecord,
          PrefetchHooks Function({bool congregationId, bool programsRefs})
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                Value<String> congregationId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> exportedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                congregationId: congregationId,
                name: name,
                notes: notes,
                exportedAt: exportedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                required String congregationId,
                required String name,
                Value<String> notes = const Value.absent(),
                Value<DateTime?> exportedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                congregationId: congregationId,
                name: name,
                notes: notes,
                exportedAt: exportedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({congregationId = false, programsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (programsRefs) db.programs],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (congregationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.congregationId,
                                    referencedTable: $$ProjectsTableReferences
                                        ._congregationIdTable(db),
                                    referencedColumn: $$ProjectsTableReferences
                                        ._congregationIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (programsRefs)
                        await $_getPrefetchedData<
                          ProjectRecord,
                          $ProjectsTable,
                          ProgramRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._programsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).programsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      ProjectRecord,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (ProjectRecord, $$ProjectsTableReferences),
      ProjectRecord,
      PrefetchHooks Function({bool congregationId, bool programsRefs})
    >;
typedef $$ProgramsTableCreateCompanionBuilder =
    ProgramsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      required String projectId,
      required String programTypeId,
      Value<WeekType> weekType,
      required String date,
      Value<int> sortIndex,
      Value<String> label,
      Value<String?> contentJson,
      Value<String> titleOverridesJson,
      Value<String?> startTime,
      Value<int?> durationMinutes,
      Value<bool?> auxRoom,
      Value<int> rowid,
    });
typedef $$ProgramsTableUpdateCompanionBuilder =
    ProgramsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      Value<String> projectId,
      Value<String> programTypeId,
      Value<WeekType> weekType,
      Value<String> date,
      Value<int> sortIndex,
      Value<String> label,
      Value<String?> contentJson,
      Value<String> titleOverridesJson,
      Value<String?> startTime,
      Value<int?> durationMinutes,
      Value<bool?> auxRoom,
      Value<int> rowid,
    });

final class $$ProgramsTableReferences
    extends BaseReferences<_$AppDatabase, $ProgramsTable, ProgramRecord> {
  $$ProgramsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('programs__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AssignmentRowsTable, List<AssignmentRecord>>
  _assignmentRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assignmentRows,
    aliasName: 'programs__id__assignments__program_id',
  );

  $$AssignmentRowsTableProcessedTableManager get assignmentRowsRefs {
    final manager = $$AssignmentRowsTableTableManager(
      $_db,
      $_db.assignmentRows,
    ).filter((f) => f.programId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assignmentRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programTypeId => $composableBuilder(
    column: $table.programTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WeekType, WeekType, String> get weekType =>
      $composableBuilder(
        column: $table.weekType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleOverridesJson => $composableBuilder(
    column: $table.titleOverridesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get auxRoom => $composableBuilder(
    column: $table.auxRoom,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> assignmentRowsRefs(
    Expression<bool> Function($$AssignmentRowsTableFilterComposer f) f,
  ) {
    final $$AssignmentRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assignmentRows,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssignmentRowsTableFilterComposer(
            $db: $db,
            $table: $db.assignmentRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programTypeId => $composableBuilder(
    column: $table.programTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekType => $composableBuilder(
    column: $table.weekType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleOverridesJson => $composableBuilder(
    column: $table.titleOverridesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get auxRoom => $composableBuilder(
    column: $table.auxRoom,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<String> get programTypeId => $composableBuilder(
    column: $table.programTypeId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WeekType, String> get weekType =>
      $composableBuilder(column: $table.weekType, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titleOverridesJson => $composableBuilder(
    column: $table.titleOverridesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get auxRoom =>
      $composableBuilder(column: $table.auxRoom, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> assignmentRowsRefs<T extends Object>(
    Expression<T> Function($$AssignmentRowsTableAnnotationComposer a) f,
  ) {
    final $$AssignmentRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assignmentRows,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssignmentRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.assignmentRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramsTable,
          ProgramRecord,
          $$ProgramsTableFilterComposer,
          $$ProgramsTableOrderingComposer,
          $$ProgramsTableAnnotationComposer,
          $$ProgramsTableCreateCompanionBuilder,
          $$ProgramsTableUpdateCompanionBuilder,
          (ProgramRecord, $$ProgramsTableReferences),
          ProgramRecord,
          PrefetchHooks Function({bool projectId, bool assignmentRowsRefs})
        > {
  $$ProgramsTableTableManager(_$AppDatabase db, $ProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> programTypeId = const Value.absent(),
                Value<WeekType> weekType = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> contentJson = const Value.absent(),
                Value<String> titleOverridesJson = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<bool?> auxRoom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                projectId: projectId,
                programTypeId: programTypeId,
                weekType: weekType,
                date: date,
                sortIndex: sortIndex,
                label: label,
                contentJson: contentJson,
                titleOverridesJson: titleOverridesJson,
                startTime: startTime,
                durationMinutes: durationMinutes,
                auxRoom: auxRoom,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                required String projectId,
                required String programTypeId,
                Value<WeekType> weekType = const Value.absent(),
                required String date,
                Value<int> sortIndex = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> contentJson = const Value.absent(),
                Value<String> titleOverridesJson = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<bool?> auxRoom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                projectId: projectId,
                programTypeId: programTypeId,
                weekType: weekType,
                date: date,
                sortIndex: sortIndex,
                label: label,
                contentJson: contentJson,
                titleOverridesJson: titleOverridesJson,
                startTime: startTime,
                durationMinutes: durationMinutes,
                auxRoom: auxRoom,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProgramsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({projectId = false, assignmentRowsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (assignmentRowsRefs) db.assignmentRows,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (projectId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.projectId,
                                    referencedTable: $$ProgramsTableReferences
                                        ._projectIdTable(db),
                                    referencedColumn: $$ProgramsTableReferences
                                        ._projectIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (assignmentRowsRefs)
                        await $_getPrefetchedData<
                          ProgramRecord,
                          $ProgramsTable,
                          AssignmentRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramsTableReferences
                              ._assignmentRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramsTableReferences(
                                db,
                                table,
                                p0,
                              ).assignmentRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramsTable,
      ProgramRecord,
      $$ProgramsTableFilterComposer,
      $$ProgramsTableOrderingComposer,
      $$ProgramsTableAnnotationComposer,
      $$ProgramsTableCreateCompanionBuilder,
      $$ProgramsTableUpdateCompanionBuilder,
      (ProgramRecord, $$ProgramsTableReferences),
      ProgramRecord,
      PrefetchHooks Function({bool projectId, bool assignmentRowsRefs})
    >;
typedef $$AssignmentRowsTableCreateCompanionBuilder =
    AssignmentRowsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      required String programId,
      required String slotKey,
      required Hall hall,
      required int position,
      required String displayName,
      Value<String?> personId,
      Value<int> rowid,
    });
typedef $$AssignmentRowsTableUpdateCompanionBuilder =
    AssignmentRowsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> hlc,
      Value<String> programId,
      Value<String> slotKey,
      Value<Hall> hall,
      Value<int> position,
      Value<String> displayName,
      Value<String?> personId,
      Value<int> rowid,
    });

final class $$AssignmentRowsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AssignmentRowsTable, AssignmentRecord> {
  $$AssignmentRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProgramsTable _programIdTable(_$AppDatabase db) =>
      db.programs.createAlias('assignments__program_id__programs__id');

  $$ProgramsTableProcessedTableManager get programId {
    final $_column = $_itemColumn<String>('program_id')!;

    final manager = $$ProgramsTableTableManager(
      $_db,
      $_db.programs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('assignments__person_id__people__id');

  $$PeopleTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<String>('person_id');
    if ($_column == null) return null;
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssignmentRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AssignmentRowsTable> {
  $$AssignmentRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slotKey => $composableBuilder(
    column: $table.slotKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Hall, Hall, String> get hall =>
      $composableBuilder(
        column: $table.hall,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  $$ProgramsTableFilterComposer get programId {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableFilterComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssignmentRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssignmentRowsTable> {
  $$AssignmentRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slotKey => $composableBuilder(
    column: $table.slotKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hall => $composableBuilder(
    column: $table.hall,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramsTableOrderingComposer get programId {
    final $$ProgramsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableOrderingComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssignmentRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssignmentRowsTable> {
  $$AssignmentRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<String> get slotKey =>
      $composableBuilder(column: $table.slotKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Hall, String> get hall =>
      $composableBuilder(column: $table.hall, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  $$ProgramsTableAnnotationComposer get programId {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableAnnotationComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssignmentRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssignmentRowsTable,
          AssignmentRecord,
          $$AssignmentRowsTableFilterComposer,
          $$AssignmentRowsTableOrderingComposer,
          $$AssignmentRowsTableAnnotationComposer,
          $$AssignmentRowsTableCreateCompanionBuilder,
          $$AssignmentRowsTableUpdateCompanionBuilder,
          (AssignmentRecord, $$AssignmentRowsTableReferences),
          AssignmentRecord,
          PrefetchHooks Function({bool programId, bool personId})
        > {
  $$AssignmentRowsTableTableManager(
    _$AppDatabase db,
    $AssignmentRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssignmentRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssignmentRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssignmentRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                Value<String> programId = const Value.absent(),
                Value<String> slotKey = const Value.absent(),
                Value<Hall> hall = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssignmentRowsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                programId: programId,
                slotKey: slotKey,
                hall: hall,
                position: position,
                displayName: displayName,
                personId: personId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> hlc = const Value.absent(),
                required String programId,
                required String slotKey,
                required Hall hall,
                required int position,
                required String displayName,
                Value<String?> personId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssignmentRowsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                hlc: hlc,
                programId: programId,
                slotKey: slotKey,
                hall: hall,
                position: position,
                displayName: displayName,
                personId: personId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssignmentRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({programId = false, personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (programId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.programId,
                                referencedTable: $$AssignmentRowsTableReferences
                                    ._programIdTable(db),
                                referencedColumn:
                                    $$AssignmentRowsTableReferences
                                        ._programIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$AssignmentRowsTableReferences
                                    ._personIdTable(db),
                                referencedColumn:
                                    $$AssignmentRowsTableReferences
                                        ._personIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssignmentRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssignmentRowsTable,
      AssignmentRecord,
      $$AssignmentRowsTableFilterComposer,
      $$AssignmentRowsTableOrderingComposer,
      $$AssignmentRowsTableAnnotationComposer,
      $$AssignmentRowsTableCreateCompanionBuilder,
      $$AssignmentRowsTableUpdateCompanionBuilder,
      (AssignmentRecord, $$AssignmentRowsTableReferences),
      AssignmentRecord,
      PrefetchHooks Function({bool programId, bool personId})
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> id,
      required String entity,
      required String entityId,
      required String hlc,
      required DateTime queuedAt,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> id,
      Value<String> entity,
      Value<String> entityId,
      Value<String> hlc,
      Value<DateTime> queuedAt,
    });

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxEntry,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$AppDatabase, $OutboxTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                entity: entity,
                entityId: entityId,
                hlc: hlc,
                queuedAt: queuedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entity,
                required String entityId,
                required String hlc,
                required DateTime queuedAt,
              }) => OutboxCompanion.insert(
                id: id,
                entity: entity,
                entityId: entityId,
                hlc: hlc,
                queuedAt: queuedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxEntry,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxEntry, BaseReferences<_$AppDatabase, $OutboxTable, OutboxEntry>),
      OutboxEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String congregationId,
      Value<String?> pullCursor,
      Value<int?> pushedThrough,
      Value<int?> missingKeyVersion,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> congregationId,
      Value<String?> pullCursor,
      Value<int?> pushedThrough,
      Value<int?> missingKeyVersion,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get congregationId => $composableBuilder(
    column: $table.congregationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pullCursor => $composableBuilder(
    column: $table.pullCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pushedThrough => $composableBuilder(
    column: $table.pushedThrough,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get missingKeyVersion => $composableBuilder(
    column: $table.missingKeyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get congregationId => $composableBuilder(
    column: $table.congregationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pullCursor => $composableBuilder(
    column: $table.pullCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pushedThrough => $composableBuilder(
    column: $table.pushedThrough,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get missingKeyVersion => $composableBuilder(
    column: $table.missingKeyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get congregationId => $composableBuilder(
    column: $table.congregationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pullCursor => $composableBuilder(
    column: $table.pullCursor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pushedThrough => $composableBuilder(
    column: $table.pushedThrough,
    builder: (column) => column,
  );

  GeneratedColumn<int> get missingKeyVersion => $composableBuilder(
    column: $table.missingKeyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateRecord,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRecord,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRecord>,
          ),
          SyncStateRecord,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> congregationId = const Value.absent(),
                Value<String?> pullCursor = const Value.absent(),
                Value<int?> pushedThrough = const Value.absent(),
                Value<int?> missingKeyVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                congregationId: congregationId,
                pullCursor: pullCursor,
                pushedThrough: pushedThrough,
                missingKeyVersion: missingKeyVersion,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String congregationId,
                Value<String?> pullCursor = const Value.absent(),
                Value<int?> pushedThrough = const Value.absent(),
                Value<int?> missingKeyVersion = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                congregationId: congregationId,
                pullCursor: pullCursor,
                pushedThrough: pushedThrough,
                missingKeyVersion: missingKeyVersion,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateRecord,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRecord,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRecord>,
      ),
      SyncStateRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CongregationsTableTableManager get congregations =>
      $$CongregationsTableTableManager(_db, _db.congregations);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$PersonAbsencesTableTableManager get personAbsences =>
      $$PersonAbsencesTableTableManager(_db, _db.personAbsences);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$ProgramsTableTableManager get programs =>
      $$ProgramsTableTableManager(_db, _db.programs);
  $$AssignmentRowsTableTableManager get assignmentRows =>
      $$AssignmentRowsTableTableManager(_db, _db.assignmentRows);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
