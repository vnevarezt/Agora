// Runs CPU-bound work off the UI isolate where there is one.
//
// The web has no isolates: `Isolate.run` throws `Unsupported operation: new
// RawReceivePort` there, which surfaced as a failed PDF preview. Everything
// this project hands to a background isolate — building a PDF, deriving an
// Argon2id key, parsing an EPUB — is pure Dart with no platform channels, so
// the web variant simply runs it inline.
//
// That is a real cost, not a free fallback: inline means on the UI thread, and
// Argon2id at OWASP parameters takes about a second. It is also the only option
// until WASM shared-everything threading lands, and it is what Flutter's own
// `compute` does on the web.
export 'background_native.dart'
    if (dart.library.js_interop) 'background_web.dart';
