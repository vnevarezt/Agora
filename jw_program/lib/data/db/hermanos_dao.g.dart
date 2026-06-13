// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hermanos_dao.dart';

// ignore_for_file: type=lint
mixin _$HermanosDaoMixin on DatabaseAccessor<AppDatabase> {
  $HermanosTable get hermanos => attachedDatabase.hermanos;
  HermanosDaoManager get managers => HermanosDaoManager(this);
}

class HermanosDaoManager {
  final _$HermanosDaoMixin _db;
  HermanosDaoManager(this._db);
  $$HermanosTableTableManager get hermanos =>
      $$HermanosTableTableManager(_db.attachedDatabase, _db.hermanos);
}
