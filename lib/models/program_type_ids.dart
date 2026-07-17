/// Stable ids of the program types (docs/DATA_ARCHITECTURE.md §2): stored
/// as TEXT in `programs.programTypeId`, resolved by the code registry when
/// it lands in phase 2. Never an enum in data — new types must not require
/// migrations.
abstract final class ProgramTypeIds {
  /// Christian Life and Ministry meeting (S-140), the only type today.
  static const mwbS140 = 'mwb-s140';
}
