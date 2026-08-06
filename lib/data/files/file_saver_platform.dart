// The three platform primitives [FileSaver] needs, split out because they are
// the only parts of saving that dart:io can reach.
//
// Native and web disagree on what "save" means: native picks a location and
// then writes to it, while a browser hands the bytes to its own download
// machinery and decides the location itself. The seam keeps that difference out
// of FileSaver, which is otherwise identical everywhere.
export 'file_saver_platform_native.dart'
    if (dart.library.js_interop) 'file_saver_platform_web.dart';
