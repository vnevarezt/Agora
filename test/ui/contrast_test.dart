import 'dart:math' as math;

import 'package:agora/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 relative luminance / contrast ratio.
double _channel(int v) {
  final c = v / 255;
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;
}

double _luminance(Color c) =>
    0.2126 * _channel((c.r * 255).round()) +
    0.7152 * _channel((c.g * 255).round()) +
    0.0722 * _channel((c.b * 255).round());

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Every (ink, ground) pair the UI actually renders, with the WCAG floor that
/// applies to it: 4.5 for text, 3.0 for the outline that identifies a control.
///
/// Grounds are listed per ink because the same ink lands on several surfaces
/// and only the worst one decides whether the token passes.
List<({String name, Color ink, Color ground, double min})> _pairs(AppTokens t) =>
    [
      (name: 'text/bg', ink: t.text, ground: t.bg, min: 4.5),
      (name: 'text/surface', ink: t.text, ground: t.surface, min: 4.5),
      (name: 'text/surface2', ink: t.text, ground: t.surface2, min: 4.5),
      (name: 'textDim/bg', ink: t.textDim, ground: t.bg, min: 4.5),
      (name: 'textDim/surface', ink: t.textDim, ground: t.surface, min: 4.5),
      (name: 'textDim/surface2', ink: t.textDim, ground: t.surface2, min: 4.5),
      (name: 'textMute/bg', ink: t.textMute, ground: t.bg, min: 4.5),
      (name: 'textMute/surface', ink: t.textMute, ground: t.surface, min: 4.5),
      (name: 'textMute/surface2', ink: t.textMute, ground: t.surface2, min: 4.5),
      (name: 'accent/surface', ink: t.accent, ground: t.surface, min: 4.5),
      (name: 'accentOnSoft/accentSoft',
          ink: t.accentOnSoft, ground: t.accentSoft, min: 4.5),
      (name: 'accentOnSoft/accentTint',
          ink: t.accentOnSoft, ground: t.accentTint, min: 4.5),
      (name: 'accentInk/accent', ink: t.accentInk, ground: t.accent, min: 4.5),
      (name: 'success/successSoft',
          ink: t.success, ground: t.successSoft, min: 4.5),
      (name: 'warning/warningSoft',
          ink: t.warning, ground: t.warningSoft, min: 4.5),
      (name: 'alert/alertSoft', ink: t.alert, ground: t.alertSoft, min: 4.5),
      (name: 'borderControl/surface',
          ink: t.borderControl, ground: t.surface, min: 3.0),
      (name: 'borderControl/surface2',
          ink: t.borderControl, ground: t.surface2, min: 3.0),
      (name: 'borderControl/bg', ink: t.borderControl, ground: t.bg, min: 3.0),
      (name: 'successStrong/surface',
          ink: t.successStrong, ground: t.surface, min: 3.0),
      (name: 'warningStrong/surface',
          ink: t.warningStrong, ground: t.surface, min: 3.0),
    ];

void main() {
  group('WCAG AA contrast', () {
    for (final mode in [
      (label: 'light', tokens: pizarra.light),
      (label: 'dark', tokens: pizarra.dark),
    ]) {
      group(mode.label, () {
        for (final p in _pairs(mode.tokens)) {
          test('${p.name} >= ${p.min}:1', () {
            final ratio = contrast(p.ink, p.ground);
            expect(ratio, greaterThanOrEqualTo(p.min),
                reason: '${p.name} in ${mode.label} is '
                    '${ratio.toStringAsFixed(2)}:1, below ${p.min}:1');
          });
        }
      });
    }

    test('textMute stays quieter than textDim in both themes', () {
      for (final t in [pizarra.light, pizarra.dark]) {
        expect(contrast(t.textMute, t.surface),
            lessThan(contrast(t.textDim, t.surface)));
      }
    });
  });
}
