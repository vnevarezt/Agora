// The drop target this platform can offer: a real one in the browser, nothing
// anywhere else.
export 'notebook_drop_stub.dart'
    if (dart.library.js_interop) 'notebook_drop_web.dart';
