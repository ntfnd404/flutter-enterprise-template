import 'package:app_database/src/app_database_configuration.dart';
import 'package:app_database/src/connection/app_database_connection.dart';

/// Rejects platforms without a supported Drift executor.
Future<AppDatabaseConnection> connect(
  AppDatabaseConfiguration configuration,
) async => throw UnsupportedError('Application database is unsupported.');
