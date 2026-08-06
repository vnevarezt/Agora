@TestOn('browser')
library;

import 'package:agora/data/device_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// local_auth has no web implementation. LocalAuthDeviceAuth is supposed to
/// absorb that and report "this device cannot", so Settings simply omits the
/// device-unlock toggle instead of the screen blowing up when it asks.
///
/// Run with: flutter test --platform chrome test/web
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('isSupported reports false rather than throwing', () async {
    expect(await LocalAuthDeviceAuth().isSupported(), isFalse);
  });

  test('authenticate reports a refusal rather than throwing', () async {
    expect(await LocalAuthDeviceAuth().authenticate('unlock'), isFalse);
  });
}
