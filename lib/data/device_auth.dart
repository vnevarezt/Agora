import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// OS-level identity check (Touch ID / Face ID / fingerprint, falling back to
/// the device PIN/password). Injectable so unit tests can fake it: local_auth
/// needs platform channels.
abstract interface class DeviceAuth {
  /// Whether THIS device can authenticate its owner at all (biometrics
  /// enrolled or a device credential set). False on errors: the feature just
  /// doesn't show up.
  Future<bool> isSupported();

  /// Shows the OS prompt. True only when the user passed it; false on
  /// cancel/failure (the OS already showed its own feedback).
  Future<bool> authenticate(String reason);
}

class LocalAuthDeviceAuth implements DeviceAuth {
  LocalAuthDeviceAuth();

  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on LocalAuthException {
      // notEnrolled/lockedOut/canceled…: treat as "did not authenticate".
      return false;
    } catch (_) {
      return false;
    }
  }
}

final deviceAuthProvider = Provider<DeviceAuth>((ref) => LocalAuthDeviceAuth());

/// Settings watches this to decide whether the device-unlock toggle exists.
final deviceAuthSupportedProvider =
    FutureProvider<bool>((ref) => ref.watch(deviceAuthProvider).isSupported());
