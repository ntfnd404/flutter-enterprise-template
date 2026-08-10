# Drift Web runtime files

The shared application database uses Drift on every Flutter target. Web builds
need two checked-in runtime files in this directory:

- [`drift_worker.js`](https://github.com/simolus3/drift/releases/download/drift-2.34.0/drift_worker.js)
  from Drift `2.34.0`:
  `b8b9f88cdfa0582eedacf3b55f6133b7d9bea7c8e74d4dc019a380da9976a7a8`;
- [`sqlite3.wasm`](https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.3.0/sqlite3.wasm)
  from sqlite3 `3.3.0`:
  `3c611e38db0a2609c34a141ccf70c89b407b262c9bf06877c4ba213cf9f3624b`.

The files came from the corresponding official GitHub releases. These exact
versions form the Web runtime matrix currently compatible with the pinned
Flutter test toolchain. When Drift, sqlite3, or Flutter is upgraded, review the
three packages together, download matching runtime artifacts from the official
releases, record and review their SHA-256 digests, run schema generation, and
execute the real browser persistence test before accepting the upgrade.
The required license texts are retained in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

Production hosting must serve `sqlite3.wasm` with
`Content-Type: application/wasm`. COOP/COEP headers improve the available Drift
storage mode but require compatibility review with authentication flows that
open cross-origin popups.
