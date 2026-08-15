import 'dart:async';

import 'package:flutter/widgets.dart';

mixin ResendCooldown<T extends StatefulWidget> on State<T> {
  static const _cooldown = Duration(seconds: 30);

  Timer? _cooldownTimer;
  int cooldownLeft = 0;

  void startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => cooldownLeft = _cooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => cooldownLeft--);
      if (cooldownLeft <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
