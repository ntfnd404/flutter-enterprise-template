import 'package:app_database/src/configuration/app_database_configuration.dart';
import 'package:app_database/src/connection/app_database_connection.dart';

import 'unsupported.dart'
    if (dart.library.ffi) 'native.dart'
    if (dart.library.js_interop) 'web.dart'
    as platform;

/// Opens one physical database connection for a validated configuration.
///
/// This construction-only contract is package-internal. Production always
/// uses [connect]; tests may inject a controlled connector at the module seam.
typedef AppDatabaseConnector = Future<AppDatabaseConnection> Function(
  AppDatabaseConfiguration configuration,
);

/// Opens a physical database through the connector selected for this platform.
Future<AppDatabaseConnection> connect(AppDatabaseConfiguration configuration) =>
    platform.connect(configuration);
