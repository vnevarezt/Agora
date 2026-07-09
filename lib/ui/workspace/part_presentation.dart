import '../../i18n/strings.g.dart';
import '../../models/program_row.dart';
import '../../state/assignment_ops.dart';
import '../limits.dart';

/// Pure row → card-view mapper. The single place where the parts' presentation
/// logic lives (card kind, chips, slot labels).

enum PartKind {
  /// Single fixed line with no assignment (middle song, intro/conclusion).
  fixedLine,

  /// Card with assignment slots.
  role,
}

/// An assignment slot inside a card.
class SlotSpec {
  final String label;
  final SlotRef ref;
  final int maxLength;

  /// Auxiliary-room slot: label in accent color.
  final bool accent;

  const SlotSpec({
    required this.label,
    required this.ref,
    required this.maxLength,
    this.accent = false,
  });
}

/// Ready-to-render data for a workspace card.
class PartView {
  final String id;
  final PartKind kind;
  final String time;
  final String title;

  /// "10 min" (extracted from the "(10 mins.)" suffix of `content`).
  final String? durationLabel;

  /// Right-hand label on fixed lines ("Cántico", "A cargo del presidente"); on
  /// role cards, an extra header chip.
  final String? fixedTag;

  /// Show "TODA LA REUNIÓN" instead of the time (chairman).
  final bool allMeetingBadge;

  /// "Auxiliary room" indicator in the header.
  final bool auxFlag;

  final List<SlotSpec> slots;

  const PartView({
    required this.id,
    required this.kind,
    this.time = '',
    required this.title,
    this.durationLabel,
    this.fixedTag,
    this.allMeetingBadge = false,
    this.auxFlag = false,
    this.slots = const [],
  });
}

final _durationSuffix = RegExp(r'\s*\((\d+)\s*mins?\.\)$');

/// Slot labels based on the row's role (same rule as the old editor). The
/// `contains('Conductor')` check matches the raw workbook data (kept in the
/// meeting language); only the displayed labels are translated.
List<String> _labelsForRole(ProgramRow row) {
  if (row.slots == 2) {
    return row.role.contains('Conductor')
        ? [t.workspace.slotConductor, t.workspace.slotReader]
        : [t.workspace.slotStudent, t.workspace.slotAssistant];
  }
  if (row.role == 'Orador:') return [t.workspace.slotSpeaker];
  return [
    row.role.isNotEmpty ? row.role.replaceAll(':', '') : t.workspace.slotInCharge
  ];
}

int _maxLengthForRole(ProgramRow row) =>
    row.slots == 2 && !row.role.contains('Conductor')
        ? Limits.studentAssistant
        : Limits.name;

/// Synthetic card for the meeting chairman.
PartView chairmanView() {
  return PartView(
    id: 'presidente',
    kind: PartKind.role,
    title: t.workspace.chairmanTitle,
    allMeetingBadge: true,
    slots: [
      SlotSpec(
        label: t.workspace.chairman,
        ref: const ChairmanSlot(),
        maxLength: Limits.name,
      ),
    ],
  );
}

/// Maps a schedule row to its card. [auxActive] = the form's Auxiliary Room
/// switch.
PartView mapRow(ProgramRow row, {required bool auxActive}) {
  final match = _durationSuffix.firstMatch(row.content);
  final title = row.content.replaceAll(_durationSuffix, '');
  final duration =
      match != null ? t.workspace.duration(n: match.group(1)!) : null;
  // `startsWith('Canción')` checks the raw workbook data (meeting language).
  final isSong = row.content.startsWith('Canción');

  if (row.slots == 0) {
    return PartView(
      id: row.id,
      kind: PartKind.fixedLine,
      time: row.time,
      title: title,
      durationLabel: duration,
      fixedTag: isSong ? t.workspace.songTag : t.workspace.chairmanTag,
    );
  }

  final labels = _labelsForRole(row);
  final maxLength = _maxLengthForRole(row);
  final withAux = auxActive && row.auxSlots > 0;

  return PartView(
    id: row.id,
    kind: PartKind.role,
    time: row.time,
    title: title,
    durationLabel: duration,
    // The opening/closing song carries the prayer slot in the model: it shows
    // as a role card with the "Cántico" chip.
    fixedTag: isSong ? t.workspace.songTag : null,
    auxFlag: withAux,
    slots: [
      for (var i = 0; i < row.slots; i++)
        SlotSpec(
          label: labels[i],
          ref: RowSlot(row, i),
          maxLength: maxLength,
        ),
      if (withAux)
        for (var i = 0; i < row.auxSlots; i++)
          SlotSpec(
            label: t.workspace.slotAux(label: labels[i]),
            ref: RowSlot(row, i, aux: true),
            maxLength: maxLength,
            accent: true,
          ),
    ],
  );
}
