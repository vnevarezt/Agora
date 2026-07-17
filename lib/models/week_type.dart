/// Week variant that alters the generated program template
/// (docs/DATA_ARCHITECTURE.md §2): a circuit-overseer visit replaces the
/// congregation Bible study with the overseer's talk, assembly/convention
/// and Memorial weeks change or drop the local meeting entirely.
enum WeekType {
  normal,
  circuitOverseerVisit,
  assembly,
  convention,
  memorial,
  noMeeting,
}
