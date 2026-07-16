import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../responsive.dart';
import '../theme/tokens.dart';

/// `.auth__main` + `.auth__card`: 400px column centered on the app
/// background, brand lockup on top and the legal line at the bottom.
/// Mobile (<720): top-aligned, full width, larger title handled by
/// [AuthTitle].
class AuthCardLayout extends StatelessWidget {
  const AuthCardLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final mobile = context.isMobile;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Align(
          alignment: mobile ? Alignment.topCenter : Alignment.center,
          child: SingleChildScrollView(
            padding: mobile
                ? const EdgeInsets.fromLTRB(20, 34, 20, 34)
                : const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandLockup()),
                  SizedBox(height: mobile ? 24 : 22),
                  child,
                  const SizedBox(height: 26),
                  Text(
                    context.t.portada.legal,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: t.textMute,
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

/// `.brand`: the same mark + name lockup as the dashboard sidebar.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.accent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            'JW',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: t.accentInk,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          context.t.app.brand,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: t.text,
          ),
        ),
      ],
    );
  }
}

/// `.auth__title` (22px desktop / 20px mobile).
class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.isMobile ? 20 : 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.44,
        color: context.tokens.text,
      ),
    );
  }
}

/// `.auth__sub`.
class AuthSub extends StatelessWidget {
  const AuthSub(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: context.tokens.textMute,
      ),
    );
  }
}
