export 'database_native_path_unsupported.dart'
    if (dart.library.io) 'database_native_path_io.dart'
    if (dart.library.js_interop) 'database_native_path_web.dart';
