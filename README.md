# log_pilot_mcp

[![pub package](https://img.shields.io/pub/v/log_pilot_mcp.svg)](https://pub.dev/packages/log_pilot_mcp)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

MCP (Model Context Protocol) server for [log_pilot](https://pub.dev/packages/log_pilot).
Gives AI coding agents in **Cursor, Claude Code, Windsurf**, and other
MCP-compatible tools direct access to your running Flutter app's log state.

---

## How It Works

```
+----------------+                    +------------------+
|  Flutter App   | -- VM Service ---> |  log_pilot_mcp   |
|  (debug mode)  | <-- ext.LogPilot.* |  (MCP server)    |
+-------+--------+                    +---------+--------+
        |                                       |
        | writes URI                            | MCP protocol
        | on start                              |
        v                                       v
  .dart_tool/                          +------------------+
  log_pilot_vm_service_uri             | Cursor / Claude  |
        |                              | Windsurf / ...   |
        +--- watched by MCP server --->+------------------+
```

`log_pilot_mcp` connects to your app's Dart VM service and uses LogPilot's
service extensions (`ext.LogPilot.*`) to query logs, take diagnostic
snapshots, change log levels, and more — without editing code or restarting.

The server **auto-reconnects** on hot restart, isolate recycle, and full
app restart (when using file-watcher auto-discovery).

---

## Quick Start

### 1. Install

Add as a dev dependency in your Flutter app:

```bash
dart pub add --dev log_pilot_mcp
```

Or activate globally:

```bash
dart pub global activate log_pilot_mcp
```

### 2. Run your Flutter app

```bash
flutter run
```

LogPilot writes the VM service URI to `.dart_tool/log_pilot_vm_service_uri`
automatically on native platforms.

### 3. Configure your IDE

Create `.cursor/mcp.json` in your **project root**:

```json
{
  "mcpServers": {
    "LogPilot": {
      "command": "dart",
      "args": ["run", "log_pilot_mcp"]
    }
  }
}
```

> **Windows users:** Cursor's working directory often differs from your
> project root. Always add `--project-root` to avoid connection issues:
>
> ```json
> {
>   "mcpServers": {
>     "LogPilot": {
>       "command": "dart",
>       "args": [
>         "run", "log_pilot_mcp",
>         "--project-root=C:/Users/you/your-app"
>       ]
>     }
>   }
> }
> ```

### 4. Enable the server in Cursor

> **You MUST complete all three steps — the server will NOT work otherwise.**

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P`) → **"Developer: Reload Window"**
2. Open **Cursor Settings → MCP** and **toggle LogPilot ON** (defaults to OFF)
3. Verify a green dot appears next to LogPilot

### 5. Verify

Ask the agent to call `get_snapshot` or `get_log_level` — if it returns
data, you're connected.

---

## When the App Restarts

**Hot restart (same debug session):** Auto-reconnects — no action needed.

**Full restart (new debug session):**
- **Auto-discovery mode** (no `--vm-service-uri` flag): the URI file updates
  automatically and the server reconnects on its own.
- **Manual URI mode** (`--vm-service-uri` in `mcp.json`): update the URI
  value and reload the Cursor window.

---

## MCP Tools

| Tool | Description |
|------|-------------|
| `get_snapshot` | Structured diagnostic summary: errors, timers, config, recent logs. Supports `group_by_tag`. |
| `query_logs` | Filter history by level, tag, message, trace ID, error presence, metadata key. |
| `export_logs` | Full log history as text or NDJSON. |
| `export_for_llm` | Compressed summary optimized for LLM context windows. |
| `set_log_level` | Change verbosity at runtime. |
| `get_log_level` | Read the current minimum log level. |
| `clear_logs` | Wipe in-memory log history. |
| `watch_logs` | Stream new entries via MCP notifications. |
| `stop_watch` | Stop the active watcher and get a delivery summary. |

### `get_snapshot` Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `max_recent_errors` | int | 5 | Max error/fatal records |
| `max_recent_logs` | int | 10 | Max recent records of any level |
| `group_by_tag` | bool | false | Include a `recentByTag` section |
| `per_tag_limit` | int | 5 | Records per tag when grouped |

### `query_logs` Parameters

All filters combine with AND logic.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `level` | string | — | Minimum log level filter |
| `tag` | string | — | Exact tag match |
| `message_contains` | string | — | Case-insensitive substring search |
| `trace_id` | string | — | Filter by exact trace ID |
| `has_error` | bool | — | `true` = only errors, `false` = only non-errors |
| `metadata_key` | string | — | Only records whose metadata contains this key |
| `limit` | int | 20 | Max records (1–100) |
| `deduplicate` | bool | false | Collapse consecutive identical entries (same level + message + caller). Service-extension mode only; eval fallback returns without deduplication. |

### `export_for_llm` Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `token_budget` | int | 4000 | Max output size in approximate tokens (~4 chars/token) |

### `watch_logs` Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `tag` | string | — | Only deliver entries with this tag |
| `level` | string | — | Minimum log level filter |
| `interval_ms` | int | 2000 | Poll interval in milliseconds (500–30 000) |

---

## MCP Resources

| Resource | Description |
|----------|-------------|
| `LogPilot://config` | Current LogPilot configuration snapshot |
| `LogPilot://session` | Session ID and trace ID |
| `LogPilot://tail` | Latest batch from the active watcher (subscribable) |

---

## Claude Code

For Claude Code or other CLI-based MCP clients, pass the URI directly:

```bash
dart run log_pilot_mcp --vm-service-uri=ws://127.0.0.1:PORT/TOKEN=/ws
```

Or via environment variable:

```bash
export LOG_PILOT_VM_SERVICE_URI=ws://127.0.0.1:PORT/TOKEN=/ws
dart run log_pilot_mcp
```

---

## Flutter Web

Auto-discovery is **not available** on Flutter Web (`dart:io` is
unavailable). Pass `--vm-service-uri` directly:

```json
{
  "mcpServers": {
    "LogPilot": {
      "command": "dart",
      "args": [
        "run", "log_pilot_mcp",
        "--vm-service-uri=ws://127.0.0.1:PORT/TOKEN=/ws"
      ]
    }
  }
}
```

The URI changes on every app restart. To avoid manual editing, use
`--vm-service-uri-file` with a helper script that captures the URI:

**macOS / Linux:**

```bash
flutter run -d chrome --machine 2>&1 \
  | grep -o 'ws://[^ "]*' | head -1 \
  > .dart_tool/log_pilot_vm_service_uri
```

**Windows (PowerShell):**

```powershell
flutter run -d chrome --machine 2>&1 |
  Select-String -Pattern 'ws://[^ "]+' |
  ForEach-Object { $_.Matches[0].Value } |
  Select-Object -First 1 |
  Set-Content .dart_tool\log_pilot_vm_service_uri
```

Then point the MCP server at the file:

```json
{
  "mcpServers": {
    "LogPilot": {
      "command": "dart",
      "args": [
        "run", "log_pilot_mcp",
        "--vm-service-uri-file=.dart_tool/log_pilot_vm_service_uri"
      ]
    }
  }
}
```

The server watches the file, so when you restart the app and re-run the
capture script, it reconnects automatically.

---

## Dart MCP vs LogPilot MCP

These are two separate MCP servers that complement each other:

| Need | Use |
|------|-----|
| Widget tree, hot reload, runtime errors | Dart MCP (`user-dart`) |
| Structured logs, snapshots, log level control | LogPilot MCP (`log_pilot_mcp`) |
| Static analysis, linting | Dart MCP (`analyze_files`) |

Both can run simultaneously.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Server shows "Disabled" in Cursor MCP settings | Toggle the switch ON — new servers default to OFF. |
| Server not appearing in MCP list | `Ctrl+Shift+P` → "Developer: Reload Window" first. |
| `Failed to connect to VM service` | App isn't running in debug/profile mode, or URI is stale. |
| "Waiting for VM service URI..." forever | Flutter Web — auto-discovery is unavailable. Pass `--vm-service-uri`. |
| Auto-discovery file not created | Pass `--project-root=<APP_PATH>` or use `--vm-service-uri` manually. |
| Tools fail after hot restart | Auto-recovers; the server retries up to 3 times with backoff. |
| Server connects but tools return errors | The app must import and initialize `log_pilot` (`LogPilot.init()`). |

---

## Requirements

- The Flutter app must depend on [`log_pilot`](https://pub.dev/packages/log_pilot) and call `LogPilot.init()` or `LogPilot.configure()`.
- The app must run in **debug or profile mode** (VM service is unavailable in release builds).
- Dart SDK >= 3.9.2.

---

## CLI Reference

```
dart run log_pilot_mcp [options]

Options:
  --vm-service-uri=URI        Connect to this VM service URI directly.
  --vm-service-uri-file=PATH  Read the URI from a file (watched for changes).
  --project-root=PATH         Absolute path to the Flutter app's project root.
  -h, --help                  Show usage information.

Environment:
  LOG_PILOT_VM_SERVICE_URI    Fallback URI when no flags are provided.
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, code style, and
submission guidelines.

## License

[MIT](LICENSE)
