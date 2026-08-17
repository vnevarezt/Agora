import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/cloud_auth.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/motion.dart';

/// `.portada--a`: immersive welcome screen — brand mark, tagline and the
/// three entry actions (cloud register / cloud sign-in / local only), with
/// the mock's staggered entrance animation.
class PortadaScreen extends ConsumerWidget {
  const PortadaScreen({
    super.key,
    required this.onCreateAccount,
    required this.onSignIn,
    required this.onLocal,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;
  final VoidCallback onLocal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tr = context.t;
    final wide = context.screenSize == ScreenSize.desktop;
    // Optimistic while the probe resolves (milliseconds, masked by the
    // entrance animation); flips to the local-only layout when this install
    // can't hold a cloud session (macOS without provisioned signing).
    final cloudOk = ref.watch(cloudAuthSupportedProvider).value ?? true;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.s24, 40, Space.s24, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  EnterUp(
                    delay: Motion.stagger(0),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: t.accent.withValues(alpha: 0.6),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: -8,
                          ),
                        ],
                      ),
                      child: Text(
                        'JW',
                        style: TextStyle(
                          fontSize: AppText.display,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.38,
                          color: t.accentInk,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.s18),
                  EnterUp(
                    delay: Motion.stagger(1),
                    child: Text(
                      tr.app.brand,
                      style: TextStyle(
                        fontSize: wide ? 30 : 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                        height: 1.1,
                        color: t.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.s10),
                  EnterUp(
                    delay: Motion.stagger(2),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        tr.portada.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: wide ? 15 : 14,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: t.textMute,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.s24),
                  EnterUp(
                    delay: Motion.stagger(3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (cloudOk) ...[
                          _PortadaButton.primary(
                            label: tr.portada.createAccount,
                            onTap: onCreateAccount,
                          ),
                          const SizedBox(height: Space.s10),
                          _PortadaButton.ghost(
                            label: tr.portada.signIn,
                            onTap: onSignIn,
                          ),
                        ] else
                          Text(
                            tr.portada.cloudUnsupported,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppText.small,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              color: t.textMute,
                            ),
                          ),
                        // Local mode is native-only. Its password wraps the DEK
                        // and the OS keychain holds the result; a browser has
                        // no keychain, so offering it here would walk the user
                        // into a gate with nothing behind it.
                        if (!kIsWeb) ...[
                          const SizedBox(height: Space.s14),
                          _LocalEntryCard(onTap: onLocal),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.s24),
                  EnterUp(
                    delay: Motion.stagger(4),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Text(
                        tr.portada.legal,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppText.caption,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: t.textMute,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortadaButton extends StatelessWidget {
  const _PortadaButton.primary({required this.label, required this.onTap})
    : primary = true;

  const _PortadaButton.ghost({required this.label, required this.onTap})
    : primary = false;

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, pressed) {
        final bg = primary
            ? (hovered ? t.accentStrong : t.accent)
            : (hovered ? t.surface2 : t.surface);
        final fg = primary ? t.accentInk : t.text;
        return AnimatedContainer(
          duration: Motion.of(context, Motion.instant),
          curve: Motion.curve,
          height: 48,
          transform: pressed
              ? (Matrix4.identity()..translateByDouble(0, 1, 0, 1))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(11),
            border: primary
                ? null
                : Border.all(color: hovered ? t.textMute : t.border),
            boxShadow: primary ? Elevation.control : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppText.bodyLarge,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                  color: fg,
                ),
              ),
              if (primary) ...[
                const SizedBox(width: Space.s8),
                AnimatedSlide(
                  duration: Motion.of(context, Motion.instant),
                  curve: Motion.curve,
                  offset: hovered ? const Offset(0.18, 0) : Offset.zero,
                  child: Icon(Icons.arrow_forward, size: AppIcon.control, color: fg),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// `.portada__local`: "continue without an account" entry row.
class _LocalEntryCard extends StatelessWidget {
  const _LocalEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => AnimatedContainer(
        duration: Motion.of(context, Motion.instant),
        curve: Motion.curve,
        padding: const EdgeInsets.symmetric(horizontal: Space.s14, vertical: Space.s12),
        decoration: BoxDecoration(
          color: hovered ? t.accentTint : t.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hovered ? t.accent : t.border2),
        ),
        child: Row(
          children: [
            Icon(Icons.smartphone, size: AppIcon.control, color: t.accentStrong),
            const SizedBox(width: Space.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.portada.noAccountTitle,
                  style: TextStyle(
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  tr.portada.noAccountCaption,
                  style: TextStyle(
                    fontSize: AppText.caption,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
