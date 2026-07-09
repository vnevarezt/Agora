/// Character limits for fields (avoid huge text that breaks the PDF layout; a
/// full name fits with plenty of room to spare).
class Limits {
  Limits._();
  static const int name = 30; // per participant (1 name)
  static const int studentAssistant = 25; // Student/Assistant pair (2 per row)
  static const int congregation = 40; // congregation name
  static const int notes = 200; // a participant's notes (directory)
}
