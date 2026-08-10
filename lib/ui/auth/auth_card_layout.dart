import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

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
                      fontSize: AppText.caption,
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
              fontSize: AppText.body,
              fontWeight: FontWeight.w800,
              color: t.accentInk,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          context.t.app.brand,
          style: TextStyle(
            fontSize: AppText.bodyLarge,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: t.text,
          ),
        ),
      ],
    );
  }
}

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

class AuthSub extends StatelessWidget {
  const AuthSub(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AppText.body,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: context.tokens.textMute,
      ),
    );
  }
}
