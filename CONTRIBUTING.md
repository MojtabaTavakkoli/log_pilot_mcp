# Contributing to log_pilot_mcp

Thanks for your interest in contributing! This is the standalone MCP server
for [log_pilot](https://github.com/MojtabaTavakkoli/log_pilot).

## Repository Structure

```
log_pilot_mcp/
├── bin/
│   └── log_pilot_mcp.dart          # CLI entrypoint (arg parsing, file watcher, server bootstrap)
├── lib/
│   ├── log_pilot_mcp.dart          # Barrel export
│   └── src/
│       └── log_pilot_mcp_server.dart   # MCP server implementation (tools, resources, VM service)
├── test/
│   └── log_pilot_mcp_test.dart     # Unit tests for public helpers
├── pubspec.yaml
├── analysis_options.yaml
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Architecture

```
bin/log_pilot_mcp.dart   — CLI entrypoint
  ├─ arg parsing         — --vm-service-uri, --vm-service-uri-file, --project-root, --help
  ├─ auto-discovery      — locates .dart_tool/log_pilot_vm_service_uri
  ├─ file watcher        — watches URI file for changes (reconnect on app restart)
  └─ server bootstrap    — creates LogPilotMcpServer with stdio channel

LogPilotMcpServer        — MCPServer with ToolsSupport, ResourcesSupport, LoggingSupport
  ├─ VM service layer    — connect, reconnect, isolate resolution, library resolution
  ├─ service extensions  — preferred path: ext.LogPilot.* RPCs (zero import overhead)
  ├─ eval fallback       — expression evaluation for older log_pilot versions
  ├─ 9 tools             — get_snapshot, query_logs, export_logs, export_for_llm,
  │                        set_log_level, get_log_level, clear_logs, watch_logs, stop_watch
  └─ 3 resources         — LogPilot://config, LogPilot://session, LogPilot://tail
```

### Design Decisions

- **Service extensions first, eval fallback** — Service extensions
  (`ext.LogPilot.*`) are the preferred communication path. They work on all
  platforms including web and don't require library resolution. Expression
  evaluation is the fallback for older `log_pilot` versions that don't
  register all extensions.

- **Auto-reconnect** — The server watches for isolate lifecycle events and
  file changes. When the app restarts, it reconnects automatically instead
  of requiring manual reconfiguration.

- **Input sanitization** — All user-provided filter values are escaped via
  `_escapeForEval()` before interpolation into `evaluate` expressions,
  preventing code injection.

- **Pure Dart** — No Flutter SDK dependency. This keeps the install lightweight
  and startup fast. The server only needs `dart_mcp` and `vm_service`.

## Development

### Prerequisites

- Dart SDK >= 3.9.2

### Running Tests

```bash
dart test
```

### Running the Analyzer

```bash
dart analyze
```

### Testing Manually

1. Start a Flutter app that uses `log_pilot`:
   ```bash
   cd /path/to/your/flutter/app
   flutter run
   ```
2. Run the MCP server pointing at the app:
   ```bash
   dart run bin/log_pilot_mcp.dart --vm-service-uri=ws://127.0.0.1:PORT/TOKEN=/ws
   ```

### Branch Naming

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New functionality | `feature/new-tool-xyz` |
| `fix/` | Bug fix | `fix/reconnect-race` |
| `docs/` | Documentation only | `docs/web-setup-guide` |
| `refactor/` | Restructuring, no behavior change | `refactor/extract-watcher` |
| `test/` | Adding or fixing tests | `test/watch-timer-edge` |
| `chore/` | CI, tooling, dependencies | `chore/bump-dart-mcp` |

Keep names lowercase with hyphens. Branches are deleted after merge.

### Commit Messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): short description
```

**Types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`

**Scopes:** `server`, `tools`, `resources`, `cli`, `watcher`, `eval`, `deps`

Examples:

```
feat(tools): add filter-by-metadata-key to query_logs
fix(watcher): prevent overlapping polls on slow connections
docs: update Flutter Web setup instructions
chore(deps): bump dart_mcp to ^0.6.0
```

### Changelog

Update `CHANGELOG.md` for any user-facing change. Use
[Keep a Changelog](https://keepachangelog.com/) section names:

- **Added** — new features
- **Fixed** — bug fixes
- **Changed** — changes to existing behavior
- **Breaking** — breaking API changes
- **Removed** — removed features

### Submitting Changes

1. Fork the repository
2. Create a branch from `main` using the naming convention above
3. Make your changes with tests
4. Run `dart test` and `dart analyze`
5. Update `CHANGELOG.md` if the change is user-facing
6. Commit using the Conventional Commits format
7. Submit a pull request

## Relationship to log_pilot

This package is the MCP server companion to
[log_pilot](https://github.com/MojtabaTavakkoli/log_pilot). It communicates
with `log_pilot` through the Dart VM service protocol — it does **not**
import `log_pilot` as a dependency.

Changes to `log_pilot`'s service extensions (`ext.LogPilot.*`) may require
corresponding updates here. When adding a new extension in `log_pilot`,
add a matching tool or resource in this package.

## License

[MIT](LICENSE)
