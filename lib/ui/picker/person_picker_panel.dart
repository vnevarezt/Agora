import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../models/person.dart';
import '../../state/people_provider.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';
import '../widgets/motion.dart';
import 'person_picker.dart';

/// Person picker content, shared between the desktop popover and the
/// mobile bottom sheet. Returns the result by popping its own route with
/// a [PickResult].
class PersonPickerPanel extends ConsumerStatefulWidget {
  const PersonPickerPanel({
    super.key,
    required this.roleLabel,
    required this.current,
    required this.maxLength,
    this.mobile = false,
  });

  final String roleLabel;

  /// Currently assigned name ('' if the slot is empty).
  final String current;
  final int maxLength;
  final bool mobile;

  @override
  ConsumerState<PersonPickerPanel> createState() => _PersonPickerPanelState();
}

class _PersonPickerPanelState extends ConsumerState<PersonPickerPanel> {
  String _query = '';

  void _pop(PickResult resultado) =>
      Navigator.of(context).pop(resultado);

  String get _search => _query.trim();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final active = ref.watch(activePeopleKeyedProvider);

    final key = normalizeName(_search);
    final filtered = [
      for (final e in active)
        if (e.key.contains(key)) e.person,
    ];
    final recent = _search.isEmpty
        ? ref.watch(recentPeopleProvider).take(4).toList()
        : const <Person>[];
    final rowHeight = personPickerRowHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.mobile)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 9, bottom: 2),
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(Dimens.rPill),
              ),
            ),
          ),
        _header(context),
        Flexible(
          child: CustomScrollView(
            // shrinkWrap so the popover still sizes to its content. It stays
            // cheap because the person slivers declare a fixed extent: the
            // list derives its height from childCount * itemExtent instead of
            // laying out every row, which is what a plain ListView did on
            // every keystroke.
            shrinkWrap: true,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(6),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    if (widget.current.isNotEmpty)
                      SliverToBoxAdapter(
                        child: PersonPickerRow(
                          name: context.t.common.removeAssignment,
                          avatarVacio: true,
                          muted: true,
                          selected: true,
                          onTap: () => _pop(const PickRemove()),
                        ),
                      ),
                    if (recent.isNotEmpty) ...[
                      SliverToBoxAdapter(
                          child: _group(t, context.t.picker.recent)),
                      SliverFixedExtentList.builder(
                        itemExtent: rowHeight,
                        itemCount: recent.length,
                        itemBuilder: (context, i) => _row(recent[i]),
                      ),
                      SliverToBoxAdapter(
                          child: _group(t, context.t.picker.all)),
                    ],
                    SliverFixedExtentList.builder(
                      itemExtent: rowHeight,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _row(filtered[i]),
                    ),
                    if (filtered.isEmpty && _search.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 18),
                          child: Text(
                            context.t.picker.noResults(query: _search),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppText.body,
                              fontWeight: FontWeight.w600,
                              color: t.textMute,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _footer(context),
      ],
    );
  }

  /// A person row: privilege as a label (only elder/servant).
  Widget _row(Person h) {
    return PersonPickerRow(
      name: h.displayName,
      tag: h.privilege == Role.publisher ? null : h.privilege.label(context.t),
      selected: h.displayName == widget.current,
      onTap: () => _pop(PickName(h.displayName)),
    );
  }

  Widget _header(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.t.picker.assign.toUpperCase()} · ${widget.roleLabel.toUpperCase()}',
            style: AppText.label(size: 11, color: t.textMute),
          ),
          const SizedBox(height: 10),
          TextField(
            autofocus: true,
            maxLength: widget.maxLength,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(
                fontSize: AppText.body, fontWeight: FontWeight.w600, color: t.text),
            decoration: InputDecoration(
              counterText: '',
              hintText: context.t.common.searchParticipant,
              prefixIcon: Icon(Icons.search, size: 16, color: t.textMute),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 36, minHeight: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(AppTokens t, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Text(title.toUpperCase(),
          style: AppText.label(color: t.textMute)),
    );
  }

  /// "Añadir" footer: assigns the typed name and adds it to the in-memory
  /// directory (full management comes in another phase).
  Widget _footer(BuildContext context) {
    final t = context.tokens;
    final enabled = _search.isNotEmpty;
    final label = enabled
        ? context.t.picker.addNamed(query: _search)
        : context.t.picker.addParticipant;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border2)),
      ),
      child: Pressable(
        onTap: enabled
            ? () => _pop(PickName(
                _search.length > widget.maxLength
                    ? _search.substring(0, widget.maxLength)
                    : _search))
            : null,
        builder: (context, hovered, _) {
          final color = enabled ? t.accentStrong : t.textMute;
          return AnimatedContainer(
            duration: Motion.instant,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: hovered && enabled
                  ? t.accentSoft
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(Dimens.rControl),
            ),
            child: Row(
              children: [
                Icon(Icons.add, size: 17, color: color),
                const SizedBox(width: 9),
                Text(label,
                    style: TextStyle(
                        fontSize: AppText.body,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The height every [PersonPickerRow] lays out at, for the current text scale.
/// The row is uniform by construction: a fixed avatar and a single-line name,
/// so neither a long name nor the privilege tag changes it. That uniformity
/// is what lets the picker virtualise while still sizing to its content.
///
/// Rounds high rather than low — a row a pixel taller than its content is
/// invisible, a pixel shorter clips it. Pinned against the real laid-out
/// height by `person_picker_test`.
double personPickerRowHeight(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  const verticalPadding = 7.0 * 2;
  const lineHeight = 1.44;
  return math.max(Dimens.avatar, scaler.scale(AppText.bodyLarge) * lineHeight) +
      verticalPadding;
}

class PersonPickerRow extends StatelessWidget {
  const PersonPickerRow({
    super.key,
    required this.name,
    required this.onTap,
    this.tag,
    this.selected = false,
    this.avatarVacio = false,
    this.muted = false,
  });

  final String name;
  final VoidCallback onTap;
  final String? tag;
  final bool selected;
  final bool avatarVacio;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? t.accentSoft
                : hovered
                    ? t.surface2
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimens.rControl),
          ),
          child: Row(
            children: [
              PersonAvatar(name: avatarVacio ? null : name),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppText.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: muted ? t.textMute : t.text,
                  ),
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: 8),
                Text(
                  tag!,
                  style: TextStyle(
                    fontSize: AppText.caption,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                ),
              ],
              if (selected && !avatarVacio) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 18, color: t.accent),
              ],
            ],
          ),
        );
      },
    );
  }
}
