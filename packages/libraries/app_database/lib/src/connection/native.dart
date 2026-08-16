import 'dart:io';

import 'package:app_database/src/configuration/app_database_configuration.dart';
import 'package:app_database/src/configuration/app_database_configuration_exception.dart';
import 'package:app_database/src/connection/app_database_connection.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;

/// Opens the application database on a background native isolate.
Future<AppDatabaseConnection> connect(
  AppDatabaseConfiguration configuration,
) async {
  final nativePath = configuration.nativePath;
  if (nativePath == null) {
    throw const AppDatabaseConfigurationException(
      AppDatabaseConfigurationFailure.missingNativePath,
    );
  }
  if (!path.isAbsolute(nativePath)) {
    throw const AppDatabaseConfigurationException(
      AppDatabaseConfigurationFailure.nonAbsoluteNativePath,
    );
  }

  return AppDatabaseConnection(
    executor: NativeDatabase.createInBackground(File(nativePath)),
    storageKind: AppDatabaseStorageKind.native,
  );
}
