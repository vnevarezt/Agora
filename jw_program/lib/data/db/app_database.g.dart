// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HermanosTable extends Hermanos with TableInfo<$HermanosTable, Hermano> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HermanosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
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
  late final GeneratedColumnWithTypeConverter<Sexo, String> sexo =
      GeneratedColumn<String>(
        'sexo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Sexo>($HermanosTable.$convertersexo);
  @override
  late final GeneratedColumnWithTypeConverter<Privilegio, String> privilegio =
      GeneratedColumn<String>(
        'privilegio',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Privilegio>($HermanosTable.$converterprivilegio);
  static const VerificationMeta _congregacionMeta = const VerificationMeta(
    'congregacion',
  );
  @override
  late final GeneratedColumn<String> congregacion = GeneratedColumn<String>(
    'congregacion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _ultimoUsoMeta = const VerificationMeta(
    'ultimoUso',
  );
  @override
  late final GeneratedColumn<DateTime> ultimoUso = GeneratedColumn<DateTime>(
    'ultimo_uso',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    sexo,
    privilegio,
    congregacion,
    activo,
    notas,
    createdAt,
    updatedAt,
    ultimoUso,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hermanos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Hermano> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('congregacion')) {
      context.handle(
        _congregacionMeta,
        congregacion.isAcceptableOrUnknown(
          data['congregacion']!,
          _congregacionMeta,
        ),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
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
    if (data.containsKey('ultimo_uso')) {
      context.handle(
        _ultimoUsoMeta,
        ultimoUso.isAcceptableOrUnknown(data['ultimo_uso']!, _ultimoUsoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Hermano map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Hermano(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      sexo: $HermanosTable.$convertersexo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sexo'],
        )!,
      ),
      privilegio: $HermanosTable.$converterprivilegio.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}privilegio'],
        )!,
      ),
      congregacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}congregacion'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      ultimoUso: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultimo_uso'],
      ),
    );
  }

  @override
  $HermanosTable createAlias(String alias) {
    return $HermanosTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Sexo, String, String> $convertersexo =
      const EnumNameConverter<Sexo>(Sexo.values);
  static JsonTypeConverter2<Privilegio, String, String> $converterprivilegio =
      const EnumNameConverter<Privilegio>(Privilegio.values);
}

class HermanosCompanion extends UpdateCompanion<Hermano> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<Sexo> sexo;
  final Value<Privilegio> privilegio;
  final Value<String> congregacion;
  final Value<bool> activo;
  final Value<String> notas;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> ultimoUso;
  final Value<int> rowid;
  const HermanosCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.sexo = const Value.absent(),
    this.privilegio = const Value.absent(),
    this.congregacion = const Value.absent(),
    this.activo = const Value.absent(),
    this.notas = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.ultimoUso = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HermanosCompanion.insert({
    required String id,
    required String nombre,
    required Sexo sexo,
    required Privilegio privilegio,
    this.congregacion = const Value.absent(),
    this.activo = const Value.absent(),
    this.notas = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.ultimoUso = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       sexo = Value(sexo),
       privilegio = Value(privilegio),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Hermano> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? sexo,
    Expression<String>? privilegio,
    Expression<String>? congregacion,
    Expression<bool>? activo,
    Expression<String>? notas,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? ultimoUso,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (sexo != null) 'sexo': sexo,
      if (privilegio != null) 'privilegio': privilegio,
      if (congregacion != null) 'congregacion': congregacion,
      if (activo != null) 'activo': activo,
      if (notas != null) 'notas': notas,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (ultimoUso != null) 'ultimo_uso': ultimoUso,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HermanosCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<Sexo>? sexo,
    Value<Privilegio>? privilegio,
    Value<String>? congregacion,
    Value<bool>? activo,
    Value<String>? notas,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? ultimoUso,
    Value<int>? rowid,
  }) {
    return HermanosCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      sexo: sexo ?? this.sexo,
      privilegio: privilegio ?? this.privilegio,
      congregacion: congregacion ?? this.congregacion,
      activo: activo ?? this.activo,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ultimoUso: ultimoUso ?? this.ultimoUso,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (sexo.present) {
      map['sexo'] = Variable<String>(
        $HermanosTable.$convertersexo.toSql(sexo.value),
      );
    }
    if (privilegio.present) {
      map['privilegio'] = Variable<String>(
        $HermanosTable.$converterprivilegio.toSql(privilegio.value),
      );
    }
    if (congregacion.present) {
      map['congregacion'] = Variable<String>(congregacion.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (ultimoUso.present) {
      map['ultimo_uso'] = Variable<DateTime>(ultimoUso.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HermanosCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('sexo: $sexo, ')
          ..write('privilegio: $privilegio, ')
          ..write('congregacion: $congregacion, ')
          ..write('activo: $activo, ')
          ..write('notas: $notas, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('ultimoUso: $ultimoUso, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$HermanoInsertable implements Insertable<Hermano> {
  Hermano _object;
  _$HermanoInsertable(this._object);
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return HermanosCompanion(
      id: Value(_object.id),
      nombre: Value(_object.nombre),
      sexo: Value(_object.sexo),
      privilegio: Value(_object.privilegio),
      congregacion: Value(_object.congregacion),
      activo: Value(_object.activo),
      notas: Value(_object.notas),
      createdAt: Value(_object.createdAt),
      updatedAt: Value(_object.updatedAt),
      ultimoUso: Value(_object.ultimoUso),
    ).toColumns(false);
  }
}

extension HermanoToInsertable on Hermano {
  _$HermanoInsertable toInsertable() {
    return _$HermanoInsertable(this);
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HermanosTable hermanos = $HermanosTable(this);
  late final HermanosDao hermanosDao = HermanosDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [hermanos];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$HermanosTableCreateCompanionBuilder =
    HermanosCompanion Function({
      required String id,
      required String nombre,
      required Sexo sexo,
      required Privilegio privilegio,
      Value<String> congregacion,
      Value<bool> activo,
      Value<String> notas,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> ultimoUso,
      Value<int> rowid,
    });
typedef $$HermanosTableUpdateCompanionBuilder =
    HermanosCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<Sexo> sexo,
      Value<Privilegio> privilegio,
      Value<String> congregacion,
      Value<bool> activo,
      Value<String> notas,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> ultimoUso,
      Value<int> rowid,
    });

class $$HermanosTableFilterComposer
    extends Composer<_$AppDatabase, $HermanosTable> {
  $$HermanosTableFilterComposer({
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

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Sexo, Sexo, String> get sexo =>
      $composableBuilder(
        column: $table.sexo,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Privilegio, Privilegio, String>
  get privilegio => $composableBuilder(
    column: $table.privilegio,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get congregacion => $composableBuilder(
    column: $table.congregacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
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

  ColumnFilters<DateTime> get ultimoUso => $composableBuilder(
    column: $table.ultimoUso,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HermanosTableOrderingComposer
    extends Composer<_$AppDatabase, $HermanosTable> {
  $$HermanosTableOrderingComposer({
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

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sexo => $composableBuilder(
    column: $table.sexo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privilegio => $composableBuilder(
    column: $table.privilegio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get congregacion => $composableBuilder(
    column: $table.congregacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
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

  ColumnOrderings<DateTime> get ultimoUso => $composableBuilder(
    column: $table.ultimoUso,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HermanosTableAnnotationComposer
    extends Composer<_$AppDatabase, $HermanosTable> {
  $$HermanosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Sexo, String> get sexo =>
      $composableBuilder(column: $table.sexo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Privilegio, String> get privilegio =>
      $composableBuilder(
        column: $table.privilegio,
        builder: (column) => column,
      );

  GeneratedColumn<String> get congregacion => $composableBuilder(
    column: $table.congregacion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get ultimoUso =>
      $composableBuilder(column: $table.ultimoUso, builder: (column) => column);
}

class $$HermanosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HermanosTable,
          Hermano,
          $$HermanosTableFilterComposer,
          $$HermanosTableOrderingComposer,
          $$HermanosTableAnnotationComposer,
          $$HermanosTableCreateCompanionBuilder,
          $$HermanosTableUpdateCompanionBuilder,
          (Hermano, BaseReferences<_$AppDatabase, $HermanosTable, Hermano>),
          Hermano,
          PrefetchHooks Function()
        > {
  $$HermanosTableTableManager(_$AppDatabase db, $HermanosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HermanosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HermanosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HermanosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<Sexo> sexo = const Value.absent(),
                Value<Privilegio> privilegio = const Value.absent(),
                Value<String> congregacion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<String> notas = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> ultimoUso = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HermanosCompanion(
                id: id,
                nombre: nombre,
                sexo: sexo,
                privilegio: privilegio,
                congregacion: congregacion,
                activo: activo,
                notas: notas,
                createdAt: createdAt,
                updatedAt: updatedAt,
                ultimoUso: ultimoUso,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required Sexo sexo,
                required Privilegio privilegio,
                Value<String> congregacion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<String> notas = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> ultimoUso = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HermanosCompanion.insert(
                id: id,
                nombre: nombre,
                sexo: sexo,
                privilegio: privilegio,
                congregacion: congregacion,
                activo: activo,
                notas: notas,
                createdAt: createdAt,
                updatedAt: updatedAt,
                ultimoUso: ultimoUso,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HermanosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HermanosTable,
      Hermano,
      $$HermanosTableFilterComposer,
      $$HermanosTableOrderingComposer,
      $$HermanosTableAnnotationComposer,
      $$HermanosTableCreateCompanionBuilder,
      $$HermanosTableUpdateCompanionBuilder,
      (Hermano, BaseReferences<_$AppDatabase, $HermanosTable, Hermano>),
      Hermano,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HermanosTableTableManager get hermanos =>
      $$HermanosTableTableManager(_db, _db.hermanos);
}
