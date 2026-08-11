/// Application-only composition API for the shared physical database.
///
/// Only application composition creates and disposes [AppDatabaseModule].
/// Bounded contexts receive narrow stores from the module and never receive the
/// physical database connection.
///
/// {@category database-architecture}
library;

export 'src/app_database_module.dart'
    show AppDatabaseModule, createAppDatabaseModule;
export 'src/app_database_stores.dart' show AppDatabaseStores;
export 'src/configuration/app_database_configuration.dart';
export 'src/configuration/app_database_configuration_exception.dart';
export 'src/connection/app_database_open_exception.dart';
