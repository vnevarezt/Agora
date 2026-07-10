import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';

/// `.portada--a`: immersive welcome screen — brand mark, tagline and the
/// three entry actions (cloud register / cloud sign-in / local only), with
/// the mock's staggered entrance animation.
class PortadaScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _EnterUp(
                    delay: Duration.zero,
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
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.38,
                          color: t.accentInk,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _EnterUp(
                    delay: const Duration(milliseconds: 50),
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
                  const SizedBox(height: 9),
                  _EnterUp(
                    delay: const Duration(milliseconds: 100),
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
                  const SizedBox(height: 26),
                  _EnterUp(
                    delay: const Duration(milliseconds: 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PortadaButton.primary(
                          label: tr.portada.createAccount,
                          onTap: onCreateAccount,
                        ),
                        const SizedBox(height: 10),
                        _PortadaButton.ghost(
                          label: tr.portada.signIn,
                          onTap: onSignIn,
                        ),
                        const SizedBox(height: 14),
                        _LocalEntryCard(onTap: onLocal),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _EnterUp(
                    delay: const Duration(milliseconds: 280),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Text(
                        tr.portada.legal,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
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
          duration: Dimens.dFast,
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
            boxShadow: primary
                ? const [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 2,
                        offset: Offset(0, 1)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                  color: fg,
                ),
              ),
              if (primary) ...[
                const SizedBox(width: 8),
                AnimatedSlide(
                  duration: Dimens.dFast,
                  offset: hovered ? const Offset(0.18, 0) : Offset.zero,
                  child: Icon(Icons.arrow_forward, size: 17, color: fg),
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
        duration: Dimens.dFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: hovered ? t.accentTint : t.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hovered ? t.accent : t.border2),
        ),
        child: Row(
          children: [
            Icon(Icons.smartphone, size: 18, color: t.accentStrong),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.portada.noAccountTitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  tr.portada.noAccountCaption,
                  style: TextStyle(
                    fontSize: 11.5,
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

/// Fade + slide-up entrance, played once on mount (mirrors the mock's
/// `portUp` keyframes with per-element delays).
class _EnterUp extends StatefulWidget {
  const _EnterUp({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_EnterUp> createState() => _EnterUpState();
}

class _EnterUpState extends State<_EnterUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
  late final CurvedAnimation _anim =
      CurvedAnimation(parent: _controller, curve: const Cubic(.2, .8, .3, 1));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _anim.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
