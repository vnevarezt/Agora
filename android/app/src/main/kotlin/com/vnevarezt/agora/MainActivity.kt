package com.vnevarezt.agora

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity): local_auth shows its
// biometric prompt through androidx.biometric, which needs a FragmentActivity.
class MainActivity : FlutterFragmentActivity()
