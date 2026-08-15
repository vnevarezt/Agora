import 'package:flutter/widgets.dart';

import '../../i18n/strings.g.dart';
import '../../state/cloud_auth.dart';

String cloudAuthErrorText(BuildContext context, CloudAuthErrorCode code) {
  final e = context.t.account.errors;
  return switch (code) {
    CloudAuthErrorCode.invalidEmail => e.invalidEmail,
    CloudAuthErrorCode.userNotFound => e.userNotFound,
    CloudAuthErrorCode.wrongPassword => e.wrongPassword,
    CloudAuthErrorCode.emailInUse => e.emailInUse,
    CloudAuthErrorCode.weakPassword => e.weakPassword,
    CloudAuthErrorCode.network => e.network,
    CloudAuthErrorCode.tooManyRequests => e.tooManyRequests,
    CloudAuthErrorCode.canceled ||
    CloudAuthErrorCode.requiresRecentLogin ||
    CloudAuthErrorCode.unknown =>
      e.unknown,
  };
}
