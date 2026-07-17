import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup/backup_service.dart';
import 'db_provider.dart';

/// Encrypted full backup (the settings "Datos" card). Lives below AuthGate
/// like every DB consumer.
final backupServiceProvider = Provider<BackupService>((ref) =>
    BackupService(ref.watch(dbProvider), ref.watch(syncScribeProvider)));
