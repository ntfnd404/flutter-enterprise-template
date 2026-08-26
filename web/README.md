# Drift Web runtime files

The shared application database uses Drift on every Flutter target. Web builds
need two checked-in runtime files in this directory:

- [`drift_worker.js`](https://github.com/simolus3/drift/releases/download/drift-2.34.3/drift_worker.js)
  from Drift `2.34.3`:
  `4db0469de8ceabad8d5cd3d920614486ba587e100e39523f36f704a3aec5f26c`;
- [`sqlite3.wasm`](https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.1/sqlite3.wasm)
  from sqlite3 `3.5.1`:
  `13d3f11d05b39ba0618a7115fb41640a5d48b6300f5d3f325f554b42bd6688a4`.

The files came from the corresponding official GitHub releases. These exact
versions form the Web runtime matrix currently compatible with the pinned
Flutter test toolchain. When Drift, sqlite3, or Flutter is upgraded, review the
three packages together, download matching runtime artifacts from the official
releases, record and review their SHA-256 digests, run schema generation, and
execute the real browser persistence test before accepting the upgrade.
The AppDatabase test suite also rejects a mismatch between pinned dependency
versions, this provenance record, and the checked-in artifact digests.
The required license texts are retained in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

Production hosting must serve `sqlite3.wasm` with
`Content-Type: application/wasm`. COOP/COEP headers improve the available Drift
storage mode but require compatibility review with authentication flows that
open cross-origin popups.
