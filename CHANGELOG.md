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
