// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participants_dao.dart';

// ignore_for_file: type=lint
mixin _$ParticipantsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ParticipantsTable get participants => attachedDatabase.participants;
  ParticipantsDaoManager get managers => ParticipantsDaoManager(this);
}

class ParticipantsDaoManager {
  final _$ParticipantsDaoMixin _db;
  ParticipantsDaoManager(this._db);
  $$ParticipantsTableTableManager get participants =>
      $$ParticipantsTableTableManager(_db.attachedDatabase, _db.participants);
}
