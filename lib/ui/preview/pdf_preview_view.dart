import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/preview_provider.dart';
import '../../state/program_form.dart';
import '../responsive.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';

/// Rasterized PDF viewer (pdfrx). The zoom/quality logic is unchanged;
/// only the chrome changes: token background, a sheet with the radius and
/// shadows, and catalog zoom FABs.
class PdfPreviewView extends ConsumerWidget {
  const PdfPreviewView({super.key, required this.controller});

  /// Driven by [PreviewPane], which shows the zoom % in its bar.
  final TransformationController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    if (ref.watch(scheduleProvider) == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 40, color: t.textMute),
            const SizedBox(height: 12),
            Text(
              context.t.preview.emptyHint,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: t.textMute,
              ),
            ),
          ],
        ),
      );
    }

    final preview = ref.watch(previewProvider);
    return preview.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.t.preview.error(error: e),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
      data: (img) => _Vista(img: img, controller: controller),
    );
  }
}

class _Vista extends ConsumerWidget {
  const _Vista({required this.img, required this.controller});

  final ui.Image img;
  final TransformationController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aspect = img.width / img.height;

    return LayoutBuilder(
      builder: (context, c) {
        const margen = 22.0;
        final pageW = c.maxWidth - margen * 2;
        final pageH = pageW / aspect;
        final childW = c.maxWidth;
        final childH = pageH + margen * 2;

        void escalaCentrada(double s) {
          s = s.clamp(0.2, 6.0);
          controller.value = Matrix4.identity()
            ..translateByDouble((c.maxWidth - childW * s) / 2,
                (c.maxHeight - childH * s) / 2, 0, 1)
            ..scaleByDouble(s, s, s, 1);
          ref.read(previewProvider.notifier).adjustZoomQuality(s);
        }

        void zoom(double factor) {
          final m0 = controller.value;
          final s0 = m0.getMaxScaleOnAxis();
          final ns = (s0 * factor).clamp(0.2, 6.0);
          final cx = c.maxWidth / 2, cy = c.maxHeight / 2;
          final spx = (cx - m0.storage[12]) / s0;
          final spy = (cy - m0.storage[13]) / s0;
          controller.value = Matrix4.identity()
            ..translateByDouble(cx - ns * spx, cy - ns * spy, 0, 1)
            ..scaleByDouble(ns, ns, ns, 1);
          ref.read(previewProvider.notifier).adjustZoomQuality(ns);
        }

        final fitPage = (c.maxHeight / childH).clamp(0.2, 1.0).toDouble();

        return Stack(
          children: [
            InteractiveViewer(
              constrained: false,
              minScale: 0.2,
              maxScale: 6,
              boundaryMargin: const EdgeInsets.all(2000),
              transformationController: controller,
              onInteractionEnd: (_) => ref
                  .read(previewProvider.notifier)
                  .adjustZoomQuality(controller.value.getMaxScaleOnAxis()),
              child: Padding(
                padding: const EdgeInsets.all(margen),
                child: Container(
                  width: pageW,
                  height: pageH,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x24000000),
                          blurRadius: 30,
                          offset: Offset(0, 8)),
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    child: RawImage(image: img, fit: BoxFit.fill),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              // On mobile the bottom bar floats over the panel: raise the FABs.
              bottom: context.isMobile ? 96 : 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconButton(
                      icon: Icons.add,
                      elevated: true,
                      tooltip: context.t.preview.zoomIn,
                      onPressed: () => zoom(1.3)),
                  const SizedBox(height: 6),
                  AppIconButton(
                      icon: Icons.remove,
                      elevated: true,
                      tooltip: context.t.preview.zoomOut,
                      onPressed: () => zoom(1 / 1.3)),
                  const SizedBox(height: 6),
                  AppIconButton(
                      icon: Icons.fit_screen_outlined,
                      elevated: true,
                      tooltip: context.t.preview.fitPage,
                      onPressed: () => escalaCentrada(fitPage)),
                  const SizedBox(height: 6),
                  AppIconButton(
                      icon: Icons.width_normal_outlined,
                      elevated: true,
                      tooltip: context.t.preview.fitWidth,
                      onPressed: () =>
                          controller.value = Matrix4.identity()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
