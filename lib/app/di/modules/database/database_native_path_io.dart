import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Resolves a stable native application-support path for the database file.
Future<String> resolveNativeDatabasePath({required String fileName}) async {
  final directory = await getApplicationSupportDirectory();
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return path.join(directory.path, fileName);
}
