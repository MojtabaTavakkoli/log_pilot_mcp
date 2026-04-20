## 1.1.0-beta.1

Beta release focused on documentation quality and discoverability.

### Docs: README Restructure

- **Moved "Dart MCP vs LogPilot MCP"** disambiguation table from the bottom
  to directly after "How It Works" — answers the first question new users have.
- **Added "Recommended Debugging Workflow"** (6-step guide) so agents reading
  only this README get the same guidance that was previously only in the
  `log_pilot` README.
- **De-emphasized the dev-dependency Windows Cursor config** — collapsed the
  15-line JSON example into a one-line description since global activation
  (shown above it) avoids the complexity entirely.
- **Added fragility warning to Flutter Web helper scripts** — the bash/PowerShell
  one-liners parse `flutter run` console output and may break across SDK versions.
- **Recommended manual URI copy as the primary Flutter Web approach**, with
  the helper scripts as an optional automation.

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
