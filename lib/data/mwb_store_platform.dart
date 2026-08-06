// The [MwbStore] this platform uses by default: a directory on native, an
// IndexedDB object store on web.
export 'mwb_store_native.dart'
    if (dart.library.js_interop) 'mwb_store_web.dart';
