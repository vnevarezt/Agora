// The document language is a browser concept; every other platform gets a
// no-op rather than a conditional at each call site.
export 'document_lang_stub.dart'
    if (dart.library.js_interop) 'document_lang_web.dart';
