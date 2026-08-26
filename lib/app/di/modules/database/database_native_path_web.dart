/// Returns no native path because Drift selects browser-managed Web storage.
Future<String?> resolveNativeDatabasePath({required String fileName}) async =>
    null;
