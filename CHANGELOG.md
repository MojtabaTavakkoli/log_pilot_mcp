## 1.1.0

### Added: `write-uri` Command

- **`log_pilot_mcp write-uri <ws://...>`** — write the VM service URI to
  `.dart_tool/log_pilot_vm_service_uri` from the host machine. Bridges the
  gap for **Android/iOS** where the on-device app cannot write to the host
  filesystem. Supports `--project-root` when cwd is not the project root.

### Improved: Friendly Error Messages

- **Stale URI errors** (e.g. `-32601 Unknown method "getVM"`) now surface
  actionable messages like _"VM service not responding — the app may have
  restarted"_ instead of raw RPC error codes.
- **WebSocket/connection failures** now explain _"Cannot connect — is the
  Flutter app running in debug mode?"_ with the original error preserved.
- **Isolate errors** now suggest _"try again in a moment"_ instead of
  exposing internal VM service state.

### Improved: Windows Post-Activation Hint

- `--help` on Windows now prints the exact `LOCALAPPDATA\Pub\Cache\bin\
  log_pilot_mcp.bat` path that should be used in `mcp.json` when the
  executable is not on PATH.

### Docs: README Restructure & Updates

- **CLI Reference** now documents the `write-uri` command.
- **Android/iOS** auto-discovery limitation documented in Quick Start,
  "When the App Restarts", and Troubleshooting sections.
- **Troubleshooting table** updated with friendlier error descriptions and
  an Android/iOS-specific row.
- Moved "Dart MCP vs LogPilot MCP" disambiguation table from the bottom
  to directly after "How It Works".
- Added "Recommended Debugging Workflow" (6-step guide).
- De-emphasized the dev-dependency Windows Cursor config.
- Added fragility warning to Flutter Web helper scripts.
- Recommended manual URI copy as the primary Flutter Web approach.

---

## 1.0.1

- Improved pub.dev score and documentation.
- **Added Example**: Full functioning example in `example/` directory.
- **Improved Documentation**: Added missing dartdoc comments for public API members (`LogPilotMcpServer`, `deduplicateRecords`, `lastEntryId`, `levelIndex`, `parseEntries`).
- **Visuals**: Added package banner and thumbnail via `screenshots` metadata.
- **Bugfixes**: Resolved secondary analyzer warnings in example code.

## 1.0.0

Initial stable release.

### Added

- **9 MCP tools** for AI coding agents:
  - `get_snapshot` — structured diagnostic summary (errors, timers, config, recent logs, group-by-tag)
  - `query_logs` — filter log history by level, tag, message substring, trace ID, error presence, metadata key; supports deduplication
  - `export_logs` — full history as human-readable text or NDJSON
  - `export_for_llm` — compressed summary optimized for LLM context windows
  - `set_log_level` / `get_log_level` — read and change verbosity at runtime
  - `clear_logs` — wipe in-memory log history
  - `watch_logs` / `stop_watch` — stream new entries via MCP log notifications

- **3 MCP resources:**
  - `LogPilot://config` — current LogPilot configuration
  - `LogPilot://session` — session and trace IDs
  - `LogPilot://tail` — latest batch from the active watcher (subscribable)

- **Auto-discovery** of the VM service URI from `.dart_tool/log_pilot_vm_service_uri`
- **Auto-reconnect** on hot restart, isolate recycle, and full app restart (file-watcher mode)
- **Exponential backoff retry** (up to 3 attempts) on transient connection errors
- **Service-extension mode** with automatic fallback to expression evaluation for older `log_pilot` versions
- **Input sanitization** for safe eval interpolation (`_escapeForEval`)
- **`--project-root`** flag for reliable auto-discovery on Windows
- **`--vm-service-uri-file`** flag for Flutter Web with a helper-script workflow
- **`--help` / `-h`** flag with full usage documentation
- **Pure Dart** — no Flutter SDK dependency; lighter install, faster startup
