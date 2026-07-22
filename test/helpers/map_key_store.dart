import 'package:jw_program/data/db/db_key_manager.dart';

/// In-memory stand-in for the OS keychain.
class MapKeyStore implements SecureKeyStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<Set<String>> keys() async => data.keys.toSet();
}

/// Cheap Argon2id cost so suites stay fast; production uses
/// [KdfParams.owasp] (blobs are self-describing, so both interoperate).
const testKdfParams = KdfParams(memoryKib: 64, iterations: 1, parallelism: 1);
