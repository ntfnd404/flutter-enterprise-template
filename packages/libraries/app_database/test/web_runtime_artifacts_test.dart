import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

const _driftVersion = '2.34.3';
const _driftWorkerSha256 =
    '4db0469de8ceabad8d5cd3d920614486ba587e100e39523f36f704a3aec5f26c';
const _driftWorkerUrl =
    'https://github.com/simolus3/drift/releases/download/'
    'drift-2.34.3/drift_worker.js';
const _sqlite3Version = '3.5.1';
const _sqlite3WasmSha256 =
    '13d3f11d05b39ba0618a7115fb41640a5d48b6300f5d3f325f554b42bd6688a4';
const _sqlite3WasmUrl =
    'https://github.com/simolus3/sqlite3.dart/releases/download/'
    'sqlite3-3.5.1/sqlite3.wasm';

void main() {
  test('Web runtime artifacts match dependencies and provenance', () {
    final packageRoot = _packageRoot();
    final repositoryRoot = packageRoot.parent.parent.parent;
    final pubspec = File('${packageRoot.path}/pubspec.yaml').readAsStringSync();
    final webRoot = Directory('${repositoryRoot.path}/web');
    final readme = File('${webRoot.path}/README.md').readAsStringSync();

    expect(
      pubspec,
      contains(RegExp('^  drift: $_driftVersion\$', multiLine: true)),
    );
    expect(
      pubspec,
      contains(RegExp('^  sqlite3: $_sqlite3Version\$', multiLine: true)),
    );
    expect(
      _sha256(File('${webRoot.path}/drift_worker.js')),
      _driftWorkerSha256,
    );
    expect(
      _sha256(File('${webRoot.path}/sqlite3.wasm')),
      _sqlite3WasmSha256,
    );
    for (final expected in <String>[
      _driftVersion,
      _driftWorkerSha256,
      _driftWorkerUrl,
      _sqlite3Version,
      _sqlite3WasmSha256,
      _sqlite3WasmUrl,
    ]) {
      expect(readme, contains(expected));
    }
  });
}

Directory _packageRoot() {
  final entrypoint = Isolate.resolvePackageUriSync(
    Uri.parse('package:app_database/app_database_composition.dart'),
  );
  if (entrypoint == null) {
    throw StateError('Unable to resolve the AppDatabase package root.');
  }

  return File.fromUri(entrypoint).parent.parent;
}

String _sha256(File file) => sha256.convert(file.readAsBytesSync()).toString();
