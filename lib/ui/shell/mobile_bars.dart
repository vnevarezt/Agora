import 'dart:ui' show ImageFilter;

import '../theme/dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/progress_provider.dart';
import '../../state/ui_state.dart';
import '../theme/tokens.dart';
import '../widgets/export_button.dart';
import '../widgets/progress_ring.dart';
import '../widgets/segmented_control.dart';

/// Assign / Preview tabs (`.mobile-tabs`).
class MobileTabs extends ConsumerWidget {
  const MobileTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tab = ref.watch(mobileTabProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s14, vertical: Space.s8),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: SegmentedTabs(
        expand: true,
        index: tab.index,
        segments: [
          (icon: Icons.edit_outlined, label: context.t.preview.assignTab),
          (icon: Icons.description_outlined, label: context.t.preview.previewTab),
        ],
        onChanged: (i) => ref
            .read(mobileTabProvider.notifier)
            .select(MobileTab.values[i]),
      ),
    );
  }
}

/// Fixed mobile bottom bar (`.bottom-bar`): frosted glass with the progress
/// ring and a full-width Export button.
///
/// Deliberately not a Consumer: a blur is the most expensive thing this app
/// asks of the GPU, and watching the progress here rebuilt — and so repainted
/// — the whole frosted layer on every name assigned. The ring watches it
/// instead, behind a RepaintBoundary so its repaints stay off the blur.
class MobileBottomBar extends StatelessWidget {
  const MobileBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(Space.s14, Space.s12, Space.s14, Space.s12 + safeBottom),
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: 0.88),
            border: Border(top: BorderSide(color: t.border)),
          ),
          child: const Row(
            children: [
              RepaintBoundary(child: _BottomBarProgress()),
              SizedBox(width: Space.s12),
              Expanded(child: ExportButton(variant: ExportVariant.full)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarProgress extends ConsumerWidget {
  const _BottomBarProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progreso = ref.watch(progressProvider);
    return ProgressRing(done: progreso.done, total: progreso.total);
  }
}
