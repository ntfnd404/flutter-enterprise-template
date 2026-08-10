/// Returns no path on platforms without an application database connector.
Future<String?> resolveNativeDatabasePath({required String fileName}) async =>
    null;
