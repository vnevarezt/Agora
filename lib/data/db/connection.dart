// Platform-specific database connection.
//
// Native builds open the SQLite3MultipleCiphers file with the DEK. Web builds
// fall back to drift's WASM backend, which is NOT encrypted — see
// `connection_web.dart` for why that is acceptable there and what it costs.
export 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';
