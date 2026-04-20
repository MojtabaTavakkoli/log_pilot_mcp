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

### Dart MCP vs LogPilot MCP

These are two separate MCP servers that complement each other:

| Need | Use |
|------|-----|
| Widget tree, hot reload, runtime errors | Dart MCP (`user-dart`) |
| Structured logs, snapshots, log level control | LogPilot MCP (`log_pilot_mcp`) |
| Static analysis, linting | Dart MCP (`analyze_files`) |

Both can run simultaneously.

---

## Quick Start

### 1. Install

**Global activation (recommended — avoids working-directory problems):**

```bash
dart pub global activate log_pilot_mcp
```

Or add as a dev dependency in your Flutter app:

```bash
dart pub add --dev log_pilot_mcp
```

> **Why prefer global activation?** When installed as a dev dependency,
> `dart run log_pilot_mcp` only works from the directory containing the
> `pubspec.yaml` that lists it. IDEs often start MCP server processes
> from a different working directory (the workspace root, which may not
> be your Flutter app root). Global activation gives you a standalone
> executable that works from anywhere.

### 2. Set up your Flutter app

Your app must call `LogPilot.init()` or `LogPilot.configure()` — both
register the service extensions the MCP server needs. If your app already
uses one of these, you're good.

```dart
// Option A — simple apps:
void main() {
  LogPilot.init(child: const MyApp());
}

// Option B — Firebase / async startup:
void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    LogPilot.configure(config: LogPilotConfig.debug());
    await Firebase.initializeApp();
    runApp(const MyApp());
  }, (error, stack) { /* ... */ });
}
```

### 3. Run your Flutter app

```bash
flutter run
```

LogPilot writes the VM service URI to `.dart_tool/log_pilot_vm_service_uri`
automatically on native platforms.

### 4. Configure your IDE

Pick your IDE below for exact setup instructions.

<details>
<summary><b>Cursor</b></summary>

Create or edit `.cursor/mcp.json` in your **workspace root**:

**If globally activated (recommended):**

```json
{
  "mcpServers": {
    "LogPilot": {
      "command": "log_pilot_mcp",
      "args": ["--project-root=/path/to/your-flutter-app"]
    }
  }
}
```

On **Windows**, use the full path to the executable:

```json
{
  "mcpServers": {
    "LogPilot": {
      "command": "C:\\Users\\you\\AppData\\Local\\Pub\\Cache\\bin\\log_pilot_mcp.bat",
      "args": ["--project-root=C:/Users/you/your-flutter-app"]
    }
  }
}
```

**If installed as a dev dependency** (macOS/Linux):

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

On **Windows** with a dev dependency, also add `--project-root` and `cwd`:
`"cwd": "C:/Users/you/your-flutter-app"` and
`"--project-root=C:/Users/you/your-flutter-app"` in args. Global
activation avoids this complexity entirely.

**Enable the server (3 steps — all required):**

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P`) → **"Developer: Reload Window"**
2. Open **Cursor Settings → MCP** and **toggle LogPilot ON** (defaults to OFF)
3. Verify a green dot appears next to LogPilot

</details>

<details>
<summary><b>VS Code (GitHub Copilot)</b></summary>

Create or edit `.vscode/mcp.json` in your **workspace root**:

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

On **Windows**, add `--project-root=C:/Users/you/your-flutter-app`.

**Enable:** Reload the window (`Ctrl+Shift+P` → "Developer: Reload
Window") and verify LogPilot appears in the MCP panel.

</details>

<details>
<summary><b>Windsurf</b></summary>

Edit the **global** config at `~/.codeium/windsurf/mcp_config.json`:

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

Merge into existing `mcpServers` if the file already has other servers.
On **Windows**, add `--project-root=C:/Users/you/your-flutter-app`.

</details>

<details>
<summary><b>Claude Code (CLI)</b></summary>

Pass the URI directly:

```bash
dart run log_pilot_mcp --vm-service-uri=ws://127.0.0.1:PORT/TOKEN=/ws
```

Or via environment variable:

```bash
export LOG_PILOT_VM_SERVICE_URI=ws://127.0.0.1:PORT/TOKEN=/ws
dart run log_pilot_mcp
```

For persistent config, add to `~/.claude/mcp.json`:

```json
{
  "mcpServers": {
    "LogPilot": {
      "command": "dart",
      "args": [
        "run", "log_pilot_mcp",
        "--project-root=/path/to/your-flutter-app"
      ]
    }
  }
}
```

</details>

<details>
<summary><b>Antigravity</b></summary>

1. Open **IDE Settings → MCP** panel
2. Add a new MCP server with:
   - **Command:** `dart`
   - **Args:** `run log_pilot_mcp`
3. On **Windows**, add `--project-root=C:/Users/you/your-flutter-app`
4. Toggle the server ON and verify it connects

</details>

<details>
<summary><b>Gemini CLI</b></summary>

Edit `~/.gemini/settings.json`:

```json
{
  "mcpServers": {
    "LogPilot": {
      "command": "dart",
      "args": [
        "run", "log_pilot_mcp",
        "--project-root=/path/to/your-flutter-app"
      ]
    }
  }
}
```

</details>

<details>
<summary><b>Other MCP clients</b></summary>

Any stdio-based MCP client works:

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

On Windows, add `--project-root=<ABSOLUTE_PATH>` to args. Consult your
client's docs for the config file location.

</details>

> **Important: working directory.** `dart run log_pilot_mcp` must execute
> from a directory where `log_pilot_mcp` is a dependency (listed in
> `pubspec.yaml`). If your IDE workspace root differs from your Flutter
> app directory (monorepo, subdirectory app, etc.), add `"cwd"` to the
> server config:
>
> ```json
> {
>   "mcpServers": {
>     "LogPilot": {
>       "command": "dart",
>       "args": ["run", "log_pilot_mcp"],
>       "cwd": "/absolute/path/to/your-flutter-app"
>     }
>   }
> }
> ```
>
> The `cwd` must point to the directory containing the `pubspec.yaml`
> that lists `log_pilot_mcp` as a dev dependency.

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

### Recommended Debugging Workflow

1. `get_snapshot` — see errors, config, active timers
2. `set_log_level(level: "verbose")` — increase detail
3. Reproduce the issue
4. `query_logs(level: "error", deduplicate: true)` — find root cause
5. `export_for_llm(token_budget: 2000)` — compressed context for analysis
6. `set_log_level(level: "warning")` — restore quiet mode

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

The URI changes on every app restart. The simplest approach is to copy
the `ws://...` URI from the debug console. For automation, you can use
`--vm-service-uri-file` with a helper script, but note these parse
Flutter's console output and **may break across SDK versions**:

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

## Troubleshooting

**Diagnosis checklist — follow in order:**

1. **Is the server visible in your IDE?** No → reload the IDE window
   after creating/editing the MCP config. New servers default to OFF.
2. **Does it show a green/connected status?** No → the app is probably
   not running, or auto-discovery failed. Continue below.
3. **Is the app running in debug mode?** Must be `flutter run` (not
   `--release`). VM service is only available in debug/profile.
4. **Does `.dart_tool/log_pilot_vm_service_uri` exist in your project?**
   No → the app must call `LogPilot.init()` or `LogPilot.configure()`.
   On Windows, add `--project-root` to the MCP server args.
5. **Call `get_snapshot`.** If it returns data, you're connected.

**Common errors:**

| Error | Cause | Fix |
|-------|-------|-----|
| Server shows "Disabled" | IDE default for new servers | Toggle the switch **ON** in MCP settings |
| Server not in MCP list | Config not loaded | `Ctrl+Shift+P` → "Developer: Reload Window" |
| `Could not find package "log_pilot_mcp"` | Package not installed | `dart pub add --dev log_pilot_mcp` |
| `Failed to connect to VM service` | App not running or URI stale | Start the app; check if the URI file contains a valid `ws://` URI |
| `getVM: (-32601) Unknown method` | The URI points to something that isn't a Dart VM service (stale or invalid URI) | Restart the app to regenerate the URI file. If using `--vm-service-uri`, copy a fresh URI from the debug console. |
| `No isolates found` | App's main isolate hasn't started yet | Wait and retry; auto-retries up to 3 times |
| `LogPilot library not found and no service extensions registered` | App doesn't depend on `log_pilot` or hasn't called `init()`/`configure()` | Add `log_pilot` to pubspec.yaml and call `LogPilot.init()` or `LogPilot.configure()` |
| `Service extensions available: false` | `init()`/`configure()` hasn't run yet | Ensure `init()` or `configure()` runs on app start. The server detects extensions as they register. |
| "Waiting for VM service URI..." forever | Flutter Web (no `dart:io`) or missing `.dart_tool` | Pass `--vm-service-uri` directly, or add `--project-root` on Windows |
| Tools fail after hot restart | Normal reconnection | Auto-recovers; retry the tool call |

---

## Requirements

- The Flutter app must depend on [`log_pilot`](https://pub.dev/packages/log_pilot) and call **`LogPilot.init()` or `LogPilot.configure()`** — both register the service extensions the MCP server needs.
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
